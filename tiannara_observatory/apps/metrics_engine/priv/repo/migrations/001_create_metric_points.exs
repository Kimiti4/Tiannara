defmodule MetricsEngine.Repo.Migrations.CreateMetricPoints do
  use Ecto.Migration

  def change do
    create table(:metric_points, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :value, :float, null: false
      add :unit, :string
      add :domain, :string
      add :timestamp, :utc_datetime_usec, null: false
      add :metadata, :map
      timestamps(updated_at: false)
    end
    create index(:metric_points, [:name])
    create index(:metric_points, [:domain])
    create index(:metric_points, [:name, :timestamp])
  end
end
