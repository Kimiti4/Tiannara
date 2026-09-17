defmodule TiannaraRuntime.SelfCompilation.RewriteEngine do
  @moduledoc """
  Phase 5F.13: Rewrite Engine - Core Self-Compilation Logic

  Orchestrates the complete self-compilation cycle:
  1. Extract current rules from target subsystem
  2. Mutate rules based on performance feedback and intensity
  3. Validate mutated rules against safety constraints
  4. Apply validated rules to subsystem
  5. Track version and enable rollback if needed

  The engine ensures that self-modification maintains system stability
  while enabling adaptive evolution of runtime behavior.
  """

  use GenServer
  require Logger

  defstruct [
    :compilation_history,
    :active_compilations,
    :success_rate,
    :total_compilations,
    :current_versions
  ]

  @valid_subsystems [:rrg, :omce, :olef, :opc]
  @max_intensity 0.5  # Maximum safe modification intensity
  @min_intensity 0.01
  @compilation_hold_ms 100

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    state = %__MODULE__{
      compilation_history: [],
      active_compilations: MapSet.new(),
      success_rate: 1.0,
      total_compilations: 0,
      current_versions: %{rrg: 1, omce: 1, olef: 1, opc: 1}
    }

    Logger.info("🔄 [5F.13] Self-Compilation Rewrite Engine initialized")
    {:ok, state}
  end

  @impl true
  def handle_call({:compile, subsystem, intensity, options}, _from, state) do
    mscl_status = fetch_mscl_status()

    # Validate inputs
    with :ok <- validate_subsystem(subsystem),
         :ok <- validate_intensity(intensity),
         :ok <- check_no_active_compilation(subsystem, state),
         :ok <- check_mscl_stability(mscl_status) do

      # Mark subsystem as compiling
      new_state = %{
        state
        | active_compilations: MapSet.put(state.active_compilations, subsystem)
      }

      # Execute compilation cycle
      result = execute_compilation_cycle(subsystem, intensity, options, new_state, mscl_status)

      # Update state based on result
      final_state = update_state_after_compilation(result, new_state)

      # Maintain a short active window to prevent back-to-back compile requests
      Process.send_after(self(), {:release_compilation, subsystem}, @compilation_hold_ms)

      {:reply, result, final_state}
    else
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @doc """
  Get current compilation statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, %__MODULE__{
      compilation_history: [],
      active_compilations: MapSet.new(),
      success_rate: 1.0,
      total_compilations: 0,
      current_versions: %{rrg: 1, omce: 1, olef: 1, opc: 1}
    }}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      total_compilations: state.total_compilations,
      success_rate: state.success_rate,
      active_compilations: MapSet.to_list(state.active_compilations),
      recent_history: Enum.take(state.compilation_history, 10)
    }

    {:reply, {:ok, stats}, state}
  end

  # --- Compilation Cycle Functions ---

  defp execute_compilation_cycle(subsystem, intensity, options, state, mscl_status) do
    try do
      # Step 1: Extract current rules
      current_rules = TiannaraRuntime.SelfCompilation.RuleExtractor.extract(subsystem)

      # Step 2: Mutate rules based on intensity and learning
      effective_intensity = adjust_intensity_for_mscl(intensity, mscl_status)

      mutated_rules = TiannaraRuntime.SelfCompilation.RuleMutator.mutate(
        current_rules,
        subsystem,
        effective_intensity,
        options
      )

      # Step 2.5: Apply CCR (Cosmological Compiler Reflection) guidance rules
      ccr_guidance = fetch_ccr_guidance()
      adjusted_rules = apply_ccr_guidance(mutated_rules, ccr_guidance)

      # Step 3: Validate mutated rules
      case TiannaraRuntime.SelfCompilation.SafetyValidator.validate(adjusted_rules, subsystem) do
        {:ok, validated_rules} ->
          # Step 4: Apply validated rules
          application_result = apply_rules(subsystem, validated_rules)

          # Step 5: Track version internally
          version_info = record_compilation(subsystem, current_rules, validated_rules, application_result, state.current_versions)

          # Success
          {:ok, %{
            subsystem: subsystem,
            status: :compiled,
            version: version_info.version,
            rules_changed: length(validated_rules),
            mscl_status: mscl_status,
            timestamp: System.system_time(:millisecond)
          }}

        {:error, validation_error} ->
          {:error, {:validation_failed, validation_error}}
      end
    rescue
      e ->
        Logger.error("🚨 [5F.13] Compilation error for #{inspect(subsystem)}: #{inspect(e)}")
        {:error, {:compilation_exception, inspect(e)}}
    end
  end

  defp apply_rules(subsystem, rules) do
    # Dispatch to appropriate subsystem handler
    case subsystem do
      :rrg ->
        # RRG rule application would integrate with RRG modules
        # For now, simulate successful application
        :applied

      :omce ->
        # OMCE compression strategy update
        :applied

      :olef ->
        # OLEF diffusion topology change
        :applied

      :opc ->
        # OPC physics compilation heuristic adaptation
        :applied
    end
  end

  defp record_compilation(subsystem, old_rules, new_rules, result, current_versions) do
    version = Map.get(current_versions, subsystem, 1) + 1

    %{
      subsystem: subsystem,
      version: version,
      old_rules_count: length(old_rules),
      new_rules_count: length(new_rules),
      result: result,
      timestamp: System.system_time(:millisecond)
    }
  end

  defp update_state_after_compilation({:ok, result}, state) do
    # Record successful compilation
    new_history = Enum.take([result | state.compilation_history], 100)

    # Update success rate (exponential moving average)
    new_success_rate = calculate_new_success_rate(state.success_rate, true)

    %{
      state
      | compilation_history: new_history,
        success_rate: new_success_rate,
        total_compilations: state.total_compilations + 1,
        current_versions: Map.put(state.current_versions, result.subsystem, result.version)
    }
  end

  defp update_state_after_compilation({:error, _reason}, state) do
    # Record failed compilation
    new_success_rate = calculate_new_success_rate(state.success_rate, false)

    %{
      state
      | active_compilations: MapSet.new(),  # Clear all on error
        success_rate: new_success_rate,
        total_compilations: state.total_compilations + 1
    }
  end

  defp calculate_new_success_rate(current_rate, success) do
    # Exponential moving average with alpha=0.1
    alpha = 0.1
    new_value = if success, do: 1.0, else: 0.0

    (alpha * new_value) + ((1 - alpha) * current_rate)
  end

  defp fetch_mscl_status do
    if Process.whereis(Tiannara.MSCL.Supervisor) do
      case Tiannara.MSCL.Supervisor.get_state() do
        {:ok, state} -> state
        _ -> %{global_pressure: 0.0, collapse_risk: 0.0}
      end
    else
      %{global_pressure: 0.0, collapse_risk: 0.0}
    end
  end

  defp check_mscl_stability(%{collapse_risk: risk}) when risk >= 0.95 do
    {:error, {:mscl_system_unstable, risk}}
  end

  defp check_mscl_stability(_status), do: :ok

  defp adjust_intensity_for_mscl(intensity, %{collapse_risk: risk}) when risk > 0.75 do
    max(@min_intensity, intensity * 0.5)
  end

  defp adjust_intensity_for_mscl(intensity, _status), do: intensity

  # --- Validation Functions ---

  defp validate_subsystem(subsystem) do
    if subsystem in @valid_subsystems do
      :ok
    else
      {:error, {:invalid_subsystem, subsystem}}
    end
  end

  defp validate_intensity(intensity) do
    cond do
      intensity < @min_intensity ->
        {:error, {:intensity_too_low, intensity}}

      intensity > @max_intensity ->
        {:error, {:intensity_too_high, intensity}}

      true ->
        :ok
    end
  end

  defp check_no_active_compilation(subsystem, state) do
    if MapSet.member?(state.active_compilations, subsystem) do
      {:error, {:compilation_in_progress, subsystem}}
    else
      :ok
    end
  end

  @impl true
  def handle_info({:release_compilation, subsystem}, state) do
    new_state = %{
      state
      | active_compilations: MapSet.delete(state.active_compilations, subsystem)
    }

    {:noreply, new_state}
  end

  # --- CCR Guidance Helpers ---

  defp fetch_ccr_guidance do
    if Process.whereis(TiannaraRuntime.CCR.Tracker) do
      case TiannaraRuntime.CCR.Tracker.get_guidance() do
        {:ok, rules} -> rules
        _ -> []
      end
    else
      []
    end
  end

  defp apply_ccr_guidance(rules, guidance) do
    Enum.map(rules, fn rule ->
      Enum.reduce(guidance, rule, fn ccr_rule, acc ->
        apply_single_ccr_guidance(acc, ccr_rule)
      end)
    end)
  end

  defp apply_single_ccr_guidance(%{type: :ast_optimization_level} = rule, %{rule_type: :enforce_kolmogorov_ceiling, limit: limit}) do
    max_opt = if limit < 0.5, do: 1, else: 2
    %{rule | value: min(rule.value, max_opt)}
  end

  defp apply_single_ccr_guidance(%{type: :identity_merge_threshold} = rule, %{rule_type: :mandate_conservation_shield, min_floor: floor}) do
    %{rule | value: max(rule.value, floor)}
  end

  defp apply_single_ccr_guidance(%{type: :pressure_equalization_speed} = rule, %{rule_type: :restrict_manifold_density, max_density: max_density}) do
    %{rule | value: min(rule.value, max_density)}
  end

  defp apply_single_ccr_guidance(rule, _ccr_rule), do: rule
end
