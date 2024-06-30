# Registering plugins globally

`TypedStructor` allows you to register plugins globally, so you don't have to specify them in each struct.
This is useful when you want to apply the same plugin to all modules that use `TypedStructor`.

> #### Global plugins are applied to all modules {: .warning}
> The global registered plugins is applied to **all modules** that use `TypedStructor`.
> That means any dependency or library that uses `TypedStructor` will also be affected.
>
> If you want to apply the plugin to specific modules, you can determine the
> module name or other conditions in the plugin implementation.


## Usage

To register a plugin globally, you can add it to the `:plugins` key in the `:typed_structor` app configuration.
```elixir
config :typed_structor, plugins: [MyPlugin, {MyPluginWithOpts, [foo: :bar]}]
```

## How to opt-out the plugin conditionally

The most common way to opt-out a plugin is to determine the module name.

```elixir
defmodule MyPlugin do
  use TypedStructor.Plugin

  @impl TypedStructor.Plugin
  defmacro before_definition(definition, _opts) do
    quote do
      if unquote(__MODULE__).__opt_in__?(__MODULE__) do
        # do something
      end

      unquote(definition)
    end
  end

  @impl TypedStructor.Plugin
  defmacro after_definition(_definition, _opts) do
    quote do
      if unquote(__MODULE__).__opt_in__?(__MODULE__) do
        # do something
      end
    end
  end

  def __opt_in__?(module) when is_atom(module) do
    # Opt-in only for schemas under MyApp.Schemas
    String.starts_with?(Atom.to_string(module), "MyApp.Schemas")
  end
end
```
