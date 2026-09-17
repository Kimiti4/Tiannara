defmodule Rbac.Repo.Migrations.CreateAuditEntries do
  use Ecto.Migration

  def change do
    create table(:audit_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :action, :string, null: false
      add :operator_id, :binary_id, null: false
      add :resource, :string, null: false
      add :details, :map
      timestamps(updated_at: false)
    end
  end
end
