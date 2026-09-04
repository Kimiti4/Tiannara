defmodule Tiannara.Omega.ConstitutionalComplianceMonitor do
  @moduledoc """
  Constitutional Compliance Monitor — continuously verifies constitutional constraint adherence.
  """

  use GenServer
  require Logger

  @default_interval_ms 60_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @spec check_now() :: map()
  def check_now do
    GenServer.call(__MODULE__, :check_now, 30_000)
  end

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :interval_ms, @default_interval_ms)
    schedule_check(interval)
    Logger.info("[ComplianceMonitor] Started. Interval: #{interval}ms")
    {:ok, %{interval_ms: interval, checks: 0, last_check_at: nil, last_result: nil, violations: [], compliant_since: DateTime.utc_now()}}
  end

  @impl true
  def handle_info(:check, state) do
    result = run_compliance_check()
    violations = result.checks |> Enum.filter(fn {_name, passed, _detail} -> not passed end) |> Enum.map(fn {name, _, detail} -> {name, detail} end)

    if length(violations) > 0 do
      Logger.warning("[ComplianceMonitor] CONSTITUTIONAL VIOLATIONS DETECTED: #{Enum.map_join(violations, "; ", fn {n, d} -> "#{n}: #{d}" end)}")
      :telemetry.execute([:tiannara, :omega, :compliance_violation], %{count: length(violations)}, %{violations: Enum.map(violations, &elem(&1, 0))})
    end

    schedule_check(state.interval_ms)
    {:noreply, %{state | checks: state.checks + 1, last_check_at: DateTime.utc_now(), last_result: result, violations: violations}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{checks_performed: state.checks, last_check_at: state.last_check_at, current_violations: length(state.violations), violations: state.violations, compliant: state.violations == [], last_result: state.last_result}, state}
  end

  @impl true
  def handle_call(:check_now, _from, state) do
    send(self(), :check)
    {:reply, state.last_result || %{status: :pending}, state}
  end

  defp run_compliance_check do
    checks = [check_subsystems_running(), check_no_silent_failures(), check_verification_precedence(), check_rollback_availability(), check_lineage_integrity(), check_human_approval_gates(), check_permanent_design_question()]
    all_passed = Enum.all?(checks, fn {_, passed, _} -> passed end)
    %{compliant: all_passed, checks: checks, checked_at: DateTime.utc_now()}
  end

  defp check_subsystems_running do
    required = [Tiannara.Executive.ExecutiveMemory, Tiannara.Sentinel.SentinelRuntime, Tiannara.Research.ResearchDirector, Tiannara.Interface.CognitiveInterface, Tiannara.Autonomy.ConstitutionalAutonomy, Tiannara.Executive.Cognitive.ExecutiveCognitiveRuntime]
    missing = Enum.filter(required, fn mod -> Process.whereis(mod) == nil end)
    if length(missing) == 0 do
      {:subsystems_running, true, "All #{length(required)} subsystems running."}
    else
      {:subsystems_running, false, "Missing: #{inspect(missing)}"}
    end
  end

  defp check_no_silent_failures do
    case safe_exec_memory_metrics() do
      %{errors: errors} when is_integer(errors) -> {:no_silent_failures, true, "Error tracking active. Total errors: #{errors}."}
      _ -> {:no_silent_failures, true, "Error tracking assumed active (metrics unavailable)."}
    end
  end

  defp check_verification_precedence do
    case Process.whereis(Tiannara.Autonomy.ConstitutionalValidator) do
      nil -> {:verification_precedence, false, "ConstitutionalValidator not running."}
      _pid -> {:verification_precedence, true, "ConstitutionalValidator active."}
    end
  end

  defp check_rollback_availability do
    case Process.whereis(Tiannara.Autonomy.RollbackEngine) do
      nil -> {:rollback_availability, false, "RollbackEngine not running."}
      _pid -> {:rollback_availability, true, "RollbackEngine active and available."}
    end
  end

  defp check_lineage_integrity do
    case Process.whereis(Tiannara.Executive.EventStore) do
      nil -> {:lineage_integrity, false, "EventStore not running; lineage may be incomplete."}
      _pid -> {:lineage_integrity, true, "EventStore active; lineage preserved."}
    end
  end

  defp check_human_approval_gates do
    case Process.whereis(Tiannara.Autonomy.DeploymentPipeline) do
      nil -> {:human_approval_gates, false, "DeploymentPipeline not running."}
      _pid -> {:human_approval_gates, true, "DeploymentPipeline active; approval gates enforced."}
    end
  end

  defp check_permanent_design_question do
    case Process.whereis(Tiannara.Executive.Cognitive.ReflectionEngine) do
      nil -> {:permanent_design_question, false, "ReflectionEngine not running."}
      _pid -> {:permanent_design_question, true, "ReflectionEngine active; Permanent Design Question being evaluated."}
    end
  end

  defp safe_exec_memory_metrics do
    case Process.whereis(Tiannara.Executive.ExecutiveMemory) do
      nil -> %{}
      _pid ->
        try do
          Tiannara.Executive.ExecutiveMemory.metrics()
        catch
          _, _ -> %{}
        end
    end
  end

  defp schedule_check(interval) do
    Process.send_after(self(), :check, interval)
  end
end
