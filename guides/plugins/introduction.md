# Introduction to the plugin system

For more customization, `TypedStructor` provides a plugin system
that allows you to extend the functionality of the library.
This is useful when you want to extract some common logic into a separate module.

See `TypedStructor.Plugin` for how to create a plugin.

This library comes with a few built-in plugins, and we don't like to
implement more built-in plugins, but instead, we encourage you to create your own plugins.
We provide some example plugins that you can use as a reference, or copy-paste.

**Plugin examples:**
- [Registering plugins globally](./registering_plugins_globally.md)
- [Implement `Access` behavior](./accessible.md)
- [Implement reflection functions](./reflection.md)
- [Type Only on Ecto Schema](./type_only_on_ecto_schema.md)
- [Add primary key and timestamps types to your Ecto schema](./primary_key_and_timestamps.md)
- [Derives the `Jason.Encoder` for `struct`](./derive_jason.md)
- [Derives the `Enumerable` for `struct`](./derive_enumerable.md)
