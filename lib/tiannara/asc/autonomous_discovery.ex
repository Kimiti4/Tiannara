defmodule Tiannara.ASC.AutonomousDiscovery do
  @moduledoc """
  The Autonomous Discovery Engine (ADE).
  Orchestrates the scientific method across all 20 domains,
  guided by Meta-Science and grounded in the Reasoning Layer.
  """

  alias Tiannara.MetaScience.PortfolioOptimizer
  alias Tiannara.MetaScience.BottleneckDetector
  alias Tiannara.Domains.CanonicalRegistry
  alias Tiannara.Observatory
  alias Tiannara.Reasoning.KnowledgeRepresentation

  @doc "Executes one full cycle of the Autonomous Scientific Method."
  def run_discovery_cycle do
    with {:ok, domain_metrics} <- collect_domain_metrics(),
         {:ok, :pipeline_healthy} <- BottleneckDetector.analyze_pipeline(domain_metrics),
         {:ok, candidates} <- generate_candidate_experiments(domain_metrics),
         {:ok, best_experiment} <- PortfolioOptimizer.select_next_experiment(candidates) do
      execute_experiment(best_experiment)
    else
      {:warning, :discovery_stall, info} ->
        Observatory.report_bottleneck(:discovery_stall, info)
        {:stalled, info}

      error ->
        Observatory.report_failure(:discovery_cycle, error)
        error
    end
  end

  defp execute_experiment(%{experiment: exp}) do
    domain_module = exp.domain_module

    case domain_module.simulate(exp.hypothesis, exp.context) do
      {:ok, sim_result} ->
        case domain_module.validate(%{model: sim_result}) do
          {:ok, %{verified: true} = validation} ->
            KnowledgeRepresentation.assert_fact(exp.hypothesis.subject, :validates, exp.hypothesis.object, validation.confidence)
            {:ok, :discovery_integrated}

          {:ok, validation} ->
            {:ok, :hypothesis_rejected, Map.get(validation, :counterexamples, [])}

          {:error, reason} ->
            {:ok, :validation_unavailable, reason}
        end

      {:error, reason} ->
        {:ok, :simulation_unavailable, reason}
    end
  end

  defp collect_domain_metrics do
    records = CanonicalRegistry.all_records()
    metrics =
      records
      |> Enum.filter(fn r -> r.module != nil end)
      |> Enum.map(fn r -> {r.module, r.module.metrics()} end)
      |> Map.new()

    {:ok, metrics}
  end

  defp generate_candidate_experiments(_metrics) do
    pilot = Tiannara.Domains.Physics.pilot_experiment()

    {:ok,
     [
       %{domain_module: Tiannara.Domains.Physics, hypothesis: pilot.hypothesis, context: pilot.context, domain_weight: 1.2},
       %{domain_module: Tiannara.Domains.Chemistry, hypothesis: %{subject: :catalyst, object: :reaction_rate, molecular_graph: %{}, predicted_distributions: [], current_beliefs: []}, context: %{}, domain_weight: 0.9}
     ]}
  end
end
