defmodule MetricsEngine.Repo.Migrations.CreateMetricWindows do
  use Ecto.Migration

  def change do
    create table(:metric_windows, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :window_ms, :integer, null: false
      add :mean, :float
      add :p50, :float
      add :p95, :float
      add :p99, :float
      add :max, :float
      add :min, :float
      add :count, :integer
      add :domain, :string
      add :window_start, :utc_datetime_usec, null: false
      add :window_end, :utc_datetime_usec, null: false
      timestamps(updated_at: false)
    end
    create index(:metric_windows, [:name, :window_start])
  end
end
