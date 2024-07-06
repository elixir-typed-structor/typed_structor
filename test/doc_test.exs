defmodule DocTest do
  use TypedStructor.TestCase, async: true

  @tag :tmp_dir
  test "typedoc", ctx do
    generated_doc =
      with_tmpmodule User, ctx do
        use TypedStructor

        @typedoc "A user struct"
        typed_structor do
          field :name, String.t()
          field :age, integer()
        end
      after
        fetch_doc!(User, {:type, :t, 0})
      end

    assert "A user struct" === generated_doc
  end

  @tag :tmp_dir
  test "typedoc inside block", ctx do
    generated_doc =
      with_tmpmodule User, ctx do
        use TypedStructor

        typed_structor do
          @typedoc "A user struct"
          field :name, String.t()
          field :age, integer()
        end
      after
        fetch_doc!(User, {:type, :t, 0})
      end

    assert "A user struct" === generated_doc
  end

  @tag :tmp_dir
  test "moduledoc and typedoc inside submodule's block", ctx do
    generated_docs =
      with_tmpmodule MyModule, ctx do
        use TypedStructor

        typed_structor module: User do
          @moduledoc "A user module"
          @typedoc "A user struct"
          field :name, String.t()
          field :age, integer()
        end
      after
        {
          fetch_doc!(MyModule.User, :moduledoc),
          fetch_doc!(MyModule.User, {:type, :t, 0})
        }
        |> tap(fn _ ->
          cleanup_modules([MyModule.User], ctx.tmp_dir)
        end)
      end

    assert {"A user module", "A user struct"} === generated_docs
  end
end
