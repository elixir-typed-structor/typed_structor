defmodule TypedStructor.Definition do
  @moduledoc """
  The definition struct that holds the `TypedStructor` options,
  fields and parameters.
  """

  @type t() :: %__MODULE__{
          options: Keyword.t(),
          fields: [Keyword.t()],
          parameters: [atom()]
        }

  defstruct [:options, :fields, :parameters]
end
