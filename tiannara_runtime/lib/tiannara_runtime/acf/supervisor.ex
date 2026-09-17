defmodule TiannaraRuntime.ACF.Supervisor do
  @moduledoc """
  OTP supervisor for the Axiomatic Conservation Framework.

  Currently it starts a single GenServer that could hold runtime state
  (e.g., audit statistics, global counters). The implementation is a
  placeholder but provides a proper supervision tree for future
  extensions.
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {TiannaraRuntime.ACF.StatsTracker, []}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
