defmodule ReplayStore.Schema.ReplayEvent do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "replay_events" do
    field(:replay_id, :binary_id)
    field(:event_id, :binary_id)
    field(:sequence, :integer)
    field(:reconstructed_state, :map)
    timestamps(updated_at: false)
  end
end
