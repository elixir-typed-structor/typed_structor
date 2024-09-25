# TypedStructor

[![Build Status](https://github.com/elixir-typed-structor/typed_structor/actions/workflows/elixir.yml/badge.svg)](https://github.com/elixir-typed-structor/typed_structor/actions/workflows/elixir.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/typed_structor)](https://hex.pm/packages/typed_structor)
[![Document](https://img.shields.io/badge/document-gray)](https://hexdocs.pm/typed_structor)
[![Plugin guides](https://img.shields.io/badge/plugin_guides-indianred?label=%F0%9F%94%A5&labelColor=snow)](https://hexdocs.pm/typed_structor/introduction.html)

<!-- MODULEDOC -->

`TypedStructor` is a library for defining structs with types effortlessly.
(This library is a rewritten version of [TypedStruct](https://github.com/ejpcmac/typed_struct) because it is no longer actively maintained.)

## Installation

Add `:typed_structor` to the list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:typed_structor, "~> 0.4"}
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
    # Note: The 'name' can not be nil, for it has a default value.
    name: String.t(),
    age: non_neg_integer()
  }
end
```
Check `TypedStructor.typed_structor/2` and `TypedStructor.field/3` for more information.

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

If you prefer to define a struct in a submodule, you can use
the `module` option with `TypedStructor`. This allows you to
encapsulate the struct definition within a specific submodule context.

Consider this example:
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
When defining a struct in a submodule, the `typed_structor` block
functions similarly to a `defmodule` block. Therefore,
the previous example can be alternatively written as:
```elixir
defmodule User do
  defmodule Profile do
    use TypedStructor

    typed_structor do
      field :id, pos_integer()
      field :name, String.t()
      field :age, non_neg_integer()
    end
  end
end
```

Furthermore, the `typed_structor` block allows you to
define functions, derive protocols, and more, just
as you would within a `defmodule` block. Here's a example:
```elixir
defmodule User do
  use TypedStructor

  typed_structor module: Profile, define_struct: false do
    @derive {Jason.Encoder, only: [:email]}
    field :email, String.t()

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
Now, you can interact with these structures:
```elixir
iex> User.Profile.__struct__()
%User.Profile{__meta__: #Ecto.Schema.Metadata<:built, "users">, email: nil}
iex> Jason.encode!(%User.Profile{})
"{\"email\":null}"
iex> User.Profile.changeset(%User.Profile{}, %{"email" => "my@email.com"})
#Ecto.Changeset<
  action: nil,
  changes: %{email: "my@email.com"},
  errors: [],
  data: #User.Profile<>,
  valid?: true
>
```
## Define an Exception

In Elixir, an exception is defined as a struct that includes a special field named `__exception__`.
To define an exception, use the `defexception` definer within the `typed_structor` block.

```elixir
defmodule HTTPException do
  use TypedStructor

  typed_structor definer: :defexception, enforce: true do
    field :status, non_neg_integer()
  end

  @impl Exception
  def message(%__MODULE__{status: status}) do
    "HTTP status #{status}"
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
typedstructor module: Profile do
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

Here is a example of `Guides.Plugins.Accessible` plugin to define `Access` behavior for the struct.
```elixir
defmodule User do
  use TypedStructor

  typed_structor do
    plugin Guides.Plugins.Accessible

    field :id, pos_integer()
    field :name, String.t()
    field :age, non_neg_integer()
  end
end

user = %User{id: 1, name: "Phil", age: 20}
get_in(user, [:name]) # => "Phil"
```

> #### Plugins guides {: .tip}
>
> Here are some [Plugin Guides](guides/plugins/introduction.md)
> for creating your own plugins. Please check them out
> and feel free to copy-paste the code.
