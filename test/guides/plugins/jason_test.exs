defmodule Guides.Plugins.JasonTest do
  use TypedStructor.GuideCase,
    async: true,
    guide: "derive_jason.md"

  test "works" do
    assert {:ok, "{\"name\":\"Phil\"}"} === Jason.encode(%User{name: "Phil"})
  end
end
