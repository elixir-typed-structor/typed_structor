defmodule Guides.Plugins.EnumerableTest do
  use TypedStructor.GuideCase,
    async: true,
    guide: "derive_enumerable.md"

  test "works" do
    user = %User{name: "Phil", age: 20}
    assert [:name, :age] === Enum.map(user, fn {key, _value} -> key end)
    assert [name: "Phil", age: 20] === Enum.to_list(user)
  end
end
