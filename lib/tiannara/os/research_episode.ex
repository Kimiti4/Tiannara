defmodule TiannaraOS.ResearchEpisode do
  @moduledoc """
  ResearchEpisode - Constitutional primitive representing the fundamental unit of institutional memory.
  
  An Episode is NOT a subsystem or artifact type—it is a semantic container that groups
  related canonical transactions into coherent scientific investigations. Every institutional
  action belongs to exactly one immutable Research Episode (Principle 12 — Episodic Integrity).
  
  Episodes are referenced by:
  - Knowledge Graph (indexing and relationship tracking)
  - Memory Pipeline (semantic compression and retrieval)
  - JTMS++ (justification chains spanning investigations)
  - Discovery Exchange (rich collaboration units)
  - Topological Knowledge (supports/contradicts/extends/replicates relationships)
  - Distributed Validation (complete investigation validation)
  - Phase 13 (institutional self-improvement through episodic analysis)
  
  ## Constitutional Hierarchy
  
      Institution
          │
          ▼
      Research Episode (belongs to exactly one Institution)
          │
       ┌──┼──────────────────────────────┐
       │  │          │          │         │
       ▼  ▼          ▼          ▼         ▼
  ResearchCycle BeliefRevision Publication Consensus Validation ...
  
  ## Key Constraints
  
  - Every canonical transaction belongs to exactly ONE Episode
  - Every Episode belongs to exactly ONE Institution
  - Nothing exists outside an Episode
  - Episodes are immutable containers that reference transactions (never duplicate them)
  - Full transactions can always be reconstructed from immutable storage
  
  ## Example Usage
  
      episode = ResearchEpisode.new(:medicine_inst, "cancer_treatment_investigation")
      episode = ResearchEpisode.add_research_cycle(episode, research_cycle_result)
      episode = ResearchEpisode.add_belief_revision(episode, belief_revision_result)
      episode = ResearchEpisode.finalize(episode)
      
      # Later: retrieve episode references (lightweight)
      ExperienceRetrievalResult contains episode IDs
      Full transactions reconstructed from Knowledge Graph via episode.transaction_references
      
  """
  
  @derive Jason.Encoder
  defstruct [
    # ==================== Episode Identity ====================
    :episode_id,                    # String.t() - unique episode identifier
    :institution_id,                # atom() - owning institution (exactly one)
    :created_tick,                  # integer() - tick when episode was created
    :finalized_tick,                # integer() | nil - tick when episode was finalized (nil if active)
    :status,                        # atom() - :active | :finalized | :archived
    
    # ==================== Semantic Description ====================
    :topic,                         # String.t() - semantic topic/theme of investigation
    :description,                   # String.t() - detailed description of investigation goals
    :keywords,                      # [String.t()] - searchable keywords for semantic retrieval
    :domain,                        # atom() - research domain (:medicine, :engineering, etc.)
    
    # ==================== Timeline ====================
    :start_tick,                    # integer() - first transaction in episode
    :end_tick,                      # integer() | nil - last transaction in episode (nil if active)
    :duration_ticks,                # integer() - total duration (end_tick - start_tick)
    
    # ==================== Transaction References ====================
    :research_cycles,               # [String.t()] - IDs of ResearchCycleResult transactions
    :belief_revisions,              # [String.t()] - IDs of BeliefRevisionResult transactions
    :publications,                  # [String.t()] - IDs of PublicationResult transactions
    :consensus_results,             # [String.t()] - IDs of ConsensusResult transactions
    :validation_results,            # [String.t()] - IDs of ValidationResult transactions
    :other_transactions,            # %{atom() => [String.t()]} - other canonical transaction types
    
    # ==================== Episode Summary ====================
    :hypothesis_summary,            # String.t() - summary of hypotheses investigated
    :key_findings,                  # [String.t()] - major discoveries or conclusions
    :failures_encountered,          # [String.t()] - significant failures and lessons learned
    :belief_changes,                # [String.t()] - summary of belief revisions within episode
    :impact_assessment,             # String.t() - overall impact/importance of investigation
    
    # ==================== Economic History ====================
    :total_cost,                    # float() - total economic cost of episode
    :cost_breakdown,                # %{atom() => float()} - costs by category (experiment, computation, etc.)
    :value_generated,               # float() - estimated value of discoveries/publications
    
    # ==================== Semantic Events ====================
    :semantic_events,               # [String.t()] - IDs of important semantic events in episode
    
    # ==================== Lifecycle Events ====================
    :lifecycle_events,              # [LifecycleEvent.t()] - immutable audit trail of episode lifecycle
    
    # ==================== Metadata ====================
    :contributors,                  # [atom()] - institutions/researchers who contributed
    :tags,                          # [String.t()] - user-defined tags for organization
    :related_episodes,              # [String.t()] - IDs of semantically related episodes
    :metadata                       # map() - additional metadata (extensible)
  ]
  
  @doc """
  Create a new ResearchEpisode for an upcoming investigation.
  
  ## Parameters
  
  - `institution_id`: atom() - owning institution
  - `topic`: String.t() - semantic topic of investigation
  - `opts`: Optional parameters (:description, :keywords, :domain, :metadata)
  
  ## Returns
  
  ResearchEpisode.t() - new active episode
  
  ## Example
  
      episode = ResearchEpisode.new(:medicine_inst, "cancer treatment protocols",
        description: "Investigate novel immunotherapy approaches",
        keywords: ["cancer", "immunotherapy", "treatment"],
        domain: :medicine
      )
  """
  def new(institution_id, topic, opts \\ []) do
    %__MODULE__{
      episode_id: generate_episode_id(),
      institution_id: institution_id,
      created_tick: Map.get(opts, :tick, 0),
      finalized_tick: nil,
      status: :active,
      topic: topic,
      description: Map.get(opts, :description, ""),
      keywords: Map.get(opts, :keywords, []),
      domain: Map.get(opts, :domain, :general),
      start_tick: Map.get(opts, :tick, 0),
      end_tick: nil,
      duration_ticks: 0,
      research_cycles: [],
      belief_revisions: [],
      publications: [],
      consensus_results: [],
      validation_results: [],
      other_transactions: %{},
      hypothesis_summary: "",
      key_findings: [],
      failures_encountered: [],
      belief_changes: [],
      impact_assessment: "",
      total_cost: 0.0,
      cost_breakdown: %{},
      value_generated: 0.0,
      semantic_events: [],
      lifecycle_events: [],
      contributors: [institution_id],
      tags: Map.get(opts, :tags, []),
      related_episodes: [],
      metadata: Map.get(opts, :metadata, %{})
    }
  end
  
  @doc """
  Add a ResearchCycleResult transaction reference to the episode.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  - `cycle_id`: String.t() - ID of ResearchCycleResult transaction
  
  ## Returns
  
  ResearchEpisode.t() - updated episode with cycle reference added
  
  ## Example
  
      episode = ResearchEpisode.add_research_cycle(episode, "cycle_abc123")
  """
  def add_research_cycle(episode, cycle_id) do
    %{episode |
      research_cycles: episode.research_cycles ++ [cycle_id],
      end_tick: max(episode.end_tick || episode.start_tick, get_transaction_tick(cycle_id)),
      duration_ticks: calculate_duration(episode.start_tick, max(episode.end_tick || episode.start_tick, get_transaction_tick(cycle_id)))
    }
  end
  
  @doc """
  Add a BeliefRevisionResult transaction reference to the episode.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  - `revision_id`: String.t() - ID of BeliefRevisionResult transaction
  
  ## Returns
  
  ResearchEpisode.t() - updated episode with revision reference added
  
  ## Example
  
      episode = ResearchEpisode.add_belief_revision(episode, "rev_xyz789")
  """
  def add_belief_revision(episode, revision_id) do
    %{episode |
      belief_revisions: episode.belief_revisions ++ [revision_id],
      end_tick: max(episode.end_tick || episode.start_tick, get_transaction_tick(revision_id)),
      duration_ticks: calculate_duration(episode.start_tick, max(episode.end_tick || episode.start_tick, get_transaction_tick(revision_id)))
    }
  end
  
  @doc """
  Add a PublicationResult transaction reference to the episode.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  - `publication_id`: String.t() - ID of PublicationResult transaction
  
  ## Returns
  
  ResearchEpisode.t() - updated episode with publication reference added
  """
  def add_publication(episode, publication_id) do
    %{episode |
      publications: episode.publications ++ [publication_id],
      end_tick: max(episode.end_tick || episode.start_tick, get_transaction_tick(publication_id)),
      duration_ticks: calculate_duration(episode.start_tick, max(episode.end_tick || episode.start_tick, get_transaction_tick(publication_id)))
    }
  end
  
  @doc """
  Add a ConsensusResult transaction reference to the episode.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  - `consensus_id`: String.t() - ID of ConsensusResult transaction
  
  ## Returns
  
  ResearchEpisode.t() - updated episode with consensus reference added
  """
  def add_consensus(episode, consensus_id) do
    %{episode |
      consensus_results: episode.consensus_results ++ [consensus_id],
      end_tick: max(episode.end_tick || episode.start_tick, get_transaction_tick(consensus_id)),
      duration_ticks: calculate_duration(episode.start_tick, max(episode.end_tick || episode.start_tick, get_transaction_tick(consensus_id)))
    }
  end
  
  @doc """
  Add a ValidationResult transaction reference to the episode.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  - `validation_id`: String.t() - ID of ValidationResult transaction
  
  ## Returns
  
  ResearchEpisode.t() - updated episode with validation reference added
  """
  def add_validation(episode, validation_id) do
    %{episode |
      validation_results: episode.validation_results ++ [validation_id],
      end_tick: max(episode.end_tick || episode.start_tick, get_transaction_tick(validation_id)),
      duration_ticks: calculate_duration(episode.start_tick, max(episode.end_tick || episode.start_tick, get_transaction_tick(validation_id)))
    }
  end
  
  @doc """
  Add a generic transaction reference to the episode.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  - `transaction_type`: atom() - type of transaction (:discovery, :collaboration, etc.)
  - `transaction_id`: String.t() - ID of transaction
  
  ## Returns
  
  ResearchEpisode.t() - updated episode with transaction reference added
  """
  def add_other_transaction(episode, transaction_type, transaction_id) do
    existing = Map.get(episode.other_transactions, transaction_type, [])
    updated_transactions = Map.put(episode.other_transactions, transaction_type, existing ++ [transaction_id])
    
    %{episode |
      other_transactions: updated_transactions,
      end_tick: max(episode.end_tick || episode.start_tick, get_transaction_tick(transaction_id)),
      duration_ticks: calculate_duration(episode.start_tick, max(episode.end_tick || episode.start_tick, get_transaction_tick(transaction_id)))
    }
  end
  
  @doc """
  Update episode summary with hypothesis information.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  - `summary`: String.t() - hypothesis summary
  
  ## Returns
  
  ResearchEpisode.t() - updated episode
  """
  def update_hypothesis_summary(episode, summary) do
    %{episode | hypothesis_summary: summary}
  end
  
  @doc """
  Add key findings to episode summary.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  - `finding`: String.t() - key finding to add
  
  ## Returns
  
  ResearchEpisode.t() - updated episode
  """
  def add_key_finding(episode, finding) do
    %{episode | key_findings: episode.key_findings ++ [finding]}
  end
  
  @doc """
  Record a failure encountered during investigation.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  - `failure_description`: String.t() - description of failure and lessons learned
  
  ## Returns
  
  ResearchEpisode.t() - updated episode
  """
  def add_failure(episode, failure_description) do
    %{episode | failures_encountered: episode.failures_encountered ++ [failure_description]}
  end
  
  @doc """
  Summarize belief changes within episode.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  - `change_summary`: String.t() - summary of belief revisions
  
  ## Returns
  
  ResearchEpisode.t() - updated episode
  """
  def add_belief_change_summary(episode, change_summary) do
    %{episode | belief_changes: episode.belief_changes ++ [change_summary]}
  end
  
  @doc """
  Update economic history for episode.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  - `cost`: float() - cost to add
  - `category`: atom() - cost category (:experiment, :computation, :publication, etc.)
  
  ## Returns
  
  ResearchEpisode.t() - updated episode with cost tracked
  """
  def add_cost(episode, cost, category \\ :general) do
    current_category_cost = Map.get(episode.cost_breakdown, category, 0.0)
    updated_breakdown = Map.put(episode.cost_breakdown, category, current_category_cost + cost)
    
    %{episode |
      total_cost: episode.total_cost + cost,
      cost_breakdown: updated_breakdown
    }
  end
  
  @doc """
  Update value generated by episode discoveries.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  - `value`: float() - estimated value generated
  
  ## Returns
  
  ResearchEpisode.t() - updated episode
  """
  def update_value_generated(episode, value) do
    %{episode | value_generated: value}
  end
  
  @doc """
  Add semantic event reference to episode.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  - `event_id`: String.t() - ID of semantic event
  
  ## Returns
  
  ResearchEpisode.t() - updated episode
  """
  def add_semantic_event(episode, event_id) do
    %{episode | semantic_events: episode.semantic_events ++ [event_id]}
  end
  
  @doc """
  Add lifecycle event to episode audit trail.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  - `event`: LifecycleEvent.t() - lifecycle event to record
  
  ## Returns
  
  ResearchEpisode.t() - updated episode
  """
  def add_lifecycle_event(episode, event) do
    %{episode | lifecycle_events: episode.lifecycle_events ++ [event]}
  end
  
  @doc """
  Add contributor to episode.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  - `contributor_id`: atom() - institution or researcher ID
  
  ## Returns
  
  ResearchEpisode.t() - updated episode
  """
  def add_contributor(episode, contributor_id) do
    unless contributor_id in episode.contributors do
      %{episode | contributors: episode.contributors ++ [contributor_id]}
    else
      episode
    end
  end
  
  @doc """
  Add tag for organization/search.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  - `tag`: String.t() - tag to add
  
  ## Returns
  
  ResearchEpisode.t() - updated episode
  """
  def add_tag(episode, tag) do
    unless tag in episode.tags do
      %{episode | tags: episode.tags ++ [tag]}
    else
      episode
    end
  end
  
  @doc """
  Link to semantically related episode.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  - `related_episode_id`: String.t() - ID of related episode
  
  ## Returns
  
  ResearchEpisode.t() - updated episode
  """
  def add_related_episode(episode, related_episode_id) do
    unless related_episode_id in episode.related_episodes do
      %{episode | related_episodes: episode.related_episodes ++ [related_episode_id]}
    else
      episode
    end
  end
  
  @doc """
  Finalize episode (mark as complete).
  
  Once finalized, episode becomes immutable and cannot be modified.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  - `finalized_tick`: integer() - tick when episode was finalized
  
  ## Returns
  
  ResearchEpisode.t() - finalized episode
  
  ## Example
  
      episode = ResearchEpisode.finalize(episode, 1500)
  """
  def finalize(episode, finalized_tick) do
    %{episode |
      finalized_tick: finalized_tick,
      end_tick: max(episode.end_tick || episode.start_tick, finalized_tick),
      duration_ticks: calculate_duration(episode.start_tick, max(episode.end_tick || episode.start_tick, finalized_tick)),
      status: :finalized
    }
  end
  
  @doc """
  Archive episode (long-term storage).
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode (must be finalized)
  
  ## Returns
  
  ResearchEpisode.t() - archived episode
  
  ## Raises
  
  ArgumentError if episode is not finalized
  """
  def archive(%{status: :finalized} = episode) do
    %{episode | status: :archived}
  end
  
  def archive(_episode) do
    raise ArgumentError, "Cannot archive non-finalized episode"
  end
  
  @doc """
  Get all transaction references in episode.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  
  ## Returns
  
  Map of transaction type to list of IDs
  """
  def get_all_transaction_references(episode) do
    %{
      research_cycles: episode.research_cycles,
      belief_revisions: episode.belief_revisions,
      publications: episode.publications,
      consensus_results: episode.consensus_results,
      validation_results: episode.validation_results,
      other_transactions: episode.other_transactions
    }
  end
  
  @doc """
  Get episode summary for display/search.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  
  ## Returns
  
  Map containing episode summary information
  """
  def get_summary(episode) do
    %{
      episode_id: episode.episode_id,
      institution_id: episode.institution_id,
      topic: episode.topic,
      domain: episode.domain,
      status: episode.status,
      timeline: %{
        start_tick: episode.start_tick,
        end_tick: episode.end_tick,
        duration_ticks: episode.duration_ticks
      },
      transaction_counts: %{
        research_cycles: length(episode.research_cycles),
        belief_revisions: length(episode.belief_revisions),
        publications: length(episode.publications),
        consensus_results: length(episode.consensus_results),
        validation_results: length(episode.validation_results)
      },
      key_findings: episode.key_findings,
      total_cost: episode.total_cost,
      value_generated: episode.value_generated
    }
  end
  
  @doc """
  Check if episode contains specific transaction type.
  
  ## Parameters
  
  - `episode`: ResearchEpisode.t() - target episode
  - `transaction_type`: atom() - type to check
  
  ## Returns
  
  boolean() - true if episode contains transactions of this type
  """
  def has_transaction_type?(episode, transaction_type) do
    case transaction_type do
      :research_cycle -> length(episode.research_cycles) > 0
      :belief_revision -> length(episode.belief_revisions) > 0
      :publication -> length(episode.publications) > 0
      :consensus -> length(episode.consensus_results) > 0
      :validation -> length(episode.validation_results) > 0
      _ -> Map.has_key?(episode.other_transactions, transaction_type) and
           length(Map.get(episode.other_transactions, transaction_type, [])) > 0
    end
  end
  
  # ==================== Private Helper Functions ====================
  
  defp generate_episode_id do
    hash = :crypto.hash(:sha256, "episode_#{System.system_time()}_#{:rand.uniform(1000000)}")
    "ep_#{Base.encode16(hash, case: :lower) |> String.slice(0..15)}"
  end
  
  defp get_transaction_tick(_transaction_id) do
    # In production, this would look up the transaction's tick from Knowledge Graph
    # For now, return current simulation tick (would be passed in opts in real implementation)
    0
  end
  
  defp calculate_duration(start_tick, end_tick) do
    max(end_tick - start_tick, 0)
  end
end
