defmodule Tiannara.ASC.Models do
  @moduledoc "Core civilizational primitives for the Autonomous Scientific Civilization."

  defmodule Civilization do
    @moduledoc "A specialized domain of scientific expertise with its own lineage."
    defstruct [
      :id, :name, :domain, :founded_at,
      institutions: [], capabilities: [], knowledge_assets: [],
      research_programs: [], researchers: [], historical_lineage: [],
      health_metrics: %{}, status: :forming
    ]
  end

  defmodule ResearchProgram do
    @moduledoc "A funded, goal-directed research initiative within a civilization."
    defstruct [
      :id, :civilization_id, :goal, :domain,
      hypotheses: [], resources_allocated: 0, experiments: [],
      discoveries: [], impact_score: 0.0, confidence: 0.0, status: :proposed
    ]
  end

  defmodule Capability do
    @moduledoc "An evolved technological or scientific capability with lineage."
    defstruct [
      :id, :name, :domain, :lineage_id,
      dependencies: [], fitness: 0.0, adoption: 0.0, impact: 0.0,
      efficiency: 0.0, cost: 0.0, scalability: 0.0,
      civilizational_value: 0.0, status: :emerging
    ]
  end

  defmodule Institution do
    @moduledoc "A persistent structure formed from successful scientific patterns."
    defstruct [
      :id, :name, :civilization_id, :purpose,
      capabilities_managed: [], knowledge_stewarded: [],
      founding_discovery_id: nil, stability: 0.0, status: :active
    ]
  end

  defmodule KnowledgeAsset do
    @moduledoc "A validated piece of knowledge that compounds civilizational intelligence."
    defstruct [
      :id, :discovery_id, :domain, :content,
      validation_status: :unvalidated, reuse_count: 0,
      capability_enabled: nil, confidence: 0.0,
      contradictions: [], created_at: nil
    ]
  end

  defmodule ResourceAllocation do
    @moduledoc "A decision to allocate civilizational resources to a research program."
    defstruct [
      :id, :program_id, :resources, :rationale,
      expected_impact: 0.0, risk: 0.0, approval_status: :pending
    ]
  end
end
