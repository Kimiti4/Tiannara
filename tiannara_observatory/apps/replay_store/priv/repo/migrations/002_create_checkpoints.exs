defmodule ReplayStore.Repo.Migrations.CreateCheckpoints do
  use Ecto.Migration

  def change do
    create table(:checkpoints, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :domain, :string, null: false
      add :snapshot_id, :binary_id
      add :event_id, :binary_id
      add :timestamp, :utc_datetime_usec, null: false
      timestamps(updated_at: false)
    end
  end
end
