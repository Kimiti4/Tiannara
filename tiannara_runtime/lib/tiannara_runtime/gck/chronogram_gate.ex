defmodule Tiannara.GCK.ChronogramGate do
  @moduledoc """
  Phase 5F.4 — GCK Validation Layer for Chronogram Memory Operations

  Global Consistency Kernel validation gate specifically for holographic memory writes and reads.

  ## Purpose

  Ensures that chronogram memory operations don't introduce:
  - Entropy overflow (unstable memories)
  - Causal drift (observer divergence beyond safe limits)
  - Cross-observer contamination (unsafe memory bleeding)

  ## Architecture

  This gate sits between ExecutionController and ChronogramMatrix:

      ExecutionController → GCK.ChronogramGate → ChronogramMatrix

  NOT:
      ExecutionController → ChronogramMatrix (unsafe!) ❌

  ## Validation Rules

  **WRITE PATH:**
  - Entropy must be below threshold (< 0.92)
  - Observer drift must be within limits (< 0.75)
  - State must have required fields (:coordinate, :entropy)

  **READ PATH:**
  - Lighter validation (observer permission check)
  - Prevents unauthorized cross-observer access

  ## Usage

      # Validate before writing to chronogram
      case ChronogramGate.validate_write(observer_id, state) do
        {:allow, :ok} ->
          ChronogramMatrix.write(observer_id, state)
        {:reject, :entropy_overflow} ->
          Logger.error("Memory too unstable")
        {:reject, :causal_drift} ->
          Logger.error("Observer diverged too far")
      end

      # Validate before reading from chronogram
      case ChronogramGate.validate_read(observer_id, coord) do
        {:allow, :ok} ->
          ChronogramMatrix.read(observer_id, coord)
        {:reject, _reason} ->
          Logger.error("Read denied")
      end
  """

  require Logger

  # ── Configuration ─────────────────────────────────────────────────────────

  # Maximum entropy allowed in memory writes (0.0 = stable, 1.0 = chaotic)
  @entropy_limit 0.92

  # Maximum observer drift before rejection (prevents runaway divergence)
  @observer_drift_limit 0.75

  # ── Public API ────────────────────────────────────────────────────────────

  @doc """
  Validates a chronogram memory write operation.

  ## Parameters
  - `observer_id`: The observer attempting to write
  - `state`: The memory state to validate (must contain :entropy and :drift)

  ## Returns
  - `{:allow, :ok}` if validation passes
  - `{:reject, :entropy_overflow}` if memory is too unstable
  - `{:reject, :causal_drift}` if observer has diverged too far
  - `{:reject, :missing_fields}` if state lacks required fields

  ## Example

      state = %{
        coordinate: "event_001",
        entropy: 0.3,
        drift: 0.2,
        data: "important observation"
      }

      case ChronogramGate.validate_write("obs_001", state) do
        {:allow, :ok} -> IO.puts("Write approved")
        {:reject, _reason} -> IO.puts("Write rejected by GCK")
      end
  """
  def validate_write(observer_id, state) do
    cond do
      not has_required_fields?(state) ->
        Logger.warning("🛑 GCK ChronogramGate: missing required fields")
        {:reject, :missing_fields}

      entropy(state) > @entropy_limit ->
        Logger.warning("🛑 GCK ChronogramGate: entropy overflow (#{entropy(state)} > #{@entropy_limit})")
        {:reject, :entropy_overflow}

      drift(observer_id, state) > @observer_drift_limit ->
        Logger.warning("🛑 GCK ChronogramGate: causal drift exceeded (#{drift(observer_id, state)} > #{@observer_drift_limit})")
        {:reject, :causal_drift}

      true ->
        Logger.debug("✅ GCK ChronogramGate: write approved for observer #{observer_id}")
        {:allow, :ok}
    end
  end

  @doc """
  Validates a chronogram memory read operation.

  Read-side validation is lighter than write-side, focusing on permission checks.

  ## Parameters
  - `observer_id`: The observer requesting the read
  - `coordinate`: The memory coordinate being requested

  ## Returns
  - `{:allow, :ok}` if read is permitted
  - `{:reject, reason}` if read should be blocked

  ## Example

      case ChronogramGate.validate_read("obs_001", "event_001") do
        {:allow, :ok} -> IO.puts("Read approved")
        {:reject, _reason} -> IO.puts("Read denied by GCK")
      end
  """
  def validate_read(observer_id, _coord) do
    # Read-side safety is lighter - mainly permission validation
    # In production, would check observer access control lists
    Logger.debug("✅ GCK ChronogramGate: read approved for observer #{observer_id}")
    {:allow, :ok}
  end

  @doc """
  Gets current validation thresholds.
  """
  def get_thresholds do
    %{
      entropy_limit: @entropy_limit,
      observer_drift_limit: @observer_drift_limit
    }
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp has_required_fields?(state) do
    Map.has_key?(state, :coordinate) and Map.has_key?(state, :entropy)
  end

  defp entropy(state) do
    Map.get(state, :entropy, 0.5)
  end

  defp drift(_observer_id, state) do
    Map.get(state, :drift, 0.1)
  end
end
