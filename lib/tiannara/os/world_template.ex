defmodule TiannaraOS.WorldTemplate do
  @moduledoc """
  Defines the structure for WorldTemplates and houses seeds for Cybersecurity,
  Robotics, and Mathematics research environments.
  """

  @derive Jason.Encoder
  defstruct [
    :id,                # atom
    :name,              # string
    :labs,              # list of map (e.g. %{id: atom, name: string})
    :goals,             # list of map (e.g. %{id: atom, description: string})
    :evidence_types,    # list of atom
    :allowed_tools      # list of atom
  ]

  @type t :: %__MODULE__{
    id: atom(),
    name: String.t(),
    labs: [map()],
    goals: [map()],
    evidence_types: [atom()],
    allowed_tools: [atom()]
  }

  @doc "Retrieves a template by its ID."
  @spec get_template(atom()) :: t() | nil
  def get_template(id) do
    Enum.find(templates(), &(&1.id == id))
  end

  @doc "Returns all registered templates."
  @spec templates() :: [t()]
  def templates do
    [
      standard_template(),
      cybersecurity_template(),
      robotics_template(),
      mathematics_template()
    ]
  end

  # --- TEMPLATE DEFINITIONS ---

  defp standard_template do
    %__MODULE__{
      id: :standard,
      name: "Standard Research Ecosystem",
      labs: [
        %{id: :discovery_lab, name: "Discovery Lab"},
        %{id: :analysis_lab_std, name: "Analysis Lab"},
        %{id: :synthesis_lab, name: "Synthesis Lab"},
        %{id: :validation_lab, name: "Validation Lab"}
      ],
      goals: [
        %{id: :knowledge_growth, description: "Grow the civilization's knowledge base through repeated discovery cycles."},
        %{id: :capability_depth, description: "Develop deep capability lineages through iterative mutation and synthesis."}
      ],
      evidence_types: [:experiment_result, :model_output, :peer_review, :synthesis_report],
      allowed_tools: [:analyzer, :simulator, :synthesizer, :validator]
    }
  end

  defp cybersecurity_template do
    %__MODULE__{
      id: :cybersecurity,
      name: "Cybersecurity Research Ecosystem",
      labs: [
        %{id: :security_lab, name: "Security Verification Lab"},
        %{id: :threat_lab, name: "Threat Vector Lab"},
        %{id: :malware_lab, name: "Malware Analysis Lab"},
        %{id: :tool_lab, name: "Offensive/Defensive Tool Lab"}
      ],
      goals: [
        %{id: :sandbox_isolation, description: "Validate container process isolation bounds."},
        %{id: :vulnerability_detection, description: "Scan generated endpoints for OWASP Top 10 vulnerabilities."}
      ],
      evidence_types: [:static_analysis, :dependency_scan, :fuzz_result, :containment_audit],
      allowed_tools: [:docker, :static_analyzer, :owasp_scanner, :fuzzer]
    }
  end

  defp robotics_template do
    %__MODULE__{
      id: :robotics,
      name: "Robotics & Kinematics Ecosystem",
      labs: [
        %{id: :control_lab, name: "Kinematics Control Lab"},
        %{id: :perception_lab, name: "Computer Vision & Perception Lab"},
        %{id: :planning_lab, name: "Path Planning Lab"},
        %{id: :safety_lab, name: "Physical Safety Loop Lab"}
      ],
      goals: [
        %{id: :path_optimality, description: "Ensure path planning resolves under 5ms latency limits."},
        %{id: :safety_override_validation, description: "Verify safety loop override prioritization invariants."}
      ],
      evidence_types: [:latency_telemetry, :simulation_run, :collision_audit],
      allowed_tools: [:simulator, :path_solver, :kinematics_validator]
    }
  end

  defp mathematics_template do
    %__MODULE__{
      id: :mathematics,
      name: "Pure Mathematics Ecosystem",
      labs: [
        %{id: :number_theory_lab, name: "Algorithmic Number Theory Lab"},
        %{id: :topology_lab, name: "Algebraic Topology Lab"},
        %{id: :analysis_lab, name: "Complex Analysis Lab"},
        %{id: :logic_lab, name: "Mathematical Logic & Proofs Lab"}
      ],
      goals: [
        %{id: :conjecture_provability, description: "Verify provable bounds of algebraic manifolds."},
        %{id: :lemma_synthesis, description: "Discover logical connections between disjoint topology structures."}
      ],
      evidence_types: [:symbolic_proof, :counterexample_run, :adjunction_mapping],
      allowed_tools: [:proof_assistant, :algebra_solver, :topology_mapper]
    }
  end
end
