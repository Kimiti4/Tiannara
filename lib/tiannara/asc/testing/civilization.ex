defmodule Tiannara.ASC.Testing.Supervisor do
  use Supervisor
  def start_link(opts \\ []), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_), do: Supervisor.init([Tiannara.ASC.Testing.Civilization], strategy: :one_for_one)
end

defmodule Tiannara.ASC.Testing.Civilization do
  @moduledoc """
  Testing Civilization (Phase E — active).

  Generates `%TestContract{}` structs from the `ProjectWorld` **before** the
  Implementation Civilization writes any code.

  ASC learns "what success looks like" before writing code — this is the
  critical architectural distinction from "Architecture → Code" pipelines.

  ## Contract Generation Rules

  | Source             | Contract Type    | Priority |
  |--------------------|------------------|----------|
  | Invariant (must)   | :property        | :critical |
  | Invariant (should) | :property        | :high    |
  | Capability         | :unit            | :high    |
  | Capability (cross) | :integration     | :medium  |
  | Constraint         | :load            | :high    |
  | Risk (score > 0.4) | :security        | depends  |

  ## Outputs

  - `project.world.test_contracts` — populated TestContract list
  - `data/asc_projects/<id>/docs/test_contracts.json` — persisted
  - Observatory: `test_effectiveness: 0.0` (updated by Crucible after code exists)
  """

  use GenServer
  require Logger

  alias Tiannara.ASC.{Project, ProjectWorld}
  alias Tiannara.ASC.ProjectWorld.{Invariant, Capability, Constraint, Risk, TestContract}
  alias Tiannara.ASC.Observatory.ProjectObservatory

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @spec run(Project.t()) :: {:ok, Project.t()} | {:error, term()}
  def run(%Project{world: nil} = project) do
    Logger.warning("[ASC.Testing] No world model on project #{project.id} — skipping")
    {:error, :no_world_model}
  end

  def run(%Project{} = project) do
    Logger.info("[ASC.Testing] Generating test contracts for project #{project.id}")

    world = project.world

    contracts =
      contracts_from_invariants(world.invariants) ++
      contracts_from_capabilities(world.capabilities) ++
      contracts_from_constraints(world.constraints) ++
      contracts_from_risks(world.risks)

    Logger.info(
      "[ASC.Testing] Generated #{length(contracts)} contracts — " <>
      "property=#{count_type(contracts, :property)}, " <>
      "unit=#{count_type(contracts, :unit)}, " <>
      "integration=#{count_type(contracts, :integration)}, " <>
      "load=#{count_type(contracts, :load)}, " <>
      "security=#{count_type(contracts, :security)}"
    )

    updated_world = ProjectWorld.put_test_contracts(world, contracts)
    updated = %{project | world: updated_world, updated_at: DateTime.utc_now()}

    persist_contracts(project.id, contracts)

    ProjectObservatory.record(project.id, %{
      test_effectiveness:  0.0,
      bug_discovery_rate:  0.0,
      test_contract_count: length(contracts),
      critical_contracts:  Enum.count(contracts, &(&1.priority == :critical))
    })

    {:ok, updated}
  rescue
    e ->
      Logger.error("[ASC.Testing] Failed for #{project.id}: #{Exception.message(e)}")
      {:error, e}
  end

  @impl true
  def init(_opts) do
    Logger.info("[ASC.Testing] Civilization initialized")
    {:ok, %{}}
  end

  # ---------------------------------------------------------------------------
  # Contract generators
  # ---------------------------------------------------------------------------

  defp contracts_from_invariants(invariants) do
    Enum.map(invariants, fn %Invariant{} = inv ->
      module = module_name_from(inv.statement) <> "InvariantTest"
      fn_name = "property #{truncate(inv.statement, 60)}"

      TestContract.new(:property, inv.id, :invariant,
        "Property: #{inv.statement}",
        test_module_name: module,
        test_function_name: fn_name,
        expected_behavior: inv.negation_form || "#{inv.statement} holds for all valid inputs",
        priority: (if inv.strength == :must, do: :critical, else: :high),
        coverage_dimension: :invariants,
        property_spec: %{
          generator: "StreamData.term()",
          assertion: inv.negation_form || inv.statement,
          runs: 1000,
          shrink: true,
          domain: inv.domain
        },
        tags: inv.tags ++ [Atom.to_string(inv.domain)]
      )
    end)
  end

  defp contracts_from_capabilities(capabilities) do
    Enum.flat_map(capabilities, fn %Capability{} = cap ->
      module = module_name_from(cap.name) <> "Test"

      unit = TestContract.new(:unit, cap.id, :capability,
        "Unit: #{cap.name}",
        test_module_name: module,
        test_function_name: "test #{cap.name} succeeds with valid inputs",
        expected_behavior: "#{cap.name} completes successfully with valid inputs",
        priority: :high,
        coverage_dimension: :capabilities,
        tags: cap.tags
      )

      integration = if integration_worthy?(cap) do
        [TestContract.new(:integration, cap.id, :capability,
          "Integration: #{cap.name} — cross-boundary",
          test_module_name: module <> "Integration",
          test_function_name: "test #{cap.name} propagates across boundaries",
          expected_behavior: "#{cap.name} propagates correctly across system boundaries",
          priority: :medium,
          coverage_dimension: :integration,
          tags: cap.tags ++ ["integration"]
        )]
      else
        []
      end

      [unit | integration]
    end)
  end

  defp contracts_from_constraints(constraints) do
    Enum.map(constraints, fn %Constraint{} = con ->
      assertion = Constraint.to_test_assertion(con)
      priority  = if con.type == :availability, do: :critical, else: :high

      TestContract.new(:load, con.id, :constraint,
        "Load: #{assertion}",
        test_function_name: "test #{con.metric} satisfies #{con.type} constraint",
        expected_behavior: assertion,
        priority: priority,
        coverage_dimension: :performance,
        property_spec: %{
          type:     con.type,
          metric:   con.metric,
          operator: con.operator,
          value:    con.value,
          unit:     con.unit
        },
        tags: [Atom.to_string(con.type), "non_functional"]
      )
    end)
  end

  defp contracts_from_risks(risks) do
    risks
    |> Enum.filter(&Risk.requires_test?/1)
    |> Enum.map(fn %Risk{} = risk ->
      priority = if risk.risk_score > 0.6, do: :critical, else: :high

      TestContract.new(:security, risk.id, :risk,
        "Security: #{truncate(risk.description, 80)}",
        test_function_name: "test defense against #{risk.category}",
        expected_behavior: "System correctly handles: #{truncate(risk.description, 60)}",
        priority: priority,
        coverage_dimension: :security,
        property_spec: %{
          risk_category: risk.category,
          probability:   risk.probability,
          severity:      risk.severity,
          adversarial:   Risk.requires_adversarial?(risk)
        },
        tags: [Atom.to_string(risk.category), "adversarial"]
      )
    end)
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp integration_worthy?(%Capability{} = cap) do
    cross_boundary_verbs = ~w(transfer send notify sync publish broadcast export import)
    String.contains?(String.downcase(cap.verb), cross_boundary_verbs) or
      length(cap.preconditions) > 0 or
      length(cap.postconditions) > 0
  end

  defp module_name_from(text) do
    text
    |> String.split(~r/\W+/)
    |> Enum.filter(&(String.length(&1) > 2))
    |> Enum.take(3)
    |> Enum.map(&String.capitalize/1)
    |> Enum.join()
  end

  defp count_type(contracts, type) do
    Enum.count(contracts, &(&1.type == type))
  end

  defp truncate(str, max) do
    if String.length(str) <= max, do: str, else: String.slice(str, 0, max) <> "…"
  end

  defp persist_contracts(project_id, contracts) do
    dir  = Path.join(["data", "asc_projects", project_id, "docs"])
    File.mkdir_p!(dir)
    path = Path.join(dir, "test_contracts.json")
    File.write!(path, Jason.encode!(contracts, pretty: true))
    Logger.debug("[ASC.Testing] Persisted #{length(contracts)} contracts to #{path}")
  rescue
    e -> Logger.warning("[ASC.Testing] Could not persist: #{Exception.message(e)}")
  end
end
