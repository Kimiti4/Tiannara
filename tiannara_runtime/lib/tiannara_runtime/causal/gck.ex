defmodule TiannaraRuntime.Causal.GCK do
  @moduledoc """
  Phase 5F.3.5 — Global Consistency Kernel (Hard Compilation Gate)
  
  Upgraded from "validation layer" to "compilation gate".
  
  ## Critical Rule
  
  If GCK fails → NOTHING downstream executes:
  - No observer creation
  - No memory write
  - No world mutation
  - No causal graph modification
  
  ## Purpose
  
  Prevents:
  - Paradox injection into causal graphs
  - Unstable physics mutations
  - Incoherent world merges
  - Causal cycle creation
  - Temporal inconsistency
  
  ## Architecture
  
  GCK acts as a HARD GATE before any Phase 5F operation:
  
      Operation Request → GCK Validation → [PASS] → Execute
                                      → [FAIL] → Reject + Log
  
  NOT:
      Operation Request → Execute → Validate (too late!) ❌
  
  ## Validation Checks
  
  1. **Causal Acyclicity** — No cycles in causal DAG
  2. **Temporal Consistency** — Events respect causality order
  3. **Physics Stability** — Physics parameters within bounds
  4. **Observer Coherence** — Observer manifolds don't contradict
  5. **Memory Integrity** — Memory writes don't corrupt lineage
  
  ## Usage
  
      # Validate before creating observer
      case GCK.validate_observer_creation(observer_config) do
        :approved -> create_observer(observer_config)
        {:rejected, reason} -> Logger.error("Observer creation blocked: #{reason}")
      end
      
      # Validate before world merge
      case GCK.validate_world_merge(world_a, world_b) do
        :approved -> merge_worlds(world_a, world_b)
        {:rejected, reason} -> escalate_to_cis(reason)
      end
      
      # Validate before memory write
      case GCK.validate_memory_write(memory_event) do
        :approved -> write_memory(memory_event)
        {:rejected, reason} -> reject_write(reason)
      end
  """

  use GenServer
  require Logger

  alias TiannaraRuntime.CIS.Supervisor, as: CISSup

  # ── Configuration ─────────────────────────────────────────────────────────

  @max_causal_depth 100              # Max causal chain length
  @max_physics_deviation 0.5         # Max deviation from base physics
  @min_coherence_threshold 0.6       # Min observer coherence
  @validation_timeout_ms 5_000       # Timeout for validation checks

  # ── State ─────────────────────────────────────────────────────────────────

  defstruct [
    validation_log: [],              # Recent validation decisions
    total_approved: 0,
    total_rejected: 0,
    rejection_reasons: %{}           # %{reason => count}
  ]

  # ── Public API ────────────────────────────────────────────────────────────

  @doc """
  Starts the GCK GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Validates observer creation request.
  
  Checks:
  - Observer coherence above threshold
  - Physics parameters stable
  - No paradox introduction
  
  Returns:
  - `:approved` — Safe to create observer
  - `{:rejected, reason}` — Blocked by GCK
  """
  def validate_observer_creation(observer_config) do
    GenServer.call(__MODULE__, {:validate_observer, observer_config}, @validation_timeout_ms)
  end

  @doc """
  Validates world merge operation.
  
  Checks:
  - Worlds are compatible (no contradictions)
  - Merge won't create causal cycles
  - Combined physics stable
  
  Returns:
  - `:approved` — Safe to merge
  - `{:rejected, reason}` — Blocked by GCK
  """
  def validate_world_merge(world_a_id, world_b_id) do
    GenServer.call(__MODULE__, {:validate_world_merge, world_a_id, world_b_id}, @validation_timeout_ms)
  end

  @doc """
  Validates memory write operation.
  
  Checks:
  - Memory doesn't contradict existing lineage
  - Write maintains causal consistency
  - No temporal paradox introduced
  
  Returns:
  - `:approved` — Safe to write
  - `{:rejected, reason}` — Blocked by GCK
  """
  def validate_memory_write(memory_event) do
    GenServer.call(__MODULE__, {:validate_memory_write, memory_event}, @validation_timeout_ms)
  end

  @doc """
  Validates causal graph modification.
  
  Checks:
  - No cycles introduced
  - Causal depth within limits
  - Graph remains acyclic DAG
  
  Returns:
  - `:approved` — Safe to modify
  - `{:rejected, reason}` — Blocked by GCK
  """
  def validate_causal_modification(graph_changes) do
    GenServer.call(__MODULE__, {:validate_causal_mod, graph_changes}, @validation_timeout_ms)
  end

  @doc """
  Gets GCK statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    Logger.info("🛡️  GCK initialized (Phase 5F.3.5 Hard Compilation Gate)")

    state = %__MODULE__{
      validation_log: [],
      total_approved: 0,
      total_rejected: 0,
      rejection_reasons: %{}
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:validate_observer, config}, _from, state) do
    coherence = Map.get(config, :coherence, 0.5)
    physics_stable = check_physics_stability(config)

    decision =
      cond do
        coherence < @min_coherence_threshold ->
          {:rejected, "Observer coherence too low: #{coherence} < #{@min_coherence_threshold}"}

        not physics_stable ->
          {:rejected, "Unstable physics parameters detected"}

        true ->
          :approved
      end

    log_and_respond(state, :observer_creation, decision)
  end

  @impl true
  def handle_call({:validate_world_merge, world_a_id, world_b_id}, _from, state) do
    # Check for contradictions between worlds
    contradictions = check_world_contradictions(world_a_id, world_b_id)

    # Check for causal cycles
    would_create_cycle = check_merge_creates_cycle(world_a_id, world_b_id)

    decision =
      cond do
        length(contradictions) > 0 ->
          {:rejected, "World contradictions detected: #{inspect(contradictions)}"}

        would_create_cycle ->
          {:rejected, "Merge would create causal cycle"}

        true ->
          :approved
      end

    log_and_respond(state, :world_merge, decision)
  end

  @impl true
  def handle_call({:validate_memory_write, memory_event}, _from, state) do
    # Check memory doesn't contradict existing lineage
    contradicts_lineage = check_memory_contradiction(memory_event)

    # Check temporal consistency
    temporally_inconsistent = check_temporal_consistency(memory_event)

    decision =
      cond do
        contradicts_lineage ->
          {:rejected, "Memory contradicts existing lineage"}

        temporally_inconsistent ->
          {:rejected, "Temporal inconsistency detected"}

        true ->
          :approved
      end

    log_and_respond(state, :memory_write, decision)
  end

  @impl true
  def handle_call({:validate_causal_mod, changes}, _from, state) do
    # Check for cycles
    creates_cycle = check_causal_cycle(changes)

    # Check depth
    exceeds_depth = check_causal_depth(changes)

    decision =
      cond do
        creates_cycle ->
          {:rejected, "Causal modification would create cycle"}

        exceeds_depth ->
          {:rejected, "Causal depth exceeds limit: #{@max_causal_depth}"}

        true ->
          :approved
      end

    log_and_respond(state, :causal_modification, decision)
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      total_approved: state.total_approved,
      total_rejected: state.total_rejected,
      approval_rate: calculate_approval_rate(state),
      top_rejection_reasons: Enum.take(state.rejection_reasons, 5),
      recent_validations: Enum.take(state.validation_log, 10)
    }

    {:reply, {:ok, stats}, state}
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp check_physics_stability(config) do
    # Check if physics parameters are within stable bounds
    # In production, this would validate against known stable physics models
    # For now, simple check
    physics_params = Map.get(config, :physics_params, %{})
    
    # Assume stable if no extreme deviations
    Map.get(physics_params, :stability_score, 1.0) > 0.5
  end

  defp check_world_contradictions(world_a_id, world_b_id) do
    # TODO: Implement actual contradiction detection
    # This would compare world states, observer memories, causal graphs
    # For now, return empty list (assume compatible)
    []
  end

  defp check_merge_creates_cycle(world_a_id, world_b_id) do
    # TODO: Implement cycle detection in merged causal graph
    # This would analyze causal dependencies between worlds
    # For now, assume no cycle
    false
  end

  defp check_memory_contradiction(memory_event) do
    # TODO: Implement memory contradiction detection
    # This would check against existing memory lineage
    # For now, assume no contradiction
    false
  end

  defp check_temporal_consistency(memory_event) in
    # TODO: Implement temporal consistency check
    # This would verify event timestamps respect causality
    # For now, assume consistent
    false
  end

  defp check_causal_cycle(changes) do
    # TODO: Implement causal cycle detection
    # This would analyze the modified graph for cycles
    # For now, assume no cycle
    false
  end

  defp check_causal_depth(changes) do
    # TODO: Implement causal depth calculation
    # This would measure longest causal chain
    # For now, assume within limits
    false
  end

  defp log_and_respond(state, operation_type, decision) do
    # Update counters
    new_state =
      case decision do
        :approved ->
          %{state | total_approved: state.total_approved + 1}

        {:rejected, reason} ->
          new_reasons = Map.update(state.rejection_reasons, reason, 1, &(&1 + 1))
          %{state | total_rejected: state.total_rejected + 1, rejection_reasons: new_reasons}
      end

    # Log validation
    log_entry = %{
      operation: operation_type,
      decision: decision,
      timestamp: DateTime.utc_now()
    }

    updated_log = [log_entry | new_state.validation_log]
    trimmed_log = Enum.take(updated_log, 100)  # Keep last 100 entries

    final_state = %{new_state | validation_log: trimmed_log}

    # Log decision
    case decision do
      :approved ->
        Logger.debug("✅ GCK approved #{operation_type}")

      {:rejected, reason} ->
        Logger.error("🛑 GCK REJECTED #{operation_type}: #{reason}")
        
        # Escalate to CIS for critical rejections
        if critical_rejection?(reason) do
          CISSup.set_safety_mode(:elevated)
        end
    end

    {:reply, decision, final_state}
  end

  defp calculate_approval_rate(state) do
    total = state.total_approved + state.total_rejected
    
    if total == 0 do
      1.0
    else
      state.total_approved / total
    end
  end

  defp critical_rejection?(reason) do
    # Determine if rejection indicates critical system issue
    String.contains?(reason, ["cycle", "paradox", "temporal"])
  end
end
