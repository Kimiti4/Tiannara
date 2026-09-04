defmodule Tiannara.Engineering.Optimization.ArchitectureGenerator do
  alias Tiannara.Engineering.Domain.{EngineeringDesign, DesignComponent}

  @architectural_patterns [:monolithic, :microkernel, :pipeline, :event_driven, :layered, :hexagonal]
  @scaling_strategies [:vertical, :horizontal, :parallel, :distributed, :serverless]
  @data_flow_models [:push, :pull, :hybrid, :reactive]

  def patterns, do: @architectural_patterns
  def scaling_strategies, do: @scaling_strategies
  def data_flow_models, do: @data_flow_models

  @spec generate_alternatives(EngineeringDesign.t(), non_neg_integer()) :: [EngineeringDesign.t()]
  def generate_alternatives(%EngineeringDesign{} = design, count \\ 3) do
    current_pattern = Map.get(design.architecture, :pattern, :monolithic)
    current_scaling = Map.get(design.architecture, :scaling_strategy, :vertical)

    alternatives =
      for pattern <- @architectural_patterns,
          scaling <- @scaling_strategies,
          pattern != current_pattern or scaling != current_scaling do
        {pattern, scaling}
      end
      |> Enum.take(count)
      |> Enum.with_index()
      |> Enum.map(fn {{pattern, scaling}, idx} -> build_alternative(design, pattern, scaling, idx) end)

    alternatives
  end

  @spec evaluate_sustainability(EngineeringDesign.t()) :: map()
  def evaluate_sustainability(%EngineeringDesign{} = design) do
    pattern = Map.get(design.architecture, :pattern, :monolithic)
    scaling = Map.get(design.architecture, :scaling_strategy, :vertical)

    %{
      design_id: design.id,
      pattern: pattern,
      scaling: scaling,
      scores: %{
        modularity: score_modularity(pattern),
        scalability: score_scalability(scaling),
        replaceability: score_replaceability(pattern),
        platform_independence: score_platform_independence(pattern, scaling),
        maintainability: score_maintainability(pattern, design),
        evolution_readiness: score_evolution_readiness(pattern, scaling)
      },
      composite: compute_sustainability_composite(pattern, scaling, design),
      recommendations: generate_sustainability_recommendations(pattern, scaling, design)
    }
  end

  defp build_alternative(%EngineeringDesign{} = design, pattern, scaling, idx) do
    data_flow = select_data_flow(pattern)
    %{design |
      id: "design_alt_#{idx}_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}",
      name: "#{design.name} (#{pattern}/#{scaling} alternative)",
      description: "Alternative architecture: #{pattern} pattern with #{scaling} scaling. #{design.description}",
      architecture: %{pattern: pattern, scaling_strategy: scaling, data_flow: data_flow, components: Enum.map(design.components, & &1.name), coupling: coupling_for_pattern(pattern)},
      components: adapt_components(design.components, pattern),
      resource_requirements: estimate_alternative_resources(design, pattern, scaling),
      feasibility: estimate_alternative_feasibility(design, pattern, scaling),
      risk: estimate_alternative_risk(pattern, scaling),
      safety_score: estimate_alternative_safety(pattern),
      lineage: design.lineage ++ [%{event: :alternative_generated, from_design: design.id, pattern: pattern, scaling: scaling, at: DateTime.utc_now()}]
    }
  end

  defp select_data_flow(:event_driven), do: :reactive
  defp select_data_flow(:pipeline), do: :push
  defp select_data_flow(:layered), do: :pull
  defp select_data_flow(_), do: :hybrid

  defp coupling_for_pattern(:monolithic), do: :tight
  defp coupling_for_pattern(:microkernel), do: :loose
  defp coupling_for_pattern(:pipeline), do: :loose
  defp coupling_for_pattern(:event_driven), do: :decoupled
  defp coupling_for_pattern(:layered), do: :loose
  defp coupling_for_pattern(:hexagonal), do: :decoupled

  defp adapt_components(components, :event_driven) do
    components ++ [DesignComponent.new(%{name: "event_bus", type: :infrastructure, description: "Event bus for decoupled communication", interfaces: [{:input, :event}, {:output, :event}], dependencies: [], resource_cost: %{compute: 30, memory: 60}, complexity: 0.4, reusability: 0.9})]
  end

  defp adapt_components(components, :pipeline) do
    components |> Enum.with_index() |> Enum.map(fn {comp, idx} ->
      %{comp | dependencies: if(idx > 0, do: [Enum.at(components, idx - 1).name], else: [])}
    end)
  end

  defp adapt_components(components, _), do: components

  defp estimate_alternative_resources(design, pattern, scaling) do
    base = design.resource_requirements
    pattern_multiplier = case pattern do
      :monolithic -> 0.8; :microkernel -> 1.0; :pipeline -> 0.9; :event_driven -> 1.2; :layered -> 1.0; :hexagonal -> 1.1
    end
    scaling_multiplier = case scaling do
      :vertical -> 0.8; :horizontal -> 1.3; :parallel -> 1.5; :distributed -> 1.8; :serverless -> 1.2
    end
    %{compute: round(Map.get(base, :compute, 100) * pattern_multiplier * scaling_multiplier), memory: round(Map.get(base, :memory, 200) * pattern_multiplier), time_hours: round(Map.get(base, :time_hours, 10) * pattern_multiplier)}
  end

  defp estimate_alternative_feasibility(design, pattern, scaling) do
    pattern_feasibility = case pattern do
      :monolithic -> 0.9; :microkernel -> 0.8; :pipeline -> 0.85; :event_driven -> 0.7; :layered -> 0.85; :hexagonal -> 0.75
    end
    scaling_feasibility = case scaling do
      :vertical -> 0.9; :horizontal -> 0.7; :parallel -> 0.6; :distributed -> 0.5; :serverless -> 0.7
    end
    design.feasibility * pattern_feasibility * scaling_feasibility
  end

  defp estimate_alternative_risk(pattern, scaling) do
    pattern_risk = case pattern do
      :monolithic -> 0.3; :microkernel -> 0.4; :pipeline -> 0.35; :event_driven -> 0.5; :layered -> 0.3; :hexagonal -> 0.45
    end
    scaling_risk = case scaling do
      :vertical -> 0.2; :horizontal -> 0.4; :parallel -> 0.5; :distributed -> 0.6; :serverless -> 0.4
    end
    (pattern_risk + scaling_risk) / 2.0
  end

  defp estimate_alternative_safety(pattern) do
    case pattern do
      :monolithic -> 0.7; :microkernel -> 0.85; :pipeline -> 0.8; :event_driven -> 0.75; :layered -> 0.9; :hexagonal -> 0.85
    end
  end

  defp score_modularity(:monolithic), do: 0.3
  defp score_modularity(:microkernel), do: 0.9
  defp score_modularity(:pipeline), do: 0.7
  defp score_modularity(:event_driven), do: 0.95
  defp score_modularity(:layered), do: 0.8
  defp score_modularity(:hexagonal), do: 0.95

  defp score_scalability(:vertical), do: 0.4
  defp score_scalability(:horizontal), do: 0.8
  defp score_scalability(:parallel), do: 0.9
  defp score_scalability(:distributed), do: 0.95
  defp score_scalability(:serverless), do: 0.85

  defp score_replaceability(:monolithic), do: 0.2
  defp score_replaceability(_), do: 0.8

  defp score_platform_independence(:monolithic, :vertical), do: 0.4
  defp score_platform_independence(:event_driven, :distributed), do: 0.9
  defp score_platform_independence(:hexagonal, _), do: 0.9
  defp score_platform_independence(_, _), do: 0.7

  defp score_maintainability(:monolithic, _design), do: 0.4
  defp score_maintainability(:layered, _design), do: 0.85
  defp score_maintainability(_, design), do: min(1.0, 0.6 + length(design.components) * 0.02)

  defp score_evolution_readiness(:monolithic, :vertical), do: 0.3
  defp score_evolution_readiness(:event_driven, _), do: 0.9
  defp score_evolution_readiness(:hexagonal, _), do: 0.9
  defp score_evolution_readiness(_, :distributed), do: 0.85
  defp score_evolution_readiness(_, _), do: 0.6

  defp compute_sustainability_composite(pattern, scaling, design) do
    scores = [score_modularity(pattern), score_scalability(scaling), score_replaceability(pattern), score_platform_independence(pattern, scaling), score_maintainability(pattern, design), score_evolution_readiness(pattern, scaling)]
    Enum.sum(scores) / length(scores)
  end

  defp generate_sustainability_recommendations(pattern, scaling, design) do
    recommendations = []
    recommendations = if pattern == :monolithic, do: [%{type: :pattern, action: "Consider decomposing monolith into specialized components", priority: :high} | recommendations], else: recommendations
    recommendations = if scaling == :vertical, do: [%{type: :scaling, action: "Consider horizontal scaling for long-term growth", priority: :medium} | recommendations], else: recommendations
    recommendations = if length(design.components) > 10, do: [%{type: :complexity, action: "High component count — consider consolidation", priority: :low} | recommendations], else: recommendations
    recommendations
  end
end
