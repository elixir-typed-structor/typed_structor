defmodule TypeAndEnforceKeysTest do
  use TypedStructor.TypeCase, async: true

  test "default is set and enforce is true" do
    expected_bytecode =
      test_module do
        @type t() :: %TestModule{
                fixed: boolean()
              }

        defstruct [:fixed]
      end

    expected_types = types(expected_bytecode)

    bytecode =
      deftmpmodule do
        use TypedStructor

        typed_structor do
          field :fixed, boolean(), default: true, enforce: true
        end
      end

    assert expected_types === types(bytecode)

    assert match?(
             %{
               __struct__: TestModule,
               fixed: true
             },
             build_struct(quote(do: %TestModule{}))
           )
  end

  test "default is set and enforce is false" do
    expected_bytecode =
      test_module do
        @type t() :: %TestModule{
                fixed: boolean()
              }

        defstruct [:fixed]
      end

    expected_types = types(expected_bytecode)

    bytecode =
      deftmpmodule do
        use TypedStructor

        typed_structor do
          field :fixed, boolean(), default: true
        end
      end

    assert expected_types === types(bytecode)

    assert match?(
             %{
               __struct__: TestModule,
               fixed: true
             },
             build_struct(quote(do: %TestModule{}))
           )
  end

  test "default is unset and enforce is true" do
    expected_bytecode =
      test_module do
        @type t() :: %TestModule{
                fixed: boolean()
              }

        defstruct [:fixed]
      end

    expected_types = types(expected_bytecode)

    bytecode =
      deftmpmodule do
        use TypedStructor

        typed_structor do
          field :fixed, boolean(), enforce: true
        end
      end

    assert expected_types === types(bytecode)

    assert_raise_on_enforce_error([:fixed], quote(do: %TestModule{}))

    assert match?(
             %{
               __struct__: TestModule,
               fixed: true
             },
             build_struct(quote(do: %TestModule{fixed: true}))
           )
  end

  test "default is unset and enforce is false" do
    expected_bytecode =
      test_module do
        @type t() :: %TestModule{
                fixed: boolean() | nil
              }

        defstruct [:fixed]
      end

    expected_types = types(expected_bytecode)

    bytecode =
      deftmpmodule do
        use TypedStructor

        typed_structor do
          field :fixed, boolean()
        end
      end

    assert expected_types === types(bytecode)

    assert match?(
             %{
               __struct__: TestModule,
               fixed: nil
             },
             build_struct(quote(do: %TestModule{}))
           )
  end

  defp assert_raise_on_enforce_error(keys, quoted) do
    assert_raise ArgumentError,
                 "the following keys must also be given when building struct #{inspect(__MODULE__.TestModule)}: #{inspect(keys)}",
                 fn ->
                   Code.eval_quoted(quoted)
                 end
  end

  defp build_struct(quoted) do
    quoted |> Code.eval_quoted() |> elem(0)
  end
end
