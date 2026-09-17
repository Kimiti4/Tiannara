defmodule TiannaraRuntime.MetaStability.ParameterAdjustment do
  @moduledoc """
  PHASE 4D.2: Parameter Adjustment Engine
  
  Dynamically tunes CAL and CIS parameters based on stability metrics.
  
  Adjustable Parameters:
  
  CIS Parameters:
  - entropy_threshold: When to trigger interventions (0.0-1.0)
  - intervention_strength: How strong interventions are (0.0-1.0)
  - damping_factor: How quickly to damp oscillations (0.0-1.0)
  
  CAL Parameters:
  - clustering_sensitivity: How sensitive coalition formation is (0.0-1.0)
  - coherence_threshold: Minimum coherence for stable coalitions (0.0-1.0)
  - arbitration_bias: Bias toward stability vs. exploration (0.0-1.0)
  
  Adjustment Strategy:
  - High collapse frequency → Increase CIS intervention strength
  - Slow recovery → Lower entropy threshold (intervene earlier)
  - High oscillation → Increase damping factor
  - Low coherence → Increase CAL coherence threshold
  - High flip rate → Increase arbitration bias toward stability
  """
  
  use GenServer
  require Logger
  
  # Default parameter ranges
  @cis_entropy_threshold_range {0.5, 0.9}
  @cis_intervention_strength_range {0.3, 0.9}
  @cis_damping_factor_range {0.1, 0.7}
  
  @cal_clustering_sensitivity_range {0.3, 0.9}
  @cal_coherence_threshold_range {0.6, 0.9}
  @cal_arbitration_bias_range {0.2, 0.8}
  
  # Adjustment step sizes (how much to change per optimization cycle)
  @adjustment_step 0.05
  @max_adjustment_per_cycle 0.15
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Get current system parameters.
  
  Returns: %{cis: %{...}, cal: %{...}}
  """
  def get_parameters() do
    GenServer.call(__MODULE__, :get_parameters)
  end
  
  @doc """
  Adjust parameters based on stability metrics.
  
  Returns: {:ok, adjustments_made} where adjustments_made is a list of changed params
  """
  def adjust_parameters(metrics) do
    GenServer.call(__MODULE__, {:adjust, metrics})
  end
  
  @doc """
  Manually set a parameter (for testing or override).
  """
  def set_parameter(category, param_name, value) do
    GenServer.call(__MODULE__, {:set_parameter, category, param_name, value})
  end
  
  @doc """
  Lock parameters (prevent automatic adjustment).
  """
  def lock_parameters() do
    GenServer.cast(__MODULE__, :lock)
  end
  
  @doc """
  Unlock parameters (allow automatic adjustment).
  """
  def unlock_parameters() do
    GenServer.cast(__MODULE__, :unlock)
  end
  
  # Server Implementation
  
  @impl true
  def init(_opts) do
    state = %{
      parameters: default_parameters(),
      locked: false,
      adjustment_history: [],  # [{timestamp, old_params, new_params, reason}]
      last_adjustment: nil
    }
    
    Logger.info("⚙️ Parameter Adjustment Engine initialized")
    Logger.info("   Initial parameters: #{inspect(state.parameters)}")
    
    {:ok, state}
  end
  
  @impl true
  def handle_call(:get_parameters, _from, state) do
    {:reply, {:ok, state.parameters}, state}
  end
  
  @impl true
  def handle_call({:adjust, metrics}, _from, state) do
    if state.locked do
      Logger.debug("⚙️ Parameters locked, skipping adjustment")
      {:reply, {:ok, []}, state}
    else
      # Calculate adjustments
      adjustments = calculate_adjustments(state.parameters, metrics)
      
      if length(adjustments) > 0 do
        # Apply adjustments with limits
        new_parameters = apply_adjustments(state.parameters, adjustments)
        
        # Record history
        history_entry = %{
          timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
          old_parameters: state.parameters,
          new_parameters: new_parameters,
          adjustments: adjustments,
          metrics_summary: summarize_metrics(metrics)
        }
        
        new_history = [history_entry | Enum.take(state.adjustment_history, 99)]
        
        Logger.info("⚙️ Parameters adjusted:")
        Enum.each(adjustments, fn {param, old_val, new_val, reason} ->
          Logger.info("   #{param}: #{Float.round(old_val, 3)} → #{Float.round(new_val, 3)} (#{reason})")
        end)
        
        # Broadcast parameter update
        Phoenix.PubSub.broadcast(
          TiannaraRuntime.PubSub,
          "parameter_updates",
          {:parameters_changed, new_parameters, adjustments}
        )
        
        new_state = %{state |
          parameters: new_parameters,
          adjustment_history: new_history,
          last_adjustment: DateTime.utc_now()
        }
        
        {:reply, {:ok, adjustments}, new_state}
      else
        Logger.debug("⚙️ No adjustments needed")
        {:reply, {:ok, []}, state}
      end
    end
  end
  
  @impl true
  def handle_call({:set_parameter, category, param_name, value}, _from, state) do
    # Validate parameter exists and value is in range
    case validate_parameter(category, param_name, value) do
      :ok ->
        new_parameters = put_in(state.parameters, [category, param_name], value)
        
        Logger.info("⚙️ Manual parameter set: #{category}.#{param_name} = #{value}")
        
        {:reply, :ok, %{state | parameters: new_parameters}}
      
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end
  
  @impl true
  def handle_cast(:lock, state) do
    Logger.info("⚙️ Parameters locked")
    {:ok, %{state | locked: true}}
  end
  
  @impl true
  def handle_cast(:unlock, state) do
    Logger.info("⚙️ Parameters unlocked")
    {:ok, %{state | locked: false}}
  end
  
  # Private Functions
  
  defp default_parameters() do
    %{
      cis: %{
        entropy_threshold: 0.7,
        intervention_strength: 0.6,
        damping_factor: 0.4
      },
      cal: %{
        clustering_sensitivity: 0.6,
        coherence_threshold: 0.75,
        arbitration_bias: 0.5
      }
    }
  end
  
  defp calculate_adjustments(parameters, metrics) do
    adjustments = []
    
    # Rule 1: High collapse frequency → Increase CIS intervention strength
    if metrics.collapse_frequency > 5.0 do
      current = parameters.cis.intervention_strength
      adjustment = min(@adjustment_step * (metrics.collapse_frequency / 5.0), @max_adjustment_per_cycle)
      new_value = min(current + adjustment, elem(@cis_intervention_strength_range, 1))
      
      adjustments = [{"cis.intervention_strength", current, new_value,
        "High collapse frequency (#{Float.round(metrics.collapse_frequency, 1)})"} | adjustments]
    end
    
    # Rule 2: Slow recovery → Lower entropy threshold (intervene earlier)
    if metrics.avg_recovery_time > 15.0 do
      current = parameters.cis.entropy_threshold
      adjustment = min(@adjustment_step * (metrics.avg_recovery_time / 15.0), @max_adjustment_per_cycle)
      new_value = max(current - adjustment, elem(@cis_entropy_threshold_range, 0))
      
      adjustments = [{"cis.entropy_threshold", current, new_value,
        "Slow recovery time (#{Float.round(metrics.avg_recovery_time, 1)} ticks)"} | adjustments]
    end
    
    # Rule 3: High oscillation → Increase damping factor
    if metrics.oscillation_rate > 0.5 do
      current = parameters.cis.damping_factor
      adjustment = min(@adjustment_step * metrics.oscillation_rate, @max_adjustment_per_cycle)
      new_value = min(current + adjustment, elem(@cis_damping_factor_range, 1))
      
      adjustments = [{"cis.damping_factor", current, new_value,
        "High oscillation rate (#{Float.round(metrics.oscillation_rate, 2)})"} | adjustments]
    end
    
    # Rule 4: Low coherence → Increase CAL coherence threshold
    if metrics.avg_coherence < 0.7 do
      current = parameters.cal.coherence_threshold
      adjustment = min(@adjustment_step * (0.7 - metrics.avg_coherence), @max_adjustment_per_cycle)
      new_value = min(current + adjustment, elem(@cal_coherence_threshold_range, 1))
      
      adjustments = [{"cal.coherence_threshold", current, new_value,
        "Low average coherence (#{Float.round(metrics.avg_coherence, 2)})"} | adjustments]
    end
    
    # Rule 5: High arbitration flip rate → Increase stability bias
    if metrics.arbitration_flip_rate > 3.0 do
      current = parameters.cal.arbitration_bias
      adjustment = min(@adjustment_step * (metrics.arbitration_flip_rate / 3.0), @max_adjustment_per_cycle)
      new_value = min(current + adjustment, elem(@cal_arbitration_bias_range, 1))
      
      adjustments = [{"cal.arbitration_bias", current, new_value,
        "High arbitration flip rate (#{Float.round(metrics.arbitration_flip_rate, 1)})"} | adjustments]
    end
    
    # Rule 6: High entropy variance → Increase CIS intervention strength
    if metrics.entropy_variance > 0.15 do
      current = parameters.cis.intervention_strength
      adjustment = min(@adjustment_step * (metrics.entropy_variance / 0.15), @max_adjustment_per_cycle)
      new_value = min(current + adjustment, elem(@cis_intervention_strength_range, 1))
      
      adjustments = [{"cis.intervention_strength", current, new_value,
        "High entropy variance (#{Float.round(metrics.entropy_variance, 3)})"} | adjustments]
    end
    
    Enum.reverse(adjustments)
  end
  
  defp apply_adjustments(parameters, adjustments) do
    Enum.reduce(adjustments, parameters, fn {param_path, _old_val, new_val, _reason}, acc ->
      [category, param_name] = String.split(param_path, ".")
      
      put_in(acc, [String.to_atom(category), String.to_atom(param_name)], new_val)
    end)
  end
  
  defp validate_parameter(category, param_name, value) do
    range = case {category, param_name} do
      {"cis", "entropy_threshold"} -> @cis_entropy_threshold_range
      {"cis", "intervention_strength"} -> @cis_intervention_strength_range
      {"cis", "damping_factor"} -> @cis_damping_factor_range
      {"cal", "clustering_sensitivity"} -> @cal_clustering_sensitivity_range
      {"cal", "coherence_threshold"} -> @cal_coherence_threshold_range
      {"cal", "arbitration_bias"} -> @cal_arbitration_bias_range
      _ -> nil
    end
    
    if is_nil(range) do
      {:error, "Unknown parameter: #{category}.#{param_name}"}
    else
      {min_val, max_val} = range
      if value >= min_val and value <= max_val do
        :ok
      else
        {:error, "Value #{value} out of range [#{min_val}, #{max_val}]"}
      end
    end
  end
  
  defp summarize_metrics(metrics) do
    %{
      collapse_frequency: Float.round(metrics.collapse_frequency, 2),
      avg_recovery_time: Float.round(metrics.avg_recovery_time, 2),
      oscillation_rate: Float.round(metrics.oscillation_rate, 2),
      avg_coherence: Float.round(metrics.avg_coherence, 2),
      stability_score: Float.round(metrics.stability_score, 3)
    }
  end
end
