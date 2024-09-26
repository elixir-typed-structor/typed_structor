defmodule TypedStructor.Definer.UtilsTest do
  use ExUnit.Case, async: true

  alias TypedStructor.Definer.Utils
  alias TypedStructor.Definition

  describe "fields_and_enforce_keys" do
    test "works" do
      definition =
        build_definitions(
          fields: [
            [name: :field],
            [name: :enforce_true_with_default, enforce: true, default: :foo],
            [name: :enforce_true_without_default, enforce: true],
            [name: :enforce_false_with_default, enforce: false, default: :foo],
            [name: :enforce_false_without_default, enforce: false]
          ]
        )

      assert {[
                field: nil,
                enforce_true_with_default: :foo,
                enforce_true_without_default: nil,
                enforce_false_with_default: :foo,
                enforce_false_without_default: nil
              ],
              [:enforce_true_without_default]} ===
               Utils.fields_and_enforce_keys(definition)
    end
  end

  describe "types" do
    test "works without parameters" do
      definition =
        build_definitions(
          options: [type_kind: :typep, type_name: :state],
          fields: [
            [name: :field, type: quote(do: atom())],
            [
              name: :enforce_true_with_default,
              type: quote(do: atom()),
              enforce: true,
              default: :foo
            ],
            [
              name: :enforce_true_without_default,
              type: quote(do: atom()),
              enforce: true
            ],
            [
              name: :enforce_false_with_default,
              type: quote(do: atom()),
              enforce: false,
              default: :foo
            ],
            [
              name: :enforce_false_without_default,
              type: quote(do: atom()),
              enforce: false
            ]
          ]
        )

      assert {
               :typep,
               :state,
               [],
               [
                 field: quote(do: atom() | nil),
                 enforce_true_with_default: quote(do: atom()),
                 enforce_true_without_default: quote(do: atom()),
                 enforce_false_with_default: quote(do: atom()),
                 enforce_false_without_default: quote(do: atom() | nil)
               ]
             } === Utils.types(definition, __ENV__)
    end

    test "works with parameters" do
      definition =
        build_definitions(
          options: [type_kind: :typep, type_name: :state],
          parameters: [[name: :name], [name: :age]],
          fields: [
            [name: :name, type: quote(do: name), enforce: true],
            [name: :age, type: quote(do: age), enforce: true]
          ]
        )

      assert {
               :typep,
               :state,
               [
                 Macro.var(:name, __MODULE__),
                 Macro.var(:age, __MODULE__)
               ],
               [
                 name: quote(do: name),
                 age: quote(do: age)
               ]
             } === Utils.types(definition, __ENV__)
    end

    test "works" do
      definition =
        build_definitions(
          options: [type_kind: :typep, type_name: :state],
          parameters: [[name: :role]],
          fields: [
            [name: :name, type: quote(do: String.t()), enforce: true],
            [name: :age, type: quote(do: pos_integer())],
            [name: :role, type: quote(do: role), default: :user]
          ]
        )

      assert {
               :typep,
               :state,
               [{:role, [], TypedStructor.Definer.UtilsTest}],
               [
                 name: quote(do: String.t()),
                 age: quote(do: pos_integer() | nil),
                 role: quote(do: role)
               ]
             } === Utils.types(definition, __ENV__)
    end
  end

  defp build_definitions(params) do
    struct(
      Definition,
      Keyword.merge([options: [], fields: [], parameters: []], params)
    )
  end
end
