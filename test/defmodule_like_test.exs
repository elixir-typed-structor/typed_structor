defmodule DefmoduleLikeTest do
  use ExUnit.Case, async: true

  defmodule User do
    use TypedStructor

    typed_structor module: Profile, define_struct: false do
      @derive {Jason.Encoder, only: [:email]}
      field :email, String.t()

      use Ecto.Schema
      @primary_key false

      schema "users" do
        Ecto.Schema.field(:email, :string)
      end

      import Ecto.Changeset

      def changeset(%__MODULE__{} = user, attrs) do
        user
        |> cast(attrs, [:email])
        |> validate_required([:email])
      end
    end
  end

  test "works" do
    assert %User.Profile{} === struct(User.Profile)
    assert [:email] === User.Profile.__schema__(:fields)
  end

  test "functions works" do
    changset = User.Profile.changeset(%User.Profile{}, %{"email" => "my@email.com"})

    assert match?(
             %Ecto.Changeset{
               valid?: true,
               changes: %{email: "my@email.com"}
             },
             changset
           )
  end

  test "deriving works" do
    assert Jason.Encoder.DefmoduleLikeTest.User.Profile ===
             Jason.Encoder.impl_for(%User.Profile{})

    user = %User.Profile{email: "my@email.com"}
    assert ~s|{"email":"my@email.com"}| === Jason.encode!(user)
  end
end
