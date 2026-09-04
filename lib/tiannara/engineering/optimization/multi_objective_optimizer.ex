defmodule Tiannara.Engineering.Optimization.MultiObjectiveOptimizer do
  alias Tiannara.Engineering.Domain.EngineeringDesign

  @objectives [:cost, :sustainability, :reliability, :safety, :performance, :manufacturability]
  def objectives, do: @objectives

  @spec evaluate(EngineeringDesign.t()) :: map()
  def evaluate(%EngineeringDesign{} = design) do
    %{
      design_id: design.id,
      cost: evaluate_cost(design),
      sustainability: evaluate_sustainability(design),
      reliability: evaluate_reliability(design),
      safety: design.safety_score,
      performance: evaluate_performance(design),
      manufacturability: evaluate_manufacturability(design)
    }
  end

  @spec pareto_front([EngineeringDesign.t()]) :: [EngineeringDesign.t()]
  def pareto_front(designs) when is_list(designs) do
    evaluations = Map.new(designs, fn d -> {d.id, evaluate(d)} end)
    Enum.filter(designs, fn design ->
      eval = Map.get(evaluations, design.id)
      not Enum.any?(designs, fn other ->
        other.id != design.id and dominates?(Map.get(evaluations, other.id), eval)
      end)
    end)
  end

  @spec select_best([EngineeringDesign.t()], map()) :: EngineeringDesign.t() | nil
  def select_best(designs, weights \\ %{})
  def select_best([], _weights), do: nil
  def select_best(designs, weights) when is_list(designs) do
    default_weights = %{cost: 0.15, sustainability: 0.20, reliability: 0.20, safety: 0.25, performance: 0.10, manufacturability: 0.10}
    effective_weights = Map.merge(default_weights, weights)
    designs |> Enum.max_by(fn design -> weighted_score(evaluate(design), effective_weights) end)
  end

  @spec weighted_score(map(), map()) :: float()
  def weighted_score(evaluation, weights) do
    @objectives |> Enum.reduce(0.0, fn obj, acc ->
      score = Map.get(evaluation, obj, 0.5)
      weight = Map.get(weights, obj, 0.0)
      effective_score = if obj == :cost, do: 1.0 - score, else: score
      acc + effective_score * weight
    end)
  end

  @spec dominates?(map(), map()) :: boolean()
  def dominates?(eval_a, eval_b) do
    all_geq = Enum.all?(@objectives, fn obj -> effective_score(eval_a, obj) >= effective_score(eval_b, obj) end)
    any_gt = Enum.any?(@objectives, fn obj -> effective_score(eval_a, obj) > effective_score(eval_b, obj) end)
    all_geq and any_gt
  end

  defp effective_score(eval, :cost), do: 1.0 - Map.get(eval, :cost, 0.5)
  defp effective_score(eval, obj), do: Map.get(eval, obj, 0.5)

  defp evaluate_cost(%EngineeringDesign{} = design) do
    resources = design.resource_requirements
    total = Map.get(resources, :compute, 0) + Map.get(resources, :memory, 0) + Map.get(resources, :time_hours, 0) * 10
    max(0.0, min(1.0, 1.0 - total / 2000.0))
  end

  defp evaluate_sustainability(%EngineeringDesign{} = design) do
    resources = design.resource_requirements
    total_resources = Map.get(resources, :compute, 0) + Map.get(resources, :memory, 0)
    resource_efficiency = max(0.0, 1.0 - total_resources / 1500.0)
    reusability = if design.components == [], do: 0.5, else: Enum.sum(Enum.map(design.components, & &1.reusability)) / length(design.components)
    platform_independence = case Map.get(design.architecture, :pattern) do
      :hexagonal -> 0.9; :event_driven -> 0.85; :microkernel -> 0.8; :monolithic -> 0.4; _ -> 0.7
    end
    resource_efficiency * 0.3 + reusability * 0.3 + platform_independence * 0.4
  end

  defp evaluate_reliability(%EngineeringDesign{} = design) do
    complexity = if design.components == [], do: 0.5, else: Enum.sum(Enum.map(design.components, & &1.complexity)) / length(design.components)
    complexity_score = 1.0 - complexity
    component_score = max(0.0, 1.0 - length(design.components) * 0.05)
    design.safety_score * 0.4 + complexity_score * 0.3 + component_score * 0.3
  end

  defp evaluate_performance(%EngineeringDesign{} = design) do
    scaling_score = case Map.get(design.architecture, :scaling_strategy) do
      :distributed -> 0.95; :parallel -> 0.9; :horizontal -> 0.8; :serverless -> 0.75; :vertical -> 0.5; _ -> 0.6
    end
    pattern_score = case Map.get(design.architecture, :pattern) do
      :pipeline -> 0.9; :event_driven -> 0.85; :microkernel -> 0.8; :layered -> 0.7; :hexagonal -> 0.75; :monolithic -> 0.5; _ -> 0.6
    end
    scaling_score * 0.5 + pattern_score * 0.5
  end

  defp evaluate_manufacturability(%EngineeringDesign{} = design) do
    complexity = if design.components == [], do: 0.5, else: Enum.sum(Enum.map(design.components, & &1.complexity)) / length(design.components)
    complexity_score = 1.0 - complexity
    design.feasibility * 0.5 + complexity_score * 0.3 + 0.7 * 0.2
  end
end
