defmodule Tiannara.Sentinel.TelemetryHub do
  @moduledoc """
  Aggregates incoming metrics from across the runtime without knowing internal subsystem structures.
  Accepts Tiannara.Sentinel.Contracts.TelemetryEvent structs.
  """
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def ingest_event(%Tiannara.Sentinel.Contracts.TelemetryEvent{} = event) do
    GenServer.cast(__MODULE__, {:ingest, event})
  end

  @impl true
  def init(_opts) do
    {:ok, %{events: []}}
  end

  @impl true
  def handle_cast({:ingest, event}, state) do
    # Forward the event to the EventClassifier
    Tiannara.Sentinel.EventClassifier.classify(event)
    
    # Broadcast to OutcomeTracker for B1.5 empirical evaluation
    Tiannara.Sentinel.Immune.OutcomeTracker.process_tick(event.timestamp, event.metrics)

    {:noreply, %{state | events: [event | state.events]}}
  end
end
