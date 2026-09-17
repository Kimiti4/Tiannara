defmodule ReplayStore.Schema.Checkpoint do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "checkpoints" do
    field(:domain, :string)
    field(:snapshot_id, :binary_id)
    field(:event_id, :binary_id)
    field(:timestamp, :utc_datetime_usec)
    timestamps(updated_at: false)
  end
end
