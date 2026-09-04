defmodule Tiannara.ASC.Core.Supervisor do
  @moduledoc """
  Production ASC Core supervision topology.

  Child order (rest_for_one):
    1. Registry      — naming/discovery substrate; everyone depends on it
    2. Metrics       — phase/global health telemetry substrate
    3. Telemetry     — core telemetry substrate
    4. PubSub        — duplicate registry for the event bus (EventBus runs on it)
    5. KnowledgeStore— shared evidence/knowledge memory
    6. WorkerSupervisor — containment boundary for ASC workers
    7. Coordinator   — bootstraps required workers; re-runs on recovery

  A worker crash is contained inside WorkerSupervisor; registry continuity
  is a property of the topology (workers re-register in init).
  """

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Substrate — naming/discovery and health planes
      {Tiannara.ASC.Core.Registry, []},
      {Tiannara.ASC.Core.Metrics, []},
      {Tiannara.ASC.Core.Telemetry, []},

      # B2 layers — event plane, shared knowledge, worker containment
      {Registry, keys: :duplicate, name: Tiannara.ASC.Core.PubSub},
      Tiannara.ASC.Core.KnowledgeStore,
      {DynamicSupervisor,
       name: Tiannara.ASC.Core.WorkerSupervisor,
       strategy: :one_for_one,
       max_restarts: 3,
       max_seconds: 5},
      Tiannara.ASC.Core.Coordinator
    ]

    Supervisor.init(children, strategy: :rest_for_one, max_restarts: 10, max_seconds: 60)
  end
end
