defmodule DefinerTest do
  @compile {:no_warn_undefined, __MODULE__.Struct}
  @compile {:no_warn_undefined, __MODULE__.MyException}
  @compile {:no_warn_undefined, __MODULE__.MyRecord}

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

  describe "defrecord" do
    @tag :tmp_dir
    test "works", ctx do
      expected_types =
        with_tmpmodule MyRecord, ctx do
          import Record

          @type t(age) :: {
                  :user,
                  name :: String.t() | nil,
                  age :: age | nil
                }

          defrecord(:user, name: nil, age: nil)
        after
          fetch_types!(MyRecord)
        end

      generated_types =
        with_tmpmodule MyRecord, ctx do
          use TypedStructor

          typed_structor definer: :defrecord, record_name: :user do
            parameter :age

            field :name, String.t()
            field :age, age
          end
        after
          assert [user: 0, user: 1, user: 2] === MyRecord.__info__(:macros)

          assert {:user, "Phil", 20} ===
                   eval(
                     quote do
                       require MyRecord
                       MyRecord.user(name: "Phil", age: 20)
                     end
                   )

          fetch_types!(MyRecord)
        end

      assert_type expected_types, generated_types
    end

    @tag :tmp_dir
    test "missing record_name", ctx do
      assert_raise ArgumentError,
                   ~r/Please provide the `:record_name` option when using the `defrecord` or `defrecordp` definer/,
                   fn ->
                     defmodule MyRecord do
                       use TypedStructor

                       typed_structor definer: :defrecord do
                         field :name, String.t()
                         field :age, pos_integer()
                       end
                     end
                   end
    end

    @tag :tmp_dir
    test "with record_tag", ctx do
      expected_types =
        with_tmpmodule MyRecord, ctx do
          import Record

          @type t() :: {
                  User,
                  name :: String.t() | nil,
                  age :: pos_integer() | nil
                }

          defrecord(:user, name: nil, age: nil)
        after
          fetch_types!(MyRecord)
        end

      generated_types =
        with_tmpmodule MyRecord, ctx do
          use TypedStructor

          typed_structor definer: :defrecord, record_name: :user, record_tag: User do
            field :name, String.t()
            field :age, pos_integer()
          end
        after
          assert [user: 0, user: 1, user: 2] === MyRecord.__info__(:macros)

          assert {User, "Phil", 20} ===
                   eval(
                     quote do
                       require MyRecord
                       MyRecord.user(name: "Phil", age: 20)
                     end
                   )

          fetch_types!(MyRecord)
        end

      assert_type expected_types, generated_types
    end

    @tag :tmp_dir
    test "define_record false", ctx do
      deftmpmodule MyRecord, ctx do
        import Record

        use TypedStructor

        typed_structor definer: :defrecord, define_record: false, record_name: :user do
          parameter :age

          field :name, String.t()
          field :age, age
        end

        defrecord(:user, name: "Phil", age: 20)
      end

      assert [user: 0, user: 1, user: 2] === MyRecord.__info__(:macros)

      assert {:user, "Phil", 20} ===
               eval(
                 quote do
                   require MyRecord
                   MyRecord.user(name: "Phil", age: 20)
                 end
               )
    after
      cleanup_modules([__MODULE__.MyRecord], ctx.tmp_dir)
    end
  end

  defp eval(quoted) do
    quoted |> Code.eval_quoted() |> elem(0)
  end
end
