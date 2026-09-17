defmodule ObservatoryCore.Repo do
  use Ecto.Repo, otp_app: :observatory_core, adapter: Ecto.Adapters.Postgres
end
