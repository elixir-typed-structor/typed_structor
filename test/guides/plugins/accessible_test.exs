defmodule Guides.Plugins.AccessibleTest do
  use TypedStructor.GuideCase,
    async: true,
    guide: "accessible.md"

  test "implements Access" do
    user = %User{name: "Phil", age: 20}

    assert "Phil" === get_in(user, [:name])
    assert %User{name: "phil", age: 20} === put_in(user, [:name], "phil")

    assert_raise ArgumentError, ~r/Cannot update `:__struct__` key/, fn ->
      put_in(user, [:__struct__], "phil")
    end

    assert %{name: "phil"} = update_in(user, [:name], fn "Phil" -> "phil" end)

    assert_raise ArgumentError, ~r/Cannot update `:__struct__` key/, fn ->
      update_in(user, [:__struct__], fn _ -> nil end)
    end

    assert_raise ArgumentError, ~r/Cannot pop `:__struct__` key/, fn ->
      pop_in(user, [:__struct__])
    end

    assert_raise ArgumentError, ~r/Cannot pop `:name` key/, fn ->
      pop_in(user, [:name])
    end
  end
end
