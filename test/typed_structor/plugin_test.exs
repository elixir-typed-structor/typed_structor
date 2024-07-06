defmodule TypedStructor.PluginTest do
  use TypedStructor.TestCase, async: true

  describe "callbacks order" do
    for plugin <- [Plugin1, Plugin2] do
      defmodule plugin do
        use TypedStructor.Plugin

        @impl TypedStructor.Plugin
        defmacro init(_plugin_opts) do
          quote do
            @plugin_calls {unquote(__MODULE__), :init}
          end
        end

        @impl TypedStructor.Plugin
        defmacro before_definition(definition, _plugin_opts) do
          quote do
            @plugin_calls {unquote(__MODULE__), :before_definition}
            unquote(definition)
          end
        end

        @impl TypedStructor.Plugin
        defmacro after_definition(_definition, _plugin_opts) do
          quote do
            @plugin_calls {unquote(__MODULE__), :after_definition}
          end
        end
      end
    end

    defmodule Struct do
      use TypedStructor
      Module.register_attribute(__MODULE__, :plugin_calls, accumulate: true)

      typed_structor do
        plugin Plugin1
        plugin Plugin2

        field :name, String.t()
      end

      def plugin_calls, do: @plugin_calls
    end

    test "callbacks are called by order" do
      assert [
               {Plugin1, :after_definition},
               {Plugin2, :after_definition},
               {Plugin2, :before_definition},
               {Plugin1, :before_definition},
               {Plugin2, :init},
               {Plugin1, :init}
             ] === Struct.plugin_calls()
    end
  end

  describe "before_definition/2" do
    @tag :tmp_dir
    test "manipulates definition", ctx do
      deftmpmodule ManipulatePlugin, ctx do
        use TypedStructor.Plugin

        @impl TypedStructor.Plugin
        defmacro before_definition(definition, _plugin_opts) do
          quote do
            Map.update!(
              unquote(definition),
              :fields,
              fn fields ->
                Enum.map(fields, fn field ->
                  {name, field} = Keyword.pop!(field, :name)
                  {type, field} = Keyword.pop!(field, :type)
                  name = name |> Atom.to_string() |> String.upcase() |> String.to_atom()
                  type = quote do: unquote(type) | atom()

                  [{:name, name}, {:type, type} | field]
                end)
              end
            )
          end
        end
      end

      expected_types =
        with_tmpmodule MyStruct, ctx do
          @type t() :: %__MODULE__{
                  NAME: (String.t() | atom()) | nil
                }

          defstruct [:NAME]
        after
          fetch_types!(MyStruct)
        end

      types =
        with_tmpmodule MyStruct, ctx do
          use TypedStructor

          typed_structor do
            plugin unquote(__MODULE__).ManipulatePlugin

            field :name, String.t()
          end
        after
          fetch_types!(MyStruct)
        end

      assert_type expected_types, types
    after
      cleanup_modules([__MODULE__.ManipulatePlugin], ctx.tmp_dir)
    end
  end
end
