defmodule ConfigTest do
  @compile {:no_warn_undefined, ConfigTest.Struct}

  # disable async for this test for changing the application env
  use TypedStructor.TestCase, async: false

  defmodule Plugin do
    use TypedStructor.Plugin

    @impl TypedStructor.Plugin
    defmacro init(opts) do
      quote do
        @plugin_calls {unquote(__MODULE__), unquote(opts)}
      end
    end
  end

  defmodule PluginWithOpts do
    use TypedStructor.Plugin

    @impl TypedStructor.Plugin
    defmacro init(opts) do
      quote do
        @plugin_calls {unquote(__MODULE__), unquote(opts)}
      end
    end
  end

  @tag :tmp_dir
  test "registers plugins from the config", ctx do
    set_plugins_config([Plugin, {PluginWithOpts, [foo: :bar]}])

    plugin_calls =
      with_tmpmodule Struct, ctx do
        use TypedStructor

        Module.register_attribute(__MODULE__, :plugin_calls, accumulate: true)

        typed_structor do
          field :name, String.t()
        end

        def plugin_calls, do: @plugin_calls
      after
        Struct.plugin_calls()
      end

    assert [
             {PluginWithOpts, [foo: :bar]},
             {Plugin, []}
           ] === plugin_calls
  end

  test "raises if the plugin is not a module" do
    set_plugins_config([42])

    assert_raise ArgumentError,
                 ~r/Expected a plugin module or a tuple with a plugin module and its keyword options/,
                 fn ->
                   defmodule Struct do
                     use TypedStructor

                     typed_structor do
                       field :name, String.t()
                     end
                   end
                 end
  end

  test "raises if the options are not a keyword list" do
    set_plugins_config([PluginWithOpts, 42])

    assert_raise ArgumentError,
                 ~r/Expected a plugin module or a tuple with a plugin module and its keyword options/,
                 fn ->
                   defmodule Struct do
                     use TypedStructor

                     typed_structor do
                       field :name, String.t()
                     end
                   end
                 end
  end

  defp set_plugins_config(plugins) do
    previous_value = Application.get_env(:typed_structor, :plugins, [])
    Application.put_env(:typed_structor, :plugins, plugins)
    on_exit(fn -> Application.put_env(:typed_structor, :plugins, previous_value) end)
  end
end
