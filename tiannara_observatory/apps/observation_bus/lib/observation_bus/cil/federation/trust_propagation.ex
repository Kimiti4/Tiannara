defmodule ObservationBus.CIL.Federation.TrustPropagation do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def list_trust_scores, do: GenServer.call(__MODULE__, :scores)
  def get_trust(node_id), do: GenServer.call(__MODULE__, {:trust, node_id})

  @impl true
  def init(_opts) do
    scores = %{
      obs_alpha: %{trust_score: 0.95, verification_history: 0.98, scientific_reliability: 0.94, evidence_quality: 0.93, certification: :certified, trust_trend: :stable},
      obs_beta: %{trust_score: 0.88, verification_history: 0.92, scientific_reliability: 0.87, evidence_quality: 0.85, certification: :certified, trust_trend: :improving},
      obs_gamma: %{trust_score: 0.72, verification_history: 0.78, scientific_reliability: 0.70, evidence_quality: 0.68, certification: :provisional, trust_trend: :declining},
      obs_delta: %{trust_score: 0.91, verification_history: 0.95, scientific_reliability: 0.90, evidence_quality: 0.88, certification: :certified, trust_trend: :stable},
      obs_epsilon: %{trust_score: 0.84, verification_history: 0.86, scientific_reliability: 0.82, evidence_quality: 0.84, certification: :certified, trust_trend: :improving},
    }
    {:ok, %{scores: scores, global_trust_index: 0.86, trust_algorithm: :weighted_evidence}}
  end

  @impl true
  def handle_call(:scores, _from, state), do: {:reply, state, state}
  def handle_call({:trust, node_id}, _from, state) do
    id = String.to_atom(node_id)
    {:reply, Map.get(state.scores, id) || Map.get(state.scores, node_id), state}
  end
end
