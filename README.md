# TypedStructor

[![Build Status](https://github.com/elixir-typed-structor/typed_structor/actions/workflows/elixir.yml/badge.svg)](https://github.com/elixir-typed-structor/typed_structor/actions/workflows/elixir.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/typed_structor)](https://hex.pm/packages/typed_structor)
[![Document](https://img.shields.io/badge/document-gray)](https://hexdocs.pm/typed_structor)
[![Plugin guides](https://img.shields.io/badge/plugin_guides-indianred?label=%F0%9F%94%A5&labelColor=snow)](https://hexdocs.pm/typed_structor/introduction.html)

Define your structs and types in one place. TypedStructor generates `defstruct`, type specs, and `@enforce_keys` while keeping your code clean and explicit.

## Why TypedStructor?

**Without TypedStructor**, you write everything twice:

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

**With TypedStructor**, you write it once:

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

Same result, half the boilerplate. Your struct definition and type spec stay in sync automatically.

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
    field :id, pos_integer()
    field :name, String.t()
  end
end
```

This generates a struct and type where fields are nullable by default (`pos_integer() | nil`).

### Enforcing Required Fields

Make fields non-nullable by enforcing them:

```elixir
typed_structor do
  field :id, pos_integer(), enforce: true  # Required, never nil
  field :name, String.t()                  # Optional, can be nil
end
```

### Providing Defaults

Fields with defaults don't need to be nullable since they always have a value:

```elixir
typed_structor do
  field :id, pos_integer(), enforce: true
  field :name, String.t(), default: "Unknown"  # String.t() (not nullable)
  field :age, non_neg_integer()                # non_neg_integer() | nil
end
```

### Controlling Nullability

You can explicitly control whether fields accept `nil`:

```elixir
typed_structor do
  field :id, integer(), null: false       # Never nil
  field :name, String.t(), null: true     # Always nullable
end
```

Or set defaults for all fields in a block:

```elixir
typed_structor null: false do
  field :id, integer()                         # Not nullable by default
  field :email, String.t()                     # Not nullable by default
  field :phone, String.t(), null: true         # Override for this field
end
```

The interaction between `enforce`, `default`, and `null` follows this logic:

| `:default` | `:enforce` | `:null` | Type includes `nil`? |
|------------|------------|---------|----------------------|
| `unset`    | `false`    | `true`  | yes                  |
| `unset`    | `false`    | `false` | no                   |
| `set`      | -          | -       | no                   |
| -          | `true`     | -       | no                   |

This is particularly useful when modeling database records where some fields can be `nil`:

```elixir
defmodule DatabaseRecord do
  use TypedStructor

  typed_structor do
    # These fields can be nil when loaded from DB
    field :name, String.t()
    field :description, String.t()

    # These fields cannot be nil (e.g., primary keys, timestamps)
    field :id, integer(), null: false
    field :inserted_at, DateTime.t(), null: false
    field :updated_at, DateTime.t(), null: false
  end
end
```

## Options

TypedStructor provides several options to customize your type definitions:

### Opaque Types

Use `type_kind: :opaque` to hide implementation details:

```elixir
typed_structor type_kind: :opaque do
  field :id, pos_integer()
  field :secret, String.t()
end

# Generates: @opaque t() :: %__MODULE__{...}
```

### Custom Type Names

Override the default `t()` type name with `type_name`:

```elixir
typed_structor type_name: :user_data do
  field :id, pos_integer()
  field :name, String.t()
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

## Common Patterns

### Nested Structs

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

### Integration with Other Tools

Skip struct generation to use with Ecto or other schema tools:

```elixir
defmodule User do
  use TypedStructor

  typed_structor module: Profile, define_struct: false do
    @derive {Jason.Encoder, only: [:email]}
    field :email, String.t(), enforce: true

    use Ecto.Schema
    @primary_key false

    schema "users" do
      Ecto.Schema.field(:email, :string)
    end

    import Ecto.Changeset

    def changeset(%__MODULE__{} = user, attrs) do
      user
      |> cast(attrs, [:email])
      |> validate_required([:email])
    end
  end
end
```

## Advanced Features

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

Create Erlang-compatible records for interoperability:

```elixir
defmodule UserRecord do
  use TypedStructor

  typed_structor definer: :defrecord, record_name: :user do
    field :name, String.t(), enforce: true
    field :age, pos_integer(), enforce: true
  end
end
```

## Plugins

Extend TypedStructor's behavior with plugins. They run during compilation to add functionality:

```elixir
defmodule User do
  use TypedStructor

  typed_structor do
    plugin Guides.Plugins.Accessible  # Adds Access behavior

    field :id, pos_integer()
    field :name, String.t()
  end
end

user = %User{id: 1, name: "Phil"}
get_in(user, [:name])  # => "Phil"
```

> #### Plugin Guides {: .tip}
>
> Check out the [Plugin Guides](guides/plugins/introduction.md) to learn how to create your own plugins.
> All examples include copy-paste-ready code.

## Documentation

Add `@moduledoc` at the module level, and `@typedoc` inside the block:

```elixir
defmodule User do
  @moduledoc "User management structures"
  use TypedStructor

  typed_structor do
    @typedoc "A user with authentication details"

    field :id, pos_integer()
    field :name, String.t()
  end
end
```

<!-- MODULEDOC -->

## Learn More

- **API Reference**: Check `TypedStructor.typed_structor/2` and `TypedStructor.field/3` for all options
- **Plugin System**: See `TypedStructor.Plugin` for creating custom plugins
- **Guides**: Visit [hexdocs.pm/typed_structor](https://hexdocs.pm/typed_structor) for detailed guides
