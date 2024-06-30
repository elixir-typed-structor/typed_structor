# Add primary key and timestamps types to your Ecto schema


## Implementation

This plugin use `c:TypedStructor.Plugin.before_definition/2` callback to
inject the primary key and timestamps fields to the type definition.

```elixir
defmodule MyApp.TypedStructor.Plugins.PrimaryKeyAndTimestamps do
  use TypedStructor.Plugin

  @impl TypedStructor.Plugin
  defmacro before_definition(definition, _opts) do
    quote do
      Map.update!(unquote(definition), :fields, fn fields ->
        # Assume that the primary key is an integer
        primary_key = [name: :id, type: quote(do: integer()), enforce: true]

        # Add two default timestamps
        timestamps = [
          [name: :inserted_at, type: quote(do: NaiveDateTime.t()), enforce: true],
          [name: :updated_at, type: quote(do: NaiveDateTime.t()), enforce: true]
        ]

        [primary_key | fields] ++ timestamps
      end)
    end
  end
end
```

## Usage

```elixir
defmodule MyApp.User do
  use TypedStructor
  use Ecto.Schema

  # disable struct creation or it will conflict with the Ecto schema
  typed_structor define_struct: false do
    # register the plugin
    plugin MyApp.TypedStructor.Plugins.PrimaryKeyAndTimestamps

    field :name, String.t()
    field :age, integer(), enforce: true # There is always a non-nil value
  end

  schema "source" do
    field :name, :string
    field :age, :integer, default: 20

    timestamps()
  end
end
```

If you want to apply this plugin conditionally, refer to the [Registering plugins globally](./registering_plugins_globally.md) section.
