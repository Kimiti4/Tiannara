defmodule Tiannara.Agency.Supervisor do
  @moduledoc """
  Supervisor for the Agency Foundation (Omega.A).

  Process tree:
    Agency.Supervisor
    |-- Agency.Orchestrator        (the glue)
    |-- Agency.ResearchDirector    (the investigator)
    |-- Agency.SentinelHeartbeat   (the pulse)

  Strategy: one_for_one -- each subsystem can fail and restart independently.
  The heartbeat's continuous cycle is what makes Tiannara alive.
  """
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :heartbeat_interval, 5_000)
    children = [
      {Tiannara.Agency.Orchestrator, []},
      {Tiannara.Agency.ResearchDirector, []},
      {Tiannara.Agency.SentinelHeartbeat, [interval_ms: interval]}
    ]

    Supervisor.init(children, strategy: :one_for_one,
                    max_restarts: 10, period: 60_000)
  end
end
