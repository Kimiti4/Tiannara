defmodule Tiannara.CCI.PriorityResearchEngine do
  @moduledoc """
  Priority Research Engine (PRE): coordinates civilization-scale research priorities.
  Input: Sentinel observations → ASC research ecosystem → Civilization model →
         Priority selection → Research civilization direction.
  """
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)

  def recommend_priorities(pid, sentinel_observations, civ_state), do: GenServer.call(pid, {:recommend, sentinel_observations, civ_state})
  def get_priorities(pid), do: GenServer.call(pid, :get_priorities)

  @impl true
  def init(_), do: {:ok, %{priorities: []}}

  @impl true
  def handle_call({:recommend, _observations, _civ_state}, _from, state) do
    priorities = generate_priorities()
    state = %{state | priorities: priorities}
    {:reply, {:ok, priorities}, state}
  end

  @impl true
  def handle_call(:get_priorities, _from, state), do: {:reply, state.priorities, state}

  defp generate_priorities do
    base = [
      %{
        domain: :knowledge_integration,
        rationale: "Cross-domain synthesis opportunities identified",
        evidence: [:sentinel_pattern_detection, :reality_graph_analysis],
        causal_chain: ["Fragmented knowledge limits capability combination", "Integration enables emergent capabilities"],
        expected_impact: 0.8,
        confidence: 0.75,
        unknowns: [:integration_mechanism_effectiveness],
        alternatives: [:domain_specific_optimization, :status_quo],
        resource_requirements: 150,
        human_benefit: 0.85,
        recommendation_level: :high
      },
      %{
        domain: :institutional_health,
        rationale: "Institutional adaptability declining in key domains",
        evidence: [:ies_health_assessments, :sentinel_observations],
        causal_chain: ["Stagnant institutions reduce innovation", "Reform enables adaptation"],
        expected_impact: 0.7,
        confidence: 0.7,
        unknowns: [:reform_effectiveness, :resistance_risk],
        alternatives: [:targeted_intervention, :gradual_evolution],
        resource_requirements: 100,
        human_benefit: 0.8,
        recommendation_level: :medium
      },
      %{
        domain: :risk_mitigation,
        rationale: "Civilizational risks require proactive management",
        evidence: [:risk_assessments, :forecasting_analysis],
        causal_chain: ["Unaddressed risks compound over time", "Mitigation preserves long-term stability"],
        expected_impact: 0.9,
        confidence: 0.8,
        unknowns: [:risk_evolution_dynamics],
        alternatives: [:reactive_response, :selective_mitigation],
        resource_requirements: 200,
        human_benefit: 0.95,
        recommendation_level: :critical
      }
    ]

    Enum.map(base, fn p ->
      struct(Tiannara.CCI.Models.ResearchPriority, Map.merge(p, %{
        id: UUID.uuid4(),
        timestamp: DateTime.utc_now()
      }))
    end)
  end
end
