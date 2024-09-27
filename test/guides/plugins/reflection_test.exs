defmodule Guides.Plugins.ReflectionTest do
  use TypedStructor.GuideCase,
    async: true,
    guide: "reflection.md"

  test "generates reflection functions" do
    assert [:name, :age] === User.__typed_structor__(:fields)
    assert [:name, :age] === MyApp.User.__typed_structor__(:fields)

    assert [:age] === User.__typed_structor__(:parameters)
    assert [] === MyApp.User.__typed_structor__(:parameters)

    assert [:name] === User.__typed_structor__(:enforced_fields)
    assert [:name, :age] === MyApp.User.__typed_structor__(:enforced_fields)

    assert "String.t()" === Macro.to_string(User.__typed_structor__(:type, :name))
    assert "age" === Macro.to_string(User.__typed_structor__(:type, :age))

    assert "String.t()" === Macro.to_string(MyApp.User.__typed_structor__(:type, :name))
    assert "integer()" === Macro.to_string(MyApp.User.__typed_structor__(:type, :age))

    assert [enforce: true, name: :name, type: type] = User.__typed_structor__(:field, :name)
    assert "String.t()" === Macro.to_string(type)

    assert [name: :age, type: type] =
             MyApp.User.__typed_structor__(:field, :age)

    assert "integer()" === Macro.to_string(type)

    assert [enforce: true, name: :name, type: type] = User.__typed_structor__(:field, :name)
    assert "String.t()" === Macro.to_string(type)
    assert [default: 20, name: :age, type: type] = User.__typed_structor__(:field, :age)
    assert "age" === Macro.to_string(type)
  end
end
