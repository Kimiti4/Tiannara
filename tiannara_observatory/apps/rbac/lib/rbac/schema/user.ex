defmodule Rbac.Schema.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "users" do
    field(:email, :string)
    field(:name, :string)

    field(:role, Ecto.Enum,
      values: [:observer, :engineer, :scientist, :governor, :auditor, :administrator, :system]
    )

    field(:active, :boolean, default: true)
    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :role, :active])
    |> validate_required([:email, :name, :role])
    |> unique_constraint(:email)
  end
end
