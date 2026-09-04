defmodule Tiannara.Core.WorldModel.BeliefSystem do
  @moduledoc """
  Belief System for the World Model.

  Manages confidence-weighted beliefs about reality.
  Provides belief storage, confidence calculation, and contradiction detection.
  """

  use GenServer
  require Logger

  @doc "Start the Belief System server."
  def start_link(opts) do
    shard_id = Keyword.get(opts, :shard_id, :world_0)
    name = Tiannara.ROS.Registry.via(__MODULE__, shard_id)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "Add a new belief to the system."
  def add_belief(statement, confidence \\ 0.7, source \\ "system", evidence \\ []) do
    belief = %{
      id: generate_belief_id(),
      statement: statement,
      confidence: confidence,
      source: source,
      evidence: evidence,
      created_at: DateTime.utc_now(),
      last_verified: DateTime.utc_now()
    }

    GenServer.call(__MODULE__, {:add_belief, belief})
  end

  @doc "Update an existing belief's confidence."
  def update_belief_confidence(_belief_id, new_confidence, reason \\ nil) do
    update_data = %{
      confidence: new_confidence,
      last_verified: DateTime.utc_now()
    }
    
    if reason do
      Map.put(update_data, :last_update_reason, reason)
    else
      update_data
    end
  end

  @doc "Get a belief by ID."
  def get_belief(belief_id) do
    GenServer.call(__MODULE__, {:get_belief, belief_id})
  end

  @doc "Get all beliefs."
  def list_beliefs do
    GenServer.call(__MODULE__, :list_beliefs)
  end

  @doc "Get high confidence beliefs above a threshold."
  def get_high_confidence_beliefs(threshold \\ 0.7) do
    GenServer.call(__MODULE__, {:get_high_confidence_beliefs, threshold})
  end

  @doc "Get beliefs by source."
  def get_beliefs_by_source(source) do
    GenServer.call(__MODULE__, {:get_beliefs_by_source, source})
  end

  @doc "Search beliefs by statement pattern."
  def search_beliefs(pattern) do
    GenServer.call(__MODULE__, {:search_beliefs, pattern})
  end

  @doc "Detect contradictions between beliefs."
  def detect_contradictions do
    GenServer.call(__MODULE__, :detect_contradictions)
  end

  @doc "Calculate confidence in a statement based on related beliefs."
  def calculate_statement_confidence(statement) do
    GenServer.call(__MODULE__, {:calculate_statement_confidence, statement})
  end

  @doc "Update evidence for a belief."
  def update_evidence(belief_id, new_evidence) do
    GenServer.call(__MODULE__, {:update_evidence, belief_id, new_evidence})
  end

  @doc "Get belief statistics."
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @impl true
  def init(_opts) do
    Logger.info("Initializing Belief System")

    # Initialize state with empty belief store and indexes
    state = %{
      beliefs: %{},
      statement_index: %{},
      source_index: %{},
      confidence_index: %{},
      contradiction_registry: [],
      last_updated: DateTime.utc_now(),
      operation_count: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:add_belief, belief}, _from, state) do
    belief_id = belief.id

    # Check for duplicate belief
    if Map.has_key?(state.beliefs, belief_id) do
      Logger.warning("Belief with ID #{belief_id} already exists")
      {:reply, {:error, :belief_exists}, state}
    else
      # Add belief to system
      updated_beliefs = Map.put(state.beliefs, belief_id, belief)
      
      # Update indexes
      updated_statement_index = update_statement_index(state.statement_index, belief)
      updated_source_index = update_source_index(state.source_index, belief)
      updated_confidence_index = update_confidence_index(state.confidence_index, belief)
      
      # Check for contradictions
      {updated_contradiction_registry, contradiction_alert} = check_for_contradictions(updated_beliefs, belief)
      
      new_state = %{state |
        beliefs: updated_beliefs,
        statement_index: updated_statement_index,
        source_index: updated_source_index,
        confidence_index: updated_confidence_index,
        contradiction_registry: updated_contradiction_registry,
        last_updated: DateTime.utc_now(),
        operation_count: state.operation_count + 1
      }

      if contradiction_alert do
        Logger.warning("Contradiction detected when adding belief: #{belief_id}")
      end

      Logger.info("Added belief: #{belief_id} (confidence: #{belief.confidence})")
      {:reply, {:ok, belief_id}, new_state}
    end
  end

  @impl true
  def handle_call({:get_belief, belief_id}, _from, state) do
    case Map.get(state.beliefs, belief_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      belief ->
        {:reply, {:ok, belief}, state}
    end
  end

  @impl true
  def handle_call(:list_beliefs, _from, state) do
    beliefs = Map.values(state.beliefs)
    {:reply, {:ok, beliefs}, state}
  end

  @impl true
  def handle_call({:get_high_confidence_beliefs, threshold}, _from, state) do
    high_conf_beliefs = Enum.filter(state.beliefs, fn {_id, belief} ->
      belief.confidence >= threshold
    end)
    
    {:reply, {:ok, Map.values(high_conf_beliefs)}, state}
  end

  @impl true
  def handle_call({:get_beliefs_by_source, source}, _from, state) do
    belief_ids = Map.get(state.source_index, source, [])
    beliefs = Enum.map(belief_ids, &Map.get(state.beliefs, &1))
    
    {:reply, {:ok, beliefs}, state}
  end

  @impl true
  def handle_call({:search_beliefs, pattern}, _from, state) do
    matching_beliefs = Enum.filter(state.beliefs, fn {_id, belief} ->
      String.contains?(belief.statement, pattern)
    end)
    
    {:reply, {:ok, Map.values(matching_beliefs)}, state}
  end

  @impl true
  def handle_call(:detect_contradictions, _from, state) do
    contradictions = find_all_contradictions(state.beliefs)
    {:reply, {:ok, contradictions}, state}
  end

  @impl true
  def handle_call({:calculate_statement_confidence, statement}, _from, state) do
    related_beliefs = find_related_beliefs(state.beliefs, statement)
    confidence = calculate_aggregated_confidence(related_beliefs)
    
    {:reply, {:ok, confidence}, state}
  end

  @impl true
  def handle_call({:update_evidence, belief_id, new_evidence}, _from, state) do
    case Map.get(state.beliefs, belief_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      belief ->
        updated_belief = %{belief | 
          evidence: new_evidence,
          last_verified: DateTime.utc_now()
        }
        
        updated_beliefs = Map.put(state.beliefs, belief_id, updated_belief)
        
        new_state = %{state |
          beliefs: updated_beliefs,
          last_updated: DateTime.utc_now(),
          operation_count: state.operation_count + 1
        }

        Logger.info("Updated evidence for belief: #{belief_id}")
        {:reply, {:ok, updated_belief}, new_state}
    end
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      total_beliefs: map_size(state.beliefs),
      high_confidence_beliefs: length(Map.values(state.confidence_index.high || %{})),
      contradictions: length(state.contradiction_registry),
      last_updated: state.last_updated,
      operation_count: state.operation_count,
      source_distribution: get_source_distribution(state.source_index)
    }

    {:reply, {:ok, stats}, state}
  end

  # Private helper functions

  defp generate_belief_id do
    "belief:#{System.system_time(:millisecond)}:#{:crypto.strong_rand_bytes(8) |> Base.encode16()}"
  end

  defp update_statement_index(statement_index, belief) do
    normalized_statement = normalize_statement(belief.statement)
    belief_ids = Map.get(statement_index, normalized_statement, [])
    updated_ids = [belief.id | belief_ids]
    Map.put(statement_index, normalized_statement, updated_ids)
  end

  defp update_source_index(source_index, belief) do
    belief_ids = Map.get(source_index, belief.source, [])
    updated_ids = [belief.id | belief_ids]
    Map.put(source_index, belief.source, updated_ids)
  end

  defp update_confidence_index(confidence_index, belief) do
    confidence_bucket = get_confidence_bucket(belief.confidence)
    belief_ids = Map.get(confidence_index, confidence_bucket, [])
    updated_ids = [belief.id | belief_ids]
    Map.put(confidence_index, confidence_bucket, updated_ids)
  end

  defp check_for_contradictions(beliefs, new_belief) do
    contradictions = find_all_contradictions(beliefs)
    new_contradiction = find_contradictions_with_belief(beliefs, new_belief)
    
    updated_contradictions = 
      if new_contradiction do
        [new_contradiction | contradictions]
      else
        contradictions
      end
    
    {updated_contradictions, not is_nil(new_contradiction)}
  end

  defp find_all_contradictions(beliefs) do
    belief_list = Map.values(beliefs)

    for b1 <- belief_list,
        b2 <- belief_list,
        b1.id != b2.id,
        contradictory?(b1, b2) do
      {b1.id, b2.id}
    end
    |> Enum.uniq()
  end

  defp find_contradictions_with_belief(beliefs, new_belief) do
    belief_list = Map.values(beliefs)

    case Enum.find(belief_list, &contradictory?(new_belief, &1)) do
      nil -> nil
      belief -> {new_belief.id, belief.id}
    end
  end

  # Contradiction verdicts are delegated to the canonical kernel
  # `Tiannara.Logic.Contradiction.detect/2` (archaeology §4). The previous
  # negation-wording / keyword-counting heuristic was fabricated: it reported
  # contradictions from free-text vocabulary overlap and confidence deltas
  # without any structural claim evidence, so it is removed. Beliefs without
  # structured `subject`/`value` fields resolve to the kernel's `:unknown`
  # verdict — no contradiction is claimed, which truthfully drops those prior
  # false positives.
  defp contradictory?(b1, b2) do
    Tiannara.Logic.Contradiction.detect(claim_from_belief(b1), claim_from_belief(b2)) ==
      :contradiction
  end

  defp claim_from_belief(belief) do
    %{subject: Map.get(belief, :subject), value: Map.get(belief, :value)}
  end

  defp find_related_beliefs(beliefs, statement) do
    # Find beliefs that are semantically related to the statement
    statement_keywords = extract_keywords(statement)
    
    Enum.filter(beliefs, fn belief ->
      belief_keywords = extract_keywords(belief.statement)
      keyword_overlap = length(statement_keywords -- belief_keywords)
      
      # Consider related if significant keyword overlap
      keyword_overlap < length(statement_keywords) * 0.7
    end)
  end

  defp calculate_aggregated_confidence(beliefs) do
    if Enum.empty?(beliefs) do
      0.0
    else
      # Weighted average based on recency and source reliability
      weights = Enum.map(beliefs, fn belief ->
        recency_weight = calculate_recency_weight(belief.created_at)
        source_weight = get_source_reliability(belief.source)
        belief.confidence * recency_weight * source_weight
      end)
      
      total_weight = Enum.sum(weights)
      if total_weight > 0 do
        total_weight / Enum.sum(Enum.map(weights, & &1 / total_weight))
      else
        0.0
      end
    end
  end

  defp calculate_recency_weight(created_at) do
    # Newer beliefs have higher weight
    age = DateTime.diff(DateTime.utc_now(), created_at)
    max_age = 86400 * 7  # 7 days in seconds
    
    min(1.0, max_age / (age + max_age))
  end

  defp get_source_reliability(source) do
    case source do
      "system" -> 1.0
      "observation" -> 0.9
      "inference" -> 0.7
      "prediction" -> 0.5
      _ -> 0.6
    end
  end

  defp normalize_statement(statement) do
    # Normalize statement for comparison
    statement
    |> String.downcase()
    |> String.replace(~r[^the\s+], "")
    |> String.replace(~r[^\s+is\s+], "")
    |> String.trim()
  end

  defp extract_keywords(statement) do
    statement
    |> String.downcase()
    |> String.split(~r[\s+])
    |> Enum.uniq()
  end

  defp get_confidence_bucket(confidence) when confidence >= 0.9, do: :very_high
  defp get_confidence_bucket(confidence) when confidence >= 0.7, do: :high
  defp get_confidence_bucket(confidence) when confidence >= 0.5, do: :medium
  defp get_confidence_bucket(confidence) when confidence >= 0.3, do: :low
  defp get_confidence_bucket(_confidence), do: :very_low

  defp get_source_distribution(source_index) do
    source_index
    |> Enum.map(fn {source, beliefs} -> {source, length(beliefs)} end)
    |> Enum.into(%{})
  end
end