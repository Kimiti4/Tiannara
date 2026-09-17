defmodule TiannaraRuntime.MetaStability.StabilityMetrics do
  @moduledoc """
  PHASE 4D.1: Stability Metrics Collector
  
  Continuously tracks system stability indicators to enable self-tuning.
  
  Metrics tracked:
  - Collapse frequency (coalitions dissolving per time window)
  - Recovery time (ticks to restore coherence after collapse)
  - Oscillation rate (rapid state changes indicating instability)
  - Entropy variance (fluctuation in system disorder)
  - Coherence duration (how long coalitions remain stable)
  - Arbitration flip rate (CAL changing decisions frequently)
  
  These metrics feed into the optimization engine for parameter adjustment.
  """
  
  use GenServer
  require Logger
  
  @window_size 100  # Number of ticks in sliding window
  @update_interval_ms 5000  # Update metrics every 5 seconds
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Record a coalition collapse event.
  """
  def record_collapse(coalition_id, timestamp \\ nil) do
    GenServer.cast(__MODULE__, {:record_collapse, coalition_id, timestamp || DateTime.utc_now()})
  end
  
  @doc """
  Record a recovery event (coalition restored to stability).
  """
  def record_recovery(coalition_id, recovery_ticks, timestamp \\ nil) do
    GenServer.cast(__MODULE__, {:record_recovery, coalition_id, recovery_ticks, timestamp || DateTime.utc_now()})
  end
  
  @doc """
  Record an oscillation event (rapid state change).
  """
  def record_oscillation(coalition_id, amplitude, timestamp \\ nil) do
    GenServer.cast(__MODULE__, {:record_oscillation, coalition_id, amplitude, timestamp || DateTime.utc_now()})
  end
  
  @doc """
  Record entropy measurement.
  """
  def record_entropy(entropy_value, timestamp \\ nil) do
    GenServer.cast(__MODULE__, {:record_entropy, entropy_value, timestamp || DateTime.utc_now()})
  end
  
  @doc """
  Record coherence measurement.
  """
  def record_coherence(coalition_id, coherence_value, timestamp \\ nil) do
    GenServer.cast(__MODULE__, {:record_coherence, coalition_id, coherence_value, timestamp || DateTime.utc_now()})
  end
  
  @doc """
  Record arbitration decision flip.
  """
  def record_arbitration_flip(old_decision, new_decision, timestamp \\ nil) do
    GenServer.cast(__MODULE__, {:record_arbitration_flip, old_decision, new_decision, timestamp || DateTime.utc_now()})
  end
  
  @doc """
  Get current stability metrics summary.
  
  Returns: %{collapse_frequency, avg_recovery_time, oscillation_rate, entropy_variance, ...}
  """
  def get_metrics() do
    GenServer.call(__MODULE__, :get_metrics)
  end
  
  @doc """
  Get stability score (0.0-1.0, higher = more stable).
  """
  def get_stability_score() do
    GenServer.call(__MODULE__, :get_stability_score)
  end
  
  @doc """
  Reset all metrics (for testing or system restart).
  """
  def reset_metrics() do
    GenServer.cast(__MODULE__, :reset)
  end
  
  # Server Implementation
  
  @impl true
  def init(_opts) do
    state = %{
      collapses: [],          # [{coalition_id, timestamp}]
      recoveries: [],         # [{coalition_id, recovery_ticks, timestamp}]
      oscillations: [],       # [{coalition_id, amplitude, timestamp}]
      entropy_readings: [],   # [{value, timestamp}]
      coherence_readings: [], # [{coalition_id, value, timestamp}]
      arbitration_flips: [],  # [{old, new, timestamp}]
      last_update: DateTime.utc_now()
    }
    
    Logger.info("📊 Stability Metrics collector initialized")
    
    # Schedule periodic metric updates
    schedule_update()
    
    {:ok, state}
  end
  
  @impl true
  def handle_cast({:record_collapse, coalition_id, timestamp}, state) do
    new_collapses = [{coalition_id, timestamp} | state.collapses]
    |> Enum.take(@window_size)
    
    Logger.debug("📊 Recorded collapse: #{coalition_id}")
    
    {:noreply, %{state | collapses: new_collapses}}
  end
  
  @impl true
  def handle_cast({:record_recovery, coalition_id, recovery_ticks, timestamp}, state) do
    new_recoveries = [{coalition_id, recovery_ticks, timestamp} | state.recoveries]
    |> Enum.take(@window_size)
    
    Logger.debug("📊 Recorded recovery: #{coalition_id} (#{recovery_ticks} ticks)")
    
    {:noreply, %{state | recoveries: new_recoveries}}
  end
  
  @impl true
  def handle_cast({:record_oscillation, coalition_id, amplitude, timestamp}, state) do
    new_oscillations = [{coalition_id, amplitude, timestamp} | state.oscillations]
    |> Enum.take(@window_size)
    
    {:noreply, %{state | oscillations: new_oscillations}}
  end
  
  @impl true
  def handle_cast({:record_entropy, value, timestamp}, state) do
    new_entropy = [{value, timestamp} | state.entropy_readings]
    |> Enum.take(@window_size)
    
    {:noreply, %{state | entropy_readings: new_entropy}}
  end
  
  @impl true
  def handle_cast({:record_coherence, coalition_id, value, timestamp}, state) do
    new_coherence = [{coalition_id, value, timestamp} | state.coherence_readings]
    |> Enum.take(@window_size)
    
    {:noreply, %{state | coherence_readings: new_coherence}}
  end
  
  @impl true
  def handle_cast({:record_arbitration_flip, old_decision, new_decision, timestamp}, state) do
    new_flips = [{old_decision, new_decision, timestamp} | state.arbitration_flips]
    |> Enum.take(@window_size)
    
    Logger.debug("📊 Recorded arbitration flip: #{old_decision} → #{new_decision}")
    
    {:noreply, %{state | arbitration_flips: new_flips}}
  end
  
  @impl true
  def handle_cast(:reset, _state) do
    Logger.info("📊 Resetting all stability metrics")
    
    new_state = %{
      collapses: [],
      recoveries: [],
      oscillations: [],
      entropy_readings: [],
      coherence_readings: [],
      arbitration_flips: [],
      last_update: DateTime.utc_now()
    }
    
    {:noreply, new_state}
  end
  
  @impl true
  def handle_call(:get_metrics, _from, state) do
    metrics = calculate_metrics(state)
    {:reply, {:ok, metrics}, state}
  end
  
  @impl true
  def handle_call(:get_stability_score, _from, state) do
    metrics = calculate_metrics(state)
    score = compute_stability_score(metrics)
    {:reply, {:ok, score}, state}
  end
  
  @impl true
  def handle_info(:update_metrics, state) do
    metrics = calculate_metrics(state)
    
    # Broadcast metrics update via PubSub
    Phoenix.PubSub.broadcast(
      TiannaraRuntime.PubSub,
      "stability_metrics",
      {:metrics_update, metrics}
    )
    
    Logger.debug("📊 Metrics updated: collapse_freq=#{metrics.collapse_frequency}, " <>
                 "avg_recovery=#{metrics.avg_recovery_time}, " <>
                 "stability_score=#{Float.round(metrics.stability_score, 3)}")
    
    schedule_update()
    
    {:noreply, %{state | last_update: DateTime.utc_now()}}
  end
  
  # Private Functions
  
  defp schedule_update() do
    Process.send_after(self(), :update_metrics, @update_interval_ms)
  end
  
  defp calculate_metrics(state) do
    %{
      collapse_frequency: calculate_collapse_frequency(state.collapses),
      avg_recovery_time: calculate_avg_recovery_time(state.recoveries),
      oscillation_rate: calculate_oscillation_rate(state.oscillations),
      entropy_variance: calculate_entropy_variance(state.entropy_readings),
      avg_coherence: calculate_avg_coherence(state.coherence_readings),
      arbitration_flip_rate: calculate_arbitration_flip_rate(state.arbitration_flips),
      coherence_duration: estimate_coherence_duration(state.coherence_readings),
      stability_score: 0.0  # Will be computed separately
    }
  end
  
  defp calculate_collapse_frequency(collapses) do
    if length(collapses) == 0 do
      0.0
    else
      # Collapses per 100 ticks (normalized)
      length(collapses) / @window_size * 100
    end
  end
  
  defp calculate_avg_recovery_time(recoveries) do
    if length(recoveries) == 0 do
      0.0
    else
      total_ticks = Enum.sum(Enum.map(recoveries, fn {_, ticks, _} -> ticks end))
      total_ticks / length(recoveries)
    end
  end
  
  defp calculate_oscillation_rate(oscillations) do
    if length(oscillations) == 0 do
      0.0
    else
      # Average amplitude of oscillations
      total_amplitude = Enum.sum(Enum.map(oscillations, fn {_, amp, _} -> amp end))
      total_amplitude / length(oscillations)
    end
  end
  
  defp calculate_entropy_variance(entropy_readings) do
    if length(entropy_readings) < 2 do
      0.0
    else
      values = Enum.map(entropy_readings, fn {val, _} -> val end)
      mean = Enum.sum(values) / length(values)
      variance = Enum.sum(Enum.map(values, fn v -> (v - mean) ** 2 end)) / length(values)
      :math.sqrt(variance)
    end
  end
  
  defp calculate_avg_coherence(coherence_readings) do
    if length(coherence_readings) == 0 do
      0.0
    else
      values = Enum.map(coherence_readings, fn {_, val, _} -> val end)
      Enum.sum(values) / length(values)
    end
  end
  
  defp calculate_arbitration_flip_rate(flips) do
    if length(flips) == 0 do
      0.0
    else
      # Flips per 100 ticks
      length(flips) / @window_size * 100
    end
  end
  
  defp estimate_coherence_duration(coherence_readings) do
    if length(coherence_readings) < 2 do
      0.0
    else
      # Estimate how long coherence stays above threshold (0.7)
      stable_periods = Enum.chunk_every(coherence_readings, 2, 1)
      |> Enum.filter(fn [first, second] ->
        {_, val1, _} = first
        {_, val2, _} = second
        val1 >= 0.7 and val2 >= 0.7
      end)
      |> length()
      
      stable_periods / length(coherence_readings) * @window_size
    end
  end
  
  defp compute_stability_score(metrics) do
    # Composite stability score (0.0-1.0)
    # Higher score = more stable system
    
    # Factors (all normalized to 0-1 range):
    collapse_penalty = min(metrics.collapse_frequency / 10.0, 1.0)  # Lower is better
    recovery_bonus = 1.0 - min(metrics.avg_recovery_time / 20.0, 1.0)  # Faster is better
    coherence_bonus = metrics.avg_coherence  # Higher is better
    oscillation_penalty = min(metrics.oscillation_rate / 1.0, 1.0)  # Lower is better
    entropy_penalty = min(metrics.entropy_variance / 0.3, 1.0)  # Lower is better
    flip_penalty = min(metrics.arbitration_flip_rate / 5.0, 1.0)  # Lower is better
    
    # Weighted combination
    score = (
      (1.0 - collapse_penalty) * 0.25 +
      recovery_bonus * 0.20 +
      coherence_bonus * 0.25 +
      (1.0 - oscillation_penalty) * 0.15 +
      (1.0 - entropy_penalty) * 0.10 +
      (1.0 - flip_penalty) * 0.05
    )
    
    # Clamp to [0.0, 1.0]
    max(0.0, min(1.0, score))
  end
end
