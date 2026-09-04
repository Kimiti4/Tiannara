defmodule Tiannara.Engineering.DesignEvaluator do
  alias Tiannara.Engineering.Domain.{EngineeringDesign, DesignEvaluation}

  @dimensions [
    :feasibility, :safety, :resource_efficiency,
    :complexity, :reusability, :verifiability, :alignment_with_principle
  ]

  def dimensions, do: @dimensions

  @spec evaluate(EngineeringDesign.t()) :: DesignEvaluation.t()
  def evaluate(%EngineeringDesign{} = design) do
    scores = %{
      feasibility: design.feasibility,
      safety: design.safety_score,
      resource_efficiency: compute_resource_efficiency(design),
      complexity: 1.0 - compute_normalized_complexity(design),
      reusability: compute_reusability(design),
      verifiability: compute_verifiability(design),
      alignment_with_principle: compute_alignment(design)
    }

    composite = geometric_mean(Map.values(scores))
    {weakest_dim, weakest_val} = Enum.min_by(scores, fn {_k, v} -> v end)

    DesignEvaluation.new(%{
      design_id: design.id,
      feasibility: scores.feasibility,
      safety: scores.safety,
      resource_efficiency: scores.resource_efficiency,
      complexity: scores.complexity,
      reusability: scores.reusability,
      verifiability: scores.verifiability,
      alignment_with_principle: scores.alignment_with_principle,
      composite_score: composite,
      weakest_dimension: {weakest_dim, weakest_val},
      recommendations: generate_recommendations(scores, design)
    })
  end

  @spec rank([EngineeringDesign.t()]) :: [{EngineeringDesign.t(), DesignEvaluation.t()}]
  def rank(designs) when is_list(designs) do
    designs
    |> Enum.map(fn design -> {design, evaluate(design)} end)
    |> Enum.sort_by(fn {_design, eval} -> eval.composite_score end, :desc)
  end

  @spec approval_decision(EngineeringDesign.t()) :: :approve | :revise | :reject
  def approval_decision(%EngineeringDesign{} = design) do
    eval = evaluate(design)
    cond do
      eval.safety < 0.5 -> :reject
      eval.composite_score < 0.3 -> :reject
      eval.composite_score < 0.6 -> :revise
      true -> :approve
    end
  end

  defp geometric_mean(values) do
    if Enum.any?(values, &(&1 <= 0.0)) do
      0.0
    else
      product = Enum.reduce(values, 1.0, &(&1 * &2))
      :math.pow(product, 1.0 / length(values))
    end
  end

  defp compute_resource_efficiency(%EngineeringDesign{} = design) do
    resources = design.resource_requirements
    total = Map.get(resources, :compute, 0) + Map.get(resources, :memory, 0)
    max(0.0, min(1.0, 1.0 - total / 2000.0))
  end

  defp compute_normalized_complexity(%EngineeringDesign{} = design) do
    if design.components == [] do
      0.0
    else
      avg_complexity = design.components |> Enum.map(& &1.complexity) |> Enum.sum() |> Kernel./(length(design.components))
      component_factor = min(1.0, length(design.components) / 10.0)
      (avg_complexity + component_factor) / 2.0
    end
  end

  defp compute_reusability(%EngineeringDesign{} = design) do
    if design.components == [] do
      0.0
    else
      design.components |> Enum.map(& &1.reusability) |> Enum.sum() |> Kernel./(length(design.components))
    end
  end

  defp compute_verifiability(%EngineeringDesign{} = design) do
    case design.verification_plan do
      nil -> 0.0
      plan ->
        test_count = length(plan.unit_tests) + length(plan.integration_tests) +
          length(plan.property_tests) + length(plan.chaos_tests) +
          length(plan.performance_tests) + length(plan.safety_checks)
        criteria_count = length(plan.acceptance_criteria)
        min(1.0, (test_count * 0.1 + criteria_count * 0.1))
    end
  end

  defp compute_alignment(%EngineeringDesign{} = design) do
    (design.feasibility + design.safety_score) / 2.0
  end

  defp generate_recommendations(scores, _design) do
    []
    |> maybe_add(scores.safety < 0.7, :safety, "Add safety checks and bounds validation", :high)
    |> maybe_add(scores.feasibility < 0.5, :feasibility, "Simplify design or increase resource allocation", :high)
    |> maybe_add(scores.reusability < 0.5, :reusability, "Extract reusable interfaces and reduce coupling", :medium)
    |> maybe_add(scores.verifiability < 0.5, :verifiability, "Add more tests and explicit acceptance criteria", :medium)
    |> maybe_add(scores.resource_efficiency < 0.4, :resource_efficiency, "Optimize resource usage or reduce scope", :low)
  end

  defp maybe_add(acc, true, dimension, action, priority), do: [%{dimension: dimension, action: action, priority: priority} | acc]
  defp maybe_add(acc, false, _dimension, _action, _priority), do: acc
end
