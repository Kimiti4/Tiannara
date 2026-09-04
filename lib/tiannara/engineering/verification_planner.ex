defmodule Tiannara.Engineering.VerificationPlanner do
  alias Tiannara.Engineering.Domain.{EngineeringDesign, VerificationPlan}

  @spec plan(EngineeringDesign.t()) :: VerificationPlan.t()
  def plan(%EngineeringDesign{} = design) do
    VerificationPlan.new(%{
      design_id: design.id,
      unit_tests: generate_unit_tests(design),
      integration_tests: generate_integration_tests(design),
      property_tests: generate_property_tests(design),
      chaos_tests: generate_chaos_tests(design),
      performance_tests: generate_performance_tests(design),
      safety_checks: generate_safety_checks(design),
      acceptance_criteria: generate_acceptance_criteria(design),
      estimated_duration_hours: estimate_duration(design)
    })
  end

  @spec validate_completeness(VerificationPlan.t()) :: :ok | {:error, [atom()]}
  def validate_completeness(%VerificationPlan{} = plan) do
    missing = []
    missing = if plan.unit_tests == [], do: [:unit_tests | missing], else: missing
    missing = if plan.integration_tests == [], do: [:integration_tests | missing], else: missing
    missing = if plan.property_tests == [], do: [:property_tests | missing], else: missing
    missing = if plan.chaos_tests == [], do: [:chaos_tests | missing], else: missing
    missing = if plan.performance_tests == [], do: [:performance_tests | missing], else: missing
    missing = if plan.safety_checks == [], do: [:safety_checks | missing], else: missing
    missing = if plan.acceptance_criteria == [], do: [:acceptance_criteria | missing], else: missing
    if missing == [], do: :ok, else: {:error, Enum.reverse(missing)}
  end

  defp generate_unit_tests(%EngineeringDesign{} = design) do
    Enum.map(design.components, fn comp ->
      %{component: comp.name, type: :unit,
        description: "Test #{comp.name} in isolation with valid and invalid inputs",
        coverage_target: 0.9}
    end)
  end

  defp generate_integration_tests(%EngineeringDesign{} = design) do
    base = [
      %{type: :integration, description: "Test all component interactions end-to-end"},
      %{type: :integration, description: "Test against source principle: #{design.description}"}
    ]
    if length(design.components) > 2 do
      base ++ [%{type: :integration, description: "Test partial failure propagation between components"}]
    else
      base
    end
  end

  defp generate_property_tests(_design) do
    [
      %{type: :property, description: "Invariants hold under 10,000 randomized inputs", iterations: 10_000},
      %{type: :property, description: "Output bounds are respected for all valid inputs"},
      %{type: :property, description: "State transitions are valid (no illegal states)"}
    ]
  end

  defp generate_chaos_tests(_design) do
    [
      %{type: :chaos, description: "Each component fails independently; system recovers"},
      %{type: :chaos, description: "Resource exhaustion does not cause data corruption"},
      %{type: :chaos, description: "Concurrent access does not violate invariants"}
    ]
  end

  defp generate_performance_tests(_design) do
    [
      %{type: :performance, description: "Throughput under sustained load", target: "100 ops/sec"},
      %{type: :performance, description: "Latency P99 under load", target: "< 100ms"},
      %{type: :performance, description: "Memory growth over 24 hours", target: "< 10% growth"}
    ]
  end

  defp generate_safety_checks(_design) do
    [
      %{type: :safety, description: "No unsafe state transitions possible"},
      %{type: :safety, description: "Resource bounds are enforced"},
      %{type: :safety, description: "Failure does not corrupt shared state"},
      %{type: :safety, description: "Constitutional compliance verified"}
    ]
  end

  defp generate_acceptance_criteria(%EngineeringDesign{} = design) do
    [
      "All unit tests pass with >= 90% coverage",
      "All integration tests pass",
      "Property tests hold for 10,000 iterations",
      "Chaos tests demonstrate graceful recovery",
      "Performance within 20% of target",
      "No safety violations detected",
      "Design traceable to source principle: #{design.insight_id}"
    ]
  end

  defp estimate_duration(%EngineeringDesign{} = design) do
    component_count = length(design.components)
    component_count * 2 + 4 + 6
  end
end
