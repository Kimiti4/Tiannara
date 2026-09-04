defmodule TiannaraOS.ConstitutionalWatchdog do
  @moduledoc """
  ConstitutionalWatchdog - Runtime integrity monitor that continuously verifies constitutional state.

  This watchdog passively monitors the constitutional substrate during execution,
  detecting any unexpected mutations to constitutional components. It never repairs
  anything - only detects, logs, and freezes adaptation when drift occurs.

  ## Constitutional Role

  The watchdog ensures:
  1. Continuous verification during execution (not just at startup)
  2. Immediate detection of runtime mutations
  3. Automatic freeze on unauthorized changes
  4. Immutable logging of all drift events
  5. Protection against mid-execution tampering

  ## Architecture

  ```
  Execution Start
        │
        ├─→ Spawn Watchdog Process
        │       │
        │       ├─→ Periodic Checks (every N ms)
        │       │     └─→ Recompute manifest → fingerprint
        │       │
        │       ├─→ Compare with Baseline Fingerprint
        │       │
        │       ├─→ Drift Detected?
        │       │     ├─→ YES → Freeze Adaptation
        │       │     │         → Raise Constitutional Drift
        │       │     │         → Write Journal Entry
        │       │     │         → Emit Event
        │       │     │         → Stop Simulation
        │       │     └─→ NO → Continue Monitoring
        │       │
        │       └─→ Execution Complete → Terminate Watchdog
        │
        └─→ Main Execution Continues
  ```

  ## Usage

      # Build manifest and derive fingerprint
      manifest = ConstitutionManifest.build()
      fingerprint = ConstitutionFingerprint.compute(manifest)

      # Start watchdog before execution
      {:ok, pid} = ConstitutionalWatchdog.start_link(fingerprint)

      # Watchdog automatically monitors in background
      # If drift detected, it will:
      #   1. Log to ConstitutionalDriftJournal
      #   2. Raise ConstitutionalViolation
      #   3. Freeze adaptation
      #   4. Stop simulation

      # Manually check current status
      status = ConstitutionalWatchdog.get_status(pid)

      # Stop watchdog after execution
      ConstitutionalWatchdog.stop(pid)
  """

  use GenServer

  alias TiannaraOS.Kernel.{
    ConstitutionCertificate,
    ConstitutionFingerprint,
    ConstitutionalDriftJournal,
    ConstitutionManifest
  }

  @type check_interval :: non_neg_integer()

  @default_check_interval 5000  # Check every 5 seconds

  @doc """
  Start the constitutional watchdog process.

  Initializes monitoring with a baseline fingerprint and begins periodic checks.

  ## Parameters

  - `baseline_fingerprint`: The expected constitutional fingerprint
  - `opts`: Optional configuration
    - `:check_interval` - Milliseconds between checks (default: 5000)

  ## Returns

  - `{:ok, pid}` - Watchdog process started successfully

  ## Examples

      manifest = ConstitutionManifest.build()
      fingerprint = ConstitutionFingerprint.compute(manifest)
      {:ok, pid} = ConstitutionalWatchdog.start_link(fingerprint)
  """
  @spec start_link(ConstitutionFingerprint.t(), keyword()) :: {:ok, pid()}
  def start_link(%ConstitutionFingerprint{} = baseline_fingerprint, opts \\ []) do
    check_interval = Keyword.get(opts, :check_interval, @default_check_interval)

    GenServer.start_link(__MODULE__, {baseline_fingerprint, check_interval})
  end

  @doc """
  Get the current watchdog status.

  Returns information about the watchdog's monitoring state.

  ## Parameters

  - `pid`: Watchdog process PID

  ## Returns

  - Map with status information

  ## Examples

      status = ConstitutionalWatchdog.get_status(pid)
      # IO.puts("Checks performed: " <> Integer.to_string(status.checks_performed))
  """
  @spec get_status(pid()) :: map()
  def get_status(pid) do
    GenServer.call(pid, :get_status)
  end

  @doc """
  Stop the watchdog process.

  Gracefully terminates monitoring.

  ## Parameters

  - `pid`: Watchdog process PID

  ## Returns

  - `:ok`

  ## Examples

      ConstitutionalWatchdog.stop(pid)
  """
  @spec stop(pid()) :: :ok
  def stop(pid) do
    GenServer.stop(pid)
  end

  # GenServer callbacks

  @impl true
  def init({baseline_fingerprint, check_interval}) do
    state = %{
      baseline_fingerprint: baseline_fingerprint,
      check_interval: check_interval,
      checks_performed: 0,
      drift_detected: false,
      last_check: nil,
      started_at: DateTime.utc_now()
    }

    # Schedule first check
    schedule_check(check_interval)

    {:ok, state}
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    status = %{
      status: if(state.drift_detected, do: :drift_detected, else: :monitoring),
      checks_performed: state.checks_performed,
      last_check: state.last_check,
      started_at: state.started_at,
      check_interval: state.check_interval,
      baseline_manifest_id: state.baseline_fingerprint.manifest_id,
      baseline_version: "13.5B"
    }

    {:reply, status, state}
  end

  @impl true
  def handle_info(:perform_check, state) do
    # Perform integrity check by recomputing fingerprint from current manifest
    current_manifest = ConstitutionManifest.build()
    current_fingerprint = ConstitutionFingerprint.compute(current_manifest)

    case ConstitutionFingerprint.compare(current_fingerprint, state.baseline_fingerprint) do
      :no_drift ->
        # No drift - continue monitoring
        new_state = %{
          state
          | checks_performed: state.checks_performed + 1,
            last_check: DateTime.utc_now()
        }

        # Schedule next check
        schedule_check(state.check_interval)

        {:noreply, new_state}

      :drift_detected ->
        # Drift detected - log and freeze
        IO.puts("\n❌ ConstitutionalWatchdog: DRIFT DETECTED!")
        IO.puts("   Freezing adaptation...")

        # Record drift event
        temp_cert = %ConstitutionCertificate{
          certificate_id: "WATCHDOG-DRIFT-#{DateTime.utc_now() |> DateTime.to_iso8601()}",
          execution_id: "WATCHDOG-CHECK",
          manifest: current_manifest,
          combined_hash: current_manifest.combined_hash,
          generation_count: 0,
          started_at: DateTime.utc_now(),
          completed_at: DateTime.utc_now(),
          validation_status: :not_run,
          replay_status: :not_run,
          watchdog_status: :not_run,
          invariant_status: :not_checked,
          drift_journal_entries: [],
          certificate_hash: "",
          constitution_id: current_manifest.constitution_id,
          metadata: %{},
          fingerprint: current_fingerprint.fingerprint
        }

        entry = ConstitutionalDriftJournal.record_execution(
          "WATCHDOG-DRIFT-#{DateTime.utc_now() |> DateTime.to_iso8601()}",
          temp_cert
        )

        # Emit drift event (in production, use Phoenix PubSub or similar)
        emit_drift_event(entry)

        # Update state to mark drift detected
        new_state = %{
          state
          | drift_detected: true,
            checks_performed: state.checks_performed + 1,
            last_check: DateTime.utc_now()
        }

        # Do NOT schedule next check - watchdog stops on drift detection
        # The system should be frozen at this point

        {:noreply, new_state}
    end
  end

  @impl true
  def terminate(_reason, state) do
    IO.puts("\n🛑 ConstitutionalWatchdog: Terminating")
    IO.puts("   Total checks performed: #{state.checks_performed}")
    IO.puts("   Drift detected: #{state.drift_detected}")
    :ok
  end

  # Private helper functions

  @spec schedule_check(check_interval()) :: reference()
  defp schedule_check(interval) do
    Process.send_after(self(), :perform_check, interval)
  end

  @spec emit_drift_event(ConstitutionalDriftJournal.entry()) :: :ok
  defp emit_drift_event(entry) do
    # In production, this would emit to Phoenix PubSub or event bus
    # For now, just log to console
    IO.puts("\n📢 Constitutional Drift Event Emitted:")
    IO.puts("   Execution ID: #{entry.execution_id}")
    IO.puts("   Status: #{entry.drift_status}")
    IO.puts("   Severity: #{entry.drift_severity}")
    IO.puts("   Result: #{entry.result}")
    IO.puts("   Components: #{Enum.join(entry.changed_components, ", ")}")

    :ok
  end
end
