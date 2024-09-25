defmodule TypedStructor.Definer.Defexception do
  @moduledoc """
  A definer to define an exception and a type for a given definition.

  ## Additional options for `typed_structor`

    * `:define_struct` - if `false`, the type will be defined, but the struct will not be defined. Defaults to `true`.

  ## Usage

      defmodule MyException do
        use TypedStructor

        typed_structor definer: :defexception, define_struct: false do
          field :message, String.t()
        end
      end
  """

  alias TypedStructor.Definer.Defstruct

  @doc """
  Defines an exception and a type for a given definition.
  """
  defmacro define(definition) do
    quote do
      unquote(__MODULE__).__exception_ast__(unquote(definition))

      require Defstruct
      Defstruct.__type_ast__(unquote(definition))
    end
  end

  @doc false
  defmacro __exception_ast__(definition) do
    quote bind_quoted: [definition: definition] do
      if Keyword.get(definition.options, :define_struct, true) do
        {fields, enforce_keys} =
          Defstruct.__extract_fields_and_enforce_keys__(definition)

        @enforce_keys Enum.reverse(enforce_keys)
        defexception fields
      end
    end
  end
end
