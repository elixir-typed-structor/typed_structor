defmodule TypedStructorTest do
  use TypedStructor.TypeCase, async: true

  test "generates the struct and the type" do
    expected_bytecode =
      test_module do
        @type t() :: %TestModule{
                age: integer() | nil,
                name: String.t() | nil
              }

        defstruct [:age, :name]
      end

    expected_types = types(expected_bytecode)

    bytecode =
      deftmpmodule do
        use TypedStructor

        typed_structor do
          field :name, String.t()
          field :age, integer()
        end
      end

    assert match?(
             %{
               __struct__: TestModule,
               name: nil,
               age: nil
             },
             struct(TestModule)
           )

    assert expected_types === types(bytecode)
  end

  describe "module option" do
    test "generates the struct and the type" do
      expected_bytecode =
        test_module do
          defmodule Struct do
            @type t() :: %TestModule.Struct{
                    age: integer() | nil,
                    name: String.t() | nil
                  }
            defstruct [:age, :name]
          end
        end

      expected_types = types(expected_bytecode)

      bytecode =
        deftmpmodule do
          use TypedStructor

          typed_structor module: Struct do
            field :name, String.t()
            field :age, integer()
          end
        end

      assert match?(
               %{
                 __struct__: TestModule.Struct,
                 name: nil,
                 age: nil
               },
               struct(TestModule.Struct)
             )

      assert expected_types === types(bytecode)
    end
  end

  describe "enforce option" do
    test "set enforce on fields" do
      expected_bytecode =
        test_module do
          @type t() :: %TestModule{
                  name: String.t(),
                  age: integer() | nil
                }

          defstruct [:age, :name]
        end

      expected_types = types(expected_bytecode)

      bytecode =
        deftmpmodule do
          use TypedStructor

          typed_structor do
            field :name, String.t(), enforce: true
            field :age, integer()
          end
        end

      assert_raise_on_enforce_error(TestModule, [:name], fn ->
        Code.eval_quoted(quote do: %TestModule{})
      end)

      assert expected_types === types(bytecode)
    end

    test "set enforce on typed_structor" do
      expected_bytecode =
        test_module do
          @type t() :: %TestModule{
                  name: String.t(),
                  age: integer()
                }

          defstruct [:age, :name]
        end

      expected_types = types(expected_bytecode)

      bytecode =
        deftmpmodule do
          use TypedStructor

          typed_structor enforce: true do
            field :name, String.t()
            field :age, integer()
          end
        end

      assert_raise_on_enforce_error(TestModule, [:name, :age], fn ->
        Code.eval_quoted(quote do: %TestModule{})
      end)

      assert expected_types === types(bytecode)
    end

    test "overwrites the enforce option on fields" do
      expected_bytecode =
        test_module do
          @type t() :: %TestModule{
                  name: String.t(),
                  age: integer() | nil
                }

          defstruct [:age, :name]
        end

      expected_types = types(expected_bytecode)

      bytecode =
        deftmpmodule do
          use TypedStructor

          typed_structor enforce: true do
            field :name, String.t()
            field :age, integer(), enforce: false
          end

          def enforce_keys, do: @enforce_keys
        end

      assert_raise_on_enforce_error(TestModule, [:name], fn ->
        Code.eval_quoted(quote do: %TestModule{})
      end)

      assert [:name] === TestModule.enforce_keys()

      assert expected_types === types(bytecode)
    end
  end

  describe "type_kind option" do
    test "generates opaque type" do
      expected_bytecode =
        test_module do
          @opaque t() :: %TestModule{
                    name: String.t() | nil,
                    age: integer() | nil
                  }

          defstruct [:age, :name]
        end

      expected_types = types(expected_bytecode)

      bytecode =
        deftmpmodule do
          use TypedStructor

          typed_structor type_kind: :opaque do
            field :name, String.t()
            field :age, integer()
          end
        end

      assert expected_types === types(bytecode)
    end

    test "generates typep type" do
      expected_bytecode =
        test_module do
          # suppress unused warning
          @type external_t() :: t()

          @typep t() :: %TestModule{
                   name: String.t() | nil,
                   age: integer() | nil
                 }

          defstruct [:age, :name]
        end

      expected_types = types(expected_bytecode)

      bytecode =
        deftmpmodule do
          use TypedStructor

          # suppress unused warning
          @type external_t() :: t()

          typed_structor type_kind: :typep do
            field :name, String.t()
            field :age, integer()
          end
        end

      assert expected_types === types(bytecode)
    end
  end

  describe "type_name option" do
    test "generates custom type_name type" do
      expected_bytecode =
        test_module do
          @type test_type() :: %TestModule{
                  name: String.t() | nil,
                  age: integer() | nil
                }

          defstruct [:age, :name]
        end

      expected_types = types(expected_bytecode)

      bytecode =
        deftmpmodule do
          use TypedStructor

          typed_structor type_name: :test_type do
            field :name, String.t()
            field :age, integer()
          end
        end

      assert expected_types === types(bytecode)
    end
  end

  describe "default option on the field" do
    test "generates struct with default values" do
      expected_bytecode =
        test_module do
          @type t() :: %TestModule{
                  name: String.t(),
                  age: integer() | nil
                }

          defstruct [:age, :name]
        end

      expected_types = types(expected_bytecode)

      bytecode =
        deftmpmodule do
          use TypedStructor

          typed_structor do
            field :name, String.t(), default: "Phil"
            field :age, integer()
          end

          def enforce_keys, do: @enforce_keys
        end

      assert match?(
               %{
                 __struct__: TestModule,
                 name: "Phil",
                 age: nil
               },
               struct(TestModule)
             )

      assert [] === TestModule.enforce_keys()

      assert expected_types === types(bytecode)
    end
  end

  describe "parameter" do
    test "generates parameterized type" do
      expected_bytecode =
        test_module do
          @type t(age) :: %TestModule{
                  age: age | nil,
                  name: String.t() | nil
                }

          defstruct [:age, :name]
        end

      expected_types = types(expected_bytecode)

      bytecode =
        deftmpmodule do
          use TypedStructor

          typed_structor do
            parameter :age

            field :name, String.t()
            field :age, age
          end
        end

      assert match?(
               %{
                 __struct__: TestModule,
                 name: nil,
                 age: nil
               },
               struct(TestModule)
             )

      assert expected_types === types(bytecode)
    end

    test "generates ordered parameters for the type" do
      expected_bytecode =
        test_module do
          @type t(age, name) :: %TestModule{
                  age: age | nil,
                  name: name | nil
                }

          defstruct [:name, :age]
        end

      expected_types = types(expected_bytecode)

      bytecode =
        deftmpmodule do
          use TypedStructor

          typed_structor do
            parameter :age
            parameter :name

            field :name, name
            field :age, age
          end
        end

      assert match?(
               %{
                 __struct__: TestModule,
                 name: nil,
                 age: nil
               },
               struct(TestModule)
             )

      assert expected_types === types(bytecode)
    end
  end

  describe "define_struct option" do
    test "implements Access" do
      deftmpmodule do
        use TypedStructor

        typed_structor define_struct: false do
          parameter :age

          field :name, String.t()
          field :age, age
        end

        defstruct name: "Phil", age: 20
      end

      assert match?(
               %{
                 __struct__: TestModule,
                 name: "Phil",
                 age: 20
               },
               struct(TestModule)
             )
    end
  end

  describe "works with Ecto.Schema" do
    test "works" do
      deftmpmodule do
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

      assert [:id, :name, :age] === TestModule.__schema__(:fields)

      assert match?(
               %{
                 __struct__: TestModule,
                 name: nil,
                 age: 20
               },
               struct(TestModule)
             )
    end
  end

  defp assert_raise_on_enforce_error(module, keys, fun) do
    assert_raise ArgumentError,
                 "the following keys must also be given when building struct #{inspect(module)}: #{inspect(keys)}",
                 fn ->
                   fun.()
                 end
  end
end
