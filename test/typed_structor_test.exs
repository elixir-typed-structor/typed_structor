defmodule TypedStructorTest do
  @compile {:no_warn_undefined, __MODULE__.Struct}

  use TypedStructor.TestCase, async: true

  @tag :tmp_dir
  test "generates the struct and the type", ctx do
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

        typed_structor do
          field :name, String.t()
          field :age, integer()
        end
      after
        assert %{__struct__: Struct, name: nil, age: nil} === struct(Struct)

        fetch_types!(Struct)
      end

    assert_type expected_types, generated_types
  end

  describe "module option" do
    @tag :tmp_dir
    test "generates the struct and the type", ctx do
      expected_types =
        with_tmpmodule MyModule, ctx do
          defmodule Struct do
            @type t() :: %__MODULE__{
                    age: integer() | nil,
                    name: String.t() | nil
                  }
            defstruct [:age, :name]
          end
        after
          fetch_types!(MyModule.Struct)
        end

      cleanup_modules([__MODULE__.MyModule.Struct], ctx.tmp_dir)

      generated_types =
        with_tmpmodule MyModule, ctx do
          use TypedStructor

          typed_structor module: Struct do
            field :name, String.t()
            field :age, integer()
          end
        after
          assert %{__struct__: MyModule.Struct, name: nil, age: nil} ===
                   struct(MyModule.Struct)

          fetch_types!(MyModule.Struct)
        end

      cleanup_modules([__MODULE__.MyModule.Struct], ctx.tmp_dir)

      assert_type expected_types, generated_types
    end
  end

  describe "enforce option" do
    @tag :tmp_dir
    test "set enforce on fields", ctx do
      expected_types =
        with_tmpmodule Struct, ctx do
          @type t() :: %__MODULE__{
                  name: String.t(),
                  age: integer() | nil
                }

          defstruct [:age, :name]
        after
          fetch_types!(Struct)
        end

      generated_types =
        with_tmpmodule Struct, ctx do
          use TypedStructor

          typed_structor do
            field :name, String.t(), enforce: true
            field :age, integer()
          end
        after
          assert_raise_on_enforce_error(Struct, [:name], quote(do: %Struct{}))

          fetch_types!(Struct)
        end

      assert_type expected_types, generated_types
    end

    @tag :tmp_dir
    test "set enforce on typed_structor", ctx do
      expected_types =
        with_tmpmodule Struct, ctx do
          @type t() :: %__MODULE__{
                  name: String.t(),
                  age: integer()
                }

          defstruct [:age, :name]
        after
          fetch_types!(Struct)
        end

      generated_types =
        with_tmpmodule Struct, ctx do
          use TypedStructor

          typed_structor enforce: true do
            field :name, String.t()
            field :age, integer()
          end
        after
          assert_raise_on_enforce_error(
            Struct,
            [:name, :age],
            quote(do: %Struct{})
          )

          fetch_types!(Struct)
        end

      assert_type expected_types, generated_types
    end

    @tag :tmp_dir
    test "overwrites the enforce option on fields", ctx do
      expected_types =
        with_tmpmodule Struct, ctx do
          @type t() :: %__MODULE__{
                  name: String.t(),
                  age: integer() | nil
                }

          defstruct [:age, :name]
        after
          fetch_types!(Struct)
        end

      generated_types =
        with_tmpmodule Struct, ctx do
          use TypedStructor

          typed_structor enforce: true do
            field :name, String.t()
            field :age, integer(), enforce: false
          end

          def enforce_keys, do: @enforce_keys
        after
          assert_raise_on_enforce_error(Struct, [:name], quote(do: %Struct{}))

          assert [:name] === Struct.enforce_keys()

          fetch_types!(Struct)
        end

      assert expected_types, generated_types
    end
  end

  describe "type_kind option" do
    @tag :tmp_dir
    test "generates opaque type", ctx do
      expected_types =
        with_tmpmodule Struct, ctx do
          @opaque t() :: %__MODULE__{
                    name: String.t() | nil,
                    age: integer() | nil
                  }

          defstruct [:age, :name]
        after
          fetch_types!(Struct)
        end

      generated_types =
        with_tmpmodule Struct, ctx do
          use TypedStructor

          typed_structor type_kind: :opaque do
            field :name, String.t()
            field :age, integer()
          end
        after
          fetch_types!(Struct)
        end

      assert_type expected_types, generated_types
    end

    @tag :tmp_dir
    test "generates typep type", ctx do
      expected_types =
        with_tmpmodule Struct, ctx do
          # suppress unused warning
          @type external_t() :: t()

          @typep t() :: %__MODULE__{
                   name: String.t() | nil,
                   age: integer() | nil
                 }

          defstruct [:age, :name]
        after
          fetch_types!(Struct)
        end

      generated_types =
        with_tmpmodule Struct, ctx do
          use TypedStructor

          # suppress unused warning
          @type external_t() :: t()

          typed_structor type_kind: :typep do
            field :name, String.t()
            field :age, integer()
          end
        after
          fetch_types!(Struct)
        end

      assert_type expected_types, generated_types
    end
  end

  describe "type_name option" do
    @tag :tmp_dir
    test "generates custom type_name type", ctx do
      expected_types =
        with_tmpmodule Struct, ctx do
          @type test_type() :: %__MODULE__{
                  name: String.t() | nil,
                  age: integer() | nil
                }

          defstruct [:age, :name]
        after
          fetch_types!(Struct)
        end

      generated_types =
        with_tmpmodule Struct, ctx do
          use TypedStructor

          typed_structor type_name: :test_type do
            field :name, String.t()
            field :age, integer()
          end
        after
          fetch_types!(Struct)
        end

      assert_type expected_types, generated_types
    end
  end

  describe "default option on the field" do
    @tag :tmp_dir
    test "generates struct with default values", ctx do
      expected_types =
        with_tmpmodule Struct, ctx do
          @type t() :: %__MODULE__{
                  name: String.t(),
                  age: integer() | nil
                }

          defstruct [:age, :name]
        after
          fetch_types!(Struct)
        end

      generated_types =
        with_tmpmodule Struct, ctx do
          use TypedStructor

          typed_structor do
            field :name, String.t(), default: "Phil"
            field :age, integer()
          end

          def enforce_keys, do: @enforce_keys
        after
          assert %{__struct__: Struct, name: "Phil", age: nil} === struct(Struct)

          assert [] === Struct.enforce_keys()

          fetch_types!(Struct)
        end

      assert_type expected_types, generated_types
    end
  end

  describe "parameter" do
    @tag :tmp_dir
    test "generates parameterized type", ctx do
      expected_types =
        with_tmpmodule Struct, ctx do
          @type t(age) :: %__MODULE__{
                  age: age | nil,
                  name: String.t() | nil
                }

          defstruct [:age, :name]
        after
          fetch_types!(Struct)
        end

      generated_types =
        with_tmpmodule Struct, ctx do
          use TypedStructor

          typed_structor do
            parameter :age

            field :name, String.t()
            field :age, age
          end
        after
          assert %{__struct__: Struct, name: nil, age: nil} === struct(Struct)

          fetch_types!(Struct)
        end

      assert_type expected_types, generated_types
    end

    @tag :tmp_dir
    test "generates ordered parameters for the type", ctx do
      expected_types =
        with_tmpmodule Struct, ctx do
          @type t(age, name) :: %__MODULE__{
                  age: age | nil,
                  name: name | nil
                }

          defstruct [:name, :age]
        after
          fetch_types!(Struct)
        end

      generated_types =
        with_tmpmodule Struct, ctx do
          use TypedStructor

          typed_structor do
            parameter :age
            parameter :name

            field :name, name
            field :age, age
          end
        after
          assert %{__struct__: Struct, name: nil, age: nil} === struct(Struct)

          fetch_types!(Struct)
        end

      assert_type expected_types, generated_types
    end

    test "raises an error when the parameter is not a atom" do
      assert_raise ArgumentError,
                   ~r|name must be an atom and opts must be a list|,
                   fn ->
                     defmodule Struct do
                       use TypedStructor

                       typed_structor do
                         parameter "age"
                       end
                     end
                   end
    end
  end

  describe "define_struct option" do
    @tag :tmp_dir
    test "implements Access", ctx do
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
  end

  describe "works with Ecto.Schema" do
    @tag :tmp_dir
    test "works", ctx do
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

  defp assert_raise_on_enforce_error(module, keys, quoted) do
    assert_raise ArgumentError,
                 "the following keys must also be given when building struct #{inspect(module)}: #{inspect(keys)}",
                 fn ->
                   Code.eval_quoted(quoted)
                 end
  end
end
