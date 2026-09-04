defmodule Tiannara.REA.Observatory.RuntimeAtlas do
  @moduledoc """
  The canonical inventory of the Tiannara architecture.
  Tracks implementation, validation, interaction coverage, and criticality
  across the Civilization and Substrate layers.
  """
  use GenServer
  require Logger

  @type validation_status :: %{
    implemented: boolean(),
    instrumented: boolean(),
    validated: boolean(),
    stress_tested: boolean(),
    production_ready: boolean()
  }

  @type interaction_status :: %{
    connected_systems: [atom()],
    coverage: map(), # system => boolean
    risk: :high | :medium | :low
  }

  @type evolutionary_status :: %{
    origin_phase: String.t(),
    generation: integer(),
    predecessors: [String.t()],
    successors: [String.t()]
  }

  @type system_record :: %{
    name: atom(),
    dependencies: [atom()],
    dependents: [atom()],
    supervisor_path: String.t(),
    criticality: :critical | :high | :medium | :low,
    validation: validation_status(),
    interaction: interaction_status(),
    evolution: evolutionary_status()
  }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_) do
    state = %{systems: default_registry()}
    {:ok, state}
  end

  def get_atlas() do
    GenServer.call(__MODULE__, :get_atlas)
  end

  def handle_call(:get_atlas, _from, state) do
    {:reply, state.systems, state}
  end

  defp default_registry() do
    %{
      CIS: %{
        name: :CIS,
        dependencies: [:OCM, :CTL],
        dependents: [:Mirror, :MetaGovernor],
        supervisor_path: "Tiannara.REA.Epistemic.Supervisor",
        criticality: :high,
        validation: %{implemented: true, instrumented: true, validated: true, stress_tested: true, production_ready: false},
        interaction: %{connected_systems: [:Mirror, :OCM], coverage: %{Mirror: true, OCM: true}, risk: :medium},
        evolution: %{origin_phase: "16", generation: 3, predecessors: ["PathogenScanner"], successors: ["Constitutional Immune System"]}
      },
      Mirror: %{
        name: :Mirror,
        dependencies: [:CIS, :OCM],
        dependents: [:Forecasting],
        supervisor_path: "Tiannara.REA.Epistemic.Supervisor",
        criticality: :high,
        validation: %{implemented: true, instrumented: true, validated: true, stress_tested: true, production_ready: false},
        interaction: %{connected_systems: [:CIS], coverage: %{CIS: true}, risk: :medium},
        evolution: %{origin_phase: "17", generation: 2, predecessors: ["SelfReflector"], successors: []}
      },
      Forecasting: %{
        name: :Forecasting,
        dependencies: [:Mirror, :CTL],
        dependents: [:Discovery, :MetaGovernor],
        supervisor_path: "Tiannara.ASC.Observatory.Supervisor",
        criticality: :medium,
        validation: %{implemented: true, instrumented: true, validated: true, stress_tested: true, production_ready: false},
        interaction: %{connected_systems: [:Discovery], coverage: %{Discovery: true}, risk: :medium},
        evolution: %{origin_phase: "18", generation: 1, predecessors: [], successors: []}
      },
      OSK: %{
        name: :OSK,
        dependencies: [:HSV, :TWP, :OED, :OSE, :OCM],
        dependents: [], # Capstone of Phase II
        supervisor_path: "Tiannara.Substrate.OSK.Supervisor",
        criticality: :critical,
        validation: %{implemented: true, instrumented: true, validated: true, stress_tested: true, production_ready: false},
        interaction: %{connected_systems: [:HSV, :TWP, :OED, :OSE, :OCM], coverage: %{HSV: true, TWP: true, OED: true, OSE: true, OCM: true}, risk: :high},
        evolution: %{origin_phase: "SV-8", generation: 1, predecessors: [], successors: ["COF"]}
      },
      OED: %{
        name: :OED,
        dependencies: [:OPC, :MCAL],
        dependents: [:OSE, :OSK],
        supervisor_path: "Tiannara.Substrate.OED.Supervisor",
        criticality: :high,
        validation: %{implemented: true, instrumented: true, validated: true, stress_tested: true, production_ready: false},
        interaction: %{connected_systems: [:OSE, :OSK, :OPC], coverage: %{OSE: true, OSK: true, OPC: true}, risk: :high},
        evolution: %{origin_phase: "SV-6", generation: 1, predecessors: [], successors: []}
      },
      OSE: %{
        name: :OSE,
        dependencies: [:OED],
        dependents: [:OSK],
        supervisor_path: "Tiannara.Substrate.OSE.Supervisor",
        criticality: :high,
        validation: %{implemented: true, instrumented: true, validated: true, stress_tested: true, production_ready: false},
        interaction: %{connected_systems: [:OED, :OSK], coverage: %{OED: true, OSK: true}, risk: :high},
        evolution: %{origin_phase: "SV-7", generation: 1, predecessors: ["Capability Darwinism"], successors: []}
      },
      MetaGovernor: %{
        name: :MetaGovernor,
        dependencies: [:Forecasting, :CIS],
        dependents: [],
        supervisor_path: "Tiannara.ASC.Governance.Supervisor",
        criticality: :critical,
        validation: %{implemented: true, instrumented: true, validated: true, stress_tested: true, production_ready: false},
        interaction: %{connected_systems: [:Teleology], coverage: %{Teleology: true}, risk: :high},
        evolution: %{origin_phase: "Phase 19", generation: 2, predecessors: [], successors: []}
      },
      OCM: %{
        name: :OCM,
        dependencies: [],
        dependents: [:CIS, :CTL, :OSK],
        supervisor_path: "Tiannara.Substrate.OCM.Supervisor",
        criticality: :critical,
        validation: %{implemented: true, instrumented: true, validated: true, stress_tested: true, production_ready: true},
        interaction: %{connected_systems: [:CTL, :TWP], coverage: %{CTL: true, TWP: true}, risk: :high},
        evolution: %{origin_phase: "SV-OCM", generation: 2, predecessors: [], successors: []}
      },
      CTL: %{
        name: :CTL,
        dependencies: [],
        dependents: [:Forecasting, :OCM],
        supervisor_path: "Tiannara.Substrate.CTL.Supervisor",
        criticality: :critical,
        validation: %{implemented: true, instrumented: true, validated: true, stress_tested: true, production_ready: true},
        interaction: %{connected_systems: [:OCM, :TWP], coverage: %{OCM: true, TWP: true}, risk: :high},
        evolution: %{origin_phase: "SV-CTL", generation: 2, predecessors: [], successors: []}
      },
      TWP: %{
        name: :TWP,
        dependencies: [:CTL],
        dependents: [:OSK, :OCM],
        supervisor_path: "Tiannara.Substrate.TWP.Supervisor",
        criticality: :critical,
        validation: %{implemented: true, instrumented: true, validated: true, stress_tested: true, production_ready: true},
        interaction: %{connected_systems: [:OCM, :CTL], coverage: %{OCM: true, CTL: true}, risk: :high},
        evolution: %{origin_phase: "SV-TWP", generation: 1, predecessors: [], successors: []}
      }
    }
  end
end
