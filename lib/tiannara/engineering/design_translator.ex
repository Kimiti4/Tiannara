defmodule Tiannara.Engineering.DesignTranslator do
  alias Tiannara.Engineering.Domain.{
    EngineeringInsight, EngineeringDesign, DesignComponent, VerificationPlan
  }

  @min_designs 1
  @max_designs 3

  @spec translate(EngineeringInsight.t()) :: [EngineeringDesign.t()]
  def translate(%EngineeringInsight{} = insight) do
    insight
    |> design_templates()
    |> Enum.take(@max_designs)
    |> Enum.map(fn template -> build_design(insight, template) end)
    |> Enum.map(fn design -> attach_verification_plan(design) end)
  end

  @spec translate_insights([EngineeringInsight.t()]) :: %{String.t() => [EngineeringDesign.t()]}
  def translate_insights(insights) when is_list(insights) do
    Map.new(insights, fn insight ->
      {insight.id, translate(insight)}
    end)
  end

  defp design_templates(%EngineeringInsight{domain: domain}) do
    base = [
      %{approach: :minimal_viable,
        name: "Minimal implementation of #{domain} principle",
        description: "Simplest design that satisfies the principle with minimal resources",
        complexity_factor: 0.3, resource_factor: 0.3, safety_factor: 0.9, reusability_factor: 0.4},
      %{approach: :modular_extensible,
        name: "Modular extensible implementation of #{domain} principle",
        description: "Component-based design optimized for future extension and replacement",
        complexity_factor: 0.6, resource_factor: 0.6, safety_factor: 0.8, reusability_factor: 0.8},
      %{approach: :high_performance,
        name: "High-performance implementation of #{domain} principle",
        description: "Optimized design for maximum throughput and minimal latency",
        complexity_factor: 0.8, resource_factor: 0.9, safety_factor: 0.7, reusability_factor: 0.5}
    ]
    case insight_confidence_tier(domain) do
      :high -> base
      :medium -> Enum.take(base, 2)
      :low -> Enum.take(base, 1)
    end
  end

  defp insight_confidence_tier(_domain), do: :high

  defp build_design(%EngineeringInsight{} = insight, template) do
    components = generate_components(insight, template)

    EngineeringDesign.new(%{
      insight_id: insight.id,
      name: template.name,
      description: "#{template.description}. Derived from: #{insight.principle_statement}",
      domain: insight.domain,
      components: components,
      architecture: build_architecture(template, components),
      resource_requirements: estimate_resources(template, components),
      feasibility: compute_feasibility(template, insight),
      risk: template.complexity_factor * 0.7,
      safety_score: template.safety_factor,
      estimated_effort: estimate_effort(template, components),
      status: :proposed,
      lineage: [%{event: :design_created, from_insight: insight.id,
        approach: template.approach, at: DateTime.utc_now()}]
    })
  end

  defp generate_components(%EngineeringInsight{} = insight, template) do
    base_components = [
      DesignComponent.new(%{name: "core_#{insight.domain}_module", type: :core_logic,
        description: "Core implementation of #{insight.principle_statement}",
        interfaces: [{:input, :principle_data}, {:output, :engineering_output}],
        dependencies: [], resource_cost: %{compute: 100, memory: 200},
        complexity: template.complexity_factor, reusability: template.reusability_factor}),
      DesignComponent.new(%{name: "validation_#{insight.domain}_module", type: :validation,
        description: "Validates outputs against the source principle",
        interfaces: [{:input, :engineering_output}, {:output, :validation_result}],
        dependencies: ["core_#{insight.domain}_module"],
        resource_cost: %{compute: 50, memory: 100},
        complexity: template.complexity_factor * 0.5, reusability: 0.7})
    ]

    if template.approach == :modular_extensible do
      base_components ++ [
        DesignComponent.new(%{name: "extension_#{insight.domain}_interface", type: :extension_point,
          description: "Extension interface for future capabilities",
          interfaces: [{:input, :extension_request}, {:output, :extension_result}],
          dependencies: ["core_#{insight.domain}_module"],
          resource_cost: %{compute: 20, memory: 50}, complexity: 0.3, reusability: 0.9})
      ]
    else
      base_components
    end
  end

  defp build_architecture(template, components) do
    %{pattern: case template.approach do
        :minimal_viable -> :monolithic
        :modular_extensible -> :microkernel
        :high_performance -> :pipeline
      end,
      components: Enum.map(components, & &1.name),
      data_flow: Enum.map(components, fn c -> {c.name, c.interfaces} end),
      scaling_strategy: case template.approach do
        :minimal_viable -> :vertical
        :modular_extensible -> :horizontal
        :high_performance -> :parallel
      end}
  end

  defp estimate_resources(template, components) do
    total = Enum.reduce(components, %{compute: 0, memory: 0}, fn comp, acc ->
      %{compute: acc.compute + Map.get(comp.resource_cost, :compute, 0),
        memory: acc.memory + Map.get(comp.resource_cost, :memory, 0)}
    end)
    %{compute: round(total.compute * (1.0 + template.resource_factor)),
      memory: round(total.memory * (1.0 + template.resource_factor)),
      time_hours: round(length(components) * 4 * template.complexity_factor)}
  end

  defp compute_feasibility(template, insight) do
    base = insight.confidence * (1.0 - template.complexity_factor * 0.5)
    max(0.1, min(0.95, base))
  end

  defp estimate_effort(template, components) do
    %{design_hours: round(length(components) * 2 * template.complexity_factor),
      implementation_hours: round(length(components) * 8 * template.complexity_factor),
      testing_hours: round(length(components) * 4 * template.complexity_factor),
      total_hours: round(length(components) * 14 * template.complexity_factor)}
  end

  defp attach_verification_plan(%EngineeringDesign{} = design) do
    plan = VerificationPlan.new(%{
      design_id: design.id,
      unit_tests: Enum.map(design.components, fn comp ->
        %{component: comp.name, type: :unit, description: "Test #{comp.name} in isolation"}
      end),
      integration_tests: [
        %{type: :integration, description: "Test component interactions"},
        %{type: :integration, description: "Test against source principle"}
      ],
      property_tests: [%{type: :property, description: "Invariants hold under randomized input"}],
      chaos_tests: [%{type: :chaos, description: "Component failure recovery"}],
      performance_tests: [%{type: :performance, description: "Throughput and latency under load"}],
      safety_checks: [
        %{type: :safety, description: "No unsafe state transitions"},
        %{type: :safety, description: "Resource bounds respected"}
      ],
      acceptance_criteria: [
        "All unit tests pass",
        "All integration tests pass",
        "Property tests hold for 10,000 iterations",
        "No safety violations",
        "Performance within 20% of target"
      ],
      estimated_duration_hours: round(length(design.components) * 2)
    })
    %{design | verification_plan: plan}
  end
end
