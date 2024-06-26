defmodule TypedStructor.Plugins.AccessibleTest do
  use ExUnit.Case, async: true

  defmodule Struct do
    use TypedStructor

    typed_structor do
      plugin TypedStructor.Plugins.Accessible

      parameter :age

      field :name, String.t()
      field :age, age
    end
  end

  describe "accessible option" do
    test "implements Access" do
      data = struct(Struct, name: "Phil", age: 20)

      assert "Phil" === get_in(data, [:name])
      assert %{name: "phil"} = put_in(data, [:name], "phil")

      assert_raise ArgumentError, ~r/Cannot update `:__struct__` key/, fn ->
        put_in(data, [:__struct__], "phil")
      end

      assert %{name: "phil"} = update_in(data, [:name], fn "Phil" -> "phil" end)

      assert_raise ArgumentError, ~r/Cannot update `:__struct__` key/, fn ->
        update_in(data, [:__struct__], fn _ -> nil end)
      end

      assert_raise ArgumentError, ~r/Cannot pop `:__struct__` key/, fn ->
        pop_in(data, [:__struct__])
      end

      assert_raise ArgumentError, ~r/Cannot pop `:name` key/, fn ->
        pop_in(data, [:name])
      end
    end
  end
end
