defmodule Guides.Plugins.PrimaryKeyAndTimestampsTest do
  use TypedStructor.GuideCase,
    async: true,
    guide: "primary_key_and_timestamps.md"

  test "works", ctx do
    assert """
           @type t() :: %Guides.Plugins.PrimaryKeyAndTimestampsTest.User{
             __meta__: term(),
             age: integer(),
             id: integer(),
             inserted_at: NaiveDateTime.t(),
             name: String.t() | nil,
             updated_at: NaiveDateTime.t()
           }
           """ === types(ctx.registered.bytecode)

    user = %User{name: "Phil"}
    assert 20 === user.age
  end
end
