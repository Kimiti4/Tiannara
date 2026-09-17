defmodule Tiannara.RRG.Kernel do
  @moduledoc """
  Core execution kernel for the Rate-limiting Ontological Graph (RRG).
  It orchestrates the flow: Observer Input → Gate → ExposureTracker → BandwidthController → GraphThrottler → AnomalyMeter → State Update → Feedback.
  """

  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, Map.merge(state, %{global_bandwidth: 1000.0, active_observers: %{}, anomaly_pressure: 0.0})}
  end

  @doc """
  Process an incoming observation.
  `observer_id` is the identifier of the observer.
  `ontology_delta` is a map with at least a `weight` field.
  """
  def handle_cast({:ingest, observer_id, ontology_delta}, state) do
    case Tiannara.RRG.Gate.check(observer_id, ontology_delta, state) do
      :allow ->
        new_state = apply_ingestion(state, observer_id, ontology_delta)
        {:noreply, new_state}

      :deny ->
        Logger.warning("🚫 RRG: ingestion blocked for #{observer_id}")
        {:noreply, state}
    end
  end

  defp apply_ingestion(state, observer_id, delta) do
    # Update anomaly pressure
    new_pressure = state.anomaly_pressure + delta.weight

    # Record exposure (placeholder implementation)
    exposure_score = Tiannara.RRG.ExposureTracker.exposure_score([])
    updated_observers = Map.put(state.active_observers, observer_id, %{exposure: exposure_score, last_delta: delta})

    %{state | anomaly_pressure: new_pressure, active_observers: updated_observers}
  end
end
