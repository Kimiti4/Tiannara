defmodule ReplayStore.Repo.Migrations.CreateSnapshots do
  use Ecto.Migration

  def change do
    create table(:snapshots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :domain, :string, null: false
      add :data, :map
      add :checksum, :string
      add :timestamp, :utc_datetime_usec, null: false
      timestamps(updated_at: false)
    end
    create index(:snapshots, [:domain])
  end
end
