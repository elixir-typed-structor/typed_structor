# Derives the `Enumerable` for `struct`

We use the `c:TypedStructor.Plugin.after_definition/2` callback to
generate the `Enumerable` implementation for the struct.
We implement `Enumerable` callbacks exclusively using the fields that are defined.

Let's start!

## Implementation
```elixir
defmodule MyPlugin do
  use TypedStructor.Plugin

  @impl TypedStructor.Plugin
  defmacro after_definition(definition, _opts) do
    quote bind_quoted: [definition: definition] do
      keys = Enum.map(definition.fields, &Keyword.fetch!(&1, :name))

      defimpl Enumerable do
        def count(enumerable), do: {:ok, Enum.count(unquote(keys))}
        def member?(enumerable, element), do: {:ok, Enum.member?(unquote(keys), element)}

        def reduce(enumerable, acc, fun) do
          # The order of fields is guaranteed to align with the sequence in which they are defined.
          unquote(keys)
          |> Enum.map(fn key -> {key, Map.fetch!(enumerable, key)} end)
          |> Enumerable.List.reduce(acc, fun)
        end

        # We don't support this
        def slice(_enumerable), do: {:error, __MODULE__}
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
    field :age, integer(), enforce: true
  end
end
```

```elixir
iex> user = %User{name: "Phil", age: 20}
%User{name: "Phil", age: 20}
# the order of fields is deterministic
iex> Enum.map(user, fn {key, _value} -> key end)
[:name, :age]
# we got a deterministic ordered Keyword list
iex> Enum.to_list(user)
[name: "Phil", age: 20]
```

> #### Bonus {: .info}
> Additionally, we gain the bonus of having a deterministic order of fields,
> determined by the sequence in which they are defined.
