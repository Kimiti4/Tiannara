defmodule TiannaraOS.TheoryFormationResult do
  @moduledoc """
  TheoryFormationResult - Canonical constitutional transaction for institutional theory formation.
  
  This artifact captures the complete audit trail of one theory formation event, including
  source research episodes, derived theories, supporting evidence, alternative theories,
  compression statistics, confidence assessments, traceability graphs, and all constitutional deltas.
  
  ## Key Principle: Behavioral Exposure Over Algorithm Exposure
  
  Instead of exposing compression algorithms, clustering mechanisms, abstraction engines,
  or model reduction techniques, this result stores only the behavioral contract: what
  episodes were analyzed, what theories emerged, what evidence supports them, and what
  provenance connects theories back to their empirical foundations.
  
  ## Constitutional Discipline
  
  - One institutional behavior: transforming validated investigations into stable theories
  - One public API: InstitutionKernel.form_theory/2
  - One canonical transaction: TheoryFormationResult
  - No new persistent state: composes existing frozen primitives
  - Complete explainability: every theory traces back to supporting episodes
  
  ## Usage
  
      result = TheoryFormationResult.new(claim, institution_id, opts)
      result = TheoryFormationResult.add_derived_theory(result, theory_data)
      result = TheoryFormationResult.add_supporting_episode(result, episode_id)
      result = TheoryFormationResult.calculate_compression_statistics(result)
      result = TheoryFormationResult.mark_formed(result)
  """
  
  defstruct [
    # Core identification
    :formation_id,
    :institution_id,
    :tick,
    
    # Source material
    :source_episode_ids,
    :validated_episodes_count,
    
    # Derived theories
    :derived_theories,
    
    # Alternative theories (competing explanations preserved)
    :alternative_theories,
    
    # Evidence and support
    :supporting_evidence,
    
    # Compression metrics
    :compression_ratio,
    :explanatory_coverage,
    :pattern_complexity_reduction,
    
    # Confidence and quality
    :overall_confidence,
    :theory_quality_score,
    
    # Traceability
    :traceability_graph,
    
    # Constitutional deltas
    :knowledge_delta,
    :ledger_delta,
    :memory_delta,
    :lifecycle_events,
    :semantic_events,
    :governance_decisions,
    :constitutional_validation,
    
    # Status tracking
    :status,
    :failure_reason
  ]
  
  @type t :: %__MODULE__{
    formation_id: String.t(),
    institution_id: atom(),
    tick: non_neg_integer(),
    source_episode_ids: [String.t()],
    validated_episodes_count: non_neg_integer(),
    derived_theories: [map()],
    alternative_theories: [map()],
    supporting_evidence: [map()],
    compression_ratio: float() | nil,
    explanatory_coverage: float() | nil,
    pattern_complexity_reduction: float() | nil,
    overall_confidence: float(),
    theory_quality_score: float() | nil,
    traceability_graph: map(),
    knowledge_delta: map() | nil,
    ledger_delta: map() | nil,
    memory_delta: map() | nil,
    lifecycle_events: [map()],
    semantic_events: [map()],
    governance_decisions: [map()],
    constitutional_validation: map() | nil,
    status: atom(),
    failure_reason: String.t() | nil
  }
  
  @doc """
  Create a new TheoryFormationResult.
  
  ## Parameters
  
  - `institution_id`: atom() - institution forming the theory
  - `opts`: keyword list or map with optional fields
  
  ## Returns
  
  TheoryFormationResult.t()
  """
  def new(institution_id, opts \\ []) do
    opts = if is_map(opts), do: Map.to_list(opts), else: opts
    
    %__MODULE__{
      formation_id: Keyword.get(opts, :formation_id, "theory_#{institution_id}_#{System.monotonic_time(:millisecond)}"),
      institution_id: institution_id,
      tick: Keyword.get(opts, :tick, 0),
      source_episode_ids: [],
      validated_episodes_count: 0,
      derived_theories: [],
      alternative_theories: [],
      supporting_evidence: [],
      compression_ratio: nil,
      explanatory_coverage: nil,
      pattern_complexity_reduction: nil,
      overall_confidence: 0.0,
      theory_quality_score: nil,
      traceability_graph: %{
        theory_to_episodes: %{},
        episode_to_validations: %{}
      },
      knowledge_delta: nil,
      ledger_delta: nil,
      memory_delta: nil,
      lifecycle_events: [],
      semantic_events: [],
      governance_decisions: [],
      constitutional_validation: nil,
      status: :initializing,
      failure_reason: nil
    }
  end
  
  @doc """
  Add a source episode to the theory formation process.
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  - `episode_id`: String.t() - research episode identifier
  
  ## Returns
  
  TheoryFormationResult.t()
  """
  def add_source_episode(result, episode_id) do
    %{result | source_episode_ids: result.source_episode_ids ++ [episode_id]}
  end
  
  @doc """
  Set the count of validated episodes analyzed.
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  - `count`: non_neg_integer() - number of validated episodes
  
  ## Returns
  
  TheoryFormationResult.t()
  """
  def set_validated_episodes_count(result, count) do
    %{result | validated_episodes_count: count}
  end
  
  @doc """
  Add a derived theory from episode analysis.
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  - `theory_data`: map() - theory information
  
  ## Returns
  
  TheoryFormationResult.t()
  """
  def add_derived_theory(result, theory_data) do
    theory = %{
      theory_id: Map.get(theory_data, :theory_id, "theory_#{length(result.derived_theories) + 1}"),
      title: Map.get(theory_data, :title, "Untitled Theory"),
      domain: Map.get(theory_data, :domain, :general),
      explanation: Map.get(theory_data, :explanation, ""),
      confidence: Map.get(theory_data, :confidence, 0.5),
      supporting_episodes: Map.get(theory_data, :supporting_episodes, []),
      explanatory_power: Map.get(theory_data, :explanatory_power, 0.0)
    }
    
    %{result | derived_theories: result.derived_theories ++ [theory]}
  end
  
  @doc """
  Add an alternative theory (competing explanation).
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  - `theory_data`: map() - alternative theory information
  
  ## Returns
  
  TheoryFormationResult.t()
  """
  def add_alternative_theory(result, theory_data) do
    theory = %{
      theory_id: Map.get(theory_data, :theory_id, "alt_theory_#{length(result.alternative_theories) + 1}"),
      title: Map.get(theory_data, :title, "Untitled Alternative"),
      domain: Map.get(theory_data, :domain, :general),
      explanation: Map.get(theory_data, :explanation, ""),
      confidence: Map.get(theory_data, :confidence, 0.5),
      supporting_episodes: Map.get(theory_data, :supporting_episodes, []),
      reason_preserved: Map.get(theory_data, :reason_preserved, "Competing explanation")
    }
    
    %{result | alternative_theories: result.alternative_theories ++ [theory]}
  end
  
  @doc """
  Add supporting evidence from validated episodes.
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  - `episode_id`: String.t() - episode providing evidence
  - `validation_ref`: String.t() - reference to validation result
  - `confidence`: float() - confidence in evidence (0.0-1.0)
  - `relevance`: float() - relevance to theory (0.0-1.0)
  
  ## Returns
  
  TheoryFormationResult.t()
  """
  def add_supporting_evidence(result, episode_id, validation_ref, confidence, relevance) do
    evidence = %{
      episode_id: episode_id,
      validation_result_ref: validation_ref,
      confidence: confidence,
      relevance: relevance
    }
    
    %{result | supporting_evidence: result.supporting_evidence ++ [evidence]}
  end
  
  @doc """
  Calculate compression statistics from episode-to-theory ratio.
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  
  ## Returns
  
  TheoryFormationResult.t()
  """
  def calculate_compression_statistics(result) do
    episode_count = length(result.source_episode_ids)
    theory_count = length(result.derived_theories)
    
    compression_ratio = if episode_count > 0 do
      Float.round(theory_count / episode_count, 4)
    else
      0.0
    end
    
    # Estimate explanatory coverage based on supporting episodes
    total_supported_episodes = result.derived_theories
      |> Enum.flat_map(& &1.supporting_episodes)
      |> Enum.uniq()
      |> length()
    
    explanatory_coverage = if episode_count > 0 do
      Float.round(total_supported_episodes / episode_count, 4)
    else
      0.0
    end
    
    # Pattern complexity reduction (heuristic: fewer theories = more reduction)
    pattern_complexity_reduction = if episode_count > 0 and theory_count > 0 do
      Float.round(1.0 - (theory_count / episode_count), 4)
    else
      0.0
    end
    
    %{result |
      compression_ratio: compression_ratio,
      explanatory_coverage: explanatory_coverage,
      pattern_complexity_reduction: pattern_complexity_reduction
    }
  end
  
  @doc """
  Update overall confidence based on derived theories.
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  
  ## Returns
  
  TheoryFormationResult.t()
  """
  def update_overall_confidence(result) do
    if length(result.derived_theories) > 0 do
      avg_confidence = result.derived_theories
        |> Enum.map(& &1.confidence)
        |> Enum.sum()
        |> Kernel./(length(result.derived_theories))
      
      %{result | overall_confidence: Float.round(avg_confidence, 4)}
    else
      result
    end
  end
  
  @doc """
  Update traceability graph connecting theories to episodes.
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  
  ## Returns
  
  TheoryFormationResult.t()
  """
  def update_traceability_graph(result) do
    theory_to_episodes = result.derived_theories
      |> Enum.reduce(%{}, fn theory, acc ->
        Map.put(acc, theory.theory_id, theory.supporting_episodes)
      end)
    
    # Build episode to validations mapping (simplified)
    episode_to_validations = result.supporting_evidence
      |> Enum.reduce(%{}, fn evidence, acc ->
        Map.update(acc, evidence.episode_id, [evidence.validation_result_ref], &[evidence.validation_result_ref | &1])
      end)
    
    %{result |
      traceability_graph: %{
        theory_to_episodes: theory_to_episodes,
        episode_to_validations: episode_to_validations
      }
    }
  end
  
  @doc """
  Add a lifecycle event.
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  - `event`: map() - lifecycle event data
  
  ## Returns
  
  TheoryFormationResult.t()
  """
  def add_lifecycle_event(result, event) do
    %{result | lifecycle_events: result.lifecycle_events ++ [event]}
  end
  
  @doc """
  Add a semantic event.
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  - `event_type`: atom() - type of semantic event
  - `data`: map() - event data
  
  ## Returns
  
  TheoryFormationResult.t()
  """
  def add_semantic_event(result, event_type, data) do
    event = %{
      event_type: event_type,
      timestamp: DateTime.utc_now(),
      data: data
    }
    
    %{result | semantic_events: result.semantic_events ++ [event]}
  end
  
  @doc """
  Add a governance decision.
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  - `decision`: map() - governance decision data
  
  ## Returns
  
  TheoryFormationResult.t()
  """
  def add_governance_decision(result, decision) do
    %{result | governance_decisions: result.governance_decisions ++ [decision]}
  end
  
  @doc """
  Mark theory as successfully formed.
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  
  ## Returns
  
  TheoryFormationResult.t()
  """
  def mark_formed(result) do
    %{result | status: :formed}
  end
  
  @doc """
  Mark theory formation as deferred.
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  - `reason`: String.t() - reason for deferral
  
  ## Returns
  
  TheoryFormationResult.t()
  """
  def mark_deferred(result, reason) do
    %{result | status: :deferred, failure_reason: reason}
  end
  
  @doc """
  Mark theory formation as rejected.
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  - `reason`: String.t() - reason for rejection
  
  ## Returns
  
  TheoryFormationResult.t()
  """
  def mark_rejected(result, reason) do
    %{result | status: :rejected, failure_reason: reason}
  end
  
  @doc """
  Mark theory formation as failed.
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  - `reason`: String.t() - failure reason
  
  ## Returns
  
  TheoryFormationResult.t()
  """
  def mark_failed(result, reason) do
    %{result | status: :failed, failure_reason: reason}
  end
  
  @doc """
  Verify theory provenance - every theory references supporting episodes.
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  
  ## Returns
  
  boolean() - true if all theories have supporting episodes
  """
  def verify_provenance(result) do
    Enum.all?(result.derived_theories, fn theory ->
      length(theory.supporting_episodes) > 0
    end)
  end
  
  @doc """
  Verify traceability - every theory can be reconstructed from episodes.
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  
  ## Returns
  
  boolean() - true if traceability graph is complete
  """
  def verify_traceability(result) do
    # Check that all derived theories appear in traceability graph
    theory_ids = Enum.map(result.derived_theories, & &1.theory_id)
    graph_theory_ids = Map.keys(result.traceability_graph.theory_to_episodes)
    
    Enum.all?(theory_ids, & &1 in graph_theory_ids)
  end
  
  @doc """
  Check if competing theories are preserved.
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  
  ## Returns
  
  boolean() - true if multiple theories exist or alternatives preserved
  """
  def has_competing_theories?(result) do
    length(result.derived_theories) > 1 or length(result.alternative_theories) > 0
  end
  
  @doc """
  Calculate theory quality score based on confidence, coverage, and compression.
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  
  ## Returns
  
  TheoryFormationResult.t() with updated theory_quality_score
  """
  def calculate_quality_score(result) do
    if length(result.derived_theories) > 0 and result.explanatory_coverage != nil do
      # Weighted combination of confidence, coverage, and compression
      confidence_weight = 0.4
      coverage_weight = 0.4
      compression_weight = 0.2
      
      compression_score = if result.compression_ratio != nil do
        min(result.compression_ratio * 2, 1.0)  # Normalize
      else
        0.0
      end
      
      quality_score = (result.overall_confidence * confidence_weight) +
                      (result.explanatory_coverage * coverage_weight) +
                      (compression_score * compression_weight)
      
      %{result | theory_quality_score: Float.round(quality_score, 4)}
    else
      result
    end
  end
  
  @doc """
  Set constitutional validation result.
  
  ## Parameters
  
  - `result`: TheoryFormationResult.t() - target result
  - `validation`: map() - constitutional validation data
  
  ## Returns
  
  TheoryFormationResult.t()
  """
  def set_constitutional_validation(result, validation) do
    %{result | constitutional_validation: validation}
  end
end
