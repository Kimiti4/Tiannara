defmodule ObservationBus.Telemetry.Metrics do
  @moduledoc """
  COB telemetry metrics definitions.

  All events flowing through the bus emit telemetry for observability.
  These metrics are consumed by the Metrics Engine and Observatory UI.
  """

  @doc """
  Returns all COB metrics definitions.
  """
  @spec definitions() :: list(map())
  def definitions do
    [
      %{name: "observation_bus.event.routed.count", type: :counter, event: [:observation_bus, :event, :routed], description: "Total events routed"},
      %{name: "observation_bus.event.published.count", type: :counter, event: [:observation_bus, :event, :published], description: "Total events published"},
      %{name: "observation_bus.event.dropped.count", type: :counter, event: [:observation_bus, :event, :dropped], description: "Total events dropped"},
      %{name: "observation_bus.priority.depth", type: :last_value, event: [:observation_bus, :priority, :depth], measurement: :depth, description: "Current priority queue depth"},
      %{name: "observation_bus.ordering.global", type: :last_value, event: [:observation_bus, :ordering, :global], measurement: :global, description: "Current global sequence counter"},
      %{name: "observation_bus.ordering.local", type: :last_value, event: [:observation_bus, :ordering, :local], measurement: :local, description: "Current local sequence counter"},
      %{name: "observation_bus.lineage.total", type: :last_value, event: [:observation_bus, :lineage, :total], measurement: :total, description: "Total lineage entries"},
      %{name: "observation_bus.lineage.orphans", type: :last_value, event: [:observation_bus, :lineage, :orphans], measurement: :orphans, description: "Orphan events"},
      %{name: "observation_bus.buffer.size", type: :last_value, event: [:observation_bus, :buffer, :size], measurement: :size, description: "Current buffer size"},
      %{name: "observation_bus.buffer.capacity", type: :last_value, event: [:observation_bus, :buffer, :capacity], measurement: :capacity, description: "Buffer capacity"},
      %{name: "observation_bus.archive.count", type: :counter, event: [:observation_bus, :archive], description: "Total events archived"},
      %{name: "observation_bus.scheduler.queued", type: :last_value, event: [:observation_bus, :scheduler, :queued], measurement: :queued, description: "Total queued events"},
      %{name: "observation_bus.error.count", type: :counter, event: [:observation_bus, :error], description: "Total errors"},
    ]
  end
end
