defmodule Tiannara.Core.WorldModel.PredictionEngine do
  @moduledoc """
  Prediction Engine for the World Model.

  Generates scenario forecasts, horizon predictions, and probabilistic outcomes.
  """

  use GenServer
  require Logger

  @doc "Start the Prediction Engine server."
  def start_link(opts) do
    shard_id = Keyword.get(opts, :shard_id, :world_0)
    name = Tiannara.ROS.Registry.via(__MODULE__, shard_id)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "Create a new prediction scenario."
  def create_prediction(scenario_id, target_entity, prediction_type, time_horizon, base_probability \\ 0.5) do
    scenario = %{
      id: scenario_id,
      target_entity: target_entity,
      prediction_type: prediction_type,
      time_horizon: time_horizon,
      base_probability: base_probability,
      created_at: DateTime.utc_now(),
      factors: [],
      historical_data: [],
      confidence: 0.0,
      status: :draft,
      predictions: []
    }

    GenServer.call(__MODULE__, {:create_prediction, scenario})
  end

  @doc "Add a factor to a prediction scenario."
  def add_prediction_factor(scenario_id, factor_description, weight, confidence) do
    factor = %{
      id: generate_factor_id(),
      description: factor_description,
      weight: weight,
      confidence: confidence,
      timestamp: DateTime.utc_now()
    }

    GenServer.call(__MODULE__, {:add_prediction_factor, scenario_id, factor})
  end

  @impl true
  def init(_opts) do
    Logger.info("Initializing Prediction Engine")

    # Initialize state with prediction tracking structures
    state = %{
      scenarios: %{},
      entity_index: %{},
      type_index: %{},
      time_index: %{},
      historical_patterns: %{},
      active_predictions: [],
      last_updated: DateTime.utc_now(),
      operation_count: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:create_prediction, scenario}, _from, state) do
    scenario_id = scenario.id

    if Map.has_key?(state.scenarios, scenario_id) do
      Logger.warning("Prediction scenario with ID #{scenario_id} already exists")
      {:reply, {:error, :scenario_exists}, state}
    else
      # Add scenario to prediction engine
      updated_scenarios = Map.put(state.scenarios, scenario_id, scenario)
      
      # Update indexes
      updated_entity_index = update_entity_index(state.entity_index, scenario)
      updated_type_index = update_type_index(state.type_index, scenario)
      updated_time_index = update_time_index(state.time_index, scenario)
      
      new_state = %{state |
        scenarios: updated_scenarios,
        entity_index: updated_entity_index,
        type_index: updated_type_index,
        time_index: updated_time_index,
        last_updated: DateTime.utc_now(),
        operation_count: state.operation_count + 1
      }

      Logger.info("Created prediction scenario: #{scenario_id} (type: #{scenario.prediction_type})")
      {:reply, {:ok, scenario_id}, new_state}
    end
  end

  @impl true
  def handle_call({:add_prediction_factor, scenario_id, factor}, _from, state) do
    case Map.get(state.scenarios, scenario_id) do
      nil ->
        {:reply, {:error, :scenario_not_found}, state}
      scenario ->
        # Add factor to scenario
        updated_scenario = %{scenario |
          factors: [factor | scenario.factors],
          status: :factors_added
        }
        
        updated_scenarios = Map.put(state.scenarios, scenario_id, updated_scenario)
        
        new_state = %{state |
          scenarios: updated_scenarios,
          last_updated: DateTime.utc_now(),
          operation_count: state.operation_count + 1
        }

        Logger.info("Added factor to scenario: #{scenario_id}")
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:generate_predictions, scenario_id}, _from, state) do
    case Map.get(state.scenarios, scenario_id) do
      nil ->
        {:reply, {:error, :scenario_not_found}, state}
      scenario ->
        # Generate predictions based on factors
        predictions = generate_scenario_predictions(scenario, state.historical_patterns)
        
        # Update scenario with predictions
        updated_scenario = %{scenario |
          predictions: predictions,
          confidence: calculate_scenario_confidence(predictions),
          status: :predictions_generated,
          last_updated: DateTime.utc_now()
        }
        
        updated_scenarios = Map.put(state.scenarios, scenario_id, updated_scenario)
        
        # Add to active predictions if confidence is high enough
        active_predictions = if updated_scenario.confidence >= 0.6 do
          [updated_scenario | state.active_predictions]
        else
          state.active_predictions
        end
        
        new_state = %{state |
          scenarios: updated_scenarios,
          active_predictions: active_predictions,
          last_updated: DateTime.utc_now(),
          operation_count: state.operation_count + 1
        }

        Logger.info("Generated predictions for scenario: #{scenario_id}")
        {:reply, {:ok, predictions}, new_state}
    end
  end

  @impl true
  def handle_call({:update_scenario_confidence, scenario_id, new_confidence}, _from, state) do
    case Map.get(state.scenarios, scenario_id) do
      nil ->
        {:reply, {:error, :scenario_not_found}, state}
      scenario ->
        updated_scenario = %{scenario |
          confidence: new_confidence,
          last_updated: DateTime.utc_now()
        }
        
        updated_scenarios = Map.put(state.scenarios, scenario_id, updated_scenario)
        
        # Update active predictions if necessary
        updated_active_predictions = if new_confidence >= 0.6 do
          if Enum.any?(state.active_predictions, & &1.id == scenario_id) do
            state.active_predictions
          else
            [updated_scenario | state.active_predictions]
          end
        else
          # Remove from active predictions if confidence dropped
          Enum.reject(state.active_predictions, & &1.id == scenario_id)
        end
        
        new_state = %{state |
          scenarios: updated_scenarios,
          active_predictions: updated_active_predictions,
          last_updated: DateTime.utc_now(),
          operation_count: state.operation_count + 1
        }

        Logger.info("Updated confidence for scenario: #{scenario_id}")
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call(:get_scenarios, _from, state) do
    scenarios = Map.values(state.scenarios)
    {:reply, {:ok, scenarios}, state}
  end

  @impl true
  def handle_call(:get_active_predictions, _from, state) do
    {:reply, {:ok, state.active_predictions}, state}
  end

  @impl true
  def handle_call({:get_scenarios_by_entity, entity_id}, _from, state) do
    scenario_ids = Map.get(state.entity_index, entity_id, [])
    scenarios = Enum.map(scenario_ids, &Map.get(state.scenarios, &1))
    
    {:reply, {:ok, scenarios}, state}
  end

  @impl true
  def handle_call({:get_scenarios_by_type, prediction_type}, _from, state) do
    scenario_ids = Map.get(state.type_index, prediction_type, [])
    scenarios = Enum.map(scenario_ids, &Map.get(state.scenarios, &1))
    
    {:reply, {:ok, scenarios}, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      total_scenarios: map_size(state.scenarios),
      active_predictions: length(state.active_predictions),
      high_confidence_predictions: length(Enum.filter(state.active_predictions, & &1.confidence >= 0.8)),
      avg_confidence: calculate_average_confidence(state.scenarios),
      time_horizon_distribution: get_time_horizon_distribution(state.scenarios),
      last_updated: state.last_updated,
      operation_count: state.operation_count,
      scenario_status_distribution: get_scenario_status_distribution(state.scenarios)
    }

    {:reply, {:ok, stats}, state}
  end

  # Private helper functions

  defp generate_factor_id do
    "factor:#{System.system_time(:millisecond)}:#{:crypto.strong_rand_bytes(8) |> Base.encode16()}"
  end

  defp update_entity_index(entity_index, scenario) do
    scenario_ids = Map.get(entity_index, scenario.target_entity, [])
    updated_ids = [scenario.id | scenario_ids]
    Map.put(entity_index, scenario.target_entity, updated_ids)
  end

  defp update_type_index(type_index, scenario) do
    scenario_ids = Map.get(type_index, scenario.prediction_type, [])
    updated_ids = [scenario.id | scenario_ids]
    Map.put(type_index, scenario.prediction_type, updated_ids)
  end

  defp update_time_index(time_index, scenario) do
    # Group scenarios by time horizon
    horizon_bucket = get_time_horizon_bucket(scenario.time_horizon)
    scenario_ids = Map.get(time_index, horizon_bucket, [])
    updated_ids = [scenario.id | scenario_ids]
    Map.put(time_index, horizon_bucket, updated_ids)
  end

  defp generate_scenario_predictions(scenario, historical_patterns) do
    # Base prediction on scenario factors and historical data
    factor_weights = Enum.map(scenario.factors, & &1.weight)
    total_weight = Enum.sum(factor_weights)
    
    if total_weight == 0 do
      # No significant factors, return default predictions
      generate_default_predictions(scenario)
    else
      # Weighted prediction based on factors
      weighted_probability = calculate_weighted_probability(scenario.factors, historical_patterns)
      
      # Generate multiple prediction outcomes
      generate_outcome_predictions(scenario, weighted_probability)
    end
  end

  defp calculate_weighted_probability(factors, historical_patterns) do
    # Calculate weighted probability based on factor weights and confidences
    weighted_sum = Enum.reduce(factors, 0.0, fn factor, acc ->
      factor_weight = factor.weight * factor.confidence
      acc + factor_weight
    end)
    
    # Normalize to probability range [0, 1]
    max_possible_weight = length(factors) * 1.0  # Assuming max weight of 1.0 per factor
    min(1.0, max(0.0, weighted_sum / max_possible_weight))
  end

  defp generate_default_predictions(scenario) do
    # Default prediction when no significant factors
    [%{
      outcome: "no_significant_change",
      probability: 0.6,
      confidence: 0.4,
      description: "No significant change expected based on available data",
      timeframe: scenario.time_horizon
    }]
  end

  defp generate_outcome_predictions(scenario, base_probability) do
    # Generate multiple possible outcomes with different probabilities
    outcomes = [
      %{
        outcome: "positive",
        probability: base_probability * 0.8,
        confidence: calculate_outcome_confidence("positive", scenario),
        description: "Positive outcome based on current factors",
        timeframe: scenario.time_horizon
      },
      %{
        outcome: "neutral",
        probability: 1.0 - (base_probability * 0.6),
        confidence: calculate_outcome_confidence("neutral", scenario),
        description: "Neutral outcome with no significant change",
        timeframe: scenario.time_horizon
      },
      %{
        outcome: "negative",
        probability: (1.0 - base_probability) * 0.7,
        confidence: calculate_outcome_confidence("negative", scenario),
        description: "Negative outcome based on current factors",
        timeframe: scenario.time_horizon
      }
    ]
    
    # Normalize probabilities to sum to 1.0
    normalize_probabilities(outcomes)
  end

  defp calculate_outcome_confidence(outcome_type, scenario) do
    # Calculate confidence based on factors and historical patterns
    factor_confidence = Enum.map(scenario.factors, & &1.confidence)
    |> Enum.sum()
    |> Kernel./(length(scenario.factors))
    
    # Adjust based on outcome type
    case outcome_type do
      "positive" -> factor_confidence * 0.9
      "neutral" -> factor_confidence * 0.7
      "negative" -> factor_confidence * 0.8
    end
  end

  defp normalize_probabilities(outcomes) do
    total_prob = Enum.sum(Enum.map(outcomes, & &1.probability))
    
    Enum.map(outcomes, fn outcome ->
      %{outcome | 
        probability: outcome.probability / total_prob,
        normalized: true
      }
    end)
  end

  defp calculate_scenario_confidence(predictions) do
    if Enum.empty?(predictions) do
      0.0
    else
      # Weighted average of prediction confidences
      confidence_sum = Enum.reduce(predictions, 0.0, fn prediction, acc ->
        acc + prediction.confidence * prediction.probability
      end)
      
      confidence_sum
    end
  end

  defp calculate_average_confidence(scenarios) do
    if Enum.empty?(scenarios) do
      0.0
    else
      confidence_values = Enum.map(scenarios, fn {_id, scenario} -> scenario.confidence end)
      Enum.sum(confidence_values) / length(confidence_values)
    end
  end

  defp get_time_horizon_bucket(time_horizon) when time_horizon >= 365, do: :long_term
  defp get_time_horizon_bucket(time_horizon) when time_horizon >= 30, do: :medium_term
  defp get_time_horizon_bucket(time_horizon) when time_horizon >= 7, do: :short_term
  defp get_time_horizon_bucket(_time_horizon), do: :immediate

  defp get_time_horizon_distribution(scenarios) do
    scenarios
    |> Enum.map(fn {_id, scenario} -> get_time_horizon_bucket(scenario.time_horizon) end)
    |> Enum.group_by(& &1)
    |> Enum.map(fn {bucket, scenario_list} -> {bucket, length(scenario_list)} end)
    |> Enum.into(%{})
  end

  defp get_scenario_status_distribution(scenarios) do
    scenarios
    |> Enum.map(fn {_id, scenario} -> scenario.status end)
    |> Enum.group_by(& &1)
    |> Enum.map(fn {status, scenario_list} -> {status, length(scenario_list)} end)
    |> Enum.into(%{})
  end
end