defmodule TypedStructor.Definition do
  @moduledoc """
  The definition struct that holds the `TypedStructor` options,
  fields and parameters.
  """

  @type t() :: %__MODULE__{
          options: Keyword.t(),
          fields: [Keyword.t()],
          parameters: [Keyword.t()]
        }

  @enforce_keys [:options, :fields, :parameters]
  defstruct [:options, :fields, :parameters]
end
