defmodule ReflectionTest do
  use ExUnit.Case, async: true

  defmodule Struct do
    use TypedStructor

    typed_structor do
      parameter :age

      field :name, String.t(), enforce: true
      field :age, age
    end
  end

  defmodule MyModule do
    use TypedStructor

    typed_structor module: Struct, enforce: true do
      field :name, String.t()
      field :age, integer()
    end
  end

  test "generates reflection functions" do
    assert [:name, :age] === Struct.__typed_structor__(:fields)
    assert [:name, :age] === MyModule.Struct.__typed_structor__(:fields)

    assert [:age] === Struct.__typed_structor__(:parameters)
    assert [] === MyModule.Struct.__typed_structor__(:parameters)

    assert [:name] === Struct.__typed_structor__(:enforced_fields)
    assert [:name, :age] === MyModule.Struct.__typed_structor__(:enforced_fields)

    assert "String.t()" === Macro.to_string(Struct.__typed_structor__(:type, :name))
    assert "age" === Macro.to_string(Struct.__typed_structor__(:type, :age))

    assert "String.t()" === Macro.to_string(MyModule.Struct.__typed_structor__(:type, :name))
    assert "integer()" === Macro.to_string(MyModule.Struct.__typed_structor__(:type, :age))

    assert [enforce: true, name: :name, type: type] = Struct.__typed_structor__(:field, :name)
    assert "String.t()" === Macro.to_string(type)

    assert [enforce: true, name: :age, type: type] =
             MyModule.Struct.__typed_structor__(:field, :age)

    assert "integer()" === Macro.to_string(type)

    assert [enforce: true, name: :name, type: type] = Struct.__typed_structor__(:field, :name)
    assert "String.t()" === Macro.to_string(type)
    assert [name: :age, type: type] = Struct.__typed_structor__(:field, :age)
    assert "age" === Macro.to_string(type)
  end
end
