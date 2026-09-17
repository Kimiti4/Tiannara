defmodule ReplayStore.Schema.Snapshot do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "snapshots" do
    field(:domain, :string)
    field(:data, :map)
    field(:checksum, :string)
    field(:timestamp, :utc_datetime_usec)
    timestamps(updated_at: false)
  end
end
