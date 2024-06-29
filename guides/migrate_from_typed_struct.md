# Migrate from `typed_struct`

This package(`typed_structor`) keeps the same API as `typed_struct`.
It is a drop-in replacement for `typed_struct`.

## Migration

1. Replace `typed_struct` with `typed_structor` in your `mix.exs` file.
```diff
-  {:typed_struct, "~> 0.3"}
+  {:typed_structor, "~> 0.1"}
```
2. Run `mix do deps.unlock --unused, deps.get, deps.clean --unused` to fetch the new dependency.
3. Replace `TypedStruct` with `TypedStructor` in your code.
```diff
-  use TypedStruct
+  use TypedStructor

-  typed_struct do
+  typed_structor do
```
4. That's it!
