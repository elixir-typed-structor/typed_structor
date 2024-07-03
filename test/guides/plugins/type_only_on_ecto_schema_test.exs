defmodule Guides.Plugins.TypeOnlyOnEctoSchema do
  use TypedStructor.GuideCase,
    async: true,
    guide: "type_only_on_ecto_schema.md"

  test "works", ctx do
    assert """
           @type t() :: %Guides.Plugins.TypeOnlyOnEctoSchema.MyApp.User{
             __meta__: term(),
             age: integer(),
             id: integer(),
             name: String.t() | nil
           }
           """ === types(ctx.registered.bytecode)

    user = %MyApp.User{name: "Phil"}
    assert 20 === user.age
  end
end
