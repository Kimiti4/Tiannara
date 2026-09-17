defmodule TiannaraRuntime.OS.Observatory.Screens.Screen02ScientificDiscovery do
  @moduledoc """
  Screen 2 — Scientific Discovery

  Live metrics:
  - Discoveries Today
  - Active Hypotheses
  - Validated Hypotheses
  - Failed Hypotheses
  - New Scientific Principles
  - Prediction Accuracy
  - Unknowns Created
  - Unknowns Resolved

  Timeline of discoveries
  """

  @spec get_data(map(), map()) :: map()
  def get_data(metrics, artifact_storage) do
    %{
      screen_id: 2,
      screen_name: "Scientific Discovery",
      live_metrics: [
        %{name: "Discoveries Today", value: get_discoveries_today(artifact_storage)},
        %{name: "Active Hypotheses", value: get_active_hypotheses(artifact_storage)},
        %{name: "Validated Hypotheses", value: get_validated_hypotheses(artifact_storage)},
        %{name: "Failed Hypotheses", value: get_failed_hypotheses(artifact_storage)},
        %{name: "New Scientific Principles", value: get_new_principles(artifact_storage)},
        %{name: "Prediction Accuracy", value: get_prediction_accuracy(metrics), unit: "%"},
        %{name: "Unknowns Created", value: get_unknowns_created(artifact_storage)},
        %{name: "Unknowns Resolved", value: get_unknowns_resolved(artifact_storage)}
      ],
      timeline: get_discovery_timeline(artifact_storage),
      timestamp: System.system_time(:millisecond)
    }
  end

  defp get_discoveries_today(artifact_storage) do
    since = System.system_time(:millisecond) - 86_400_000
    TiannaraRuntime.OS.Observatory.ArtifactStorage.search(artifact_storage, %{type: :discovery, since: since})
    |> length()
  end

  defp get_active_hypotheses(artifact_storage) do
    TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :hypothesis)
  end

  defp get_validated_hypotheses(artifact_storage) do
    # Count hypotheses with validation status
    0
  end

  defp get_failed_hypotheses(artifact_storage) do
    0
  end

  defp get_new_principles(artifact_storage) do
    TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :principle)
  end

  defp get_prediction_accuracy(metrics) do
    get_in(metrics, [:scientific, :prediction_success]) || 0.0
  end

  defp get_unknowns_created(artifact_storage) do
    TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :unknown)
  end

  defp get_unknowns_resolved(artifact_storage) do
    0
  end

  defp get_discovery_timeline(artifact_storage) do
    since = System.system_time(:millisecond) - 86_400_000
    TiannaraRuntime.OS.Observatory.ArtifactStorage.search(artifact_storage, %{since: since})
    |> Enum.take(50)  # Last 50 events
    |> Enum.map(fn artifact ->
      %{
        timestamp: artifact.timestamp,
        event: artifact.type,
        details: artifact.data
      }
    end)
  end
end

defmodule TiannaraRuntime.OS.Observatory.Screens.Screen03Engineering do
  @moduledoc """
  Screen 3 — Engineering

  Metrics:
  - Designs Generated
  - Optimizations
  - Experiments Running
  - Verified Designs
  - Engineering Success Rate
  - Resource Usage
  - Simulation Queue
  """

  @spec get_data(map(), map()) :: map()
  def get_data(metrics, artifact_storage) do
    %{
      screen_id: 3,
      screen_name: "Engineering",
      metrics: [
        %{name: "Designs Generated", value: get_designs_generated(artifact_storage)},
        %{name: "Optimizations", value: get_optimizations(artifact_storage)},
        %{name: "Experiments Running", value: get_experiments_running(artifact_storage)},
        %{name: "Verified Designs", value: get_verified_designs(artifact_storage)},
        %{name: "Engineering Success Rate", value: get_engineering_success_rate(metrics), unit: "%"},
        %{name: "Resource Usage", value: "0%", unit: "%"},
        %{name: "Simulation Queue", value: 0}
      ],
      timestamp: System.system_time(:millisecond)
    }
  end

  defp get_designs_generated(artifact_storage) do
    TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :engineering)
  end

  defp get_optimizations(artifact_storage) do
    TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :optimization)
  end

  defp get_experiments_running(artifact_storage) do
    TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :experiment)
  end

  defp get_verified_designs(artifact_storage) do
    0
  end

  defp get_engineering_success_rate(metrics) do
    get_in(metrics, [:engineering, :design_success]) || 0.0
  end
end

defmodule TiannaraRuntime.OS.Observatory.Screens.Screen04KnowledgeGrowth do
  @moduledoc """
  Screen 4 — Knowledge Growth

  Living graph showing:
  - Concepts
  - Relations
  - Theories
  - Domains
  - Unknowns
  - Contradictions

  Animated visualization of knowledge expanding
  """

  @spec get_data(map(), map()) :: map()
  def get_data(metrics, artifact_storage) do
    %{
      screen_id: 4,
      screen_name: "Knowledge Growth",
      graph_data: [
        %{name: "Concepts", value: get_concept_count(metrics), trend: "growing"},
        %{name: "Relations", value: get_relation_count(artifact_storage), trend: "growing"},
        %{name: "Theories", value: get_theory_count(artifact_storage), trend: "stable"},
        %{name: "Domains", value: get_domain_count(artifact_storage), trend: "stable"},
        %{name: "Unknowns", value: get_unknown_count(metrics), trend: "growing"},
        %{name: "Contradictions", value: get_contradiction_count(artifact_storage), trend: "declining"}
      ],
      timestamp: System.system_time(:millisecond)
    }
  end

  defp get_concept_count(metrics) do
    get_in(metrics, [:scientific, :knowledge_growth]) || 0
  end

  defp get_relation_count(artifact_storage) do
    TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :relation)
  end

  defp get_theory_count(artifact_storage) do
    TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :theory)
  end

  defp get_domain_count(artifact_storage) do
    TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :domain)
  end

  defp get_unknown_count(metrics) do
    get_in(metrics, [:scientific, :unknown_growth]) || 0
  end

  defp get_contradiction_count(artifact_storage) do
    TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :contradiction)
  end
end

defmodule TiannaraRuntime.OS.Observatory.Screens.Screen05OntologyEvolution do
  @moduledoc """
  Screen 5 — Ontology Evolution

  Tree visualization showing:
  - Concept Created
  - Merged
  - Split
  - Deprecated
  - Version
  - Replay
  - Archaeology

  Time slider for historical view
  """

  @spec get_data(map()) :: map()
  def get_data(artifact_storage) do
    %{
      screen_id: 5,
      screen_name: "Ontology Evolution",
      tree_data: get_ontology_tree(artifact_storage),
      evolution_events: get_evolution_events(artifact_storage),
      current_version: "v1.0",
      timestamp: System.system_time(:millisecond)
    }
  end

  defp get_ontology_tree(artifact_storage) do
    # Build tree from ontology artifacts
    %{}
  end

  defp get_evolution_events(artifact_storage) do
    TiannaraRuntime.OS.Observatory.ArtifactStorage.search(artifact_storage, %{type: :ontology_evolution})
    |> Enum.take(20)
    |> Enum.map(fn artifact ->
      %{
        timestamp: artifact.timestamp,
        event: artifact.data[:event_type],
        concept: artifact.data[:concept]
      }
    end)
  end
end

defmodule TiannaraRuntime.OS.Observatory.Screens.Screen06TheoryEcology do
  @moduledoc """
  Screen 6 — Theory Ecology

  Darwinian visualization where each theory appears as an organism:
  - Size (evidence)
  - Prediction Accuracy
  - Engineering Utility
  - Evidence
  - Competition
  - Dominance
  - Replacement

  Watch theories compete in real-time
  """

  @spec get_data(map()) :: map()
  def get_data(artifact_storage) do
    %{
      screen_id: 6,
      screen_name: "Theory Ecology",
      theories: get_theories(artifact_storage),
      competition_matrix: get_competition_matrix(artifact_storage),
      dominant_theories: get_dominant_theories(artifact_storage),
      timestamp: System.system_time(:millisecond)
    }
  end

  defp get_theories(artifact_storage) do
    TiannaraRuntime.OS.Observatory.ArtifactStorage.get_by_type(artifact_storage, :theory)
    |> Enum.map(fn artifact ->
      %{
        id: artifact.hash,
        name: get_in(artifact.data, [:name]) || "Unknown",
        evidence: get_in(artifact.data, [:evidence_count]) || 0,
        prediction_accuracy: get_in(artifact.data, [:prediction_accuracy]) || 0.0
      }
    end)
  end

  defp get_competition_matrix(artifact_storage) do
    %{}
  end

  defp get_dominant_theories(artifact_storage) do
    []
  end
end

defmodule TiannaraRuntime.OS.Observatory.Screens.Screen07RuntimeEvolution do
  @moduledoc """
  Screen 7 — Runtime Evolution

  Version history:
  - Generation 1
  - Generation 2
  - Generation 3
  - Generation 4

  Every migration visible with replay capability
  """

  @spec get_data(map()) :: map()
  def get_data(artifact_storage) do
    %{
      screen_id: 7,
      screen_name: "Runtime Evolution",
      generations: get_generations(artifact_storage),
      current_generation: "Generation 1",
      migration_history: get_migration_history(artifact_storage),
      timestamp: System.system_time(:millisecond)
    }
  end

  defp get_generations(artifact_storage) do
    TiannaraRuntime.OS.Observatory.ArtifactStorage.get_by_type(artifact_storage, :generation)
    |> Enum.map(fn artifact ->
      %{
        id: get_in(artifact.data, [:id]) || 1,
        name: get_in(artifact.data, [:name]) || "Generation 1",
        timestamp: artifact.timestamp
      }
    end)
  end

  defp get_migration_history(artifact_storage) do
    TiannaraRuntime.OS.Observatory.ArtifactStorage.get_by_type(artifact_storage, :migration)
    |> Enum.take(20)
  end
end

defmodule TiannaraRuntime.OS.Observatory.Screens.Screen08DiscoveryPipeline do
  @moduledoc """
  Screen 8 — Discovery Pipeline

  Every discovery flowing through:
  Observation → Question → Hypothesis → Experiment → Simulation → Evidence → Validation → Knowledge → Engineering

  Thousands simultaneously
  """

  @spec get_data(map()) :: map()
  def get_data(artifact_storage) do
    %{
      screen_id: 8,
      screen_name: "Discovery Pipeline",
      pipeline_stages: [
        %{name: "Observation", count: TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :observation)},
        %{name: "Question", count: TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :question)},
        %{name: "Hypothesis", count: TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :hypothesis)},
        %{name: "Experiment", count: TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :experiment)},
        %{name: "Simulation", count: TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :simulation)},
        %{name: "Evidence", count: TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :evidence)},
        %{name: "Validation", count: TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :validation)},
        %{name: "Knowledge", count: TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :knowledge)},
        %{name: "Engineering", count: TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :engineering)}
      ],
      active_discoveries: [],
      timestamp: System.system_time(:millisecond)
    }
  end
end

defmodule TiannaraRuntime.OS.Observatory.Screens.Screen09LongTermMetrics do
  @moduledoc """
  Screen 9 — Long-Term Metrics

  The most important page. Not CPU/RAM, but:
  - Knowledge Growth Rate
  - Scientific Discovery Velocity
  - Engineering Velocity
  - Replay Cost
  - Archaeology Cost
  - Unknown Density
  - Ontology Expansion
  - Theory Turnover
  - Prediction Accuracy
  - Optimization Yield
  - Discovery Efficiency
  - Scientific ROI
  - Civilizational Benefit Score
  """

  @spec get_data(map()) :: map()
  def get_data(metrics) do
    %{
      screen_id: 9,
      screen_name: "Long-Term Metrics",
      metrics: [
        %{name: "Knowledge Growth Rate", value: "#{get_in(metrics, [:scientific, :knowledge_growth]) || 0} concepts/day"},
        %{name: "Scientific Discovery Velocity", value: "#{get_in(metrics, [:scientific, :discovery_rate]) || 0} discoveries/day"},
        %{name: "Engineering Velocity", value: "0 designs/day"},
        %{name: "Replay Cost", value: "0 ms"},
        %{name: "Archaeology Cost", value: "0 ms"},
        %{name: "Unknown Density", value: "0.0"},
        %{name: "Ontology Expansion", value: "0.0"},
        %{name: "Theory Turnover", value: "0.0"},
        %{name: "Prediction Accuracy", value: "#{get_in(metrics, [:scientific, :prediction_success]) || 0.0}%"},
        %{name: "Optimization Yield", value: "0.0"},
        %{name: "Discovery Efficiency", value: "0.0"},
        %{name: "Scientific ROI", value: "0.0x"},
        %{name: "Civilizational Benefit Score", value: "0.0"}
      ],
      timestamp: System.system_time(:millisecond)
    }
  end
end

defmodule TiannaraRuntime.OS.Observatory.Screens.Screen10Evolution do
  @moduledoc """
  Screen 10 — Evolution

  Watch Tiannara improve itself:
  Candidate → Validation → Sandbox → Deployment → Certification → Production

  Each self-improvement shown
  """

  @spec get_data(map()) :: map()
  def get_data(artifact_storage) do
    %{
      screen_id: 10,
      screen_name: "Evolution",
      evolution_pipeline: [
        %{stage: "Candidate", count: TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :candidate)},
        %{stage: "Validation", count: TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :validation)},
        %{stage: "Sandbox", count: TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :sandbox)},
        %{stage: "Deployment", count: TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :deployment)},
        %{stage: "Certification", count: TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :certification)},
        %{stage: "Production", count: TiannaraRuntime.OS.Observatory.ArtifactStorage.count_by_type(artifact_storage, :production)}
      ],
      recent_evolutions: [],
      timestamp: System.system_time(:millisecond)
    }
  end
end

defmodule TiannaraRuntime.OS.Observatory.Screens.Screen11PlanetaryTwin do
  @moduledoc """
  Screen 11 — Planetary Twin

  Once Phase 23 begins:
  Earth visualization with layers:
  - Climate
  - Energy
  - Agriculture
  - Transportation
  - Economy
  - Infrastructure
  - Ecology
  - Scientific Infrastructure

  Everything updates continuously
  """

  @spec get_data(map()) :: map()
  def get_data(metrics) do
    %{
      screen_id: 11,
      screen_name: "Planetary Twin",
      status: "Phase 23 — Pending",
      layers: [
        %{name: "Climate", status: :inactive},
        %{name: "Energy", status: :inactive},
        %{name: "Agriculture", status: :inactive},
        %{name: "Transportation", status: :inactive},
        %{name: "Economy", status: :inactive},
        %{name: "Infrastructure", status: :inactive},
        %{name: "Ecology", status: :inactive},
        %{name: "Scientific Infrastructure", status: :inactive}
      ],
      planetary_metrics: Map.get(metrics, :planetary, %{}),
      timestamp: System.system_time(:millisecond)
    }
  end
end

defmodule TiannaraRuntime.OS.Observatory.Screens.Screen12MissionTimeline do
  @moduledoc """
  Screen 12 — Mission Timeline

  Spacecraft-style timeline showing months/years:
  Discoveries → Engineering → Optimization → Evolution → Milestones → Certification
  """

  @spec get_data(map()) :: map()
  def get_data(artifact_storage) do
    %{
      screen_id: 12,
      screen_name: "Mission Timeline",
      timeline: get_timeline(artifact_storage),
      milestones: get_milestones(),
      timestamp: System.system_time(:millisecond)
    }
  end

  defp get_timeline(artifact_storage) do
    TiannaraRuntime.OS.Observatory.ArtifactStorage.search(artifact_storage, %{})
    |> Enum.take(100)
    |> Enum.map(fn artifact ->
      %{
        timestamp: artifact.timestamp,
        event: artifact.type,
        details: artifact.data,
        hash: artifact.hash
      }
    end)
  end

  defp get_milestones() do
    [
      %{name: "Phase 18 — Cognitive OS Complete", timestamp: System.system_time(:millisecond)},
      %{name: "Phase 20 — CSOS v1.0 Frozen", timestamp: System.system_time(:millisecond)},
      %{name: "Phase 22 — Civilizational Intelligence", timestamp: System.system_time(:millisecond)},
      %{name: "Phase 22.X — Certification Framework", timestamp: System.system_time(:millisecond)},
      %{name: "Phase 23.0 — Observatory Operational", timestamp: System.system_time(:millisecond)}
    ]
  end
end
