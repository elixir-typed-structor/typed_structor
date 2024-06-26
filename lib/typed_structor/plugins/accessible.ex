defmodule TypedStructor.Plugins.Accessible do
  @moduledoc """
  This plugin implements the `Access` behavior for the struct
  by delegating the `fetch/2`, `get_and_update/3`, and `pop/2`
  functions to the `Map` module.

  > #### Destructive operations  {: .warning}
  > These operations are not allowed for the struct:
  > * update `:__struct__` key
  > * pop a key
  >
  > The functions will raise an `ArgumentError` if called.
  > To enable these functionalities, override the `get_and_update/3` and `pop/2` functions.

  ## Usage

  ```elixir
    typed_structor do
      plugin TypedStructor.Plugins.Accessible

      # fields
    end
  ```
  """

  use TypedStructor.Plugin

  @impl TypedStructor.Plugin
  defmacro after_definition(_definition, _opts) do
    quote do
      @behaviour Access

      @impl Access
      defdelegate fetch(term, key), to: Map

      @impl Access
      def get_and_update(data, :__struct__, _function) do
        raise ArgumentError,
              "Cannot update `:__struct__` key." <>
                "To enable this functionality, implement `Access.get_and_update/3` for #{inspect(__MODULE__)} to override this behaviour."
      end

      defdelegate get_and_update(data, key, function), to: Map

      @impl Access
      def pop(data, key) do
        raise ArgumentError,
              "Cannot pop `#{inspect(key)}` key.\n" <>
                "To enable this functionality, implement `Access.pop/2` for #{inspect(__MODULE__)} to override this behaviour."
      end

      @defoverridable Access
    end
  end
end
