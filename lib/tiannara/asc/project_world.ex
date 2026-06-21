defmodule Tiannara.ASC.ProjectWorld do
  @moduledoc """
  Shared representational substrate for all ASC phase civilizations.

  The `%ProjectWorld{}` is the central typed data model that flows through
  the entire 10-phase pipeline. Each civilization reads from it and writes
  its outputs back into it, ensuring coherent state across all phases.

  This mirrors how `TiannaraOS.State` flows through REA civilizations,
  but specialized for software engineering artifacts.

  ## Population Timeline

      Requirements  → invariants, capabilities, constraints, risks, acceptance_criteria
      Architecture  → components, interfaces, dependencies, architecture_style
      Testing       → test_contracts, property_specs, coverage_targets   ← BEFORE implementation
      Implementation → source_files
      Operations    → health (continuously updated)

  ## Key Design Principle

  Testing populates `test_contracts` **before** Implementation writes any code.
  The contracts define "what success looks like" and serve as the specification
  that the Implementation Civilization must satisfy.
  """

  alias Tiannara.ASC.ProjectWorld.{Invariant, Capability, Constraint, Risk, TestContract}

  @derive Jason.Encoder

  defstruct [
    # From Requirements Civilization
    invariants: [],
    capabilities: [],
    constraints: [],
    risks: [],
    acceptance_criteria: [],

    # From Architecture Civilization
    components: %{},
    interfaces: [],
    dependencies: [],
    architecture_style: nil,

    # From Testing Civilization (populated BEFORE Implementation)
    test_contracts: [],
    property_specs: [],
    coverage_targets: %{invariants: 1.0, capabilities: 0.95, integration: 0.90},

    # From Implementation Civilization
    source_files: [],

    # Living state — updated by Operations
    health: %{},
    version: 0
  ]

  @type architecture_style ::
    :modular_monolith | :microservices | :event_driven | :actor_based | :hybrid | nil

  @type t :: %__MODULE__{
    invariants: [Invariant.t()],
    capabilities: [Capability.t()],
    constraints: [Constraint.t()],
    risks: [Risk.t()],
    acceptance_criteria: [String.t()],
    components: %{String.t() => map()},
    interfaces: [map()],
    dependencies: [map()],
    architecture_style: architecture_style(),
    test_contracts: [TestContract.t()],
    property_specs: [map()],
    coverage_targets: map(),
    source_files: [map()],
    health: map(),
    version: non_neg_integer()
  }

  @doc "Create a fresh, empty world for a new project."
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc "Apply Requirements Civilization output — populates the specification layer."
  @spec put_requirements(t(), [Invariant.t()], [Capability.t()], [Constraint.t()], [Risk.t()], [String.t()]) :: t()
  def put_requirements(%__MODULE__{} = world, invariants, capabilities, constraints, risks, acceptance_criteria) do
    %{world |
      invariants: invariants,
      capabilities: capabilities,
      constraints: constraints,
      risks: risks,
      acceptance_criteria: acceptance_criteria,
      version: world.version + 1
    }
  end

  @doc "Apply Architecture Civilization output."
  @spec put_architecture(t(), architecture_style(), map(), [map()], [map()]) :: t()
  def put_architecture(%__MODULE__{} = world, architecture_style, components, interfaces, dependencies) do
    %{world |
      architecture_style: architecture_style,
      components: components,
      interfaces: interfaces,
      dependencies: dependencies,
      version: world.version + 1
    }
  end

  @doc "Apply Testing Civilization output — test contracts BEFORE implementation."
  @spec put_test_contracts(t(), [TestContract.t()], [map()], map() | nil) :: t()
  def put_test_contracts(%__MODULE__{} = world, test_contracts, property_specs \\ [], coverage_targets \\ nil) do
    %{world |
      test_contracts: test_contracts,
      property_specs: property_specs,
      coverage_targets: coverage_targets || world.coverage_targets,
      version: world.version + 1
    }
  end

  @doc "Apply Implementation Civilization output."
  @spec put_source_files(t(), [map()]) :: t()
  def put_source_files(%__MODULE__{} = world, source_files) do
    %{world | source_files: source_files, version: world.version + 1}
  end

  @doc "Update the world health record (called by Operations Civilization)."
  @spec update_health(t(), map()) :: t()
  def update_health(%__MODULE__{} = world, health_update) do
    %{world | health: Map.merge(world.health, health_update), version: world.version + 1}
  end

  @doc "Compute a summary of the requirements surface and test coverage."
  @spec requirements_surface(t()) :: map()
  def requirements_surface(%__MODULE__{} = world) do
    %{
      invariants: length(world.invariants),
      capabilities: length(world.capabilities),
      constraints: length(world.constraints),
      risks: length(world.risks),
      test_contracts: length(world.test_contracts),
      coverage_ratio: coverage_ratio(world)
    }
  end

  @doc "True if the world has enough specification to proceed to Testing."
  @spec requirements_complete?(t()) :: boolean()
  def requirements_complete?(%__MODULE__{} = world) do
    length(world.capabilities) > 0 or length(world.invariants) > 0
  end

  @doc "True if TestContracts have been generated (Testing Civilization has run)."
  @spec test_contracts_ready?(t()) :: boolean()
  def test_contracts_ready?(%__MODULE__{test_contracts: tc}), do: length(tc) > 0

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp coverage_ratio(%__MODULE__{test_contracts: [], invariants: [], capabilities: []}), do: 0.0
  defp coverage_ratio(%__MODULE__{} = world) do
    covered = length(world.test_contracts)
    total   = length(world.invariants) + length(world.capabilities)
    if total > 0, do: Float.round(covered / total, 4), else: 0.0
  end
end
