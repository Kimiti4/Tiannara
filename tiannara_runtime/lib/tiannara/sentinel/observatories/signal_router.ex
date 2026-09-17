defmodule Tiannara.Sentinel.Observatories.SignalRouter do
  use GenServer
  
  alias Tiannara.Sentinel.Observatories.Specialized.{RuntimeObservatory, EcologicalObservatory, SemanticObservatory}
  alias Tiannara.Sentinel.Observatories.Core.{ConsensusEngine, MetricsCollector}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def route_anomaly(anomaly) do
    GenServer.cast(__MODULE__, {:route, anomaly})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:route, anomaly}, state) do
    # 1. Ask observatories for signals
    runtime_sig = RuntimeObservatory.generate_signal(anomaly)
    eco_sig = EcologicalObservatory.generate_signal(anomaly)
    semantic_sig = SemanticObservatory.generate_signal(anomaly)
    
    signals = [runtime_sig, eco_sig, semantic_sig]

    # 2. Fuse signals (pure evidence generation)
    consensus = ConsensusEngine.fuse(signals)

    # 3. Record for dashboard metrics (passive)
    MetricsCollector.record_evaluation_case(%{
      anomaly_id: anomaly.id,
      consensus_prediction: consensus.preferred_action,
      consensus_action_scores: consensus.action_scores,
      observatory_signals: signals,
      observatory_predictions: Map.new(signals, &{&1.observatory, &1.recommended_action}),
      observed: :pending # Updated later by outcome tracker
    })

    {:noreply, state}
  end
end
