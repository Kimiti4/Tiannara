defmodule ObservatoryApi.Repo do
  use Ecto.Repo,
    otp_app: :observatory_api,
    adapter: Ecto.Adapters.Postgres
end
