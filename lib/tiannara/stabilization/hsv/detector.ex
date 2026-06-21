defmodule Tiannara.Stabilization.HSV.Detector do
  @moduledoc """
  Singularity detector for the HSV system.

  Monitors ontology density levels and detects when singularity formation is imminent.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def monitor_region(region, density_data) do
    GenServer.call(__MODULE__, {:monitor_region, region, density_data})
  end

  def get_detection_thresholds() do
    GenServer.call(__MODULE__, :get_detection_thresholds)
  end

  def set_detection_thresholds(thresholds) do
    GenServer.call(__MODULE__, {:set_detection_thresholds, thresholds})
  end

  def get_active_detections() do
    GenServer.call(__MODULE__, :get_active_detections)
  end

  def run_full_scan() do
    GenServer.call(__MODULE__, :run_full_scan)
  end

  def get_detection_stats() do
    GenServer.call(__MODULE__, :get_detection_stats)
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize ETS tables for detection
    :ets.new(:density_monitoring, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(:detection_history, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:detection_thresholds, [
      :set,
      :public,
      :named_table
    ])

    # Set default thresholds
    default_thresholds = %{
      warning: 0.7,
      critical: 0.85,
      singularity: 0.95,
      concept_density_warning: 0.8,
      causal_density_warning: 0.75
    }

    :ets.insert(:detection_thresholds, {:defaults, default_thresholds})

    Logger.info("HSV detector initialized")
    
    {:ok, %{
      thresholds: default_thresholds,
      active_detections: 0,
      total_detections: 0,
      false_positives: 0,
      last_scan: 0,
      monitoring_regions: 0
    }}
  end

  @impl true
  def handle_call({:monitor_region, region, density_data}, _from, state) do
    # Validate density data
    validated = validate_density_data(density_data)
    
    # Store monitoring data
    timestamp = System.system_time(:millisecond)
    :ets.insert(:density_monitoring, {region, timestamp, validated})
    
    # Check for singularity conditions
    detection = analyze_density_anomalies(region, validated, state.thresholds)
    
    case detection do
      {:alert, level, details} ->
        Logger.warning("Singularity alert for region #{region}: #{level} - #{inspect(details)}")
        
        # Record detection
        :ets.insert(:detection_history, {timestamp, region, level, details})
        
        {:reply, {:ok, {:alert, level, details}}, update_detection_stats(state, :alert)}
        
      {:normal, metrics} ->
        Logger.debug("Region #{region} density normal: #{inspect(metrics)}")
        {:reply, {:ok, {:normal, metrics}}, update_detection_stats(state, :normal)}
    end
  end

  @impl true
  def handle_call(:get_detection_thresholds, _from, state) do
    case :ets.lookup(:detection_thresholds, :defaults) do
      [{:defaults, thresholds}] -> {:reply, {:ok, thresholds}, state}
      [] -> {:reply, {:error, :thresholds_not_found}, state}
    end
  end

  @impl true
  def handle_call({:set_detection_thresholds, thresholds}, _from, state) when is_map(thresholds) do
    # Validate thresholds
    validated = validate_thresholds(thresholds)
    
    # Update stored thresholds
    :ets.insert(:detection_thresholds, {:defaults, validated})
    
    Logger.info("Updated detection thresholds: #{inspect(validated)}")
    
    {:reply, :ok, %{state | thresholds: validated}}
  end

  @impl true
  def handle_call(:get_active_detections, _from, state) do
    # Get current active detections (recent alerts)
    current_time = System.system_time(:millisecond)
    recent_threshold = current_time - 60_000  # Last minute
    
    recent_detections = :ets.select(:detection_history, [{
      {:"$1", :"$2", :"$3", :"$4"},
      [{:>, :"$1", recent_threshold}],
      [{{:"$2", :"$3", :"$4"}}]
    }])
    
    {:reply, {:ok, recent_detections}, state}
  end

  @impl true
  def handle_call(:run_full_scan, _from, state) do
    current_time = System.system_time(:millisecond)
    
    # Scan all monitored regions
    monitored_regions = :ets.tab2list(:density_monitoring)
    
    results = Enum.map(monitored_regions, fn {region, _, density_data} ->
      analysis = analyze_density_anomalies(region, density_data, state.thresholds)
      {region, analysis}
    end)
    
    # Count alerts
    alerts = Enum.filter(results, fn {_, {:alert, _, _}} -> true; _ -> false end)
    
    Logger.info("Full scan completed: #{length(alerts)} alerts out of #{length(results)} regions")
    
    {:reply, {:ok, %{total_regions: length(results), alerts: length(alerts)}}, 
     %{state | last_scan: current_time}}
  end

  @impl true
  def handle_call(:get_detection_stats, _from, state) do
    stats = %{
      active_detections: state.active_detections,
      total_detections: state.total_detections,
      false_positives: state.false_positives,
      monitoring_regions: :ets.info(:density_monitoring, :size),
      last_scan: state.last_scan,
      threshold_settings: state.thresholds
    }
    
    {:reply, {:ok, stats}, state}
  end

  # Helper functions
  defp validate_density_data(density_data) when is_map(density_data) do
    %{
      overall_density: min(max(Map.get(density_data, :overall_density, 0.0), 0.0), 1.0),
      concept_density: min(max(Map.get(density_data, :concept_density, 0.0), 0.0), 1.0),
      causal_density: min(max(Map.get(density_data, :causal_density, 0.0), 0.0), 1.0),
      timestamp: System.system_time(:millisecond),
      concept_count: Map.get(density_data, :concept_count, 0),
      causal_links: Map.get(density_data, :causal_links, 0),
      metadata: Map.get(density_data, :metadata, %{})
    }
  end

  defp validate_density_data(_), do: %{}

  defp validate_thresholds(thresholds) when is_map(thresholds) do
    %{
      warning: min(max(Map.get(thresholds, :warning, 0.7), 0.0), 1.0),
      critical: min(max(Map.get(thresholds, :critical, 0.85), 0.0), 1.0),
      singularity: min(max(Map.get(thresholds, :singularity, 0.95), 0.0), 1.0),
      concept_density_warning: min(max(Map.get(thresholds, :concept_density_warning, 0.8), 0.0), 1.0),
      causal_density_warning: min(max(Map.get(thresholds, :causal_density_warning, 0.75), 0.0), 1.0)
    }
  end

  defp validate_thresholds(_), do: %{
    warning: 0.7,
    critical: 0.85,
    singularity: 0.95,
    concept_density_warning: 0.8,
    causal_density_warning: 0.75
  }

  defp analyze_density_anomalies(region, density_data, thresholds) do
    # Check various density metrics against thresholds
    metrics = %{
      overall_density: density_data.overall_density,
      concept_density: density_data.concept_density,
      causal_density: density_data.causal_density,
      concept_count: density_data.concept_count,
      causal_links: density_data.causal_links
    }
    
    # Determine alert level
    cond do
      # Singularity threshold
      density_data.overall_density >= thresholds.singularity ->
        {:alert, :singularity_imminent, %{
          region: region,
          density: density_data.overall_density,
          threshold: thresholds.singularity,
          metrics: metrics
        }}
      
      # Critical threshold
      density_data.overall_density >= thresholds.critical ->
        {:alert, :critical_density, %{
          region: region,
          density: density_data.overall_density,
          threshold: thresholds.critical,
          metrics: metrics
        }}
      
      # Warning threshold
      density_data.overall_density >= thresholds.warning ->
        {:alert, :warning_density, %{
          region: region,
          density: density_data.overall_density,
          threshold: thresholds.warning,
          metrics: metrics
        }}
      
      # Concept density anomaly
      density_data.concept_density >= thresholds.concept_density_warning ->
        {:alert, :concept_density_anomaly, %{
          region: region,
          concept_density: density_data.concept_density,
          threshold: thresholds.concept_density_warning,
          metrics: metrics
        }}
      
      # Causal density anomaly
      density_data.causal_density >= thresholds.causal_density_warning ->
        {:alert, :causal_density_anomaly, %{
          region: region,
          causal_density: density_data.causal_density,
          threshold: thresholds.causal_density_warning,
          metrics: metrics
        }}
      
      # Normal
      true ->
        {:normal, metrics}
    end
  end

  defp update_detection_stats(%{total_detections: total} = state, :alert) do
    %{state | 
      total_detections: total + 1,
      active_detections: state.active_detections + 1
    }
  end

  defp update_detection_stats(%{total_detections: total} = state, :normal) do
    %{state | 
      total_detections: total + 1,
      active_detections: max(0, state.active_detections - 1)
    }
  end
end
