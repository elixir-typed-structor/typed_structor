defmodule TypedStructor.PluginTest do
  use TypedStructor.TypeCase, async: true

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
    defmodule ManipulatePlugin do
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

    test "manipulates definition" do
      expected_bytecode =
        test_module do
          @type t() :: %TestModule{
                  NAME: (String.t() | atom()) | nil
                }

          defstruct [:NAME]
        end

      expected_types = types(expected_bytecode)

      bytecode =
        test_module do
          use TypedStructor

          typed_structor do
            plugin ManipulatePlugin

            field :name, String.t()
          end
        end

      assert expected_types === types(bytecode)
    end
  end
end
