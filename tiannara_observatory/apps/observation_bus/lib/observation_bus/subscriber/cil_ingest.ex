defmodule ObservationBus.Subscriber.CILIngest do
  @moduledoc """
  COB subscriber that feeds constitutional events into the CIL modules.

  Routes every COB event into PatternEngine, CausalEngine, AnomalyDetector,
  TrendEngine, HealthEngine, KnowledgeSynthesizer, RiskAnalyzer, and
  ConfidenceEngine — enabling live constitutional intelligence on real data.
  """
  use GenServer

  @topic_pattern "constitution.*:*.*:*"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    ObservationBus.SubscriptionRegistry.subscribe(self(), @topic_pattern)
    {:ok, %{ingested: 0}}
  end

  @impl true
  def handle_info({:constitutional_event, %ObservationBus.Event{} = event, _topic}, state) do
    ingest_to_cil(event)
    {:noreply, %{state | ingested: state.ingested + 1}}
  end

  defp ingest_to_cil(%ObservationBus.Event{domain: domain, id: id, payload: payload}) do
    event_map = %{
      id: id,
      domain: domain,
      timestamp: DateTime.utc_now(),
      payload: payload || %{}
    }

    ObservationBus.CIL.PatternEngine.ingest_event(event_map)
    ObservationBus.CIL.CausalEngine.record_event(id, %{domain: domain})
    ObservationBus.CIL.AnomalyDetector.analyze(event_map)
    route_by_domain(domain, event_map)
  end

  defp route_by_domain("scientific" <> _, event) do
    ObservationBus.CIL.KnowledgeSynthesizer.synthesize([%{domain: "scientific", intensity: 1}])
    ObservationBus.CIL.ConfidenceEngine.evaluate(event.id, :scientific, [])
  end

  defp route_by_domain("discovery" <> _, event) do
    ObservationBus.CIL.HealthEngine.update_dimension(:discovery, :active, %{last_event: event.id})
    ObservationBus.CIL.RecommendationEngine.from_pattern(:discovery_burst, %{event_id: event.id})
  end

  defp route_by_domain("engineering" <> _, _event) do
    ObservationBus.CIL.HealthEngine.update_dimension(:engineering, :active, %{})
    ObservationBus.CIL.TrendEngine.record(:engineering_activity, 1)
  end

  defp route_by_domain("knowledge" <> _, event) do
    ObservationBus.CIL.KnowledgeSynthesizer.synthesize([%{domain: "knowledge", intensity: 1}])
    ObservationBus.CIL.ConfidenceEngine.evaluate(event.id, :epistemic, [])
    ObservationBus.CIL.TrendEngine.record(:knowledge_activity, 1)
  end

  defp route_by_domain("runtime" <> _, _event) do
    ObservationBus.CIL.HealthEngine.update_dimension(:runtime, :operational, %{})
    ObservationBus.CIL.TrendEngine.record(:runtime_activity, 1)
  end

  defp route_by_domain("experiment" <> _, event) do
    ObservationBus.CIL.HealthEngine.update_dimension(:experiment, :running, %{last_event: event.id})
    ObservationBus.CIL.TrendEngine.record(:experiment_activity, 1)
  end

  defp route_by_domain("certification" <> _, _event) do
    ObservationBus.CIL.HealthEngine.update_dimension(:certification, :active, %{})
    ObservationBus.CIL.RecommendationEngine.from_pattern(:certification, %{})
    ObservationBus.CIL.TrendEngine.record(:certification_activity, 1)
  end

  defp route_by_domain("planetary" <> _, _event) do
    ObservationBus.CIL.TrendEngine.record(:planetary_activity, 1)
  end

  defp route_by_domain("civilization" <> _, _event) do
    ObservationBus.CIL.HealthEngine.update_dimension(:civilization, :observed, %{})
    ObservationBus.CIL.TrendEngine.record(:civilization_activity, 1)
  end

  defp route_by_domain("governance" <> _, _event) do
    ObservationBus.CIL.HealthEngine.update_dimension(:governance, :active, %{})
  end

  defp route_by_domain(_domain, event) do
    ObservationBus.CIL.HealthEngine.update_dimension(:general, :active, %{last_event: event.id})
    ObservationBus.CIL.TrendEngine.record(:general_activity, 1)
  end
end
