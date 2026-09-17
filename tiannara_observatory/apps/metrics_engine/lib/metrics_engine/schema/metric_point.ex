defmodule MetricsEngine.Schema.MetricPoint do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "metric_points" do
    field(:name, :string)
    field(:value, :float)
    field(:unit, :string)
    field(:domain, :string)
    field(:timestamp, :utc_datetime_usec)
    field(:metadata, :map)
    timestamps(updated_at: false)
  end
end
