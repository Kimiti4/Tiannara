defmodule TiannaraOS.EpisodeIndex do
  @moduledoc """
  EpisodeIndex - Constitutional service for indexing immutable ResearchEpisode objects.
  
  This is NOT a subsystem or parallel memory layer. It is a simple index over
  canonical ResearchEpisode objects owned by the Institution.
  
  ## Responsibilities
  
  - Store lightweight episode index entries (topic, domain, keywords, outcome, etc.)
  - Provide semantic search over episode index
  - Return episode references (IDs) for replay from Knowledge Graph
  
  ## What it is NOT
  
  - NOT a storage system (episodes stored in Institution's civilizational_memory)
  - NOT an embedding store (embeddings belong to retrieval engine)
  - NOT a transaction database (transactions inside episodes)
  
  ## Constitutional Hierarchy
  
      Institution
          │
          ▼
      Research Episode (canonical, immutable)
          │
          ▼
      Episode Index Entry (lightweight, searchable)
          │
          ▼
      Semantic Retrieval (returns episode references)
  
  ## Usage
  
      # Add episode to index
      index = EpisodeIndex.add_entry(index, episode)
      
      # Search episodes
      results = EpisodeIndex.search(index, query, opts)
      
      # Get episode reference for replay
      episode_id = hd(results).episode_id
      episode = KnowledgeGraph.get_episode(episode_id)  # Replay
  """
  
  @derive Jason.Encoder
  defstruct [
    :institution_id,              # atom() - owning institution
    :entries,                     # %{episode_id => EpisodeIndexEntry.t()}
    :total_episodes               # integer() - total indexed episodes
  ]
  
  @type t :: %__MODULE__{
    institution_id: atom(),
    entries: map(),
    total_episodes: integer()
  }
  
  defmodule Entry do
    @moduledoc """
    EpisodeIndexEntry - Lightweight searchable representation of a ResearchEpisode.
    
    Contains only metadata needed for semantic retrieval. Full episode reconstructed
    from Knowledge Graph via episode_id when needed.
    """
    
    @derive Jason.Encoder
    defstruct [
      :episode_id,                  # String.t() - reference to canonical episode
      :topic,                       # String.t() - semantic topic
      :domain,                      # atom() - research domain
      :keywords,                    # [String.t()] - searchable keywords
      :outcome,                     # atom() - :success | :failure | :deferred | :rejected
      :publication_ids,             # [String.t()] - associated publications
      :confidence,                  # float() - overall investigation confidence
      :start_tick,                  # integer() - episode start
      :end_tick,                    # integer() - episode end
      :transaction_counts,          # %{research_cycles: int, belief_revisions: int, ...}
      :embedding                    # binary() | nil - VSA embedding (owned by retrieval engine)
    ]
    
    @type t :: %__MODULE__{}
  end
  
  # ==================== Public API ====================
  
  @doc """
  Create a new empty EpisodeIndex for an institution.
  """
  def new(institution_id) do
    %__MODULE__{
      institution_id: institution_id,
      entries: %{},
      total_episodes: 0
    }
  end
  
  @doc """
  Add a ResearchEpisode to the index.
  
  Extracts lightweight metadata from the canonical episode and creates
  an index entry. Does NOT duplicate the episode - stores only searchable fields.
  
  ## Parameters
  
  - `index`: EpisodeIndex.t() - target index
  - `episode`: ResearchEpisode.t() - canonical episode to index
  
  ## Returns
  
  EpisodeIndex.t() - updated index with new entry
  """
  def add_entry(index, episode) do
    # Determine outcome from episode status and transactions
    outcome = determine_outcome(episode)
    
    # Extract keywords from topic and description
    keywords = extract_keywords(episode)
    
    # Count transactions
    transaction_counts = %{
      research_cycles: length(episode.research_cycles),
      belief_revisions: length(episode.belief_revisions),
      publications: length(episode.publications),
      consensus_results: length(episode.consensus_results),
      validation_results: length(episode.validation_results)
    }
    
    # Calculate average confidence from belief revisions
    confidence = calculate_confidence(episode)
    
    # Create index entry
    entry = %TiannaraOS.EpisodeIndex.Entry{
      episode_id: episode.episode_id,
      topic: episode.topic,
      domain: episode.domain,
      keywords: keywords,
      outcome: outcome,
      publication_ids: episode.publications,
      confidence: confidence,
      start_tick: episode.start_tick,
      end_tick: episode.end_tick,
      transaction_counts: transaction_counts,
      embedding: nil  # Embedding computed during indexing (retrieval engine responsibility)
    }
    
    # Add to index
    updated_entries = Map.put(index.entries, episode.episode_id, entry)
    
    %{index |
      entries: updated_entries,
      total_episodes: map_size(updated_entries)
    }
  end
  
  @doc """
  Search episodes by semantic similarity to query.
  
  Uses keyword/topic matching (simulated VSA). In production, would use
  actual vector similarity on embeddings.
  
  ## Parameters
  
  - `index`: EpisodeIndex.t() - index to search
  - `query`: map() - search query (%{topic: String.t(), keywords: [String.t()]})
  - `opts`: map() - options (%{max_results: int, min_similarity: float})
  
  ## Returns
  
  [%{episode_id: String.t(), similarity: float(), entry: Entry.t()}] - ranked results
  """
  def search(index, query, opts \\ %{}) do
    max_results = Map.get(opts, :max_results, 5)
    min_similarity = Map.get(opts, :min_similarity, 0.3)
    
    # Calculate similarity for all entries
    scored_entries = Enum.map(index.entries, fn {episode_id, entry} ->
      similarity = calculate_similarity(entry, query)
      {episode_id, entry, similarity}
    end)
    
    # Filter by minimum similarity and sort by score
    results = scored_entries
      |> Enum.filter(fn {_id, _entry, sim} -> sim >= min_similarity end)
      |> Enum.sort_by(fn {_id, _entry, sim} -> -sim end)
      |> Enum.take(max_results)
      |> Enum.map(fn {episode_id, entry, similarity} ->
        %{
          episode_id: episode_id,
          similarity: similarity,
          entry: entry
        }
      end)
    
    results
  end
  
  @doc """
  Get episode index entry by ID.
  
  Returns lightweight metadata for replay decision. Full episode retrieved
  from Knowledge Graph if needed.
  
  ## Parameters
  
  - `index`: EpisodeIndex.t() - index to query
  - `episode_id`: String.t() - episode to retrieve
  
  ## Returns
  
  EpisodeIndexEntry.t() | nil - entry if found
  """
  def get_entry(index, episode_id) do
    Map.get(index.entries, episode_id)
  end
  
  @doc """
  Get all episode IDs in the index.
  
  Useful for iteration or bulk operations.
  
  ## Parameters
  
  - `index`: EpisodeIndex.t() - index to query
  
  ## Returns
  
  [String.t()] - list of episode IDs
  """
  def list_episode_ids(index) do
    Map.keys(index.entries)
  end
  
  # ==================== Private Helpers ====================
  
  # Determine episode outcome from status and transactions
  defp determine_outcome(episode) do
    cond do
      episode.status == :archived -> :failure
      length(episode.publications) > 0 -> :success
      true -> :success
    end
  end
  
  # Extract keywords from episode topic and description
  defp extract_keywords(episode) do
    # Combine topic and description, tokenize, remove stop words
    text = "#{episode.topic} #{episode.description || ""}"
    
    text
    |> String.downcase()
    |> String.split(~r/[^a-z0-9]+/, trim: true)
    |> Enum.filter(fn word -> String.length(word) > 2 end)  # Remove short words
    |> Enum.uniq()
    |> Enum.take(20)  # Limit to top 20 keywords
  end
  
  # Calculate average confidence from belief revisions
  defp calculate_confidence(episode) do
    # In production, would aggregate from BeliefRevisionResult.confidence_changes
    # For now, return default based on publication status
    if length(episode.publications) > 0 do
      0.7  # Published investigations tend to have higher confidence
    else
      0.5  # Unpublished investigations are uncertain
    end
  end
  
  # Calculate semantic similarity between entry and query
  defp calculate_similarity(entry, query) do
    query_topic = String.downcase(Map.get(query, :topic, ""))
    query_keywords = Map.get(query, :keywords, [])
    
    entry_topic = String.downcase(entry.topic || "")
    entry_keywords = entry.keywords
    
    # Keyword matching score
    keyword_matches = Enum.count(query_keywords, fn qkw ->
      Enum.any?(entry_keywords, fn ekw ->
        String.contains?(ekw, String.downcase(qkw)) or
        String.contains?(String.downcase(qkw), ekw)
      end)
    end)
    
    keyword_score = if length(query_keywords) > 0 do
      keyword_matches / length(query_keywords)
    else
      0.0
    end
    
    # Topic matching score (substring match)
    topic_score = if String.length(query_topic) > 3 and String.contains?(entry_topic, query_topic) do
      0.8
    else
      0.0
    end
    
    # Combined score (weighted)
    combined_score = (keyword_score * 0.6) + (topic_score * 0.4)
    
    # Scale to reasonable range
    min(combined_score * 1.2, 1.0)
  end
end
