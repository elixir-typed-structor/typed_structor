defmodule TypedStructor.Definer.Utils do
  @moduledoc """
  Utilities for definer modules.
  """

  @doc """
  Extracts fields and enforce keys from a definition.
  """
  @spec fields_and_enforce_keys(TypedStructor.Definition.t()) ::
          {Keyword.t(), [atom()]}
  def fields_and_enforce_keys(definition) do
    Enum.map_reduce(definition.fields, [], fn field, acc ->
      name = Keyword.fetch!(field, :name)
      default = Keyword.get(field, :default)

      if get_keyword_value(field, :enforce, definition.options, false) and
           not Keyword.has_key?(field, :default) do
        {{name, default}, [name | acc]}
      else
        {{name, default}, acc}
      end
    end)
  end

  @doc """
  Extracts types from a definition.
  """
  @spec types(TypedStructor.Definition.t(), Macro.Env.t()) :: {
          type_kind :: :type | :opaque | :typep,
          type_name :: atom(),
          parameters :: [{parameter_name :: atom(), [], context :: atom()}],
          fields :: [{field_name :: atom(), Macro.t()}]
        }
  def types(definition, caller) do
    type_kind = Keyword.get(definition.options, :type_kind, :type)
    type_name = Keyword.get(definition.options, :type_name, :t)

    parameters =
      Enum.map(
        definition.parameters,
        fn parameter ->
          parameter
          |> Keyword.fetch!(:name)
          |> Macro.var(caller.module)
        end
      )

    fields =
      Enum.map(definition.fields, fn field ->
        name = Keyword.fetch!(field, :name)
        type = Keyword.fetch!(field, :type)

        if get_keyword_value(field, :enforce, definition.options, false) or
             Keyword.has_key?(field, :default) do
          {name, type}
        else
          {name, quote(do: unquote(type) | nil)}
        end
      end)

    {type_kind, type_name, parameters, fields}
  end

  @spec get_keyword_value(Keyword.t(val), atom(), Keyword.t(val), val) :: val
        when val: Keyword.value()
  defp get_keyword_value(kv, key, options, default)
       when is_list(kv) and is_atom(key) and is_list(options) do
    Keyword.get_lazy(kv, key, fn ->
      Keyword.get(options, key, default)
    end)
  end
end
