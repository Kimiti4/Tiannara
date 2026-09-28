defmodule Tiannara.Physics.TWP do
  @moduledoc """
  Temporal Wavefunction Pruning (TWP).

  Manages temporal coherence, prunes improbable futures, and maintains temporal information integrity.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def prune_temporal_states(_states, _pruning_threshold \\ 0.95) do
    {:error, :physics_substrate_unavailable}
  end

  def add_temporal_state(_state_id, _probability_vector, _metadata \\ %{}) do
    {:error, :physics_substrate_unavailable}
  end

  def get_temporal_states() do
    {:error, :physics_substrate_unavailable}
  end

  def calculate_temporal_coherence() do
    {:error, :physics_substrate_unavailable}
  end

  def prune_future_branches(_branch_entropy_threshold \\ 0.8) do
    {:error, :physics_substrate_unavailable}
  end

  def get_temporal_metrics() do
    {:error, :physics_substrate_unavailable}
  end

  def validate_temporal_consistency() do
    {:error, :physics_substrate_unavailable}
  end

  def collapse_temporal_wavefunction(_target_state_id) do
    {:error, :physics_substrate_unavailable}
  end

  def get_temporal_predictions() do
    {:error, :physics_substrate_unavailable}
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize ETS tables for temporal management
    :ets.new(:temporal_states, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(:temporal_metrics, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:temporal_history, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:temporal_consistency, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    # Configuration
    config = %{
      max_states: 1000,
      pruning_threshold: 0.95,
      collapse_threshold: 0.99,
      coherence_window: 10000,  # 10 seconds
      prediction_horizon: 5000,  # 5 seconds
      entropy_threshold: 0.8,
      max_branches: 100
    }

    # Initialize temporal consistency
    :ets.insert(:temporal_consistency, {
      config,
      System.system_time(:millisecond),
      0,
      0
    })

    Logger.info("Temporal Wavefunction Pruning initialized")
    
    {:ok, %{
      config: config,
      total_states: 0,
      pruned_states: 0,
      collapsed_states: 0,
      last_prune: 0,
      last_collapse: 0,
      temporal_coherence: 1.0,
      entropy_level: 0.0
    }}
  end

  @impl true
  def handle_call({:prune_temporal_states, states, threshold}, _from, state) when is_list(states) do
    # Calculate probabilities and sort by likelihood
    ranked_states = rank_temporal_states(states)
    
    # Apply pruning threshold
    pruned_states = Enum.filter(ranked_states, fn state ->
      state.probability >= threshold
    end)
    
    # Store pruned states
    timestamp = System.system_time(:millisecond)
    Enum.each(pruned_states, fn state ->
      temporal_data = %{
        state_id: state.id,
        probability: state.probability,
        entropy: state.entropy,
        timestamp: timestamp,
        metadata: state.metadata
      }
      :ets.insert(:temporal_states, {state.id, temporal_data})
    end)
    
    # Record pruning metrics
    pruning_metrics = %{
      timestamp: timestamp,
      original_count: length(ranked_states),
      pruned_count: length(pruned_states),
      threshold: threshold,
      entropy_reduction: calculate_entropy_reduction(ranked_states, pruned_states)
    }
    
    :ets.insert(:temporal_metrics, {pruning_metrics})
    
    Logger.info("Pruned #{length(ranked_states)} -> #{length(pruned_states)} temporal states")
    
    {:reply, {:ok, pruned_states}, 
     %{state | 
       total_states: state.total_states + length(pruned_states),
       pruned_states: state.pruned_states + (length(ranked_states) - length(pruned_states)),
       last_prune: timestamp,
       entropy_level: calculate_entropy_level(pruned_states)
     }}
  end

  @impl true
  def handle_call({:add_temporal_state, state_id, probability_vector, metadata}, _from, state) do
    # Validate state
    case validate_temporal_state(state_id, probability_vector) do
      :ok ->
        # Calculate derived metrics
        probability = calculate_probability(probability_vector)
        entropy = calculate_entropy(probability_vector)
        
        temporal_data = %{
          state_id: state_id,
          probability: probability,
          entropy: entropy,
          probability_vector: probability_vector,
          metadata: metadata,
          timestamp: System.system_time(:millisecond)
        }
        
        # Store state
        :ets.insert(:temporal_states, {state_id, temporal_data})
        
        # Check if collapse should occur
        if probability >= state.config.collapse_threshold do
          Process.send_after(self(), {:collapse_state, state_id}, 100)
        end
        
        Logger.debug("Added temporal state #{state_id} with probability #{probability}")
        
        {:reply, :ok, 
         %{state | 
           total_states: state.total_states + 1,
           temporal_coherence: do_calculate_temporal_coherence()
         }}
        
      {:error, reason} ->
        Logger.error("Invalid temporal state: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:get_temporal_states, _from, state) do
    states = :ets.tab2list(:temporal_states)
    |> Enum.map(fn {state_id, state_data} ->
      %{state_id: state_id, state: state_data}
    end)
    |> Enum.sort_by(& &1.state.probability, :desc)
    
    {:reply, {:ok, states}, state}
  end

  @impl true
  def handle_call(:calculate_temporal_coherence, _from, state) do
    coherence = do_calculate_temporal_coherence()
    {:reply, {:ok, coherence}, %{state | temporal_coherence: coherence}}
  end

  @impl true
  def handle_call({:prune_future_branches, entropy_threshold}, _from, state) do
    # Analyze temporal branches
    branches = analyze_temporal_branches()
    
    # Prune high-entropy branches
    pruned_branches = Enum.filter(branches, fn branch ->
      branch.entropy >= entropy_threshold
    end)
    
    # Remove pruned branches
    Enum.each(pruned_branches, fn branch ->
      Enum.each(branch.state_ids, fn state_id ->
        :ets.delete(:temporal_states, state_id)
      end)
    end)
    
    # Record metrics
    pruning_metrics = %{
      timestamp: System.system_time(:millisecond),
      total_branches: length(branches),
      pruned_branches: length(pruned_branches),
      entropy_threshold: entropy_threshold,
      states_removed: Enum.reduce(pruned_branches, 0, fn branch, acc -> acc + length(branch.state_ids) end)
    }
    
    :ets.insert(:temporal_metrics, {pruning_metrics})
    
    Logger.info("Pruned #{length(pruned_branches)} temporal branches with entropy >= #{entropy_threshold}")
    
    {:reply, {:ok, pruned_branches}, 
     %{state | 
       pruned_states: state.pruned_states + Enum.reduce(pruned_branches, 0, fn branch, acc -> acc + length(branch.state_ids) end),
       entropy_level: calculate_entropy_level(:ets.tab2list(:temporal_states))
     }}
  end

  @impl true
  def handle_call(:get_temporal_metrics, _from, state) do
    metrics = %{
      total_states: :ets.info(:temporal_states, :size),
      total_metrics: :ets.info(:temporal_metrics, :size),
      total_history: :ets.info(:temporal_history, :size),
      temporal_coherence: state.temporal_coherence,
      entropy_level: state.entropy_level,
      total_states_added: state.total_states,
      states_pruned: state.pruned_states,
      states_collapsed: state.collapsed_states,
      last_prune: state.last_prune,
      last_collapse: state.last_collapse
    }
    
    {:reply, {:ok, metrics}, state}
  end

  @impl true
  def handle_call(:validate_temporal_consistency, _from, state) do
    # Check temporal consistency
    consistency_check = perform_temporal_consistency_check()
    
    # Store consistency result
    timestamp = System.system_time(:millisecond)
    :ets.insert(:temporal_consistency, {
      timestamp,
      consistency_check.score,
      consistency_check.violations,
      consistency_check.warnings
    })
    
    # Update consistency metrics
    :ets.insert(:temporal_metrics, {
      timestamp,
      type: :consistency_check,
      score: consistency_check.score,
      violations: consistency_check.violations,
      warnings: consistency_check.warnings
    })
    
    Logger.info("Temporal consistency check: #{consistency_check.score}")
    
    {:reply, {:ok, consistency_check}, state}
  end

  @impl true
  def handle_call({:collapse_temporal_wavefunction, target_state_id}, _from, state) do
    case :ets.lookup(:temporal_states, target_state_id) do
      [{^target_state_id, target_data}] ->
        # Perform collapse
        collapse_result = perform_collapse(target_state_id, target_data)
        
        # Store collapse event
        timestamp = System.system_time(:millisecond)
        collapse_event = %{
          timestamp: timestamp,
          target_state: target_state_id,
          probability: target_data.probability,
          collapsed_to: collapse_result.collapsed_to,
          entropy_reduction: collapse_result.entropy_reduction
        }
        
        :ets.insert(:temporal_history, {collapse_event})
        
        Logger.info("Collapsed temporal wavefunction to #{target_state_id}")
        
        {:reply, {:ok, collapse_result}, 
         %{state | 
           collapsed_states: state.collapsed_states + 1,
           last_collapse: timestamp,
           temporal_coherence: 1.0
         }}
        
      [] ->
        {:reply, {:error, :target_state_not_found}, state}
    end
  end

  @impl true
  def handle_call(:get_temporal_predictions, _from, state) do
    predictions = generate_temporal_predictions()
    
    {:reply, {:ok, predictions}, state}
  end

  # Handle state collapse asynchronously
  @impl true
  def handle_info({:collapse_state, state_id}, state) do
    case :ets.lookup(:temporal_states, state_id) do
      [{^state_id, state_data}] ->
        # Perform collapse
        collapse_result = perform_collapse(state_id, state_data)
        
        # Store collapse event
        timestamp = System.system_time(:millisecond)
        collapse_event = %{
          timestamp: timestamp,
          target_state: state_id,
          probability: state_data.probability,
          collapsed_to: collapse_result.collapsed_to,
          entropy_reduction: collapse_result.entropy_reduction
        }
        
        :ets.insert(:temporal_history, {collapse_event})
        
        Logger.info("Async collapsed temporal wavefunction to #{state_id}")
        
        {:noreply, 
         %{state | 
           collapsed_states: state.collapsed_states + 1,
           last_collapse: timestamp,
           temporal_coherence: 1.0
         }}
        
      [] ->
        {:noreply, state}
    end
  end

  # Helper functions
  defp validate_temporal_state(state_id, probability_vector) when is_binary(state_id) and is_list(probability_vector) do
    case state_id do
      "" -> {:error, :empty_state_id}
      _ ->
        case probability_vector do
          [] -> {:error, :empty_probability_vector}
          _ ->
            # Validate probability vector structure
            case Enum.all?(probability_vector, &valid_probability_element?/1) do
              true -> :ok
              false -> {:error, :invalid_probability_vector}
            end
        end
    end
  end

  defp validate_temporal_state(_, _), do: {:error, :invalid_parameters}

  defp valid_probability_element?(element) do
    case element do
      {_, probability} when is_number(probability) and probability >= 0 and probability <= 1 -> true
      _ -> false
    end
  end

  defp rank_temporal_states(states) do
    Enum.map(states, fn state ->
      case state do
        %{id: id, probability: probability, entropy: entropy, metadata: metadata} ->
          %{id: id, probability: probability, entropy: entropy, metadata: metadata}
        %{id: id, probability: probability} ->
          %{id: id, probability: probability, entropy: calculate_entropy_from_state(state), metadata: %{}}
        state_id when is_binary(state_id) ->
          %{id: state_id, probability: 0.5, entropy: 0.5, metadata: %{}}
      end
    end)
    |> Enum.sort_by(& &1.probability, :desc)
  end

  defp calculate_entropy_reduction(original_states, pruned_states) do
    original_entropy = Enum.sum(Enum.map(original_states, & &1.entropy))
    pruned_entropy = Enum.sum(Enum.map(pruned_states, & &1.entropy))
    
    if original_entropy > 0 do
      (original_entropy - pruned_entropy) / original_entropy
    else
      0.0
    end
  end

  defp calculate_entropy_level(states) do
    if length(states) > 0 do
      Enum.sum(Enum.map(states, & &1.entropy)) / length(states)
    else
      0.0
    end
  end

  defp calculate_probability(probability_vector) do
    probabilities = Enum.map(probability_vector, &elem(&1, 1))
    Enum.sum(probabilities) / max(length(probabilities), 1)
  end

  defp calculate_entropy(probability_vector) do
    # Shannon entropy calculation
    probabilities = Enum.map(probability_vector, &elem(&1, 1))
    Enum.sum(Enum.map(probabilities, fn p ->
      if p > 0, do: -p * :math.log2(p), else: 0
    end))
  end

  defp calculate_entropy_from_state(state) do
    case state do
      %{entropy: entropy} -> entropy
      _ -> 0.5  # Default entropy
    end
  end

  defp do_calculate_temporal_coherence() do
    states = :ets.tab2list(:temporal_states)
    
    case length(states) do
      0 -> 1.0
      _ ->
        # Calculate coherence based on probability distribution
        probabilities = Enum.map(states, & &1.probability)
        avg_probability = Enum.sum(probabilities) / length(probabilities)
        
        # Higher coherence when probabilities are concentrated
        1.0 - :math.exp(-avg_probability * 5)
    end
  end

  defp analyze_temporal_branches() do
    # Group states by temporal branches
    states = :ets.tab2list(:temporal_states)
    
    # Simple branch analysis based on temporal proximity and similarity
    branches = Enum.chunk_by(states, fn state ->
      # Group by time window
      div(state.timestamp, 1000)
    end)
    
    Enum.map(branches, fn branch_states ->
      branch_entropy = calculate_entropy_level(branch_states)
      
      %{
        state_ids: Enum.map(branch_states, & &1.state_id),
        entropy: branch_entropy,
        timestamp: hd(branch_states).timestamp,
        state_count: length(branch_states)
      }
    end)
  end

  defp perform_temporal_consistency_check() do
    states = :ets.tab2list(:temporal_states)
    
    # Check for temporal contradictions
    contradictions = check_temporal_contradictions(states)
    
    # Check probability normalization
    normalization_issues = check_probability_normalization(states)
    
    # Check temporal ordering
    ordering_violations = check_temporal_ordering(states)
    
    # Calculate overall consistency score
    total_issues = length(contradictions) + length(normalization_issues) + length(ordering_violations)
    score = max(0.0, 1.0 - (total_issues / max(length(states), 1)))
    
    %{
      score: score,
      violations: contradictions ++ normalization_issues ++ ordering_violations,
      warnings: [],  # Additional warnings can be added here
      timestamp: System.system_time(:millisecond)
    }
  end

  defp check_temporal_contradictions(_states) do
    # Check for states with conflicting timestamps or probabilities
    contradictions = []
    
    # Add contradiction detection logic here
    # For example, states with same ID but different probabilities
    # Or states with invalid temporal relationships
    
    contradictions
  end

  defp check_probability_normalization(states) do
    Enum.flat_map(states, fn state ->
      sum =
        state.probability_vector
        |> Enum.map(&elem(&1, 1))
        |> Enum.sum()

      if abs(sum - 1.0) > 0.01 do
        ["State #{state.state_id} probability vector not normalized: #{sum}"]
      else
        []
      end
    end)
  end

  defp check_temporal_ordering(states) do
    sorted_states = Enum.sort_by(states, & &1.timestamp)

    sorted_states
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {state, idx} ->
      if idx > 1 do
        prev_state = Enum.at(sorted_states, idx - 2)
        prob_diff = abs(state.probability - prev_state.probability)
        if prob_diff > 0.5 do
          ["Large probability jump from #{prev_state.state_id} to #{state.state_id}: #{prob_diff}"]
        else
          []
        end
      else
        []
      end
    end)
  end

  defp perform_collapse(target_state_id, _target_data) do
    # Remove other states with high probability
    states = :ets.tab2list(:temporal_states)
    high_prob_states = Enum.filter(states, fn state ->
      state.state_id != target_state_id and state.probability > 0.1
    end)
    
    # Remove high probability states
    Enum.each(high_prob_states, fn state ->
      :ets.delete(:temporal_states, state.state_id)
    end)
    
    # Normalize remaining probabilities
    remaining_states = :ets.tab2list(:temporal_states)
    total_prob = Enum.sum(Enum.map(remaining_states, & &1.probability))
    
    if total_prob > 0 do
      Enum.each(remaining_states, fn state ->
        updated_data = %{state | 
          probability: state.probability / total_prob,
          collapsed: true
        }
        :ets.insert(:temporal_states, {state.state_id, updated_data})
      end)
    end
    
    %{
      collapsed_to: target_state_id,
      states_removed: length(high_prob_states),
      entropy_reduction: calculate_entropy_reduction(
        states ++ high_prob_states, 
        remaining_states
      )
    }
  end

  defp generate_temporal_predictions() do
    states = :ets.tab2list(:temporal_states)
    
    # Generate predictions based on current temporal state
    predictions = Enum.map(states, fn state ->
      # Simple prediction: extrapolate current probability
      predicted_probability = state.probability * 0.95  # Slight decay
      predicted_entropy = state.entropy * 1.05  # Slight increase
      
      %{
        source_state: state.state_id,
        predicted_probability: predicted_probability,
        predicted_entropy: predicted_entropy,
        confidence: state.probability,
        timestamp: System.system_time(:millisecond) + state.config.prediction_horizon
      }
    end)
    
    # Sort by confidence and return top predictions
    predictions
    |> Enum.sort_by(& &1.confidence, :desc)
    |> Enum.take(10)  # Top 10 predictions
  end
end
