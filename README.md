# TypedStructor

[![Build Status](https://github.com/elixir-typed-structor/typed_structor/actions/workflows/elixir.yml/badge.svg)](https://github.com/elixir-typed-structor/typed_structor/actions/workflows/elixir.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/typed_structor)](https://hex.pm/packages/typed_structor)
[![HexDocs](https://img.shields.io/badge/HexDocs-gray)](https://hexdocs.pm/typed_structor)
[![Plugin guides](https://img.shields.io/badge/plugin_guides-indianred?label=%F0%9F%94%A5&labelColor=snow)](https://hexdocs.pm/typed_structor/introduction.html)

TypedStructor eliminates the boilerplate of defining Elixir structs, type specs, and enforced keys separately. Define them once, keep them in sync automatically.

**Before** -- three declarations that must stay in sync manually:

```elixir
defmodule User do
  @enforce_keys [:id]
  defstruct [:id, :name, :age]

  @type t() :: %__MODULE__{
    id: pos_integer(),
    name: String.t() | nil,
    age: non_neg_integer() | nil
  }
end
```

**After** -- a single source of truth:

```elixir
defmodule User do
  use TypedStructor

  typed_structor do
    field :id, pos_integer(), enforce: true
    field :name, String.t()
    field :age, non_neg_integer()
  end
end
```

## Feature Highlights

- **Single definition** -- struct, type spec, and `@enforce_keys` generated from one block
- **Nullable by default** -- unenforced fields without defaults automatically include `| nil`
- **Fine-grained null control** -- override nullability per-field or per-block with the `:null` option
- **Opaque and custom types** -- generate `@opaque`, `@typep`, or rename the type from `t()`
- **Type parameters** -- define generic/parametric types
- **Multiple definers** -- supports structs, exceptions, and Erlang records
- **Plugin system** -- extend behavior at compile time with composable plugins
- **Nested modules** -- define structs in submodules with the `:module` option

<!-- MODULEDOC -->

## Installation

Add `:typed_structor` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:typed_structor, "~> 0.6"}
  ]
end
```

> #### Formatter Setup {: .tip}
>
> Add `:typed_structor` to your `.formatter.exs` for proper indentation:
>
> ```elixir
> [
>   import_deps: [..., :typed_structor],
>   inputs: [...]
> ]
> ```

## Getting Started

Use `typed_structor` blocks to define fields with their types:

```elixir
defmodule User do
  use TypedStructor

  typed_structor do
    field :id, pos_integer(), enforce: true  # Required, never nil
    field :name, String.t()                  # Optional, nullable
    field :role, String.t(), default: "user" # Has default, not nullable
  end
end
```

### Nullability Rules

The interaction between `:enforce`, `:default`, and `:null` determines whether a field's type includes `nil`:

| `:default` | `:enforce` | `:null` | Type includes `nil`? |
|------------|------------|---------|----------------------|
| `unset`    | `false`    | `true`  | yes                  |
| `unset`    | `false`    | `false` | no                   |
| `set`      | -          | -       | no                   |
| -          | `true`     | -       | no                   |

You can set `:null` at the block level to change the default for all fields:

```elixir
typed_structor null: false do
  field :id, integer()                         # Not nullable
  field :email, String.t()                     # Not nullable
  field :phone, String.t(), null: true         # Override: nullable
end
```

## Options

### Opaque Types

Use `type_kind: :opaque` to hide implementation details:

```elixir
typed_structor type_kind: :opaque do
  field :secret, String.t()
end
# Generates: @opaque t() :: %__MODULE__{...}
```

### Custom Type Names

Override the default `t()` type name:

```elixir
typed_structor type_name: :user_data do
  field :id, pos_integer()
end
# Generates: @type user_data() :: %__MODULE__{...}
```

### Type Parameters

Create generic types with `parameter/1`:

```elixir
typed_structor do
  parameter :value_type
  parameter :error_type

  field :value, value_type
  field :error, error_type
end
# Generates: @type t(value_type, error_type) :: %__MODULE__{...}
```

### Nested Modules

Define structs in submodules:

```elixir
defmodule User do
  use TypedStructor

  typed_structor module: Profile do
    field :email, String.t(), enforce: true
    field :bio, String.t()
  end
end
# Creates User.Profile with its own struct and type
```

## Plugins

Extend TypedStructor's behavior with plugins that run at compile time:

```elixir
typed_structor do
  plugin Guides.Plugins.Accessible

  field :id, pos_integer()
  field :name, String.t()
end
```

See the [Plugin Guides](https://hexdocs.pm/typed_structor/introduction.html) for examples and instructions on writing your own.

## Documentation

Add `@typedoc` inside the block, and `@moduledoc` at the module level as usual:

```elixir
defmodule User do
  @moduledoc "User account data"
  use TypedStructor

  typed_structor do
    @typedoc "A user with authentication details"

    field :id, pos_integer()
    field :name, String.t()
  end
end
```

<!-- MODULEDOC -->

## Advanced Usage

### Exceptions

Define typed exceptions with automatic `__exception__` handling:

```elixir
defmodule HTTPException do
  use TypedStructor

  typed_structor definer: :defexception, enforce: true do
    field :status, non_neg_integer()
    field :message, String.t()
  end

  @impl Exception
  def message(%__MODULE__{status: status, message: msg}) do
    "HTTP #{status}: #{msg}"
  end
end
```

### Records

Create Erlang-compatible records:

```elixir
defmodule UserRecord do
  use TypedStructor

  typed_structor definer: :defrecord, record_name: :user do
    field :name, String.t(), enforce: true
    field :age, pos_integer(), enforce: true
  end
end
```

### Integration with Other Libraries

Use `define_struct: false` to skip struct generation when another library defines the struct:

```elixir
defmodule User do
  use TypedStructor

  typed_structor define_struct: false do
    field :email, String.t(), enforce: true

    use Ecto.Schema
    @primary_key false

    schema "users" do
      Ecto.Schema.field(:email, :string)
    end
  end
end
```

This generates only the type spec while letting the other library handle the struct definition.

For full Ecto integration with typed fields, see [EctoTypedSchema](https://github.com/elixir-typed-structor/ecto_typed_schema) -- a companion library built on TypedStructor.

## Learn More

- [HexDocs](https://hexdocs.pm/typed_structor) -- full API reference and guides
- [Plugin Guides](https://hexdocs.pm/typed_structor/introduction.html) -- build and use plugins
- [Changelog](https://hexdocs.pm/typed_structor/changelog.html) -- release history
