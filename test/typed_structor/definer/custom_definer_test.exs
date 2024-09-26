defmodule TypedStructor.Definer.CustomDefinerTest do
  use TypedStructor.TestCase, async: true

  defmodule MyDefiner do
    defmacro define(definition) do
      quote do
        def definition, do: unquote(definition)
      end
    end
  end

  defmodule Plugin do
    use TypedStructor.Plugin

    @impl TypedStructor.Plugin
    defmacro before_definition(definition, _plugin_opts) do
      quote do
        Map.update!(unquote(definition), :options, fn options ->
          Keyword.put(options, :definer, MyDefiner)
        end)
      end
    end
  end

  test "custom definer works" do
    defmodule MyStruct do
      use TypedStructor

      typed_structor definer: MyDefiner do
        field :name, String.t()
      end
    end

    assert function_exported?(MyStruct, :definition, 0)
    refute function_exported?(MyStruct, :__struct__, 0)
  end

  test "raises when invalid definer is given" do
    assert_raise ArgumentError, ~r/Definer must be one of/, fn ->
      defmodule InvalidDefiner do
        use TypedStructor

        typed_structor definer: 1 do
          field :name, String.t()
        end
      end
    end
  end

  test "warns when definer is overridden" do
    {_result, [warning]} =
      Code.with_diagnostics(fn ->
        defmodule DefinerWarning do
          use TypedStructor

          typed_structor do
            plugin Plugin

            field :name, String.t()
          end
        end
      end)

    assert match?(
             %{
               message:
                 "The definer option set in the `typed_structor` block is different from the definer option in the definition" <>
                   _message
             },
             warning
           )
  end
end
