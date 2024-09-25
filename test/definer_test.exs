defmodule DefinerTest do
  @compile {:no_warn_undefined, __MODULE__.Struct}
  @compile {:no_warn_undefined, __MODULE__.MyException}

  use TypedStructor.TestCase, async: true

  describe "defstruct" do
    @tag :tmp_dir
    test "works", ctx do
      expected_types =
        with_tmpmodule Struct, ctx do
          @type t() :: %__MODULE__{
                  age: integer() | nil,
                  name: String.t() | nil
                }

          defstruct [:age, :name]
        after
          fetch_types!(Struct)
        end

      generated_types =
        with_tmpmodule Struct, ctx do
          use TypedStructor

          typed_structor definer: :defstruct do
            field :name, String.t()
            field :age, integer()
          end
        after
          assert %{__struct__: Struct, name: nil, age: nil} === struct(Struct)

          fetch_types!(Struct)
        end

      assert_type expected_types, generated_types
    end

    @tag :tmp_dir
    test "define_struct false", ctx do
      deftmpmodule Struct, ctx do
        use TypedStructor

        typed_structor define_struct: false do
          parameter :age

          field :name, String.t()
          field :age, age
        end

        defstruct name: "Phil", age: 20
      end

      assert %{__struct__: Struct, name: "Phil", age: 20} === struct(Struct)
    after
      cleanup_modules([__MODULE__.Struct], ctx.tmp_dir)
    end

    @tag :tmp_dir
    test "works with Ecto.Schema", ctx do
      deftmpmodule Struct, ctx do
        use TypedStructor

        typed_structor define_struct: false do
          parameter :age

          field :name, String.t()
          field :age, age
        end

        use Ecto.Schema

        schema "source" do
          field :name, :string
          field :age, :integer, default: 20
        end
      end

      assert [:id, :name, :age] === Struct.__schema__(:fields)

      assert match?(%{__struct__: Struct, id: nil, name: nil, age: 20}, struct(Struct))
    after
      cleanup_modules([__MODULE__.Struct], ctx.tmp_dir)
    end
  end

  describe "defexception" do
    @tag :tmp_dir
    test "works", ctx do
      expected_types =
        with_tmpmodule MyException, ctx do
          @type t() :: %__MODULE__{
                  message: String.t() | nil
                }

          defexception [:message]
        after
          fetch_types!(MyException)
        end

      generated_types =
        with_tmpmodule MyException, ctx do
          use TypedStructor

          typed_structor definer: :defexception do
            field :message, String.t()
          end

          @impl Exception
          def exception(arguments) do
            %__MODULE__{message: Keyword.fetch!(arguments, :message)}
          end

          @impl Exception
          def message(%__MODULE__{message: message}) do
            message
          end
        after
          exception = MyException.exception(message: "this is an error")
          assert is_exception(exception)
          assert "this is an error" === Exception.message(exception)
          fetch_types!(MyException)
        end

      assert_type expected_types, generated_types
    end

    @tag :tmp_dir
    test "define_struct false", ctx do
      deftmpmodule MyException, ctx do
        use TypedStructor

        typed_structor define_struct: false do
          parameter :message

          field :message, message
        end

        defexception message: "error"
      end

      assert %{__struct__: MyException, __exception__: true, message: "error"} ===
               struct(MyException)
    after
      cleanup_modules([__MODULE__.MyException], ctx.tmp_dir)
    end
  end
end
