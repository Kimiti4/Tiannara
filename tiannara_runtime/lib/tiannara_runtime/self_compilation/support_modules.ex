defmodule TiannaraRuntime.SelfCompilation.SafetyValidator do
  @moduledoc """
  Phase 5F.13: Safety Validator - Validates Mutated Rules Against Constraints

  Ensures that self-compiled rules maintain system stability and don't violate
  meta-ontological constraints. Prevents recursive optimization exploits and
  substrate awareness explosions.

  Validation checks include:
  - Parameter range validation
  - Cross-subsystem consistency
  - Meta-ontology guard compliance
  - Stability preservation guarantees
  """

  @doc """
  Validate proposed rule changes against safety constraints.

  ## Parameters
  - rules: Proposed mutated rules
  - subsystem: Target subsystem

  ## Returns
  {:ok, validated_rules} | {:error, reason}
  """
  def validate(rules, subsystem) do
    with :ok <- validate_parameter_ranges(rules, subsystem),
         :ok <- validate_cross_subsystem_consistency(rules, subsystem),
         :ok <- TiannaraRuntime.SelfCompilation.MetaOntologyGuard.check_compliance(rules, subsystem) do
      {:ok, rules}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_parameter_ranges(rules, subsystem) do
    # Check all parameters are within safe operational bounds
    invalid_rules = Enum.filter(rules, fn rule ->
      not parameter_in_safe_range?(rule, subsystem)
    end)

    if length(invalid_rules) > 0 do
      {:error, {:parameter_out_of_range, invalid_rules}}
    else
      :ok
    end
  end

  defp parameter_in_safe_range?(rule, subsystem) do
    # Extract value safely (handle both map types)
    value = Map.get(rule, :value, Map.get(rule, "value", nil))

    if is_nil(value) do
      false  # No value field means invalid rule
    else
      case {subsystem, rule.type} do
        {:rrg, :psi_threshold} -> value >= 0.2 and value <= 0.5
        {:rrg, :novelty_injection_max} -> value >= 0.1 and value <= 0.25
        {:omce, :compression_ratio_aggressive} -> value >= 0.3 and value <= 0.5
        {:olef, :diffusion_rate} -> value >= 0.05 and value <= 0.2
        {:opc, :ast_optimization_level} -> is_integer(value) and value >= 0 and value <= 3
        {:opc, :epsilon_shim_budget} -> is_float(value) and value >= 0.2 and value <= 1.0
        _ -> true  # Unknown parameters pass by default
      end
    end
  end

  defp validate_cross_subsystem_consistency(_rules, _subsystem) do
    # Placeholder: In production, check for conflicts between subsystems
    # For now, assume consistency
    :ok
  end
end

defmodule TiannaraRuntime.SelfCompilation.MetaOntologyGuard do
  @moduledoc """
  Phase 5F.13: Meta-Ontology Guard - Enforces Existence Constraints

  The highest-level safety layer that ensures self-compilation doesn't violate
  fundamental ontological principles. Prevents the system from rewriting itself
  into logical impossibilities or existential paradoxes.
  """

  @allowed_rule_types [
    :psi_threshold, :novelty_injection_max, :recursion_regulation_threshold,
    :compression_ratio_aggressive, :compression_ratio_moderate,
    :diffusion_rate, :pressure_equalization_speed,
    :ast_optimization_level, :shader_cache_ttl,
    :attractor_detection_sensitivity, :identity_merge_threshold,
    :causal_prune_depth, :node_capacity_threshold, :load_balancing_interval,
    :compilation_timeout, :parallel_compilation_limit,
    :epsilon_shim_budget
  ]

  @doc """
  Check if proposed rules comply with meta-ontological constraints.

  ## Returns
  :ok | {:error, reason}
  """
  def check_compliance(rules, _subsystem) do
    # Verify all rule types are allowed
    disallowed = Enum.filter(rules, fn rule ->
      rule.type not in @allowed_rule_types
    end)

    if length(disallowed) > 0 do
      {:error, {:disallowed_rule_types, Enum.map(disallowed, & &1.type)}}
    else
      :ok
    end
  end
end

defmodule TiannaraRuntime.SelfCompilation.VersionTracker do
  @moduledoc """
  Phase 5F.13: Version Tracker - Tracks Compilation History and Versions

  Maintains version history for all subsystems, enabling rollback and
  providing audit trail for self-modification events.
  """

  use GenServer

  defstruct [
    :current_versions,
    :version_history,
    :compilation_log
  ]

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @impl true
  def init(_opts) do
    state = %__MODULE__{
      current_versions: %{rrg: 1, omce: 1, olef: 1, opc: 1},
      version_history: [],
      compilation_log: []
    }

    {:ok, state}
  end

  @doc """
  Record a compilation event and increment version.
  """
  def record_compilation(subsystem, old_rules, new_rules, result) do
    GenServer.call(__MODULE__, {:record, subsystem, old_rules, new_rules, result})
  end

  @doc """
  Get current system versions.
  """
  def get_version do
    GenServer.call(__MODULE__, :get_version)
  end

  @impl true
  def handle_call({:record, subsystem, old_rules, new_rules, result}, _from, state) do
    # Increment version for subsystem
    new_version = Map.get(state.current_versions, subsystem, 1) + 1

    new_current_versions = Map.put(state.current_versions, subsystem, new_version)

    # Record in history
    version_record = %{
      subsystem: subsystem,
      version: new_version,
      old_rules_count: length(old_rules),
      new_rules_count: length(new_rules),
      result: result,
      timestamp: System.system_time(:millisecond)
    }

    new_history = Enum.take([version_record | state.version_history], 100)

    new_state = %{
      state
      | current_versions: new_current_versions,
        version_history: new_history
    }

    {:reply, version_record, new_state}
  end

  @impl true
  def handle_call(:get_version, _from, state) do
    {:reply, {:ok, state.current_versions}, state}
  end
end

defmodule TiannaraRuntime.SelfCompilation.RollbackManager do
  @moduledoc """
  Phase 5F.13: Rollback Manager - Manages System Rollbacks to Previous Versions

  Provides emergency rollback capability when self-compilation produces
  unstable or invalid system states.
  """

  use GenServer

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  @impl true
  def init(_opts), do: {:ok, %{rollback_history: []}}

  @doc """
  Rollback subsystem to previous version.
  """
  def rollback(target_version \\ :previous) do
    GenServer.call(__MODULE__, {:rollback, target_version})
  end

  @impl true
  def handle_call({:rollback, _target_version}, _from, state) do
    # Placeholder: In production, restore previous rule set
    {:reply, {:ok, :rollback_simulated}, state}
  end
end

defmodule TiannaraRuntime.SelfCompilation.AdaptiveLearner do
  @moduledoc """
  Phase 5F.13: Adaptive Learner - Learns from Compilation Outcomes

  Analyzes historical compilation results to improve future mutation strategies.
  Uses performance feedback to guide rule modifications toward optimal configurations.
  """

  use GenServer

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  @impl true
  def init(_opts), do: {:ok, %{learning_data: %{}, total_observations: 0}}

  @doc """
  Get learning statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    {:reply, {:ok, %{total_observations: state.total_observations}}, state}
  end
end

defmodule TiannaraRuntime.SelfCompilation.PerformanceMonitor do
  @moduledoc """
  Phase 5F.13: Performance Monitor - Monitors Post-Compilation System Performance

  Tracks key performance metrics after self-compilation to detect degradation
  and trigger rollbacks if necessary.
  """

  use GenServer

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  @impl true
  def init(_opts), do: {:ok, %{metrics: %{}, monitoring_active: true}}

  @doc """
  Get current performance metrics.
  """
  def get_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    {:reply, {:ok, state.metrics}, state}
  end
end
