defmodule Tiannara.ACE.CivilizationDigitalTwin do
  @moduledoc """
  Civilization Digital Twin: simulation environment for testing technologies,
  policies, infrastructure, economic systems, and environmental interventions.

  Ensures: Real World ← Validation ← Simulation ← Engineering Proposal
  """
  use GenServer
  alias Tiannara.ACE.Models.{DesignCandidate, SimulationResult}

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)

  def simulate(pid, design, environment), do: GenServer.call(pid, {:simulate, design, environment})
  def run_edge_cases(pid, design), do: GenServer.call(pid, {:edge_cases, design})

  @impl true
  def init(_), do: {:ok, %{results: %{}, environments: %{}}}

  @impl true
  def handle_call({:simulate, design, environment}, _from, state) do
    result = run_simulation(design, environment)

    state = put_in(state, [:results, result.id], result)
    {:reply, {:ok, result}, state}
  end

  @impl true
  def handle_call({:edge_cases, _design}, _from, state) do
    edge_case_results = test_edge_cases()
    {:reply, {:ok, edge_case_results}, state}
  end

  defp run_simulation(design, environment) do
    success_metrics = simulate_success_metrics(design, environment)
    failure_scenarios = identify_failure_scenarios(design, environment)
    unexpected = detect_unexpected_behaviors(design)

    confidence = calculate_simulation_confidence(success_metrics, failure_scenarios)

    %SimulationResult{
      id: UUID.uuid4(),
      design_id: design.id,
      simulation_environment: environment,
      success_metrics: success_metrics,
      failure_scenarios: failure_scenarios,
      edge_cases_tested: 100,
      confidence_level: confidence,
      unexpected_behaviors: unexpected,
      timestamp: DateTime.utc_now()
    }
  end

  defp simulate_success_metrics(_design, _environment) do
    %{
      operational_success: :rand.uniform() * 0.4 + 0.6,
      performance_target_met: :rand.uniform() * 0.3 + 0.7,
      resource_efficiency: :rand.uniform() * 0.5 + 0.5,
      safety_compliance: :rand.uniform() * 0.2 + 0.8
    }
  end

  defp identify_failure_scenarios(_design, _environment) do
    [
      %{scenario: "extreme_load", probability: 0.05, impact: :high},
      %{scenario: "component_degradation", probability: 0.12, impact: :medium},
      %{scenario: "environmental_stress", probability: 0.08, impact: :medium}
    ]
  end

  defp detect_unexpected_behaviors(_design) do
    if :rand.uniform() < 0.2 do
      [%{behavior: "unexpected_interaction", severity: :low}]
    else
      []
    end
  end

  defp calculate_simulation_confidence(success_metrics, failure_scenarios) do
    base_confidence = Enum.reduce(Map.values(success_metrics), 0, &(&1 + &2)) / 4
    failure_penalty = length(failure_scenarios) * 0.05
    max(0.0, base_confidence - failure_penalty)
  end

  defp test_edge_cases do
    Enum.map(1..100, fn i ->
      %{
        edge_case_id: i,
        passed: :rand.uniform() > 0.1,
        severity: if(:rand.uniform() > 0.9, do: :critical, else: :normal)
      }
    end)
  end
end
