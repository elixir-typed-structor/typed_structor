defmodule DefinerTest do
  @compile {:no_warn_undefined, __MODULE__.Struct}

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
end
