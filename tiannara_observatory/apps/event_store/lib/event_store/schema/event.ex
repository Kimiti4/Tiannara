defmodule EventStore.Schema.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "events" do
    field(:source, :string)
    field(:version, :string)
    field(:timestamp, :utc_datetime_usec)
    field(:domain, :string)
    field(:payload, :map)
    field(:provenance, :map)
    field(:classification, :map)
    field(:lineage, :map)
    field(:certification, :map)
    field(:signature, :map)
    field(:replay_id, :binary_id)
    field(:retention, :string, default: "P90D")

    timestamps(updated_at: false)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :source,
      :version,
      :timestamp,
      :domain,
      :payload,
      :provenance,
      :classification,
      :lineage,
      :certification,
      :signature,
      :replay_id,
      :retention
    ])
    |> validate_required([:source, :version, :timestamp, :domain])
  end
end
