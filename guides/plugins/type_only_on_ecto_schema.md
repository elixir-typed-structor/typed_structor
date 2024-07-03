# Type Only on Ecto Schema

`Ecto` is a great library for working with both databases and data validation.
However, it has its own way of defining schemas and fields,
which results a struct but without type definitions.
This plugin automatically disables struct creation for `Ecto` schemas.

## Implementation

It uses the `c:TypedStructor.Plugin.before_definition/2` callback to determine if the module is an `Ecto` schema
by checking the `@ecto_fields` module attribute. If it is, the `:define_struct` option is
set to `false` to prevent struct creation.

Here is the plugin(*feel free to copy and paste*):
```elixir
defmodule Guides.Plugins.TypeOnlyOnEctoSchema do
  use TypedStructor.Plugin

  @impl TypedStructor.Plugin
  defmacro before_definition(definition, _opts) do
    quote do
      if Module.has_attribute?(__MODULE__, :ecto_fields) do
        Map.update!(unquote(definition), :options, fn opts ->
          Keyword.put(opts, :define_struct, false)
        end)
      else
        unquote(definition)
      end
    end
  end
end
```

## Usage

To use this plugin, you can add it to the `typed_structor` block like this:
```elixir
defmodule MyApp.User do
  use TypedStructor
  use Ecto.Schema

  typed_structor do
    plugin Guides.Plugins.TypeOnlyOnEctoSchema

    field :id, integer(), enforce: true
    field :name, String.t()
    field :age, integer(), enforce: true # There is always a non-nil value
  end

  schema "source" do
    field :name, :string
    field :age, :integer, default: 20
  end
end
```

## Registering the plugin globally
```elixir
config :typed_structor, plugins: [Guides.Plugins.TypeOnlyOnEctoSchema]
```

Note that the plugin is applied to **all modules** that use `TypedStructor`,
you can opt-out by determining the module name or other conditions.

Let's change the plugin to only apply to modules from the `MyApp` namespace(*feel free to copy and paste*):

```elixir
defmodule Guides.Plugins.TypeOnlyOnEctoSchema do
  use TypedStructor.Plugin

  @impl TypedStructor.Plugin
  defmacro before_definition(definition, _opts) do
    quote do
      # Check if the module is from the MyApp namespace
      with "MyApp" <- __MODULE__ |> Module.split() |> hd(),
           true <- Module.has_attribute?(__MODULE__, :ecto_fields) do
        Map.update!(unquote(definition), :options, fn opts ->
          Keyword.put(opts, :define_struct, false)
        end)
      else
        _otherwise -> unquote(definition)
      end
    end
  end
end
```

Now you can use `typed_structor` without registering the plugin explicitly:

```diff
 defmodule MyApp.User do
   use TypedStructor
   use Ecto.Schema

   typed_structor do
-    plugin Guides.Plugins.TypeOnlyOnEctoSchema
 
     field :id, integer(), enforce: true
     field :name, String.t()
     field :age, integer(), enforce: true
   end

   schema "source" do
     field :name, :string
     field :age, :integer, default: 20
   end
 end
```
