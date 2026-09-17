defmodule ReplayStore.Repo do
  use Ecto.Repo, otp_app: :replay_store, adapter: Ecto.Adapters.Postgres
end
