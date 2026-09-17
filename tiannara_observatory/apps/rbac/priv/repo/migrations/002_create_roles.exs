defmodule Rbac.Repo.Migrations.CreateRoleAssignments do
  use Ecto.Migration

  def change do
    create table(:role_assignments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, :binary_id, null: false
      add :role, :string, null: false
      add :assigned_by, :binary_id
      add :active, :boolean, default: true
      timestamps()
    end
  end
end
