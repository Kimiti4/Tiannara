defmodule EventStore.Repo.Migrations.CreateEventsTable do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :source, :string, null: false
      add :version, :string, null: false
      add :timestamp, :utc_datetime_usec, null: false
      add :domain, :string, null: false
      add :payload, :map
      add :provenance, :map
      add :classification, :map
      add :lineage, :map
      add :certification, :map
      add :signature, :map
      add :replay_id, :binary_id
      add :retention, :string, default: "P90D"
      add :sequence_number, :bigint, auto_generated: true
      timestamps(updated_at: false)
    end

    create index(:events, [:domain])
    create index(:events, [:timestamp])
    create index(:events, [:domain, :timestamp])
  end
end
