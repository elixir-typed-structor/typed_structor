defmodule TypedStructor.GuideCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using opts do
    guide = Keyword.fetch!(opts, :guide)

    file = Path.expand([__DIR__, "../../../", "guides/plugins/", guide])

    ast = Code.string_to_quoted!(extract_code(file))

    quote do
      Code.compiler_options(debug_info: true)

      {:module, _module_name, bytecode, _submodule} = unquote(ast)

      ExUnit.Case.register_module_attribute(__MODULE__, :bytecode)
      @bytecode bytecode

      import unquote(__MODULE__), only: [types: 1]
    end
  end

  def types(bytecode) when is_binary(bytecode) do
    TypedStructor.TypeCase.types(bytecode) <> "\n"
  end

  defp extract_code(file) do
    content =
      File.read!(file)

    content
    |> String.split("\n")
    |> Enum.with_index(1)
    |> extract_code(%{in_code_block?: false, codes: []})
    |> case do
      %{codes: [implementation, usage | _resut]} ->
        """
        #{implementation |> Enum.reverse() |> Enum.join("\n")}
        #{usage |> Enum.reverse() |> Enum.join("\n")}
        """

      ctx ->
        raise ArgumentError,
              """
              Cannot find implementation and usage in file #{inspect(file)}
              context: #{inspect(ctx)}
              #{content}
              """
    end
  end

  @start "```elixir"
  @stop "```"

  defp extract_code([], %{in_code_block?: false} = ctx) do
    %{ctx | codes: Enum.reverse(ctx.codes)}
  end

  defp extract_code([{@start, _index} | rest], %{in_code_block?: false} = ctx) do
    extract_code(rest, %{ctx | in_code_block?: true, codes: [[] | ctx.codes]})
  end

  defp extract_code([{@stop, _index} | rest], %{in_code_block?: true} = ctx) do
    extract_code(rest, %{ctx | in_code_block?: false})
  end

  defp extract_code([{text, _index} | rest], %{in_code_block?: true} = ctx) do
    [current | codes] = ctx.codes
    extract_code(rest, %{ctx | codes: [[text | current] | codes]})
  end

  defp extract_code([_text | rest], %{in_code_block?: false} = ctx) do
    extract_code(rest, ctx)
  end

  defp extract_code([{text, index} | _rest], ctx) do
    raise ArgumentError,
          """
          Unexpected text at line #{index}: #{inspect(text)}
          context: #{inspect(ctx)}
          """
  end

  defp extract_code([], ctx) do
    raise ArgumentError,
          """
          Code block not closed
          context: #{inspect(ctx)}
          """
  end
end