defmodule TypeAndEnforceKeysTest do
  use TypedStructor.TestCase, async: true

  @tag :tmp_dir
  test "default is set and enforce is true", ctx do
    expected_types =
      with_tmpmodule Struct, ctx do
        @type t() :: %__MODULE__{
                fixed: boolean()
              }

        defstruct [:fixed]
      after
        fetch_types!(Struct)
      end

    generated_types =
      with_tmpmodule Struct, ctx do
        use TypedStructor

        typed_structor do
          field :fixed, boolean(), default: true, enforce: true
        end
      after
        assert %{__struct__: Struct, fixed: true} === build_struct(quote(do: %Struct{}))

        fetch_types!(Struct)
      end

    assert_type expected_types, generated_types
  end

  @tag :tmp_dir
  test "default is set and enforce is false", ctx do
    expected_types =
      with_tmpmodule Struct, ctx do
        @type t() :: %__MODULE__{
                fixed: boolean()
              }

        defstruct [:fixed]
      after
        fetch_types!(Struct)
      end

    generated_types =
      with_tmpmodule Struct, ctx do
        use TypedStructor

        typed_structor do
          field :fixed, boolean(), default: true
        end
      after
        assert %{__struct__: Struct, fixed: true} === build_struct(quote(do: %Struct{}))

        fetch_types!(Struct)
      end

    assert_type expected_types, generated_types
  end

  @tag :tmp_dir
  test "default is unset and enforce is true", ctx do
    expected_types =
      with_tmpmodule Struct, ctx do
        @type t() :: %__MODULE__{
                fixed: boolean()
              }

        defstruct [:fixed]
      after
        fetch_types!(Struct)
      end

    generated_types =
      with_tmpmodule Struct, ctx do
        use TypedStructor

        typed_structor do
          field :fixed, boolean(), enforce: true
        end
      after
        assert_raise_on_enforce_error([:fixed], quote(do: %Struct{}))

        assert %{__struct__: Struct, fixed: true} ===
                 build_struct(quote(do: %Struct{fixed: true}))

        fetch_types!(Struct)
      end

    assert_type expected_types, generated_types
  end

  @tag :tmp_dir
  test "default is unset and enforce is false", ctx do
    expected_types =
      with_tmpmodule Struct, ctx do
        @type t() :: %__MODULE__{
                fixed: boolean() | nil
              }

        defstruct [:fixed]
      after
        fetch_types!(Struct)
      end

    generated_types =
      with_tmpmodule Struct, ctx do
        use TypedStructor

        typed_structor do
          field :fixed, boolean()
        end
      after
        assert %{__struct__: Struct, fixed: nil} === build_struct(quote(do: %Struct{}))

        fetch_types!(Struct)
      end

    assert_type expected_types, generated_types
  end

  defp assert_raise_on_enforce_error(keys, quoted) do
    assert_raise ArgumentError,
                 "the following keys must also be given when building struct #{inspect(__MODULE__.Struct)}: #{inspect(keys)}",
                 fn ->
                   Code.eval_quoted(quoted)
                 end
  end

  defp build_struct(quoted) do
    quoted |> Code.eval_quoted() |> elem(0)
  end
end
