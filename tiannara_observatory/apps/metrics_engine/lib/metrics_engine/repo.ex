defmodule MetricsEngine.Repo do
  use Ecto.Repo, otp_app: :metrics_engine, adapter: Ecto.Adapters.Postgres
end
