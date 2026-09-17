defmodule ReplayStore.Repo.Migrations.CreateReplayEvents do
  use Ecto.Migration

  def change do
    create table(:replay_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :replay_id, :binary_id
      add :event_id, :binary_id
      add :sequence, :integer
      add :reconstructed_state, :map
      timestamps(updated_at: false)
    end
  end
end
