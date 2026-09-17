defmodule ObservationBus.Supervisor do
  @moduledoc """
  Top-level supervisor for the Constitutional Observation Bus.

  Starts all COB subsystems in dependency order:
    1. Registries (topic + subscription)
    2. Buffer
    3. Engines (priority, ordering, lineage)
    4. Scheduler
    5. Garbage collector
  """
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Registries — foundational, no deps
      ObservationBus.TopicRegistry,
      ObservationBus.SubscriptionRegistry,

      # Buffer — holds pending events
      ObservationBus.Buffer,

      # Engines — depend on registries
      ObservationBus.PriorityEngine,
      ObservationBus.OrderingEngine,
      ObservationBus.LineageEngine,

      # Scheduler — manages event class scheduling
      ObservationBus.Scheduler,

      # Garbage collector — periodic cleanup
      ObservationBus.GarbageCollector,

      # Subscribers — COB → downstream apps
      ObservationBus.Subscriber.EventStore,
      ObservationBus.Subscriber.MetricsEngine,
      ObservationBus.Subscriber.ReplayStore,

      # CIL Ingest — feeds live events into CIL modules (M10-M19)
      ObservationBus.Subscriber.CILIngest,

      # Constitutional Intelligence Layer (CIL) — M10
      ObservationBus.CIL.Supervisor,

      # Soak Test Engine — long-duration autonomous health monitoring
      ObservationBus.Soak.SoakTestEngine,
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
