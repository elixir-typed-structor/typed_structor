defmodule TypedStructor.Definer.Defstruct do
  additional_options = """
  * `:define_struct` - if `false`, the type will be defined, but the struct will not be defined. Defaults to `true`.
  """

  @moduledoc """
  A definer to define a struct and a type for a given definition.

  ## Additional options for `typed_structor`

  #{additional_options}

  ## Usage

      defmodule MyStruct do
        use TypedStructor

        typed_structor definer: :defstruct, define_struct: false do
          field :name, String.t()
          field :age, integer()
        end
      end
  """

  alias TypedStructor.Definer.Utils

  @doc """
  Defines a struct and a type for a given definition.
  """
  defmacro define(definition) do
    quote do
      unquote(__MODULE__).__struct_ast__(unquote(definition))
      unquote(__MODULE__).__type_ast__(unquote(definition))
    end
  end

  @doc false
  defmacro __struct_ast__(definition) do
    quote bind_quoted: [definition: definition] do
      if Keyword.get(definition.options, :define_struct, true) do
        {fields, enforce_keys} = Utils.fields_and_enforce_keys(definition)

        @enforce_keys Enum.reverse(enforce_keys)
        defstruct fields
      end
    end
  end

  @doc false
  defmacro __type_ast__(definition) do
    quote bind_quoted: [definition: definition] do
      {type_kind, type_name, parameters, fields} = Utils.types(definition, __ENV__)

      case type_kind do
        :type ->
          @type unquote(type_name)(unquote_splicing(parameters)) :: %__MODULE__{
                  unquote_splicing(fields)
                }

        :opaque ->
          @opaque unquote(type_name)(unquote_splicing(parameters)) :: %__MODULE__{
                    unquote_splicing(fields)
                  }

        :typep ->
          @typep unquote(type_name)(unquote_splicing(parameters)) :: %__MODULE__{
                   unquote_splicing(fields)
                 }
      end
    end
  end

  @doc false
  def __additional_options__, do: unquote(additional_options)
end
