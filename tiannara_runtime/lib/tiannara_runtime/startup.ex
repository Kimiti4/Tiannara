defmodule TiannaraRuntime.Startup do
  @moduledoc """
  Tiannara Unified Startup API

  Thin convenience wrapper around `TiannaraRuntime.StartupSupervisor`.
  Provides start/stop/status/verify operations for all Tiannara systems.

  Startup Order (managed by StartupSupervisor with :rest_for_one):
  1. Constitutional Persistence Layer (CPL) - Event journal and checkpointing
  2. Omega Robustness Substrate - heartbeat, event bus, scheduler, audits
  3. Constitutional Observatory Platform (COP) - Scientific instrumentation
  4. Core Runtime Systems - Existing Tiannara subsystems
  """

  require Logger

  @type startup_config :: %{
          cpl_opts: keyword(),
          omega_opts: keyword(),
          cop_opts: keyword(),
          runtime_opts: keyword(),
          verification: boolean()
        }

  @type startup_result :: %{
          status: :success | :partial | :failed,
          cpl_started: boolean(),
          omega_started: boolean(),
          cop_started: boolean(),
          runtime_started: boolean(),
          verification_passed: boolean(),
          started_at: integer(),
          duration_ms: integer(),
          errors: [String.t()]
        }

  @doc """
  Starts all Tiannara systems through the StartupSupervisor.
  """
  @spec start_all(startup_config()) :: {:ok, startup_result()} | {:error, String.t()}
  def start_all(config \\ default_config()) do
    start_ms = System.monotonic_time(:millisecond)
    Logger.info("Starting Tiannara Unified System...")

    case start_supervisor(config) do
      {:ok, _pid} ->
        result = finalize_start(start_ms, config)
        {:ok, result}

      {:error, reason} ->
        Logger.error("Tiannara Startup Failed: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Stops all Tiannara systems by stopping the StartupSupervisor.
  """
  @spec stop_all() :: :ok | {:error, String.t()}
  def stop_all do
    Logger.info("Stopping Tiannara Unified System...")

    case Process.whereis(TiannaraRuntime.StartupSupervisor) do
      nil ->
        Logger.info("System not running")
        :ok

      pid ->
        Supervisor.stop(pid, :normal, 5000)
        Logger.info("Tiannara Unified System Stopped")
        :ok
    end
  rescue
    e ->
      error_msg = "Stop failed: #{inspect(e)}"
      Logger.error(error_msg)
      {:error, error_msg}
  end

  @doc """
  Returns the status of all Tiannara systems.
  Delegates to StartupSupervisor.
  """
  @spec status() :: map()
  def status do
    TiannaraRuntime.StartupSupervisor.status()
  end

  @doc """
  Verifies that all systems started successfully.
  """
  @spec verify_startup(boolean()) ::
          {:ok, %{passed: boolean(), details: map()}} | {:error, String.t()}
  def verify_startup(enabled \\ true) do
    if enabled do
      Logger.info("Verifying startup...")

      cpl_alive =
        Process.whereis(TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayer) != nil

      omega_alive = Process.whereis(TiannaraRuntime.Omega.Supervisor) != nil
      cop_alive = Process.whereis(TiannaraRuntime.OS.Observatory) != nil
      runtime_alive = Process.whereis(TiannaraRuntime.RootSupervisor) != nil

      passed = cpl_alive and omega_alive and cop_alive and runtime_alive

      details = %{
        cpl_alive: cpl_alive,
        omega_alive: omega_alive,
        cop_alive: cop_alive,
        runtime_alive: runtime_alive
      }

      if passed do
        Logger.info("All systems verified")
      else
        Logger.error("Verification failed")
      end

      {:ok, %{passed: passed, details: details}}
    else
      Logger.info("Verification disabled")
      {:ok, %{passed: true, details: %{}}}
    end
  end

  @doc """
  Returns default startup configuration.
  """
  @spec default_config() :: startup_config()
  def default_config do
    %{
      cpl_opts: [
        checkpoint_interval: 30_000,
        storage_path: "data/cpl"
      ],
      omega_opts: [],
      cop_opts: [],
      runtime_opts: [],
      verification: true
    }
  end

  # -- Private Functions --

  defp start_supervisor(config) do
    case TiannaraRuntime.StartupSupervisor.start_link(config_to_opts(config)) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}

      {:error, reason} ->
        {:error, "StartupSupervisor failed: #{inspect(reason)}"}
    end
  end

  defp config_to_opts(config) do
    Keyword.merge(
      config.cpl_opts,
      omega_opts: Map.get(config, :omega_opts, []),
      cop_opts: config.cop_opts,
      runtime_opts: config.runtime_opts
    )
  end

  defp finalize_start(start_ms, config) do
    {:ok, verification} = verify_startup(config.verification)

    duration = System.monotonic_time(:millisecond) - start_ms

    cpl_alive =
      Process.whereis(TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayer) != nil

    omega_alive = Process.whereis(TiannaraRuntime.Omega.Supervisor) != nil
    cop_alive = Process.whereis(TiannaraRuntime.OS.Observatory) != nil
    runtime_alive = Process.whereis(TiannaraRuntime.RootSupervisor) != nil

    run_resurrection()

    status =
      cond do
        cpl_alive and omega_alive and cop_alive and runtime_alive and verification.passed ->
          :success

        cpl_alive and omega_alive and cop_alive and runtime_alive ->
          :partial

        true ->
          :failed
      end

    result = %{
      status: status,
      cpl_started: cpl_alive,
      omega_started: omega_alive,
      cop_started: cop_alive,
      runtime_started: runtime_alive,
      verification_passed: verification.passed,
      started_at: System.system_time(:millisecond),
      duration_ms: duration,
      errors: collect_errors(verification)
    }

    Logger.info("Tiannara Unified System Started (#{duration}ms)")
    Logger.info("  CPL: #{if cpl_alive, do: "OK", else: "FAIL"}")
    Logger.info("  Omega: #{if omega_alive, do: "OK", else: "FAIL"}")
    Logger.info("  COP: #{if cop_alive, do: "OK", else: "FAIL"}")
    Logger.info("  Runtime: #{if runtime_alive, do: "OK", else: "FAIL"}")
    Logger.info("  Verification: #{if verification.passed, do: "OK", else: "FAIL"}")

    result
  end

  defp run_resurrection do
    resurrected =
      try do
        case TiannaraRuntime.OS.Persistence.ResurrectionEngine.resurrect() do
          {:ok, report} ->
            Logger.info(
              "Resurrection: #{report.events_replayed} events replayed, #{report.experiments_recovered} experiments recovered"
            )

            true

          {:error, reason} ->
            Logger.warning("Resurrection skipped: #{reason}")
            false
        end
      rescue
        _ -> false
      end

    TiannaraRuntime.OS.Persistence.ResurrectionEngine.mark_running()
    resurrected
  end

  defp collect_errors(verification) do
    errors = []

    cpl_alive =
      Process.whereis(TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayer) != nil

    errors = if not cpl_alive, do: ["CPL failed to start" | errors], else: errors

    omega_alive = Process.whereis(TiannaraRuntime.Omega.Supervisor) != nil
    errors = if not omega_alive, do: ["Omega robustness failed to start" | errors], else: errors

    cop_alive = Process.whereis(TiannaraRuntime.OS.Observatory) != nil
    errors = if not cop_alive, do: ["COP failed to start" | errors], else: errors

    runtime_alive = Process.whereis(TiannaraRuntime.RootSupervisor) != nil
    errors = if not runtime_alive, do: ["Core Runtime failed to start" | errors], else: errors

    errors =
      if not verification.passed, do: ["Startup verification failed" | errors], else: errors

    Enum.reverse(errors)
  end
end
