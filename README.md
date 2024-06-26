# TypedStructor

[![Build Status](https://github.com/elixir-typed-structor/typed_structor/actions/workflows/elixir.yml/badge.svg)](https://github.com/elixir-typed-structor/typed_structor/actions/workflows/elixir.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/typed_structor.svg)](https://hex.pm/packages/typed_structor)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/typed_structor/)

`TypedStructor` is a library for defining structs with types effortlessly.
(This library is a rewritten version of [TypedStruct](https://github.com/ejpcmac/typed_struct) because it is no longer actively maintained.)

<!-- MODULEDOC -->

## Installation

Add `:typed_structor` to the list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:typed_structor, "~> 0.1.0"}
  ]
end
```

Add `:typed_structor` to your `.formatter.exs` file

```elixir
[
  # import the formatter rules from `:typed_structor`
  import_deps: [..., :typed_structor],
  inputs: [...]
]
```

## Usage

### General usage

To define a struct with types, use `TypedStructor`,
and then define fields under the `TypedStructor.typed_structor/2` macro,
using the `TypedStructor.field/3` macro to define each field.

```elixir
defmodule User do
  # use TypedStructor to import the `typed_structor` macro
  use TypedStructor

  typed_structor do
    # Define each field with the `field` macro.
    field :id, pos_integer()

    # set a default value
    field :name, String.t(), default: "Unknown"

    # enforce a field
    field :age, non_neg_integer(), enforce: true
  end
end
```
This is equivalent to:
```elixir
defmodule User do
  defstruct [:id, :name, :age]

  @type t() :: %__MODULE__{
    id: pos_integer() | nil,
    # Note: The 'name' can be nil, even though it has a default value.
    name: String.t() | nil,
    age: non_neg_integer()
  }
end
```
Check `TypedStructor.typed_structor/2` and `TypedStructor.field/3` for more information.

> #### `:enforce` and `:default` option  {: .warning}
> Note that the `default` option does not affect the `enforce` option.
> If you want to enforce a field, you should explicitly set the `enforce` option to `true`.
>
> Consider the following example, `nil` is a valid value for the `:foo` field.
>
> ```elixir
> defmodule Settings do
>   @enforce_keys [:foo]
>   defstruct [foo: :bar]
> end
> 
> %Settings{} # => ** (ArgumentError) the following keys must also be given when building struct Settings: [:foo]
> # `nil` is a valid value for the `:foo` field
> %Settings{foo: nil} # => %Settings{foo: nil}
> ```

### Options

You can also generate an `opaque` type for the struct,
even changing the type name:

```elixir
defmodule User do
  use TypedStructor

  typed_structor type_kind: :opaque, type_name: :profile do
    field :id, pos_integer()
    field :name, String.t()
    field :age, non_neg_integer()
  end
end
```
This is equivalent to:
```elixir
defmodule User do
  use TypedStructor

  defstruct [:id, :name, :age]

  @opaque profile() :: %__MODULE__{
    id: pos_integer() | nil,
    name: String.t() | nil,
    age: non_neg_integer() | nil
  }
end
```

Type parameters also can be defined:
```elixir
defmodule User do
  use TypedStructor

  typed_structor do
    parameter :id
    parameter :name

    field :id, id
    field :name, name
    field :age, non_neg_integer()
  end
end
```
becomes:
```elixir
defmodule User do
  @type t(id, name) :: %__MODULE__{
    id: id | nil,
    name: name | nil,
    age: non_neg_integer() | nil
  }

  defstruct [:id, :name, :age]
end
```

If you prefer to define a struct in a submodule, pass the `module` option.
```elixir
defmodule User do
  use TypedStructor

  # `%User.Profile{}` is generated
  typed_structor module: Profile do
    field :id, pos_integer()
    field :name, String.t()
    field :age, non_neg_integer()
  end
end
```

You can define the type only without defining the struct,
it is useful when the struct is defined by another library(like `Ecto.Schema`).
```elixir
defmodule User do
  use Ecto.Schema
  use TypedStructor

  typed_structor define_struct: false do
    field :id, pos_integer()
    field :name, String.t()
    field :age, non_neg_integer(), default: 0 # default value is useless in this case
  end

  schema "users" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

## Documentation

To add a `@typedoc` to the struct type, just add the attribute in the typed_structor block:

```elixir
typed_structor do
  @typedoc "A typed user"

  field :id, pos_integer()
  field :name, String.t()
  field :age, non_neg_integer()
end
```
You can also document submodules this way:

```elixir
typedstruct module: Profile do
  @moduledoc "A user profile struct"
  @typedoc "A typed user profile"

  field :id, pos_integer()
  field :name, String.t()
  field :age, non_neg_integer()
end
```

## Plugins

`TypedStructor` offers a plugin system to enhance functionality.
For details on creating a plugin, refer to the `TypedStructor.Plugin` module.

Here is a example of `TypedStructor.Plugins.Accessible` plugin to define `Access` behavior for the struct.
```elixir
defmodule User do
  use TypedStructor

  typed_structor do
    plugin TypedStructor.Plugins.Accessible

    field :id, pos_integer()
    field :name, String.t()
    field :age, non_neg_integer()
  end
end

user = %User{id: 1, name: "Phil", age: 20}
get_in(user, [:name]) # => "Phil"
```
