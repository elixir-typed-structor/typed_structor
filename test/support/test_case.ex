defmodule TypedStructor.TestCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  setup ctx do
    if Map.has_key?(ctx, :tmp_dir) do
      true = Code.append_path(ctx.tmp_dir)
      on_exit(fn -> Code.delete_path(ctx.tmp_dir) end)
    end

    :ok
  end

  using do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Defines a temporary module with the given `module_name` and executes the code
  in the `after` block. The module is removed after the block is executed.
  And the `after` block's return value is returned.

  Note that the `module_name` is expanded to the caller's module.
  """
  defmacro with_tmpmodule(module_name, ctx, options) when is_list(options) do
    module_name =
      module_name
      |> Macro.expand(__CALLER__)
      |> then(&Module.concat(__CALLER__.module, &1))

    code = Keyword.fetch!(options, :do)

    content =
      """
      defmodule #{Atom.to_string(module_name)} do
        #{Macro.to_string(code)}
      end
      """

    fun =
      quote do
        fn ->
          alias unquote(module_name)
          unquote(Keyword.get(options, :after))
        end
      end

    quote do
      unquote(__MODULE__).__with_file__(
        unquote(ctx),
        {unquote(module_name), unquote(content)},
        unquote(fun)
      )
    end
  end

  @doc false
  def __with_file__(%{tmp_dir: dir}, {module_name, content}, fun) when is_function(fun, 0) do
    path = Path.join([dir, Atom.to_string(module_name)])

    File.write!(path, content)
    mods = compile_file!(path, dir)

    try do
      fun.()
    after
      File.rm!(path)
      cleanup_modules(mods, dir)
    end
  end

  @doc """
  Defines a temporary module with the given `module_name`,
  returns the compiled modules.

  You should clean up the modules by calling `cleanup_modules/2`
  after you are done.

  Note that the `module_name` is expanded to the caller's module
  like `with_tmpmodule/3`.
  """
  defmacro deftmpmodule(module_name, ctx, do: block) do
    module_name =
      module_name
      |> Macro.expand(__CALLER__)
      |> then(&Module.concat(__CALLER__.module, &1))

    content =
      """
      defmodule #{Atom.to_string(module_name)} do
        #{Macro.to_string(block)}
      end
      """

    quote do
      alias unquote(module_name)

      unquote(__MODULE__).__compile_tmpmodule__(
        unquote(ctx),
        {unquote(module_name), unquote(content)}
      )
    end
  end

  @doc false
  def __compile_tmpmodule__(%{tmp_dir: dir}, {module_name, content}) do
    path = Path.join([dir, Atom.to_string(module_name)])

    File.write!(path, content)
    compile_file!(path, dir)
  end

  defp compile_file!(path, dir) do
    Code.compiler_options(docs: true, debug_info: true)
    {:ok, modules, []} = Kernel.ParallelCompiler.compile_to_path(List.wrap(path), dir)

    modules
  end

  @doc """
  Cleans up the modules by removing the beam files and purging the code.
  """
  @spec cleanup_modules([module()], dir :: Path.t()) :: term()
  def cleanup_modules(mods, dir) do
    Enum.each(mods, fn mod ->
      File.rm(Path.join([dir, "#{mod}.beam"]))
      :code.purge(mod)
      true = :code.delete(mod)
    end)
  end

  @doc """
  Fetches the types for the given module.
  """
  @spec fetch_types!(module() | binary) :: [tuple()]
  def fetch_types!(module) when is_atom(module) or is_binary(module) do
    module
    |> Code.Typespec.fetch_types()
    |> case do
      :error -> flunk("Failed to fetch types for module #{module}")
      {:ok, types} -> types
    end
  end

  @doc """
  Fetches the doc for the given module or its functions and types.
  """
  def fetch_doc!(module, :moduledoc) when is_atom(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, :elixir, _, %{"en" => doc}, _, _} -> doc
      _ -> flunk("Failed to fetch moduledoc for #{module}")
    end
  end

  def fetch_doc!(module, {type, name, arity}) when is_atom(module) do
    docs =
      case Code.fetch_docs(module) do
        {:docs_v1, _, :elixir, _, _, _, docs} -> docs
        {:error, reason} -> flunk("Failed to fetch doc for #{module}: #{inspect(reason)}")
      end

    case List.keyfind(docs, {type, name, arity}, 0) do
      nil ->
        flunk("""
        Failed to fetch doc for #{inspect({type, name, arity})} at #{module}, docs:
        #{Enum.map_join(docs, "  \n", fn doc -> inspect(elem(doc, 0)) end)}
        """)

      {_, _, _, %{"en" => doc}, _} ->
        doc
    end
  end

  @doc """
  Asserts that the expected types are equal to the actual types by comparing
  their formatted strings.
  """
  @spec assert_type(expected :: [tuple()], actual :: [tuple()]) :: term()
  def assert_type(expected, actual) do
    expected_types = format_types(expected)

    if String.length(String.trim(expected_types)) === 0 do
      flunk("Expected types are empty: #{inspect(expected)}")
    end

    assert expected_types == format_types(actual)
  end

  @spec format_types([tuple()]) :: String.t()
  def format_types(types) do
    types
    |> Enum.sort_by(fn {_, {name, _, args}} -> {name, length(args)} end)
    |> Enum.map_join(
      "\n",
      fn {kind, type} ->
        ast = Code.Typespec.type_to_quoted(type)
        "@#{kind} #{Macro.to_string(ast)}"
      end
    )
  end
end
