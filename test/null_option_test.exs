defmodule TypedStructor.NullOptionTest do
  use TypedStructor.TestCase, async: true

  describe "field-level null option" do
    @tag :tmp_dir
    test "null: false prevents nil from being added to type", ctx do
      expected_types =
        with_tmpmodule TestStruct, ctx do
          @type t() :: %__MODULE__{
                  id: integer(),
                  name: String.t() | nil,
                  status: String.t(),
                  email: String.t(),
                  description: String.t() | nil,
                  code: String.t()
                }
          defstruct id: nil, name: nil, status: "active", email: nil, description: nil, code: nil
        after
          fetch_types!(TestStruct)
        end

      generated_types =
        with_tmpmodule TestStruct, ctx do
          use TypedStructor

          typed_structor do
            field :id, integer(), null: false
            field :name, String.t(), null: true
            field :status, String.t(), default: "active", null: true
            field :email, String.t(), enforce: true, null: true
            field :description, String.t()
            field :code, String.t(), enforce: false, null: false
          end
        after
          fetch_types!(TestStruct)
        end

      assert_type expected_types, generated_types
    end

    @tag :tmp_dir
    test "struct fields default to nil regardless of null option", ctx do
      with_tmpmodule TestStruct, ctx do
        use TypedStructor

        typed_structor do
          field :id, integer(), null: false
          field :name, String.t()
          field :email, String.t(), enforce: true
        end
      after
        # Struct fields can be nil at runtime regardless of null option in the type spec
        struct = struct(TestStruct, email: "test@example.com")
        assert struct.id == nil
        assert struct.name == nil
        assert struct.email == "test@example.com"
      end
    end
  end

  describe "module-level null option" do
    @tag :tmp_dir
    test "module-level null: false applies to all fields without explicit null", ctx do
      expected_types =
        with_tmpmodule ModuleLevelNull, ctx do
          @type t() :: %__MODULE__{
                  id: integer(),
                  name: String.t() | nil,
                  status: String.t(),
                  email: String.t(),
                  code: String.t()
                }
          defstruct id: nil, name: nil, status: "active", email: nil, code: nil
        after
          fetch_types!(ModuleLevelNull)
        end

      generated_types =
        with_tmpmodule ModuleLevelNull, ctx do
          use TypedStructor

          typed_structor null: false do
            field :id, integer()
            field :name, String.t(), null: true
            field :status, String.t(), default: "active"
            field :email, String.t(), enforce: true
            field :code, String.t()
          end
        after
          fetch_types!(ModuleLevelNull)
        end

      assert_type expected_types, generated_types
    end
  end

  describe "database loading use case" do
    @tag :tmp_dir
    test "non-nullable fields for required database columns", ctx do
      expected_types =
        with_tmpmodule DatabaseLoadingExample, ctx do
          @type t() :: %__MODULE__{
                  id: integer(),
                  name: String.t() | nil,
                  email: String.t() | nil,
                  phone: String.t() | nil,
                  inserted_at: DateTime.t(),
                  updated_at: DateTime.t(),
                  preferences: map() | nil,
                  metadata: map() | nil
                }
          defstruct [
            :id,
            :name,
            :email,
            :phone,
            :inserted_at,
            :updated_at,
            :preferences,
            :metadata
          ]
        after
          fetch_types!(DatabaseLoadingExample)
        end

      generated_types =
        with_tmpmodule DatabaseLoadingExample, ctx do
          use TypedStructor

          typed_structor do
            field :id, integer(), null: false
            field :name, String.t()
            field :email, String.t()
            field :phone, String.t()
            field :inserted_at, DateTime.t(), null: false
            field :updated_at, DateTime.t(), null: false
            field :preferences, map()
            field :metadata, map()
          end
        after
          fetch_types!(DatabaseLoadingExample)
        end

      assert_type expected_types, generated_types
    end
  end

  describe "interaction with other options" do
    @tag :tmp_dir
    test "default and enforce take precedence over null option", ctx do
      expected_types =
        with_tmpmodule InteractionTest, ctx do
          @type t() :: %__MODULE__{
                  status: String.t(),
                  email: String.t(),
                  code: String.t()
                }
          defstruct status: "active", email: nil, code: nil
        after
          fetch_types!(InteractionTest)
        end

      generated_types =
        with_tmpmodule InteractionTest, ctx do
          use TypedStructor

          typed_structor do
            # default takes precedence over null
            field :status, String.t(), default: "active", null: true
            # enforce takes precedence over null
            field :email, String.t(), enforce: true, null: true
            # enforce: false with null: false
            field :code, String.t(), enforce: false, null: false
          end
        after
          fetch_types!(InteractionTest)
        end

      assert_type expected_types, generated_types
    end
  end
end
