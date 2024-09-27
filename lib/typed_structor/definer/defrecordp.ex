defmodule TypedStructor.Definer.Defrecordp do
  @moduledoc """
  A definer to define private record macros and a type for a given definition.

  See more at `TypedStructor.Definer.Defrecord`.
  """

  alias TypedStructor.Definer.Defrecord

  @doc """
  Defines an exception and a type for a given definition.
  """
  defmacro define(definition) do
    quote do
      require Defrecord

      Defrecord.__record_ast__(:private, unquote(definition))
      Defrecord.__type_ast__(unquote(definition))
    end
  end
end
