defmodule Tiannara.Stabilization.OLEF.EntropyTracker do
  @moduledoc """
  Tracks and analyzes entropy distribution across the ontology field.

  Monitors entropy levels and triggers redistribution when needed.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def track_entropy(ontology_id, entropy_data) do
    GenServer.call(__MODULE__, {:track_entropy, ontology_id, entropy_data})
  end

  def get_global_entropy() do
    GenServer.call(__MODULE__, :get_global_entropy)
  end

  def get_entropy_history(ontology_id \\ nil) do
    GenServer.call(__MODULE__, {:get_entropy_history, ontology_id})
  end

  def detect_anomalies() do
    GenServer.call(__MODULE__, :detect_anomalies)
  end

  def redistribute_if_needed() do
    GenServer.call(__MODULE__, :redistribute_if_needed)
  end

  def get_entropy_stats() do
    GenServer.call(__MODULE__, :get_entropy_stats)
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize ETS tables for entropy tracking
    :ets.new(:entropy_history, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:entropy_aggregates, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:entropy_thresholds, [
      :set,
      :public,
      :named_table
    ])

    # Set default entropy thresholds
    default_thresholds = %{
      critical_high: 0.9,
      warning_high: 0.7,
      warning_low: 0.3,
      critical_low: 0.1
    }

    :ets.insert(:entropy_thresholds, {:defaults, default_thresholds})

    Logger.info("Entropy tracker initialized")
    
    {:ok, %{
      global_entropy: 0.0,
      last_redistribution: 0,
      redistribution_count: 0,
      anomaly_count: 0,
      tracking_count: 0
    }}
  end

  @impl true
  def handle_call({:track_entropy, ontology_id, entropy_data}, _from, state) do
    # Validate entropy data
    validated = validate_entropy_data(entropy_data)
    
    # Store entropy measurement
    timestamp = System.system_time(:millisecond)
    :ets.insert(:entropy_history, {ontology_id, timestamp, validated})
    
    # Update aggregates
    update_entropy_aggregates(ontology_id, validated)
    
    # Check if redistribution is needed
    should_redistribute = should_redistribute_entropy(state)
    
    if should_redistribute do
      Logger.warning("Entropy threshold exceeded, triggering redistribution")
      # Trigger redistribution (would call OLEF.main)
      # For now, just update state
      new_state = %{state | 
        redistribution_count: state.redistribution_count + 1,
        last_redistribution: timestamp
      }
      {:reply, {:ok, :redistribution_triggered}, new_state}
    else
      {:reply, :ok, %{state | 
        tracking_count: state.tracking_count + 1
      }}
    end
  end

  @impl true
  def handle_call(:get_global_entropy, _from, state) do
    # Calculate current global entropy
    global_entropy = calculate_current_global_entropy()
    
    {:reply, {:ok, global_entropy}, %{state | global_entropy: global_entropy}}
  end

  @impl true
  def handle_call({:get_entropy_history, ontology_id}, _from, state) do
    case ontology_id do
      nil ->
        # Get global entropy history
        history = group_by_ontology()
        {:reply, {:ok, history}, state}
        
      _ ->
        # Get history for specific ontology
        history = :ets.select(:entropy_history, [{
          {ontology_id, :"$1", :"$2"},
          [],
          [:"$1"]
        }])
        |> Enum.map(fn {timestamp, entropy} -> %{timestamp: timestamp, entropy: entropy} end)
        |> Enum.sort_by(& &1.timestamp)
        
        {:reply, {:ok, history}, state}
    end
  end

  @impl true
  def handle_call(:detect_anomalies, _from, state) do
    anomalies = detect_entropy_anomalies()
    
    case anomalies do
      [] ->
        Logger.debug("No entropy anomalies detected")
        {:reply, {:ok, []}, state}
      _ ->
        Logger.warning("Detected #{length(anomalies)} entropy anomalies")
        {:reply, {:ok, anomalies}, %{state | anomaly_count: state.anomaly_count + length(anomalies)}}
    end
  end

  @impl true
  def handle_call(:redistribute_if_needed, _from, state) do
    global_entropy = calculate_current_global_entropy()
    thresholds = get_entropy_thresholds()
    
    if global_entropy > thresholds.warning_high do
      Logger.warning("Global entropy #{global_entropy} exceeds threshold #{thresholds.warning_high}")
      # Trigger redistribution
      {:reply, {:ok, :redistribution_triggered}, %{state | 
        redistribution_count: state.redistribution_count + 1,
        last_redistribution: System.system_time(:millisecond)
      }}
    else
      {:reply, {:ok, :no_redistribution_needed}, state}
    end
  end

  @impl true
  def handle_call(:get_entropy_stats, _from, state) do
    stats = %{
      global_entropy: state.global_entropy,
      total_trackings: state.tracking_count,
      redistribution_count: state.redistribution_count,
      anomaly_count: state.anomaly_count,
      last_redistribution: state.last_redistribution,
      ontology_count: :ets.info(:entropy_history, :size)
    }
    
    {:reply, {:ok, stats}, state}
  end

  # Helper functions
  defp validate_entropy_data(entropy_data) when is_map(entropy_data) do
    # Ensure entropy values are within valid range [0, 1]
    Enum.map(entropy_data, fn {region, entropy} ->
      normalized_entropy = min(max(entropy, 0.0), 1.0)
      {region, normalized_entropy}
    end) |> Map.new()
  end

  defp validate_entropy_data(_), do: %{}

  defp update_entropy_aggregates(ontology_id, entropy_data) do
    # Calculate aggregate metrics for this ontology
    entropy_values = Map.values(entropy_data)
    
    aggregates = %{
      average: Enum.sum(entropy_values) / max(length(entropy_values), 1),
      maximum: Enum.max(entropy_values),
      minimum: Enum.min(entropy_values),
      variance: calculate_variance(entropy_values)
    }
    
    :ets.insert(:entropy_aggregates, {ontology_id, aggregates})
  end

  defp calculate_variance(values) do
    if length(values) > 1 do
      mean = Enum.sum(values) / length(values)
      sum_sq = Enum.map(values, fn x -> :math.pow(x - mean, 2) end) |> Enum.sum()
      sum_sq / length(values)
    else
      0.0
    end
  end

  defp calculate_current_global_entropy() do
    # Calculate weighted average of all ontologies
    aggregates = :ets.tab2list(:entropy_aggregates)
    
    if length(aggregates) > 0 do
      total_weight = aggregates |> Enum.map(fn {_, agg} -> agg.average end) |> Enum.sum()
      total_weight / length(aggregates)
    else
      0.0
    end
  end

  defp should_redistribute_entropy(%{global_entropy: global_entropy} = state) do
    thresholds = get_entropy_thresholds()
    
    # Check if entropy is too high or too low
    too_high = global_entropy > thresholds.warning_high
    too_low = global_entropy < thresholds.warning_low
    
    # Also check if enough time has passed since last redistribution
    time_since_redistribution = System.system_time(:millisecond) - state.last_redistribution
    min_interval = 60_000  # 1 minute minimum interval
    
    (too_high or too_low) and time_since_redistribution > min_interval
  end

  defp detect_entropy_anomalies() do
    aggregates = :ets.tab2list(:entropy_aggregates)
    thresholds = get_entropy_thresholds()
    
    Enum.reduce(aggregates, [], fn {ontology_id, agg}, anomalies ->
      cond do
        agg.average > thresholds.critical_high ->
          [%{ontology_id: ontology_id, type: :critical_high, value: agg.average} | anomalies]
        
        agg.average < thresholds.critical_low ->
          [%{ontology_id: ontology_id, type: :critical_low, value: agg.average} | anomalies]
        
        agg.variance > 0.5 ->
          [%{ontology_id: ontology_id, type: :high_variance, value: agg.variance} | anomalies]
        
        true ->
          anomalies
      end
    end)
  end

  defp get_entropy_thresholds() do
    case :ets.lookup(:entropy_thresholds, :defaults) do
      [{:defaults, thresholds}] -> thresholds
      [] -> %{
        critical_high: 0.9,
        warning_high: 0.7,
        warning_low: 0.3,
        critical_low: 0.1
      }
    end
  end

  defp group_by_ontology() do
    :ets.tab2list(:entropy_history)
    |> Enum.group_by(fn {ontology_id, _, _} -> ontology_id end)
    |> Enum.map(fn {ontology_id, entries} ->
      %{
        ontology_id: ontology_id,
        history: Enum.map(entries, fn {_, timestamp, entropy} -> 
          %{timestamp: timestamp, entropy: entropy} 
        end)
        |> Enum.sort_by(& &1.timestamp)
      }
    end)
    |> Enum.sort_by(& &1.ontology_id)
  end
end
