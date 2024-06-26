defmodule TypedStructor.Plugin do
  @moduledoc """
  This module defines the plugin behaviour for `TypedStructor`.

  ## Plugin Behaviour

  A plugin is a module that implements the `TypedStructor.Plugin` behaviour.
  Three macro callbacks are available for injecting code at different stages:

  * `c:init/1`: This macro callback is called when the plugin is used.
  * `c:before_definition/2`: This macro callback is called right before defining the struct.
  Note hat plugins will run in the order they are registered.
  * `c:after_definition/2`: This macro callback is called right after defining the struct.
  Note that plugins will run in the **reverse** order they are registered.

  ### Example

  Let's define a plugin that defines `Ecto.Schema` while defining a typed struct.
  This plugin takes a `:source` option which passing to `Ecto.Schema.schema/2`,
  you can use `belongs_to` and `has_many` directly in the module.
  It would be used like this:
  ```elixir
  defmodule MyApp do
    use TypedStructor

    # fix aliases
    alias __MODULE__.User
    alias __MODULE__.Post

    typed_structor module: User do
      # import the plugin with source option
      plugin EctoSchemaPlugin, source: "users"

      field :name, :string, enforce: true
      field :age, :integer, default: 0
      # pass redact option to Ecto.Schema.field/3
      field :password, :string, redact: true
      has_many :posts, Post
    end

    typed_structor module: Post do
      # import the plugin with source option
      plugin EctoSchemaPlugin, source: "posts"

      field :title, :string, enforce: true
      field :content, :string, enforce: true
      belongs_to :user, User, enforce: true
    end
  end
  ```
  After compiled, you got:
  ```elixir
  iex> t MyApp.User
  @type t() :: %MyApp.User{
          __meta__: Ecto.Schema.Metadata.t(),
          age: integer() | nil,
          id: integer(),                                                                                                                                                                       name: String.t(),
          password: String.t() | nil,
          posts: [MyApp.Post.t()] | nil
        }

  iex> t MyApp.Post
  @type t() :: %MyApp.Post{
          __meta__: Ecto.Schema.Metadata.t(),
          content: String.t(),
          id: integer(),
          title: String.t(),
          user: MyApp.User.t(),
          user_id: integer()
        }

  iex> MyApp.User.__schema__(:redact_fields)
  [:password]

  iex> MyApp.User.__schema__(:association, :posts)
  %Ecto.Association.Has{
    cardinality: :many,
    field: :posts,
    owner: MyApp.User,
    related: MyApp.Post,
    owner_key: :id,
    related_key: :user_id,
    on_cast: nil,
    queryable: MyApp.Post,
    on_delete: :nothing,                                                                                                                                                                 on_replace: :raise,
    where: [],
    unique: true,
    defaults: [],
    relationship: :child,
    ordered: false,
    preload_order: []
  }

  iex> MyApp.Post.__schema__(:association, :user)
  %Ecto.Association.BelongsTo{
    field: :user,
    owner: MyApp.Post,
    related: MyApp.User,
    owner_key: :user_id,
    related_key: :id,
    queryable: MyApp.User,
    on_cast: nil,
    on_replace: :raise,
    where: [],
    defaults: [],
    cardinality: :one,
    relationship: :parent,
    unique: true,
    ordered: false
  }
  ```
  Following is the implementation of the plugin:
  ```elixir
  defmodule EctoSchemaPlugin do
    use TypedStructor.Plugin

    @impl TypedStructor.Plugin
    defmacro init(opts) do
      quote do
        unless Keyword.has_key?(unquote(opts), :source) do
          raise "The `:source` option is not provided."
        end

        # import association functions to the module,
        # so that we can use `has_many` and `belongs_to` directly
        import unquote(__MODULE__), only: [has_many: 2, belongs_to: 3]
      end
    end

    @impl TypedStructor.Plugin
    defmacro before_definition(definition, _opts) do
      # manipulate the definition before defining the struct
      quote do
        unquote(definition)
        # disable defining struct, for Ecto.Schema will define it
        |> Map.update!(:options, &Keyword.put(&1, :define_struct, false))
        |> Map.update!(:fields, fn fields ->
          Enum.flat_map(fields, fn field ->
            {ecto_type, options} = Keyword.pop!(field, :type)
            type = unquote(__MODULE__).__ecto_type_to_type__(ecto_type)

            field = Keyword.merge(options, type: type, ecto_type: ecto_type)

            case ecto_type do
              {:belongs_to, name} ->
                foreign_key_name =
                  name
                  |> Macro.expand(__ENV__)
                  |> Module.split()
                  |> List.last()
                  |> Macro.underscore()
                  |> Kernel.<>("_id")
                  |> String.to_atom()

                foreign_key =
                  Keyword.merge(options, name: foreign_key_name, type: quote(do: integer()))

                [foreign_key, field]

              _other ->
                [field]
            end
          end)
        end)
        |> Map.update!(
          :fields,
          &[
            [name: :__meta__, type: quote(do: Ecto.Schema.Metadata.t()), enforce: true],
            [name: :id, type: quote(do: integer()), enforce: true]
            | &1
          ]
        )
      end
    end

    @impl TypedStructor.Plugin
    defmacro after_definition(definition, opts) do
      # here we define the Ecto.Schema
      quote bind_quoted: [definition: definition, opts: opts] do
        use Ecto.Schema

        source = Keyword.fetch!(opts, :source)

        schema source do
          for options <- definition.fields do
            {name, options} = Keyword.pop!(options, :name)
            {ecto_type, options} = Keyword.pop(options, :ecto_type)
            options = Keyword.take(options, [:primary_key, :default, :redact])

            case ecto_type do
              nil ->
                # skip some fields
                nil

              {:has_many, module} ->
                module = Macro.expand(module, __ENV__)

                Ecto.Schema.has_many(name, module, options)

              {:belongs_to, module} ->
                module = Macro.expand(module, __ENV__)

                Ecto.Schema.belongs_to(name, module, options)

              _ ->
                Ecto.Schema.field(name, ecto_type, options)
            end
          end
        end
      end
    end

    defmacro has_many(name, queryable) do
      quote do
        field unquote(name), {:has_many, unquote(queryable)}
      end
    end

    defmacro belongs_to(name, queryable, opts) do
      quote do
        field unquote(name), {:belongs_to, unquote(queryable)}, unquote(opts)
      end
    end

    def __ecto_type_to_type__(:string), do: quote(do: String.t())
    def __ecto_type_to_type__(:integer), do: quote(do: integer())
    def __ecto_type_to_type__({:has_many, module}), do: quote(do: [unquote(module).t()])
    def __ecto_type_to_type__({:belongs_to, module}), do: quote(do: unquote(module).t())
  end
  ```
  """

  @doc """
  This macro callback is called when the plugin is used.

  Here you can define module attributes, import modules, etc.
  """
  @macrocallback init(plugin_opts :: Keyword.t()) :: Macro.t()

  @doc """
  This macro callback is called right before defining the struct.

  It receives the definition of the struct and the plugin options,
  and it should return the `TypedStructor.Definition` struct or
  a list which contains exactly one `TypedStructor.Definition` struct.
  """
  @macrocallback before_definition(
                   definition :: TypedStructor.Definition.t(),
                   plugin_opts :: Keyword.t()
                 ) ::
                   Macro.t()

  @doc """
  This macro callback is called right after defining the struct.

  It receives the definition of the struct and the plugin options,
  and its return value is ignored.
  """
  @macrocallback after_definition(
                   definition :: TypedStructor.Definition.t(),
                   plugin_opts :: Keyword.t()
                 ) ::
                   Macro.t()

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour TypedStructor.Plugin

      @impl TypedStructor.Plugin
      defmacro init(_opts), do: nil

      @impl TypedStructor.Plugin
      defmacro before_definition(definition, _opts), do: definition

      @impl TypedStructor.Plugin
      defmacro after_definition(_definition, _opts), do: nil

      defoverridable init: 1, before_definition: 2, after_definition: 2
    end
  end
end
