defmodule TypedStructor.TypeCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  setup do
    Code.compiler_options(debug_info: true)

    :ok
  end

  using do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro deftmpmodule(do: block) do
    quote do
      {:module, module_name, bytecode, submodule} =
        defmodule TestModule do
          # credo:disable-for-previous-line Credo.Check.Readability.ModuleDoc
          unquote(block)
        end

      case submodule do
        {:module, submodule_name, bytecode, _} ->
          on_exit(fn ->
            remove_module(module_name)
            remove_module(submodule_name)
          end)

          bytecode

        _other ->
          on_exit(fn ->
            remove_module(module_name)
          end)

          bytecode
      end
    end
  end

  defmacro test_module(do: block) do
    quote do
      {:module, module_name, bytecode, submodule} =
        returning =
        defmodule TestModule do
          # credo:disable-for-previous-line Credo.Check.Readability.ModuleDoc
          unquote(block)
        end

      case submodule do
        {:module, submodule_name, bytecode, _} ->
          remove_module(module_name)
          remove_module(submodule_name)

          bytecode

        _other ->
          remove_module(module_name)

          bytecode
      end
    end
  end

  def remove_module(module) do
    :code.delete(module)
    :code.purge(module)
  end

  def types(module) when is_binary(module) or is_atom(module) do
    module
    |> Code.Typespec.fetch_types()
    |> elem(1)
    |> Enum.sort_by(fn {_, {name, _, args}} -> {name, length(args)} end)
    |> Enum.map_join(
      "\n",
      fn {kind, type} ->
        ast = Code.Typespec.type_to_quoted(type)
        format_typespec(ast, kind)
      end
    )
  end

  defp format_typespec(ast, kind) do
    "@#{kind} #{Macro.to_string(ast)}"
  end
end
