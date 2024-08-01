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
    case Keyword.pop(options, :module) do
      {nil, options} ->
        __typed_structor__(__CALLER__.module, options, block)

      {module, options} ->
        quote do
          defmodule unquote(module) do
            use TypedStructor

            typed_structor unquote(options) do
              unquote(block)
            end
          end
        end
    end
  end

  defp __typed_structor__(mod, options, block) do
    Module.register_attribute(mod, :__ts_options__, accumulate: false)
    Module.register_attribute(mod, :__ts_struct_fields__, accumulate: true)
    Module.register_attribute(mod, :__ts_struct_parameters__, accumulate: true)
    Module.register_attribute(mod, :__ts_struct_plugins__, accumulate: true)
    Module.register_attribute(mod, :__ts_definition____, accumulate: false)

    quote do
      @__ts_options__ unquote(options)

      # create a lexical scope
      try do
        import TypedStructor,
          only: [assoc: 2, field: 2, field: 3, parameter: 1, parameter: 2, plugin: 1, plugin: 2]

        unquote(register_global_plugins())

        unquote(block)
      after
        :ok
      end

      # create a lexical scope
      try do
        definition =
          TypedStructor.__call_plugins_before_definitions__(%TypedStructor.Definition{
            options: @__ts_options__,
            fields: Enum.reverse(@__ts_struct_fields__),
            parameters: Enum.reverse(@__ts_struct_parameters__)
          })

        @__ts_definition__ definition
        @__ts_options__ definition.options
      after
        :ok
      end

      TypedStructor.__struct_ast__()
      TypedStructor.__type_ast__()

      # create a lexical scope
      try do
        TypedStructor.__call_plugins_after_definitions__()
      after
        # cleanup
        Module.delete_attribute(__MODULE__, :__ts_options__)
        Module.delete_attribute(__MODULE__, :__ts_struct_fields__)
        Module.delete_attribute(__MODULE__, :__ts_struct_parameters__)
        Module.delete_attribute(__MODULE__, :__ts_struct_plugins__)
        Module.delete_attribute(__MODULE__, :__ts_definition__)
      end
    end
  end

  # register global plugins
  defp register_global_plugins do
    :typed_structor
    |> Application.get_env(:plugins, [])
    |> List.wrap()
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
    |> Enum.map(fn {plugin, opts} ->
      quote do
        plugin unquote(plugin), unquote(opts)
      end
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
      @__ts_struct_fields__ Keyword.merge(@__ts_options__, unquote(options))
    end
  end

  defmacro assoc(name, type, options \\ []) do
    type = quote(do: unquote(type) | Ecto.Association.NotLoaded.t())
    options = Keyword.merge(options, name: name, type: Macro.escape(type))

    quote do
      @__ts_struct_fields__ Keyword.merge(@__ts_options__, unquote(options))
    end
  end

  @doc """
  Defines a type parameter in a `typed_structor/2`.

  ## Example

      # A type parameter named int
      parameter :int

      fied :number, int # not int()
  """
  defmacro parameter(name, opts \\ [])

  defmacro parameter(name, opts) when is_atom(name) and is_list(opts) do
    quote do
      @__ts_struct_parameters__ Keyword.merge(unquote(opts), name: unquote(name))
    end
  end

  defmacro parameter(name, opts) do
    raise ArgumentError,
          "name must be an atom and opts must be a list, got: #{inspect(name)} and #{inspect(opts)}"
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
    Module.put_attribute(__CALLER__.module, :__ts_struct_plugins__, {plugin, opts})

    quote do
      require unquote(plugin)

      unquote(plugin).init(unquote(opts))
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
      if Keyword.get(@__ts_options__, :define_struct, true) do
        unquote(ast)
      end
    end
  end

  @doc false
  defmacro __type_ast__ do
    quote unquote: false do
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

      type_name = Keyword.get(@__ts_options__, :type_name, :t)

      parameters =
        Enum.map(
          @__ts_definition__.parameters,
          fn parameter ->
            parameter
            |> Keyword.fetch!(:name)
            |> Macro.var(__MODULE__)
          end
        )

      case Keyword.get(@__ts_options__, :type_kind, :type) do
        :type ->
          @type unquote(type_name)(unquote_splicing(parameters)) :: %__MODULE__{
                  unquote_splicing(fields)
                }

        :opaque ->
          @opaque unquote(type_name)(unquote_splicing(parameters)) :: %__MODULE__{
                    unquote_splicing(fields)
                  }

        :typep ->
          @typep unquote(type_name)(unquote_splicing(parameters)) :: %__MODULE__{
                   unquote_splicing(fields)
                 }
      end
    end
  end

  @doc false
  defmacro __call_plugins_before_definitions__(definition) do
    alias TypedStructor.Definition

    plugins = Module.get_attribute(__CALLER__.module, :__ts_struct_plugins__)

    Enum.reduce(plugins, definition, fn {plugin, opts}, acc ->
      quote do
        require unquote(plugin)

        result = unquote(plugin).before_definition(unquote(acc), unquote(opts))

        result
        |> List.wrap()
        |> Enum.filter(&is_struct(&1, Definition))
        |> case do
          [definition] ->
            definition

          _otherwise ->
            raise """
            The plugin call to `#{inspect(unquote(plugin))}` did not return a `#{inspect(Definition)}` struct,
            got: #{inspect(result)}

            The plugin call should return a `#{inspect(Definition)}` struct,
            or a list which contains exactly one `#{inspect(Definition)}` struct.
            """
        end
      end
    end)
  end

  @doc false
  defmacro __call_plugins_after_definitions__ do
    plugins = Module.get_attribute(__CALLER__.module, :__ts_struct_plugins__)

    for {plugin, opts} <- plugins do
      quote do
        require unquote(plugin)

        unquote(plugin).after_definition(
          @__ts_definition__,
          unquote(Macro.escape(opts))
        )
      end
    end
  end
end
