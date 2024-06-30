defmodule TypedStructor do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MODULEDOC -->", parts: 2)
             |> Enum.fetch!(1)

  defmacro __using__(_opts) do
    quote do
      import TypedStructor, only: [typed_structor: 1, typed_structor: 2]
    end
  end

  @doc """
  Defines a struct with type information.

  Inside a `typed_structor` block, you can define fields with the `field/3` macro.

  ## Options

    * `:module` - if provided, a new submodule will be created with the struct.
    * `:enforce` - if `true`, the struct will enforce the keys, see `field/3` options for more information.
    * `:define_struct` - if `false`, the type will be defined, but the struct will not be defined. Defaults to `true`.
    * `:type_kind` - the kind of type to use for the struct. Defaults to `type`, can be `opaque` or `typep`.
    * `:type_name` - the name of the type to use for the struct. Defaults to `t`.

  ## Examples

      defmodule MyStruct do
        use TypedStructor

        typed_structor do
          field :name, String.t()
          field :age, integer()
        end
      end

  Creates the struct in a submodule instead:

      defmodule MyStruct do
        use TypedStructor

        typed_structor module: Struct do
          field :name, String.t()
          field :age, integer()
        end
      end

  To add a `@typedoc` to the struct type and `@moduledoc` to the submodule,
  just add the module attribute in the `typed_structor` block:

      defmodule MyStruct do
        use TypedStructor

        typed_structor module: Struct do
          @typedoc "A typed struct"
          @moduledoc "A submodule"

          field :name, String.t()
          field :age, integer()
        end
      end
  """
  defmacro typed_structor(options \\ [], do: block) when is_list(options) do
    register_plugins =
      for {plugin, opts} <- get_global_plugins() do
        quote do
          TypedStructor.plugin(unquote(plugin), unquote(opts))
        end
      end

    definition =
      quote do
        {module, options} = Keyword.pop(unquote(options), :module, __MODULE__)

        Module.register_attribute(__MODULE__, :__ts_current_module__, accumulate: false)
        Module.register_attribute(__MODULE__, :__ts_struct_fields_acc__, accumulate: true)
        Module.register_attribute(__MODULE__, :__ts_struct_parameters_acc__, accumulate: true)
        Module.register_attribute(__MODULE__, :__ts_struct_plugins_acc__, accumulate: true)

        @__ts_current_module__ {module, options}

        # create a lexical scope
        try do
          import TypedStructor, only: [field: 2, field: 3, parameter: 1, plugin: 1, plugin: 2]

          unquote(register_plugins)

          unquote(block)

          fields = Enum.reverse(@__ts_struct_fields_acc__)
          parameters = Enum.reverse(@__ts_struct_parameters_acc__)

          Module.delete_attribute(__MODULE__, :__ts_struct_fields_acc__)
          Module.delete_attribute(__MODULE__, :__ts_struct_parameters_acc__)

          @__ts_struct_plugins__ Enum.reverse(@__ts_struct_plugins_acc__)
          Module.delete_attribute(__MODULE__, :__ts_struct_plugins_acc__)

          definition =
            TypedStructor.__call_plugins_before_definitions__(%TypedStructor.Definition{
              options: options,
              fields: fields,
              parameters: parameters
            })

          @__ts_definition__ definition
          @__ts_current_module__ {module, definition.options}

          TypedStructor.__struct_ast__()
          TypedStructor.__type_ast__()
          TypedStructor.__reflection_ast__()
        after
          :ok
        end
      end

    ast =
      quote do
        unquote(definition)

        # create a lexical scope
        try do
          TypedStructor.__call_plugins_after_definitions__()
        after
          # cleanup
          Module.delete_attribute(__MODULE__, :__ts_struct_plugins__)
          Module.delete_attribute(__MODULE__, :__ts_definition__)
          Module.delete_attribute(__MODULE__, :__ts_current_module__)
        end
      end

    case Keyword.fetch(options, :module) do
      {:ok, module} ->
        quote do
          defmodule unquote(module) do
            unquote(ast)
          end
        end

      :error ->
        ast
    end
  end

  # get the global plugins from config
  defp get_global_plugins do
    :typed_structor
    |> Application.get_env(:plugins, [])
    |> Enum.map(fn
      {plugin, opts} when is_atom(plugin) and is_list(opts) ->
        {plugin, opts}

      plugin when is_atom(plugin) ->
        {plugin, []}

      other ->
        raise ArgumentError,
              """
              Expected a plugin module or a tuple with a plugin module and its keyword options,
              Got: #{inspect(other)}

              Example:

                  config :typed_structor, plugins: [
                    {MyPlugin, [option: :value]},
                    MyAnotherPlugin
                  ]
              """
    end)
  end

  @doc """
  Defines a field in a `typed_structor/2`.
  You can override the options set by `typed_structor/2` by passing options.

  ## Example

      # A field named :example of type String.t()
      field :example, String.t()

  ## Options

    * `:default` - sets the default value for the field
    * `:enforce` - if set to `true`, enforces the field, and makes its type
      non-nullable if `:default` is not set

  > ### How `:default` and `:enforce` affect `type` and `@enforce_keys` {: .tip}
  >
  > | **`:default`** | **`:enforce`** | **`type`**        | **`@enforce_keys`** |
  > | -------------- | -------------- | ----------------- | ------------------- |
  > | `set`          | `true`         | `t()`             | `excluded`          |
  > | `set`          | `false`        | `t()`             | `excluded`          |
  > | `unset`        | `true`         | `t()`             | **`included`**      |
  > | `unset`        | `false`        | **`t() \\| nil`** | `excluded`          |
  """
  defmacro field(name, type, options \\ []) do
    options = Keyword.merge(options, name: name, type: Macro.escape(type))

    quote do
      {_module, options} = @__ts_current_module__

      @__ts_struct_fields_acc__ Keyword.merge(options, unquote(options))
    end
  end

  @doc """
  Defines a type parameter in a `typed_structor/2`.

  ## Example

      # A type parameter named int
      parameter :int

      fied :number, int # not int()
  """
  defmacro parameter(name) when is_atom(name) do
    quote do
      @__ts_struct_parameters_acc__ unquote(name)
    end
  end

  defmacro parameter(name) do
    raise ArgumentError, "expected an atom, got: #{inspect(name)}"
  end

  @doc """
  Registers a plugin for the currently defined struct.

  ## Example

      typed_structor do
        plugin MyPlugin

        field :string, String.t()
      end

  For more information on how to define your own plugins, please see
  `TypedStructor.Plugin`. To use a third-party plugin, please refer directly to
  its documentation.
  """
  defmacro plugin(plugin, opts \\ []) when is_list(opts) do
    quote do
      require unquote(plugin)

      unquote(plugin).init(unquote(opts))

      @__ts_struct_plugins_acc__ {
        unquote(plugin),
        unquote(opts),
        {
          # workaround to resolve these issues:
          # 1. warning: variable '&1' is unused (this might happen when using a capture argument as a pattern)
          # 2. error: invalid argument for require, expected a compile time atom or alias, got: plugin
          fn definition, opts -> unquote(plugin).before_definition(definition, opts) end,
          fn definition, opts -> unquote(plugin).after_definition(definition, opts) end
        }
      }
    end
  end

  @doc false
  defmacro __struct_ast__ do
    ast =
      quote do
        {fields, enforce_keys} =
          Enum.map_reduce(@__ts_definition__.fields, [], fn field, acc ->
            name = Keyword.fetch!(field, :name)
            default = Keyword.get(field, :default)

            if Keyword.get(field, :enforce, false) and not Keyword.has_key?(field, :default) do
              {{name, default}, [name | acc]}
            else
              {{name, default}, acc}
            end
          end)

        @enforce_keys Enum.reverse(enforce_keys)
        defstruct fields
      end

    quote do
      {_module, options} = @__ts_current_module__

      if Keyword.get(options, :define_struct, true) do
        unquote(ast)
      end
    end
  end

  @doc false
  defmacro __type_ast__ do
    quote unquote: false do
      {module, options} = @__ts_current_module__

      fields =
        Enum.reduce(@__ts_definition__.fields, [], fn field, acc ->
          name = Keyword.fetch!(field, :name)
          type = Keyword.fetch!(field, :type)

          if Keyword.get(field, :enforce, false) or Keyword.has_key?(field, :default) do
            [{name, type} | acc]
          else
            [{name, quote(do: unquote(type) | nil)} | acc]
          end
        end)

      type_name = Keyword.get(options, :type_name, :t)

      parameters = Enum.map(@__ts_definition__.parameters, &Macro.var(&1, __MODULE__))

      case Keyword.get(options, :type_kind, :type) do
        :type ->
          @type unquote(type_name)(unquote_splicing(parameters)) :: %unquote(module){
                  unquote_splicing(fields)
                }

        :opaque ->
          @opaque unquote(type_name)(unquote_splicing(parameters)) :: %unquote(module){
                    unquote_splicing(fields)
                  }

        :typep ->
          @typep unquote(type_name)(unquote_splicing(parameters)) :: %unquote(module){
                   unquote_splicing(fields)
                 }
      end
    end
  end

  @doc false
  defmacro __reflection_ast__ do
    quote unquote: false do
      fields = Enum.map(@__ts_definition__.fields, &Keyword.fetch!(&1, :name))

      enforced_fields =
        @__ts_definition__.fields
        |> Stream.filter(&Keyword.get(&1, :enforce, false))
        |> Stream.map(&Keyword.fetch!(&1, :name))
        |> Enum.to_list()

      def __typed_structor__(:fields), do: unquote(fields)
      def __typed_structor__(:parameters), do: @__ts_definition__.parameters
      def __typed_structor__(:enforced_fields), do: unquote(enforced_fields)

      for field <- @__ts_definition__.fields do
        name = Keyword.fetch!(field, :name)
        type = field |> Keyword.fetch!(:type) |> Macro.escape()

        def __typed_structor__(:type, unquote(name)), do: unquote(type)
        def __typed_structor__(:field, unquote(name)), do: unquote(Macro.escape(field))
      end
    end
  end

  defmacro __call_plugins_before_definitions__(definition) do
    alias TypedStructor.Definition

    quote do
      Enum.reduce(
        @__ts_struct_plugins__,
        unquote(definition),
        fn {plugin, opts, {before_definition, _after_definition}}, acc ->
          result = before_definition.(acc, opts)

          result
          |> List.wrap()
          |> Enum.filter(&is_struct(&1, Definition))
          |> case do
            [definition] ->
              definition

            _otherwise ->
              raise """
              The plugin call to `#{inspect(plugin)}` did not return a `#{inspect(Definition)}` struct,
              got: #{inspect(result)}

              The plugin call should return a `#{inspect(Definition)}` struct,
              or a list which contains exactly one `#{inspect(Definition)}` struct.
              """
          end
        end
      )
    end
  end

  defmacro __call_plugins_after_definitions__ do
    quote do
      Enum.each(
        Enum.reverse(@__ts_struct_plugins__),
        fn {plugin, opts, {_before_definition, after_definition}} ->
          after_definition.(@__ts_definition__, opts)
        end
      )
    end
  end
end
