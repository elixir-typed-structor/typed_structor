# Implement reflection functions

Define a plugin that generates reflection functions that
can be used to access the fields and parameters of a struct.

## Implement

```elixir
defmodule Guides.Plugins.Reflection do
  use TypedStructor.Plugin

  @impl TypedStructor.Plugin
  defmacro after_definition(definition, _opts) do
    quote bind_quoted: [definition: definition] do
      fields = Enum.map(definition.fields, &Keyword.fetch!(&1, :name))

      enforced_fields =
        definition.fields
        |> Stream.filter(fn field ->
          Keyword.get_lazy(field, :enforce, fn ->
            Keyword.get(definition.options, :enforce, false)
          end)
        end)
        |> Stream.map(&Keyword.fetch!(&1, :name))
        |> Enum.to_list()

      def __typed_structor__(:fields), do: unquote(fields)
      def __typed_structor__(:parameters), do: Enum.map(unquote(definition.parameters), &Keyword.fetch!(&1, :name))
      def __typed_structor__(:enforced_fields), do: unquote(enforced_fields)

      for field <- definition.fields do
        name = Keyword.fetch!(field, :name)
        type = field |> Keyword.fetch!(:type) |> Macro.escape()

        def __typed_structor__(:type, unquote(name)), do: unquote(type)
        def __typed_structor__(:field, unquote(name)), do: unquote(Macro.escape(field))
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
    plugin Guides.Plugins.Reflection

    parameter :age

    field :name, String.t(), enforce: true
    field :age, age, default: 20
  end
end

defmodule MyApp do
  use TypedStructor

  typed_structor module: User, enforce: true do
    plugin Guides.Plugins.Reflection

    field :name, String.t()
    field :age, integer()
  end
end
```

```elixir
iex> User.__typed_structor__(:fields)
[:name, :age]
iex> User.__typed_structor__(:parameters)
[:age]

iex> MyApp.User.__typed_structor__(:enforced_fields)
[:name, :age]
iex> Macro.to_string(User.__typed_structor__(:type, :age))
"age"
```
