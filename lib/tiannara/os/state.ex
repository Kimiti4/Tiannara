defmodule TiannaraOS.State do
  @moduledoc """
  Canonical state substrate for TiannaraOS.
  All subsystems, worlds, and execution layers read and write through this single struct.
  """

  @derive Jason.Encoder
  defstruct [
    worlds: %{},
    theories: %{},
    institutions: %{},
    tools: %{},
    evidence_graph: %{},
    discoveries: %{},
    research_programs: %{},
    collaborators: %{},
    discovery_assets: %{},
    memory: %{},
    economy: %{},
    security: %{},
    governance: %{},
    dependency_history: [],
    capabilities: %{},             # LAYER 6.5D: Civilization Level Capability Graph
    
    # LAYER 6.5D: INSTITUTIONAL EVOLUTION ⭐ NEW
    program_graveyard: %{},        # Institutional memory (dead programs)
    species_registry: %{},         # Species tracking (SpeciationEngine)
    world_epistemic_physics: %{},  # World physics profiles
    institution_registry: %{},     # Institution-level tracking
    
    # PERFORMANCE OPTIMIZATIONS
    metadata: %{},
    world_program_index: %{},
    world_population_cache: %{},
    maturation_queue: %{},
    reproduction_candidates: %{},
    tick_discoveries: []
  ]

  @type t :: %__MODULE__{
    worlds: map(),
    theories: map(),
    institutions: map(),
    tools: %{atom() => TiannaraOS.ToolGenome.t()},
    evidence_graph: %{atom() => TiannaraOS.EvidenceNode.t()},
    discoveries: %{atom() => TiannaraOS.Discovery.t()},
    research_programs: %{atom() => TiannaraOS.ResearchProgram.t()},
    collaborators: %{atom() => TiannaraOS.HumanCollaborator.t()},
    discovery_assets: map(),
    memory: map(),
    economy: map(),
    security: map(),
    governance: map(),
    dependency_history: [any()],
    capabilities: map(),
    
    # LAYER 6.5D FIELDS
    program_graveyard: %{atom() => map()},
    species_registry: %{atom() => map()},
    world_epistemic_physics: %{atom() => TiannaraOS.WorldEpistemicPhysics.t()},
    institution_registry: %{atom() => map()},
    
    # PERFORMANCE OPTIMIZATIONS
    metadata: map(),
    world_program_index: %{atom() => MapSet.t()},
    world_population_cache: %{atom() => map()},
    maturation_queue: %{integer() => [atom()]},
    reproduction_candidates: map(),
    tick_discoveries: [atom()]
  }
end
