defmodule TypedStructor.Definer.Defstruct do
  @moduledoc """
  A definer to define a struct and a type for a given definition.

  ## Additional options for `typed_structor`

    * `:define_struct` - if `false`, the type will be defined, but the struct will not be defined. Defaults to `true`.

  ## Usage

      defmodule MyStruct do
        use TypedStructor

        typed_structor definer: :defstruct, define_struct: false do
          field :name, String.t()
          field :age, integer()
        end
      end
  """

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
    alias TypedStructor.Definer.Defstruct

    quote bind_quoted: [definition: definition] do
      if Keyword.get(definition.options, :define_struct, true) do
        {fields, enforce_keys} =
          Defstruct.__extract_fields_and_enforce_keys__(definition)

        @enforce_keys Enum.reverse(enforce_keys)
        defstruct fields
      end
    end
  end

  @doc false
  @spec __extract_fields_and_enforce_keys__(TypedStructor.Definition.t()) ::
          {Keyword.t(), [atom()]}
  def __extract_fields_and_enforce_keys__(definition) do
    Enum.map_reduce(definition.fields, [], fn field, acc ->
      name = Keyword.fetch!(field, :name)
      default = Keyword.get(field, :default)

      if Keyword.get(field, :enforce, false) and not Keyword.has_key?(field, :default) do
        {{name, default}, [name | acc]}
      else
        {{name, default}, acc}
      end
    end)
  end

  @doc false
  defmacro __type_ast__(definition) do
    quote bind_quoted: [definition: definition] do
      fields =
        Enum.reduce(definition.fields, [], fn field, acc ->
          name = Keyword.fetch!(field, :name)
          type = Keyword.fetch!(field, :type)

          if Keyword.get(field, :enforce, false) or Keyword.has_key?(field, :default) do
            [{name, type} | acc]
          else
            [{name, quote(do: unquote(type) | nil)} | acc]
          end
        end)

      type_name = Keyword.get(definition.options, :type_name, :t)

      parameters =
        Enum.map(
          definition.parameters,
          fn parameter ->
            parameter
            |> Keyword.fetch!(:name)
            |> Macro.var(__MODULE__)
          end
        )

      case Keyword.get(definition.options, :type_kind, :type) do
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
end
