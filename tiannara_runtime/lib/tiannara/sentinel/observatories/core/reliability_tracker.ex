defmodule Tiannara.Sentinel.Observatories.Core.ReliabilityTracker do
  @moduledoc """
  Tracks historical performance to assign reliability states.
  Uses exponential moving averages for adaptive drift detection.
  """
  use GenServer
  require Logger

  @type observatory_id :: atom()
  @type reliability_state :: :unproven | :provisional | :trusted
  
  @evaluation_thresholds %{
    unproven: %{min_evaluations: 0, min_accuracy: 0.0, max_cal_error: 1.0},
    provisional: %{min_evaluations: 50, min_accuracy: 0.60, max_cal_error: 0.25},
    trusted: %{min_evaluations: 200, min_accuracy: 0.80, max_cal_error: 0.15}
  }
  
  @ema_alpha 0.05  # Slow adaptation to prevent noisy state flips
  @recency_half_life_hours 48

  # Public API
  @spec record_outcome(observatory_id(), map(), any()) :: :ok
  def record_outcome(observatory_id, signal, observed) do
    GenServer.cast(__MODULE__, {:record, observatory_id, signal, observed})
  end

  @spec get_state(observatory_id()) :: %{state: reliability_state(), metrics: map()}
  def get_state(observatory_id) do
    GenServer.call(__MODULE__, {:get_state, observatory_id})
  end

  @spec compute_weight(observatory_id()) :: float()
  def compute_weight(observatory_id) do
    %{state: state, metrics: %{accuracy: acc, calibration_error: cal_err, recency: rec, diversity: div}} = 
      get_state(observatory_id)
    
    # We apply D.0 insight here explicitly:
    # weight = state_multiplier * accuracy * (1 - cal_error) * diversity * recency
    state_mult = case state do
      :trusted -> 1.0
      :provisional -> 0.7
      :unproven -> 0.3
    end
    
    # Use diversity from metrics (updated live or via EpistemicDiversityTracker)
    diversity_mult = if div == 0.0, do: 1.0, else: div

    Float.round(state_mult * acc * (1 - cal_err) * diversity_mult * rec, 3)
  end

  # GenServer callbacks
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{
      metrics: %{},      # observatory_id => performance_metrics
      evaluations: %{},  # observatory_id => count
      last_updated: %{}  # observatory_id => timestamp
    }}
  end

  @impl true
  def handle_cast({:record, obs_id, signal, observed}, state) do
    # Compute evaluation result
    match = outcomes_match?(signal.recommended_action, observed)
    calibration_delta = abs(signal.confidence - if(match, do: 1.0, else: 0.0))
    
    # Update or initialize metrics
    current = Map.get(state.metrics, obs_id, default_metrics())
    eval_count = Map.get(state.evaluations, obs_id, 0)
    
    # EMA updates
    new_accuracy = ema_update(current.accuracy, if(match, do: 1.0, else: 0.0), @ema_alpha)
    new_cal_error = ema_update(current.calibration_error, calibration_delta, @ema_alpha)
    
    # Recency weight
    now = System.system_time(:second)
    hours_since = if state.last_updated[obs_id], 
      do: (now - state.last_updated[obs_id]) / 3600, 
      else: @recency_half_life_hours
    recency = :math.pow(0.5, hours_since / @recency_half_life_hours)
    
    # Determine reliability state
    new_state = classify_reliability(eval_count + 1, new_accuracy, new_cal_error)
    
    # Fetch diversity from tracker
    div_mod = Tiannara.Sentinel.Observatories.EpistemicDiversityTracker.get_diversity_modifier(obs_id)

    # Compute drift metrics based on calibration error changes
    prev_cal_error = current.calibration_error
    velocity = Float.round(new_cal_error - prev_cal_error, 4)
    acceleration = Float.round(velocity - Map.get(current, :drift_velocity, 0.0), 4)

    Logger.debug("📊 [RELIABILITY] #{obs_id}: #{new_state} (acc=#{Float.round(new_accuracy,3)}, cal=#{Float.round(new_cal_error,3)}, vel=#{velocity}, acc=#{acceleration})")
    
    {:noreply, %{
      state |
      metrics: Map.put(state.metrics, obs_id, %{
        accuracy: Float.round(new_accuracy, 4),
        calibration_error: Float.round(new_cal_error, 4),
        recency: Float.round(recency, 4),
        diversity: div_mod,
        drift_velocity: velocity,
        drift_acceleration: acceleration
      }),
      evaluations: Map.put(state.evaluations, obs_id, eval_count + 1),
      last_updated: Map.put(state.last_updated, obs_id, now)
    }}
  end

  @impl true
  def handle_call({:get_state, obs_id}, _from, state) do
    metrics = Map.get(state.metrics, obs_id, default_metrics())
    eval_count = Map.get(state.evaluations, obs_id, 0)
    state_label = classify_reliability(eval_count, metrics.accuracy, metrics.calibration_error)
    
    {:reply, %{state: state_label, metrics: metrics}, state}
  end

  # Helpers
  defp default_metrics do
    %{accuracy: 0.5, calibration_error: 0.5, recency: 1.0, diversity: 1.0, drift_velocity: 0.0, drift_acceleration: 0.0}
  end

  defp ema_update(prev, curr, alpha), do: alpha * curr + (1 - alpha) * prev

  defp outcomes_match?(expected, observed) when is_atom(expected) and is_atom(observed), do: expected == observed
  defp outcomes_match?(%{action: exp}, %{action: obs}), do: exp == obs
  defp outcomes_match?(_, _), do: false

  defp classify_reliability(eval_count, accuracy, cal_error) do
    cond do
      eval_count >= @evaluation_thresholds.trusted.min_evaluations and
      accuracy >= @evaluation_thresholds.trusted.min_accuracy and
      cal_error <= @evaluation_thresholds.trusted.max_cal_error -> :trusted
      
      eval_count >= @evaluation_thresholds.provisional.min_evaluations and
      accuracy >= @evaluation_thresholds.provisional.min_accuracy and
      cal_error <= @evaluation_thresholds.provisional.max_cal_error -> :provisional
      
      true -> :unproven
    end
  end
end
