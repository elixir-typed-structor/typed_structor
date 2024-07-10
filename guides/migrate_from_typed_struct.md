# Migrate from `typed_struct`

This package(`typed_structor`) keeps the same API as `typed_struct`.
It is a drop-in replacement for `typed_struct`.

## Migration

1. Replace `typed_struct` with `typed_structor` in your `mix.exs` file.

```diff
   defp deps do
     [
       # ...deps
-      {:typed_struct, "~> 0.3.0"},
+      {:typed_structor, "~> 0.4"},
     ]
   end
```

2. Run `mix do deps.unlock --unused, deps.get, deps.clean --unused` to fetch the new dependency.
3. Replace `TypedStruct` with `TypedStructor` in your code.

```diff
 defmodule User do
-  use TypedStruct
+  use TypedStructor
 
-  typedstruct do
+  typed_structor do
     field :id, pos_integer()
     field :name, String.t()
     field :age, non_neg_integer()
   end
 end
```
4. That's it!
