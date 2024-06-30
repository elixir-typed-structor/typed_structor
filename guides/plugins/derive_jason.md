# Derives the `Jason.Encoder` for `struct`

We use the `c:TypedStructor.Plugin.after_definition/2` callback to
generate the `Jason.Encoder` implementation for the struct.

## Implementation
```elixir
defmodule MyPlugin do
  use TypedStructor.Plugin

  @impl TypedStructor.Plugin
  defmacro after_definition(definition, _opts) do
    quote bind_quoted: [definition: definition] do
      # Extract the field names
      keys = Enum.map(definition.fields, &Keyword.fetch!(&1, :name))

      defimpl Jason.Encoder do
        def encode(value, opts) do
          Jason.Encode.map(Map.take(value, unquote(keys)), opts)
        end
      end
    end
  end
end
```

## Usage
```elixir
defmodule User do
  use TypedStructor

  typed_structor do
    plugin MyPlugin

    field :name, String.t(), enforce: true
  end
end
```

After compiled, you got:
```elixir
iex> Jason.encode(%User{name: "Phil"})
{:ok, "{\"name\":\"Phil\"}"}
```
