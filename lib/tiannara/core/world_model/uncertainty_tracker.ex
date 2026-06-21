defmodule Tiannara.Core.WorldModel.UncertaintyTracker do
  @moduledoc """
  Uncertainty Tracker for the World Model.

  Manages ambiguities, contradictions, and confidence distributions.
  """

  use GenServer
  require Logger

  @doc "Start the Uncertainty Tracker server."
  def start_link(opts) do
    shard_id = Keyword.get(opts, :shard_id, :world_0)
    name = Tiannara.ROS.Registry.via(__MODULE__, shard_id)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "Add an ambiguity to the tracker."
  def add_ambiguity(entity_id, description, ambiguity_level \\ 0.5) do
    ambiguity = %{
      id: generate_ambiguity_id(),
      entity_id: entity_id,
      description: description,
      level: ambiguity_level,
      created_at: DateTime.utc_now(),
      sources: [],
      resolution_attempts: 0
    }

    GenServer.call(__MODULE__, {:add_ambiguity, ambiguity})
  end

  @doc "Add a contradiction to the tracker."
  def add_contradiction(entity_id, statement1, statement2, confidence1, confidence2) do
    contradiction = %{
      id: generate_contradiction_id(),
      entity_id: entity_id,
      statements: [statement1, statement2],
      confidences: [confidence1, confidence2],
      created_at: DateTime.utc_now(),
      resolution_status: :unresolved,
      resolution_attempts: 0
    }

    GenServer.call(__MODULE__, {:add_contradiction, contradiction})
  end

  @doc "Add a source to an ambiguity."
  def add_ambiguity_source(ambiguity_id, source_type, source_description) do
    source = %{
      type: source_type,
      description: source_description,
      timestamp: DateTime.utc_now()
    }

    GenServer.call(__MODULE__, {:add_ambiguity_source, ambiguity_id, source})
  end

  @doc "Attempt to resolve an ambiguity."
  def attempt_ambiguity_resolution(ambiguity_id, resolution_method, result) do
    GenServer.call(__MODULE__, {:attempt_ambiguity_resolution, ambiguity_id, resolution_method, result})
  end

  @impl true
  def init(_opts) do
    Logger.info("Initializing Uncertainty Tracker")

    # Initialize state with uncertainty tracking structures
    state = %{
      ambiguities: %{},
      contradictions: %{},
      entity_uncertainty: %{},
      confidence_distribution: %{},
      resolution_history: [],
      last_updated: DateTime.utc_now(),
      operation_count: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:add_ambiguity, ambiguity}, _from, state) do
    ambiguity_id = ambiguity.id

    if Map.has_key?(state.ambiguities, ambiguity_id) do
      Logger.warning("Ambiguity with ID #{ambiguity_id} already exists")
      {:reply, {:error, :ambiguity_exists}, state}
    else
      # Add ambiguity to tracker
      updated_ambiguities = Map.put(state.ambiguities, ambiguity_id, ambiguity)
      
      # Update entity uncertainty index
      updated_entity_uncertainty = update_entity_uncertainty(state.entity_uncertainty, ambiguity_id, ambiguity.level)
      
      # Update confidence distribution
      updated_confidence_distribution = update_confidence_distribution(state.confidence_distribution, ambiguity.level)
      
      new_state = %{state |
        ambiguities: updated_ambiguities,
        entity_uncertainty: updated_entity_uncertainty,
        confidence_distribution: updated_confidence_distribution,
        last_updated: DateTime.utc_now(),
        operation_count: state.operation_count + 1
      }

      Logger.info("Added ambiguity: #{ambiguity_id} (level: #{ambiguity.level})")
      {:reply, {:ok, ambiguity_id}, new_state}
    end
  end

  @impl true
  def handle_call({:add_contradiction, contradiction}, _from, state) do
    contradiction_id = contradiction.id

    if Map.has_key?(state.contradictions, contradiction_id) do
      Logger.warning("Contradiction with ID #{contradiction_id} already exists")
      {:reply, {:error, :contradiction_exists}, state}
    else
      # Add contradiction to tracker
      updated_contradictions = Map.put(state.contradictions, contradiction_id, contradiction)
      
      # Update entity uncertainty (contradictions increase uncertainty)
      updated_entity_uncertainty = update_entity_uncertainty(state.entity_uncertainty, contradiction_id, 0.8)
      
      # Update confidence distribution
      updated_confidence_distribution = update_confidence_distribution(state.confidence_distribution, 0.9)
      
      # Record in resolution history
      resolution_record = %{
        type: :contradiction,
        id: contradiction_id,
        timestamp: DateTime.utc_now(),
        action: :detected
      }
      
      new_state = %{state |
        contradictions: updated_contradictions,
        entity_uncertainty: updated_entity_uncertainty,
        confidence_distribution: updated_confidence_distribution,
        resolution_history: [resolution_record | state.resolution_history],
        last_updated: DateTime.utc_now(),
        operation_count: state.operation_count + 1
      }

      Logger.warning("Detected contradiction: #{contradiction_id}")
      {:reply, {:ok, contradiction_id}, new_state}
    end
  end

  @impl true
  def handle_call({:add_ambiguity_source, ambiguity_id, source}, _from, state) do
    case Map.get(state.ambiguities, ambiguity_id) do
      nil ->
        {:reply, {:error, :ambiguity_not_found}, state}
      ambiguity ->
        updated_ambiguity = %{ambiguity |
          sources: [source | ambiguity.sources]
        }
        
        updated_ambiguities = Map.put(state.ambiguities, ambiguity_id, updated_ambiguity)
        
        new_state = %{state |
          ambiguities: updated_ambiguities,
          last_updated: DateTime.utc_now(),
          operation_count: state.operation_count + 1
        }

        Logger.info("Added source to ambiguity: #{ambiguity_id}")
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:attempt_ambiguity_resolution, ambiguity_id, resolution_method, result}, _from, state) do
    case Map.get(state.ambiguities, ambiguity_id) do
      nil ->
        {:reply, {:error, :ambiguity_not_found}, state}
      ambiguity ->
        # Update ambiguity with resolution attempt
        updated_ambiguity = %{ambiguity |
          resolution_attempts: ambiguity.resolution_attempts + 1,
          resolution_status: determine_resolution_status(result)
        }
        
        updated_ambiguities = Map.put(state.ambiguities, ambiguity_id, updated_ambiguity)
        
        # Update entity uncertainty based on resolution result
        resolution_impact = calculate_resolution_impact(result)
        updated_entity_uncertainty = update_entity_uncertainty(state.entity_uncertainty, ambiguity_id, resolution_impact)
        
        # Record resolution attempt
        resolution_record = %{
          type: :ambiguity,
          id: ambiguity_id,
          timestamp: DateTime.utc_now(),
          action: :resolution_attempt,
          method: resolution_method,
          result: result,
          success: determine_resolution_success(result)
        }
        
        new_state = %{state |
          ambiguities: updated_ambiguities,
          entity_uncertainty: updated_entity_uncertainty,
          resolution_history: [resolution_record | state.resolution_history],
          last_updated: DateTime.utc_now(),
          operation_count: state.operation_count + 1
        }

        Logger.info("Attempted resolution for ambiguity: #{ambiguity_id}")
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call(:get_ambiguities, _from, state) do
    ambiguities = Map.values(state.ambiguities)
    {:reply, {:ok, ambiguities}, state}
  end

  @impl true
  def handle_call(:get_contradictions, _from, state) do
    contradictions = Map.values(state.contradictions)
    {:reply, {:ok, contradictions}, state}
  end

  @impl true
  def handle_call(:get_entity_uncertainty, _from, state) do
    {:reply, {:ok, state.entity_uncertainty}, state}
  end

  @impl true
  def handle_call(:get_confidence_distribution, _from, state) do
    {:reply, {:ok, state.confidence_distribution}, state}
  end

  @impl true
  def handle_call(:get_resolution_history, _from, state) do
    {:reply, {:ok, state.resolution_history}, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      total_ambiguities: map_size(state.ambiguities),
      total_contradictions: map_size(state.contradictions),
      unresolved_ambiguities: count_unresolved(state.ambiguities),
      unresolved_contradictions: count_unresolved(state.contradictions),
      avg_uncertainty_level: calculate_average_uncertainty(state.entity_uncertainty),
      resolution_success_rate: calculate_resolution_success_rate(state.resolution_history),
      last_updated: state.last_updated,
      operation_count: state.operation_count,
      uncertainty_distribution: get_uncertainty_distribution(state.entity_uncertainty)
    }

    {:reply, {:ok, stats}, state}
  end

  # Private helper functions

  defp generate_ambiguity_id do
    "ambiguity:#{System.system_time(:millisecond)}:#{:crypto.strong_rand_bytes(8) |> Base.encode16()}"
  end

  defp generate_contradiction_id do
    "contradiction:#{System.system_time(:millisecond)}:#{:crypto.strong_rand_bytes(8) |> Base.encode16()}"
  end

  defp update_entity_uncertainty(entity_uncertainty, entity_id, uncertainty_level) do
    current_uncertainty = Map.get(entity_uncertainty, entity_id, 0.0)
    
    # Weighted average with new uncertainty level
    updated_uncertainty = 0.7 * current_uncertainty + 0.3 * uncertainty_level
    
    Map.put(entity_uncertainty, entity_id, updated_uncertainty)
  end

  defp update_confidence_distribution(confidence_distribution, uncertainty_level) do
    # Update confidence distribution based on uncertainty level
    bucket = get_uncertainty_bucket(uncertainty_level)
    current_count = Map.get(confidence_distribution, bucket, 0)
    
    Map.put(confidence_distribution, bucket, current_count + 1)
  end

  defp determine_resolution_status(result) when result == :resolved, do: :resolved
  defp determine_resolution_status(result) when result == :partially_resolved, do: :partially_resolved
  defp determine_resolution_status(_result), do: :unresolved

  defp calculate_resolution_impact(:resolved), do: 0.1   # Significant reduction
  defp calculate_resolution_impact(:partially_resolved), do: 0.3  # Moderate reduction
  defp calculate_resolution_impact(_), do: 0.8  # No improvement

  defp determine_resolution_success(:resolved), do: true
  defp determine_resolution_success(:partially_resolved), do: true
  defp determine_resolution_success(_), do: false

  defp count_unresolved(items) do
    Enum.count(items, fn {_id, item} ->
      item.resolution_status == :unresolved
    end)
  end

  defp calculate_average_uncertainty(entity_uncertainty) do
    if Enum.empty?(entity_uncertainty) do
      0.0
    else
      uncertainty_values = Map.values(entity_uncertainty)
      Enum.sum(uncertainty_values) / length(uncertainty_values)
    end
  end

  defp calculate_resolution_success_rate(resolution_history) do
    if Enum.empty?(resolution_history) do
      0.0
    else
      successful_attempts = Enum.count(resolution_history, fn record ->
        record.success == true
      end)
      
      successful_attempts / length(resolution_history)
    end
  end

  defp get_uncertainty_bucket(uncertainty) when uncertainty >= 0.8, do: :very_high
  defp get_uncertainty_bucket(uncertainty) when uncertainty >= 0.6, do: :high
  defp get_uncertainty_bucket(uncertainty) when uncertainty >= 0.4, do: :medium
  defp get_uncertainty_bucket(uncertainty) when uncertainty >= 0.2, do: :low
  defp get_uncertainty_bucket(_uncertainty), do: :very_low

  defp get_uncertainty_distribution(entity_uncertainty) do
    entity_uncertainty
    |> Enum.group_by(fn {_id, uncertainty} -> get_uncertainty_bucket(uncertainty) end)
    |> Enum.map(fn {bucket, entities} -> {bucket, length(entities)} end)
    |> Enum.into(%{})
  end
end