defmodule MetricsEngine.Schema.MetricWindow do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "metric_windows" do
    field(:name, :string)
    field(:window_ms, :integer)
    field(:mean, :float)
    field(:p50, :float)
    field(:p95, :float)
    field(:p99, :float)
    field(:max, :float)
    field(:min, :float)
    field(:count, :integer)
    field(:domain, :string)
    field(:window_start, :utc_datetime_usec)
    field(:window_end, :utc_datetime_usec)
    timestamps(updated_at: false)
  end
end
