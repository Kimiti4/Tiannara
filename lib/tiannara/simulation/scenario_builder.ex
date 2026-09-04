defmodule Tiannara.Simulation.ScenarioBuilder do
  alias Tiannara.Simulation.Domain.SimulationScenario
  alias Tiannara.Engineering.Domain.EngineeringDesign

  @spec build(EngineeringDesign.t()) :: SimulationScenario.t()
  def build(%EngineeringDesign{} = design) do
    SimulationScenario.new(%{
      design_id: design.id,
      name: "Impact simulation: #{design.name}",
      description: "Simulate the civilizational impact of deploying: #{design.description}",
      injected_changes: build_injected_changes(design),
      parameters: build_parameters(design),
      horizons: SimulationScenario.default_horizons(),
      status: :proposed
    })
  end

  @spec build_variants(EngineeringDesign.t(), non_neg_integer()) :: [SimulationScenario.t()]
  def build_variants(%EngineeringDesign{} = design, count) when count >= 1 do
    base = build(design)

    variants = Enum.map(1..count, fn i ->
      variation_factor = 0.8 + (i * 0.1)
      %{base | id: "sim_variant_#{i}_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}",
        name: "#{base.name} (variant #{i})",
        parameters: Map.merge(base.parameters, %{variation_factor: variation_factor, variant_index: i})}
    end)

    [base | variants]
  end

  @spec validate(SimulationScenario.t()) :: :ok | {:error, term()}
  def validate(%SimulationScenario{} = scenario) do
    cond do
      scenario.design_id == nil -> {:error, :missing_design_id}
      scenario.injected_changes == [] -> {:error, :no_injected_changes}
      scenario.horizons == [] -> {:error, :no_horizons}
      true -> :ok
    end
  end

  defp build_injected_changes(%EngineeringDesign{} = design) do
    component_changes = Enum.map(design.components, fn comp ->
      %{type: :add_capability, target: comp.name, description: comp.description,
        resource_cost: comp.resource_cost, complexity: comp.complexity}
    end)

    design_change = %{type: :add_engineering_design, target: design.id,
      description: design.description, domain: design.domain,
      feasibility: design.feasibility, risk: design.risk, safety_score: design.safety_score}

    [design_change | component_changes]
  end

  defp build_parameters(%EngineeringDesign{} = design) do
    %{resource_requirements: design.resource_requirements,
      estimated_effort: design.estimated_effort, feasibility: design.feasibility,
      risk: design.risk, safety_score: design.safety_score,
      component_count: length(design.components),
      architecture_pattern: Map.get(design.architecture, :pattern, :unknown),
      scaling_strategy: Map.get(design.architecture, :scaling_strategy, :unknown)}
  end
end
