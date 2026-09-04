defmodule Tiannara.Executive.Supervisor do
  @moduledoc """
  Supervisor for the Executive Memory subsystem.

  Orchestrates the following child processes:
  - Tiannara.Executive.EventStore
  - Tiannara.Executive.EventBus
  - Tiannara.Executive.ExecutiveMemory
  - Tiannara.Executive.Coordinator

  Strategy: `:one_for_one` with `:permanent` restarts (max 10 in 60s).
  Shutdown is ordered: EventBus → Coordinator → ExecutiveMemory → EventStore.
  """

  use Supervisor

  require Logger

  @doc "Starts the Executive Memory supervisor."
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    Logger.info("[ExecutiveMemory.Supervisor] Starting Executive Memory subsystem")

    event_store_opts = Keyword.get(opts, :event_store_opts, [])
    memory_opts = Keyword.get(opts, :memory_opts, [])
    event_bus_opts = Keyword.get(opts, :event_bus_opts, [])
    coordinator_opts = Keyword.get(opts, :coordinator_opts, [])

    children = [
      # EventStore first — used by others
      {Tiannara.Executive.EventStore, event_store_opts ++ [[name: Tiannara.Executive.EventStore]]},

      # EventBus — pub/sub dispatch
      {Tiannara.Executive.EventBus, event_bus_opts ++ [[name: Tiannara.Executive.EventBus]]},

      # ExecutiveMemory — core GenServer
      {Tiannara.Executive.ExecutiveMemory, memory_opts ++ [[name: Tiannara.Executive.ExecutiveMemory]]},

      # Coordinator — command execution
      {Tiannara.Executive.Coordinator, coordinator_opts ++ [[name: Tiannara.Executive.Coordinator]]},
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 10, max_seconds: 60)
  end
end
