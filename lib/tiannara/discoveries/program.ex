defmodule Tiannara.Discoveries.Program do
  @moduledoc """
  Represents a high-level scientific Research Program.
  """
  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
    :goal,
    :objective,
    :hypotheses,    # List of hypotheses texts
    :discoveries,   # List of discovery IDs
    :laws,          # List of law IDs
    :theories,      # List of theory IDs
    :interventions, # List of intervention IDs
    :unknowns,      # List of unknown IDs
    :experiments,   # List of experiment names/IDs
    :status,        # :active | :paused | :completed
    :timestamp
  ]

  @file_path "data/programs.ndjson"

  @doc """
  Loads all programs from persistence.
  """
  def all do
    if File.exists?(@file_path) do
      @file_path
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == ""))
      |> Stream.map(fn line ->
        case Jason.decode(line, keys: :atoms) do
          {:ok, attrs} -> 
            attrs = Map.update!(attrs, :status, &String.to_atom(to_string(&1)))
            struct(__MODULE__, attrs)
          _ -> nil
        end
      end)
      |> Stream.reject(&is_nil/1)
      |> Enum.to_list()
    else
      list = seeds()
      write_all(list)
      list
    end
  end

  @doc """
  Saves a single program.
  """
  def save(%__MODULE__{} = program) do
    File.mkdir_p!(Path.dirname(@file_path))
    program = %{program | timestamp: program.timestamp || DateTime.utc_now() |> DateTime.to_iso8601()}
    line = Jason.encode!(program) <> "\n"
    File.write!(@file_path, line, [:append])
    {:ok, program}
  end

  @doc """
  Saves all programs back to the file.
  """
  def write_all(list) do
    File.mkdir_p!(Path.dirname(@file_path))
    content = Enum.map(list, fn program -> Jason.encode!(program) <> "\n" end) |> Enum.join("")
    File.write!(@file_path, content)
    :ok
  end

  def seeds do
    [
      %__MODULE__{
        id: "generativity_physics",
        name: "Generativity Physics",
        goal: "Discover retention laws",
        objective: "Discover how memory retention influences possibility spaces emergence",
        hypotheses: ["Structured Forgetting", "Memory Capital", "Generative orbits are sustained by identity preservation"],
        discoveries: ["structured_forgetting", "generative_orbit_equivalence", "identity_sustained_regeneration"],
        laws: ["structured_forgetting", "generative_orbit_equivalence", "identity_sustained_regeneration"],
        theories: ["adaptive_memory_ecology"],
        interventions: ["int1"],
        unknowns: ["un1"],
        experiments: ["Phase 11.6", "Phase 11.7", "Phase 11.8"],
        status: :active,
        timestamp: "2026-06-11T12:00:00Z"
      },
      %__MODULE__{
        id: "constitutional_navigation",
        name: "Constitutional Navigation",
        goal: "Discover laws governing adaptive steering",
        objective: "Evolve dynamic navigation genomes that steer systems through phase spaces",
        hypotheses: ["Metaplastic governance is optimal under uncertainty"],
        discoveries: ["scp_retention_boundary"],
        laws: ["scp_retention_boundary"],
        theories: ["regenerative_governance", "uncertainty_weighted_governance"],
        interventions: ["int2"],
        unknowns: ["un2"],
        experiments: ["Phase 10", "Phase 10.5"],
        status: :active,
        timestamp: "2026-06-11T12:00:00Z"
      },
      %__MODULE__{
        id: "research_optimization",
        name: "Research Optimization",
        goal: "Improve Tiannara's ability to discover valid laws",
        objective: "Calibrate specialists, optimize experiment quality, and adjust audit sensitivities",
        hypotheses: ["Feedback loop from validation improves discovery criteria"],
        discoveries: [],
        laws: [],
        theories: [],
        interventions: [],
        unknowns: [],
        experiments: [],
        status: :active,
        timestamp: "2026-06-11T12:00:00Z"
      },
      # --- NEW DOMAIN RESEARCH PROGRAMS ---
      %__MODULE__{
        id: "resilient_systems",
        name: "Resilient Systems",
        goal: "Evolve structures with high topological resilience",
        objective: "Minimize structural failures under shock",
        hypotheses: ["Metaplastic damping prevents cascades"],
        discoveries: ["generative_orbit_equivalence"],
        laws: [],
        theories: [],
        interventions: [],
        unknowns: [],
        experiments: [],
        status: :active,
        timestamp: "2026-06-11T18:00:00Z"
      },
      %__MODULE__{
        id: "adaptive_architecture",
        name: "Adaptive Architecture",
        goal: "Optimize physical layout configurations",
        objective: "Determine recovery bounds under stress",
        hypotheses: ["Variable retention shapes possibility space emergence"],
        discoveries: ["structured_forgetting"],
        laws: [],
        theories: [],
        interventions: [],
        unknowns: [],
        experiments: [],
        status: :active,
        timestamp: "2026-06-11T18:00:00Z"
      },
      %__MODULE__{
        id: "adaptive_treatment_systems",
        name: "Adaptive Treatment Systems",
        goal: "Optimize treatment pathways under stress",
        objective: "Balance organism structural integrity",
        hypotheses: ["Dynamic modulation of biological parameters increases survivability"],
        discoveries: [],
        laws: [],
        theories: [],
        interventions: [],
        unknowns: [],
        experiments: [],
        status: :active,
        timestamp: "2026-06-11T18:00:00Z"
      },
      %__MODULE__{
        id: "biological_resilience",
        name: "Biological Resilience",
        goal: "Verify biological recovery transitions",
        objective: "Track identity survival thresholds",
        hypotheses: ["Identity preservation keeps cells within survival attractors"],
        discoveries: ["identity_sustained_regeneration"],
        laws: [],
        theories: [],
        interventions: [],
        unknowns: [],
        experiments: [],
        status: :active,
        timestamp: "2026-06-11T18:00:00Z"
      },
      %__MODULE__{
        id: "uncertainty_allocation",
        name: "Uncertainty Allocation",
        goal: "Dynamically distribute authority bounds based on environmental volatility",
        objective: "Minimize systemic friction and control violations",
        hypotheses: ["Decentralized constraint modulation outperforms centralized interference"],
        discoveries: [],
        laws: [],
        theories: [],
        interventions: [],
        unknowns: [],
        experiments: [],
        status: :active,
        timestamp: "2026-06-11T18:00:00Z"
      },
      %__MODULE__{
        id: "adaptive_computation",
        name: "Adaptive Computation",
        goal: "Optimize dynamic algorithmic memory retention parameters",
        objective: "Scale algorithmic efficiency under computational constraints",
        hypotheses: ["Dynamic memory forgetting rates prevent model collapse"],
        discoveries: ["generative_orbit_equivalence"],
        laws: [],
        theories: [],
        interventions: [],
        unknowns: [],
        experiments: [],
        status: :active,
        timestamp: "2026-06-11T18:00:00Z"
      },
      %__MODULE__{
        id: "memory_ecology",
        name: "Memory Ecology",
        goal: "Verify Structured Forgetting under memory load",
        objective: "Preserve possibility spaces in high-throughput network channels",
        hypotheses: ["Intermediate retention maximizes information entropy"],
        discoveries: ["structured_forgetting"],
        laws: [],
        theories: [],
        interventions: [],
        unknowns: [],
        experiments: [],
        status: :active,
        timestamp: "2026-06-11T18:00:00Z"
      },
      %__MODULE__{
        id: "autonomous_resilience",
        name: "Autonomous Resilience",
        goal: "Design mechanical systems that recover from physical failures",
        objective: "Establish feedback control loop benchmarks",
        hypotheses: ["Evolving local sensor networks prevents macro failure modes"],
        discoveries: [],
        laws: [],
        theories: [],
        interventions: [],
        unknowns: [],
        experiments: [],
        status: :active,
        timestamp: "2026-06-11T18:00:00Z"
      },
      %__MODULE__{
        id: "embodied_adaptation",
        name: "Embodied Adaptation",
        goal: "Evolve robot physical morphology steering",
        objective: "Adapt physical constraints locally under kinematic load",
        hypotheses: ["Morphological shape-shifting prevents inelastic trapping"],
        discoveries: [],
        laws: [],
        theories: [],
        interventions: [],
        unknowns: [],
        experiments: [],
        status: :active,
        timestamp: "2026-06-11T18:00:00Z"
      },
      %__MODULE__{
        id: "energy_network_adaptation",
        name: "Energy Network Adaptation",
        goal: "Maximize power grid recoverability under load spikes",
        objective: "Calibrate transmission thresholds dynamically",
        hypotheses: ["Decentralized grid nodes adjust parameters to contain cascades"],
        discoveries: [],
        laws: [],
        theories: [],
        interventions: [],
        unknowns: [],
        experiments: [],
        status: :active,
        timestamp: "2026-06-11T18:00:00Z"
      },
      %__MODULE__{
        id: "market_navigation_dynamics",
        name: "Market Navigation Dynamics",
        goal: "Track resource routing and price signals",
        objective: "Evolve transaction stability rules",
        hypotheses: ["Market optionality is maximized under intermediate regulation bounds"],
        discoveries: [],
        laws: [],
        theories: [],
        interventions: [],
        unknowns: [],
        experiments: [],
        status: :active,
        timestamp: "2026-06-11T18:00:00Z"
      },
      %__MODULE__{
        id: "recursive_control_systems",
        name: "Recursive Control Systems",
        goal: "Build feedback networks for negative entropy",
        objective: "Control error drift rates dynamically",
        hypotheses: ["Cybernetic control loops prevent topological decay"],
        discoveries: [],
        laws: [],
        theories: [],
        interventions: [],
        unknowns: [],
        experiments: [],
        status: :active,
        timestamp: "2026-06-11T18:00:00Z"
      },
      %__MODULE__{
        id: "intelligence_evolution",
        name: "Intelligence Evolution",
        goal: "Track mental model speciation and reasoning depth",
        objective: "Validate reasoning provenance dynamically",
        hypotheses: ["Deliberate friction filters structurally incoherent models"],
        discoveries: [],
        laws: [],
        theories: [],
        interventions: [],
        unknowns: [],
        experiments: [],
        status: :active,
        timestamp: "2026-06-11T18:00:00Z"
      },
      %__MODULE__{
        id: "adaptation_geometry",
        name: "Adaptation Geometry",
        goal: "Map phase space transitions mathematically",
        objective: "Formalize attractor classifications",
        hypotheses: ["Agglomerative clustering identifies persistent attractors"],
        discoveries: ["generative_orbit_equivalence"],
        laws: [],
        theories: [],
        interventions: [],
        unknowns: [],
        experiments: [],
        status: :active,
        timestamp: "2026-06-11T18:00:00Z"
      }
    ]
  end
end
