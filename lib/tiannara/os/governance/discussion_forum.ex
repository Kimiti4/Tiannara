defmodule TiannaraOS.Governance.DiscussionForum do
  @moduledoc """
  DiscussionForum - Manage RFC community discussion.

  Creates discussion threads, collects feedback, tracks participation,
  summarizes themes, and enforces time limits (7-30 days).

  ## Archaeology

  - **purpose**: Facilitate community discussion of RFC proposals
  - **introduced_in**: Phase 14.1
  - **depends_on**: TiannaraOS.Governance.RFC, TiannaraOS.Governance.RFCRegistry
  - **constitution_reference**: PHASE14_1_RFC_SYSTEM_SPECIFICATION.md Section 3.4
  - **owner**: Governance Council

  ## Usage

      {:ok, thread_id} = DiscussionForum.open_discussion(rfc_id)
      {:ok, comment} = DiscussionForum.add_comment(thread_id, author, content)
      {:ok, summary} = DiscussionForum.summarize_discussion(thread_id)
  """

  use GenServer

  @type thread_id :: String.t()
  @type rfc_id :: String.t()
  @type comment :: map()

  # Client API

  @doc """
  Start the Discussion Forum.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Open a new discussion thread for an RFC.

  Returns {:ok, thread_id}.
  """
  @spec open_discussion(rfc_id()) :: {:ok, thread_id()} | {:error, term()}
  def open_discussion(rfc_id) do
    GenServer.call(__MODULE__, {:open_discussion, rfc_id})
  end

  @doc """
  Add a comment to a discussion thread.

  Returns {:ok, comment}.
  """
  @spec add_comment(thread_id(), String.t(), String.t()) :: {:ok, comment()} | {:error, term()}
  def add_comment(thread_id, author, content) do
    GenServer.call(__MODULE__, {:add_comment, thread_id, author, content})
  end

  @doc """
  Summarize discussion themes and sentiment.

  Returns {:ok, summary} with categorized feedback.
  """
  @spec summarize_discussion(thread_id()) :: {:ok, map()} | {:error, term()}
  def summarize_discussion(thread_id) do
    GenServer.call(__MODULE__, {:summarize, thread_id})
  end

  @doc """
  Get participation statistics for a thread.

  Returns {:ok, stats} with participant count, comment count, etc.
  """
  @spec get_participation_stats(thread_id()) :: {:ok, map()} | {:error, term()}
  def get_participation_stats(thread_id) do
    GenServer.call(__MODULE__, {:get_stats, thread_id})
  end

  @doc """
  Close a discussion thread (end discussion period).

  Returns :ok or {:error, reason}.
  """
  @spec close_discussion(thread_id()) :: :ok | {:error, term()}
  def close_discussion(thread_id) do
    GenServer.call(__MODULE__, {:close, thread_id})
  end

  @doc """
  Get all comments for a thread.

  Returns {:ok, [comment]}.
  """
  @spec get_comments(thread_id()) :: {:ok, [comment()]} | {:error, :not_found}
  def get_comments(thread_id) do
    GenServer.call(__MODULE__, {:get_comments, thread_id})
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    {:ok, %{
      threads: %{},       # %{thread_id => thread_data}
      comments: %{},      # %{thread_id => [comment]}
      participants: %{}   # %{thread_id => MapSet of authors}
    }}
  end

  @impl true
  def handle_call({:open_discussion, rfc_id}, _from, state) do
    thread_id = generate_thread_id()
    now = DateTime.utc_now()
    
    thread = %{
      thread_id: thread_id,
      rfc_id: rfc_id,
      opened_at: now,
      closed_at: nil,
      status: :open,
      min_duration_days: 7,
      max_duration_days: 30
    }
    
    threads = Map.put(state.threads, thread_id, thread)
    comments = Map.put(state.comments, thread_id, [])
    participants = Map.put(state.participants, thread_id, MapSet.new())
    
    {:reply, {:ok, thread_id}, %{state | threads: threads, comments: comments, participants: participants}}
  end

  @impl true
  def handle_call({:add_comment, thread_id, author, content}, _from, state) do
    case Map.get(state.threads, thread_id) do
      nil ->
        {:reply, {:error, :thread_not_found}, state}
      
      %{status: :closed} ->
        {:reply, {:error, :thread_closed}, state}
      
      _thread ->
        now = DateTime.utc_now()
        comment = %{
          comment_id: generate_comment_id(),
          thread_id: thread_id,
          author: author,
          content: content,
          timestamp: now,
          sentiment: analyze_sentiment(content)
        }
        
        # Add comment
        comments = Map.update(state.comments, thread_id, [comment], &[comment | &1])
        
        # Track participant
        participants = Map.update(state.participants, thread_id, MapSet.new([author]), 
                                  &MapSet.put(&1, author))
        
        {:reply, {:ok, comment}, %{state | comments: comments, participants: participants}}
    end
  end

  @impl true
  def handle_call({:summarize, thread_id}, _from, state) do
    case Map.get(state.comments, thread_id) do
      nil ->
        {:reply, {:error, :thread_not_found}, state}
      
      comments ->
        # Categorize by theme
        themes = categorize_themes(comments)
        
        # Count sentiment
        sentiment_counts = Enum.group_by(comments, & &1.sentiment)
                          |> Enum.map(fn {sentiment, comments} -> {sentiment, length(comments)} end)
                          |> Map.new()
        
        # Extract revision suggestions
        suggestions = extract_suggestions(comments)
        
        summary = %{
          thread_id: thread_id,
          total_comments: length(comments),
          participant_count: MapSet.size(Map.get(state.participants, thread_id, MapSet.new())),
          sentiment_counts: sentiment_counts,
          themes: themes,
          revision_suggestions: suggestions,
          summarized_at: DateTime.utc_now()
        }
        
        {:reply, {:ok, summary}, state}
    end
  end

  @impl true
  def handle_call({:get_stats, thread_id}, _from, state) do
    case Map.get(state.comments, thread_id) do
      nil ->
        {:reply, {:error, :thread_not_found}, state}
      
      comments ->
        participants = Map.get(state.participants, thread_id, MapSet.new())
        thread = Map.get(state.threads, thread_id)
        
        duration = if thread.closed_at do
          DateTime.diff(thread.closed_at, thread.opened_at, :day)
        else
          DateTime.diff(DateTime.utc_now(), thread.opened_at, :day)
        end
        
        stats = %{
          thread_id: thread_id,
          status: thread.status,
          opened_at: thread.opened_at,
          duration_days: duration,
          comment_count: length(comments),
          participant_count: MapSet.size(participants),
          institutions_represented: extract_institutions(participants)
        }
        
        {:reply, {:ok, stats}, state}
    end
  end

  @impl true
  def handle_call({:close, thread_id}, _from, state) do
    case Map.get(state.threads, thread_id) do
      nil ->
        {:reply, {:error, :thread_not_found}, state}
      
      %{status: :closed} ->
        {:reply, {:error, :already_closed}, state}
      
      thread ->
        # Check minimum duration
        duration = DateTime.diff(DateTime.utc_now(), thread.opened_at, :day)
        
        if duration < thread.min_duration_days do
          {:reply, {:error, :minimum_duration_not_met}, state}
        else
          updated_thread = %{thread | status: :closed, closed_at: DateTime.utc_now()}
          threads = Map.put(state.threads, thread_id, updated_thread)
          {:reply, :ok, %{state | threads: threads}}
        end
    end
  end

  @impl true
  def handle_call({:get_comments, thread_id}, _from, state) do
    case Map.get(state.comments, thread_id) do
      nil -> {:reply, {:error, :not_found}, state}
      comments -> {:reply, {:ok, comments}, state}
    end
  end

  # Private helpers

  defp generate_thread_id() do
    timestamp = System.system_time(:millisecond)
    random = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
    "THREAD-#{timestamp}-#{random}"
  end

  defp generate_comment_id() do
    timestamp = System.system_time(:millisecond)
    random = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
    "COMMENT-#{timestamp}-#{random}"
  end

  defp analyze_sentiment(content) do
    # Simple keyword-based sentiment analysis
    # In production: use NLP model
    positive_words = ["good", "great", "excellent", "support", "agree", "approve"]
    negative_words = ["bad", "poor", "reject", "disagree", "concern", "issue"]
    
    content_lower = String.downcase(content)
    
    positive_count = Enum.count(positive_words, &String.contains?(content_lower, &1))
    negative_count = Enum.count(negative_words, &String.contains?(content_lower, &1))
    
    cond do
      positive_count > negative_count -> :positive
      negative_count > positive_count -> :negative
      true -> :neutral
    end
  end

  defp categorize_themes(comments) do
    # Simple theme extraction based on keywords
    # In production: use topic modeling
    theme_keywords = %{
      "technical" => ["implementation", "code", "architecture", "design"],
      "economic" => ["cost", "budget", "resource", "expensive"],
      "governance" => ["institution", "authority", "role", "power"],
      "safety" => ["risk", "violation", "invariant", "security"]
    }
    
    Enum.reduce(theme_keywords, %{}, fn {theme, keywords}, acc ->
      count = Enum.count(comments, fn comment ->
        Enum.any?(keywords, &String.contains?(String.downcase(comment.content), &1))
      end)
      
      if count > 0 do
        Map.put(acc, theme, %{mention_count: count, sentiment: :neutral})
      else
        acc
      end
    end)
  end

  defp extract_suggestions(comments) do
    # Extract comments that suggest revisions
    # In production: use pattern matching for suggestion phrases
    Enum.filter(comments, fn comment ->
      String.contains?(String.downcase(comment.content), ["suggest", "recommend", "should", "could"])
    end)
    |> Enum.map(fn comment ->
      %{
        suggestion_id: "SUGG-#{comment.comment_id}",
        author: comment.author,
        description: comment.content,
        support_count: 0,  # Would track upvotes in production
        priority: :optional
      }
    end)
  end

  defp extract_institutions(participants) do
    # Extract institution affiliations from participant set
    # In production: query institutional membership
    MapSet.to_list(participants)
    |> Enum.map(fn _author -> "institution_placeholder" end)
    |> Enum.uniq()
  end
end
