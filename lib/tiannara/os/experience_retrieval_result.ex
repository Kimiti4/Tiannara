defmodule TiannaraOS.ExperienceRetrievalResult do
  @moduledoc """
  ExperienceRetrievalResult - Canonical constitutional transaction for episode retrieval.
  
  This artifact captures the complete audit trail of one institutional episode retrieval
  event, including query parameters, retrieved episodes with their constituent transaction
  references, similarity metrics, and all constitutional deltas.
  
  ## Constitutional Design
  
  The ExperienceRetrievalResult follows the same architectural discipline as
  ResearchCycleResult and BeliefRevisionResult:
  
  - Single canonical transaction artifact
  - Complete traceability (lifecycle events, semantic events)
  - Composes existing constitutional services (no new layers)
  - Consumed by future capabilities (Do-Calculus, Discovery Exchange, etc.)
  - Internal retrieval engine hidden (VSA/hyperdimensional/vector embeddings never exposed)
  
  ## Key Principle: Lightweight References
  
  Instead of embedding full transaction objects, this result stores EPISODE REFERENCES.
  Full transactions can always be reconstructed from immutable storage via Knowledge Graph.
  
  This keeps retrieval lightweight while preserving complete traceability.
  
  ## Example Usage
  
      result = ExperienceRetrievalResult.new(:medicine_inst, query)
      result = ExperienceRetrievalResult.add_retrieved_episode(result, %{
        episode_id: "ep_abc123",
        similarity: 0.85,
        explanation: "Similar cancer treatment investigation with immunotherapy focus"
      })
      result = ExperienceRetrievalResult.mark_completed(result, :semantic_match)
      
      # Later: reconstruct full episodes from references
      episode_ids = Enum.map(result.retrieved_episodes, & &1.episode_id)
      episodes = KnowledgeGraph.get_episodes(episode_ids)
      
  """
  
  @derive Jason.Encoder
  defstruct [
    # ==================== Retrieval Identity ====================
    :retrieval_id,                # String.t() - unique retrieval identifier
    :institution_id,              # atom() - institution performing retrieval
    :timestamp,                   # DateTime.t() - when retrieval occurred
    :tick,                        # integer() - simulation tick
    
    # ==================== Query ====================
    :query,                       # map() - what was searched for (topic, keywords, context)
    :query_type,                  # atom() - :hypothesis | :experiment | :failure | :revision | :publication | :intervention | :collaboration | :general
    
    # ==================== Retrieved Episodes ====================
    :retrieved_episodes,          # [%{episode_id: String.t(), similarity: float(), explanation: String.t(), ...}]
    :total_episodes_searched,     # integer() - how many episodes were considered
    :retrieval_method,            # atom() - :vsa | :hyperdimensional | :vector_embedding | :sparse_distributed | :hybrid | :graph_similarity (internal only)
    
    # ==================== Episode Composition Details (Lightweight) ====================
    :episode_summaries,           # %{episode_id => %{transaction_counts: %{}, timeline: %{}, topic: String.t()}}
    
    # ==================== Similarity Metrics ====================
    :similarity_distribution,     # %{mean: float(), std_dev: float(), max: float(), min: float()}
    :ranking_justification,       # String.t() - why these episodes ranked highest
    
    # ==================== Constitutional Deltas ====================
    :knowledge_delta,             # nil (read-only operation, no mutations)
    :ledger_delta,                # LedgerDelta.t() - economic costs of retrieval
    :memory_delta,                # MemoryDelta.t() - access pattern updates
    
    # ==================== Event Audit Trail ====================
    :lifecycle_events,            # [LifecycleEvent.t()] - immutable lifecycle history
    :semantic_events,             # [SemanticEvent.t()] - domain-specific events emitted
    
    # ==================== Execution Metadata ====================
    :execution_time_ms,           # integer() - wall clock time for retrieval
    :constitutional_validation,   # Validation.t() - invariant compliance check
    
    # ==================== Status ====================
    :status,                      # atom() - :completed | :partial | :empty | :deferred | :failed
    :failure_reason               # String.t() | nil - explanation if status != :completed
  ]
  
  @doc """
  Create a new ExperienceRetrievalResult for an upcoming retrieval.
  
  ## Parameters
  
  - `institution_id`: atom() - institution performing retrieval
  - `query`: map() - search query (topic, keywords, context)
  - `opts`: Optional parameters (:query_type, :tick, :metadata)
  
  ## Returns
  
  ExperienceRetrievalResult.t() - new pending retrieval result
  
  ## Example
  
      result = ExperienceRetrievalResult.new(:medicine_inst, %{
        topic: "cancer treatment protocols",
        keywords: ["immunotherapy", "checkpoint inhibitors"]
      }, query_type: :hypothesis)
  """
  def new(institution_id, query, opts \\ []) do
    %__MODULE__{
      retrieval_id: generate_retrieval_id(),
      institution_id: institution_id,
      timestamp: DateTime.utc_now(),
      tick: Map.get(opts, :tick, 0),
      query: query,
      query_type: Map.get(opts, :query_type, :general),
      retrieved_episodes: [],
      total_episodes_searched: 0,
      retrieval_method: nil,
      episode_summaries: %{},
      similarity_distribution: nil,
      ranking_justification: "",
      knowledge_delta: nil,
      ledger_delta: nil,
      memory_delta: nil,
      lifecycle_events: [],
      semantic_events: [],
      execution_time_ms: 0,
      constitutional_validation: nil,
      status: :pending,
      failure_reason: nil
    }
  end
  
  @doc """
  Add a retrieved episode to the result.
  
  Stores lightweight reference (episode_id, similarity, explanation) rather than
  full transaction objects. Full episodes reconstructed from Knowledge Graph later.
  
  ## Parameters
  
  - `result`: ExperienceRetrievalResult.t() - target result
  - `episode_ref`: map() - episode reference with keys:
    - :episode_id (String.t())
    - :similarity (float())
    - :explanation (String.t())
    - :transaction_counts (map()) - optional summary of contained transactions
    - :timeline (map()) - optional start/end ticks
  
  ## Returns
  
  ExperienceRetrievalResult.t() - updated result with episode reference added
  
  ## Example
  
      result = ExperienceRetrievalResult.add_retrieved_episode(result, %{
        episode_id: "ep_abc123",
        similarity: 0.85,
        explanation: "Similar cancer treatment investigation",
        transaction_counts: %{research_cycles: 3, belief_revisions: 2}
      })
  """
  def add_retrieved_episode(result, episode_ref) do
    episode_id = Map.get(episode_ref, :episode_id)
    
    updated_episodes = result.retrieved_episodes ++ [episode_ref]
    
    # Update episode summaries (lightweight metadata)
    updated_summaries = Map.put(result.episode_summaries, episode_id, %{
      transaction_counts: Map.get(episode_ref, :transaction_counts, %{}),
      timeline: Map.get(episode_ref, :timeline, %{}),
      topic: Map.get(episode_ref, :topic, ""),
      similarity: Map.get(episode_ref, :similarity, 0.0)
    })
    
    # Update similarity distribution
    updated_distribution = update_similarity_distribution(result, Map.get(episode_ref, :similarity, 0.0))
    
    %{result |
      retrieved_episodes: updated_episodes,
      episode_summaries: updated_summaries,
      similarity_distribution: updated_distribution
    }
  end
  
  @doc """
  Set total number of episodes searched during retrieval.
  
  ## Parameters
  
  - `result`: ExperienceRetrievalResult.t() - target result
  - `count`: integer() - total episodes considered
  
  ## Returns
  
  ExperienceRetrievalResult.t() - updated result
  """
  def set_total_episodes_searched(result, count) do
    %{result | total_episodes_searched: count}
  end
  
  @doc """
  Record retrieval method used (internal implementation detail).
  
  ## Parameters
  
  - `result`: ExperienceRetrievalResult.t() - target result
  - `method`: atom() - retrieval method (:vsa, :hyperdimensional, :vector_embedding, etc.)
  
  ## Returns
  
  ExperienceRetrievalResult.t() - updated result
  """
  def set_retrieval_method(result, method) do
    %{result | retrieval_method: method}
  end
  
  @doc """
  Set ranking justification explaining why episodes were ranked as they were.
  
  ## Parameters
  
  - `result`: ExperienceRetrievalResult.t() - target result
  - `justification`: String.t() - explanation of ranking criteria
  
  ## Returns
  
  ExperienceRetrievalResult.t() - updated result
  """
  def set_ranking_justification(result, justification) do
    %{result | ranking_justification: justification}
  end
  
  @doc """
  Set ledger delta for retrieval costs.
  
  ## Parameters
  
  - `result`: ExperienceRetrievalResult.t() - target result
  - `delta`: LedgerDelta.t() - economic cost accounting
  
  ## Returns
  
  ExperienceRetrievalResult.t() - updated result
  """
  def set_ledger_delta(result, delta) do
    %{result | ledger_delta: delta}
  end
  
  @doc """
  Set memory delta for access pattern updates.
  
  ## Parameters
  
  - `result`: ExperienceRetrievalResult.t() - target result
  - `delta`: MemoryDelta.t() - memory pipeline updates
  
  ## Returns
  
  ExperienceRetrievalResult.t() - updated result
  """
  def set_memory_delta(result, delta) do
    %{result | memory_delta: delta}
  end
  
  @doc """
  Add lifecycle event to retrieval audit trail.
  
  ## Parameters
  
  - `result`: ExperienceRetrievalResult.t() - target result
  - `event`: LifecycleEvent.t() - lifecycle event to record
  
  ## Returns
  
  ExperienceRetrievalResult.t() - updated result
  """
  def add_lifecycle_event(result, event) do
    %{result | lifecycle_events: result.lifecycle_events ++ [event]}
  end
  
  @doc """
  Add semantic event to retrieval audit trail.
  
  ## Parameters
  
  - `result`: ExperienceRetrievalResult.t() - target result
  - `event`: SemanticEvent.t() - semantic event to emit
  
  ## Returns
  
  ExperienceRetrievalResult.t() - updated result
  """
  def add_semantic_event(result, event) do
    %{result | semantic_events: result.semantic_events ++ [event]}
  end
  
  @doc """
  Set execution time for retrieval operation.
  
  ## Parameters
  
  - `result`: ExperienceRetrievalResult.t() - target result
  - `time_ms`: integer() - wall clock time in milliseconds
  
  ## Returns
  
  ExperienceRetrievalResult.t() - updated result
  """
  def set_execution_time(result, time_ms) do
    %{result | execution_time_ms: time_ms}
  end
  
  @doc """
  Set constitutional validation result.
  
  ## Parameters
  
  - `result`: ExperienceRetrievalResult.t() - target result
  - `validation`: Validation.t() - invariant compliance check
  
  ## Returns
  
  ExperienceRetrievalResult.t() - updated result
  """
  def set_constitutional_validation(result, validation) do
    %{result | constitutional_validation: validation}
  end
  
  @doc """
  Mark retrieval as completed successfully.
  
  ## Parameters
  
  - `result`: ExperienceRetrievalResult.t() - target result
  - `reason`: atom() - completion reason (:semantic_match, :keyword_match, :partial_match, etc.)
  
  ## Returns
  
  ExperienceRetrievalResult.t() - completed result
  """
  def mark_completed(result, _reason) do
    %{result |
      status: :completed
    }
  end
  
  @doc """
  Mark retrieval as partially completed (some episodes found but incomplete).
  
  ## Parameters
  
  - `result`: ExperienceRetrievalResult.t() - target result
  - `reason`: String.t() - explanation of partial completion
  
  ## Returns
  
  ExperienceRetrievalResult.t() - partial result
  """
  def mark_partial(result, reason) do
    %{result |
      status: :partial,
      failure_reason: reason
    }
  end
  
  @doc """
  Mark retrieval as empty (no matching episodes found).
  
  ## Parameters
  
  - `result`: ExperienceRetrievalResult.t() - target result
  
  ## Returns
  
  ExperienceRetrievalResult.t() - empty result
  """
  def mark_empty(result) do
    %{result |
      status: :empty,
      ranking_justification: "No semantically similar episodes found in institutional memory"
    }
  end
  
  @doc """
  Mark retrieval as deferred (insufficient budget).
  
  ## Parameters
  
  - `result`: ExperienceRetrievalResult.t() - target result
  - `reason`: String.t() - explanation of deferral
  
  ## Returns
  
  ExperienceRetrievalResult.t() - deferred result
  """
  def mark_deferred(result, reason) do
    %{result |
      status: :deferred,
      failure_reason: reason
    }
  end
  
  @doc """
  Mark retrieval as failed (error occurred).
  
  ## Parameters
  
  - `result`: ExperienceRetrievalResult.t() - target result
  - `reason`: String.t() - explanation of failure
  
  ## Returns
  
  ExperienceRetrievalResult.t() - failed result
  """
  def mark_failed(result, reason) do
    %{result |
      status: :failed,
      failure_reason: reason
    }
  end
  
  @doc """
  Get summary of retrieved episodes for display.
  
  ## Parameters
  
  - `result`: ExperienceRetrievalResult.t() - target result
  
  ## Returns
  
  List of episode summaries with IDs, similarities, and explanations
  """
  def get_retrieved_episode_summary(result) do
    Enum.map(result.retrieved_episodes, fn episode_ref ->
      %{
        episode_id: Map.get(episode_ref, :episode_id),
        similarity: Map.get(episode_ref, :similarity),
        explanation: Map.get(episode_ref, :explanation),
        transaction_counts: Map.get(episode_ref, :transaction_counts, %{})
      }
    end)
  end
  
  @doc """
  Check if retrieval returned any results.
  
  ## Parameters
  
  - `result`: ExperienceRetrievalResult.t() - target result
  
  ## Returns
  
  boolean() - true if at least one episode was retrieved
  """
  def has_results?(result) do
    length(result.retrieved_episodes) > 0
  end
  
  @doc """
  Get best matching episode (highest similarity).
  
  ## Parameters
  
  - `result`: ExperienceRetrievalResult.t() - target result
  
  ## Returns
  
  map() | nil - best matching episode reference or nil if no results
  """
  def get_best_match(result) do
    case result.retrieved_episodes do
      [] -> nil
      episodes ->
        Enum.max_by(episodes, fn ep -> Map.get(ep, :similarity, 0.0) end)
    end
  end
  
  # ==================== Private Helper Functions ====================
  
  defp generate_retrieval_id do
    hash = :crypto.hash(:sha256, "retrieval_#{System.system_time()}_#{:rand.uniform(1000000)}")
    "ret_#{Base.encode16(hash, case: :lower) |> String.slice(0..15)}"
  end
  
  defp update_similarity_distribution(result, new_similarity) do
    current_dist = result.similarity_distribution
    
    if current_dist == nil do
      # First similarity value
      %{
        mean: new_similarity,
        std_dev: 0.0,
        max: new_similarity,
        min: new_similarity,
        count: 1,
        sum: new_similarity,
        sum_squared: new_similarity * new_similarity
      }
    else
      # Update running statistics
      count = current_dist.count + 1
      sum = current_dist.sum + new_similarity
      sum_squared = current_dist.sum_squared + (new_similarity * new_similarity)
      mean = sum / count
      
      variance = if count > 1 do
        (sum_squared / count) - (mean * mean)
      else
        0.0
      end
      
      std_dev = :math.sqrt(max(variance, 0.0))
      
      %{
        mean: mean,
        std_dev: std_dev,
        max: max(current_dist.max, new_similarity),
        min: min(current_dist.min, new_similarity),
        count: count,
        sum: sum,
        sum_squared: sum_squared
      }
    end
  end
end
