defmodule Rbac.Schema.RoleAssignment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "role_assignments" do
    field(:user_id, :binary_id)

    field(:role, Ecto.Enum,
      values: [:observer, :engineer, :scientist, :governor, :auditor, :administrator, :system]
    )

    field(:assigned_by, :binary_id)
    field(:active, :boolean, default: true)
    timestamps()
  end

  def changeset(ra, attrs) do
    ra
    |> cast(attrs, [:user_id, :role, :assigned_by, :active])
    |> validate_required([:user_id, :role])
  end
end
