defmodule TypedStructor.Definer.Defexception do
  additional_options = """
  * `:define_struct` - if `false`, the type will be defined, but the struct will not be defined. Defaults to `true`.
  """

  @moduledoc """
  A definer to define an exception and a type for a given definition.

  ## Additional options for `typed_structor`

  #{additional_options}

  ## Usage

      defmodule MyException do
        use TypedStructor

        typed_structor definer: :defexception, define_struct: false do
          field :message, String.t()
        end
      end
  """

  alias TypedStructor.Definer.Defstruct
  alias TypedStructor.Definer.Utils

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
        {fields, enforce_keys} = Utils.fields_and_enforce_keys(definition)

        @enforce_keys Enum.reverse(enforce_keys)
        defexception fields
      end
    end
  end

  @doc false
  def __additional_options__, do: unquote(additional_options)
end
