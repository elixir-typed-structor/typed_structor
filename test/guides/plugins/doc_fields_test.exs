defmodule Guides.Plugins.DocFieldsTest do
  use TypedStructor.TestCase

  @tag :tmp_dir
  test "works", ctx do
    doc =
      with_tmpmodule TestModule, ctx do
        unquote(
          "doc_fields.md"
          |> TypedStructor.GuideCase.extract_code()
          |> Code.string_to_quoted!()
        )
      after
        fetch_doc!(TestModule.User, {:type, :t, 1})
      end

    expected = """
    @type t(age) :: %User{age: age | nil, name: String.t() | nil}

    This is a user struct.

    ## Parameters

    Name | Description
    :age | The age parameter.

    ## Fields

    Name  | Type             | Description
    :name | String.t() | nil | The name of the user.
    :age  | age | nil        | The age of the user.
    """

    assert expected === doc
  end
end
