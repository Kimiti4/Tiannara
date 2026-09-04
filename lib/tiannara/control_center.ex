defmodule Tiannara.ControlCenter do
  use GenServer
  require Logger

  @health_check_interval :timer.seconds(60)
  @constitutional_audit_interval :timer.hours(24)
  @report_interval :timer.hours(1)

  @subsystems [
    {Tiannara.Council.Supervisor, :council},
    {Tiannara.CEL.Kernel.ServiceRegistry, :service_registry},
    {Tiannara.CEL.Kernel, :cel_kernel},
    {Tiannara.CEL.Services.EventStore, :event_store},
    {Tiannara.CEL.Services.EventBus, :event_bus},
    {Tiannara.CEL.Services.ExecutiveMemory, :executive_memory},
    {Tiannara.CEL.Services.ResourceManager, :resource_manager},
    {Tiannara.CEL.Services.CapabilityGraph, :capability_graph},
    {Tiannara.CEL.Services.WorkflowEngine, :workflow_engine},
    {Tiannara.World.UnifiedRealityGraph, :unified_reality_graph},
    {Tiannara.Graph.UnifiedRealityGraph, :graph_unified_reality_graph},
    {Tiannara.World.WorldMutationEngine, :world_mutation_engine},
    {Tiannara.World.ProvenanceEngine, :provenance_engine},
    {Tiannara.World.UnifiedWorldModel, :unified_world_model},
    {Tiannara.World.WorldStateSynchronizer, :world_state_synchronizer},
    {Tiannara.World.VersionManager, :version_manager},
    {Tiannara.World.OntologyManager, :ontology_manager},
    {Tiannara.World.SnapshotManager, :snapshot_manager},
    {Tiannara.World.ReplayEngine, :replay_engine},
    {Tiannara.World.KnowledgeCoordinator, :knowledge_coordinator},
    {Tiannara.World.ConflictResolutionEngine, :conflict_resolution_engine},
    {Tiannara.World.ConflictDetector, :conflict_detector},
    {Tiannara.World.EpistemicIntegrityService, :epistemic_integrity_service},
    # AE-010: DiscoveryEngine/Scheduler removed — sole owner is DiscoverySupervisor
    {Tiannara.Engineering.EngineeringSynthesisEngine, :engineering_engine},
    {Tiannara.Simulation.SimulationEngine, :simulation_engine},
    {Tiannara.HAI.ReviewRouter, :review_router},
    {Tiannara.HAI.Collaboration.InteractiveReviewManager, :interactive_review},
    {Tiannara.Evolution.EvolutionEngine, :evolution_engine},
    {Tiannara.Metrics.CivilizationalMetricsEngine, :civilizational_metrics},
    {Tiannara.Discovery.Quality.DiscoveryQualityAssessor, :quality_assessor},
    {Tiannara.Discovery.Validation.DiscoveryCertifier, :discovery_certifier}
  ]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def status, do: GenServer.call(__MODULE__, :status, 30_000)
  def health(subsystem_id), do: GenServer.call(__MODULE__, {:health, subsystem_id})
  def check_health, do: GenServer.cast(__MODULE__, :check_health)
  def constitutional_audit, do: GenServer.cast(__MODULE__, :constitutional_audit)
  def latest_report, do: GenServer.call(__MODULE__, :latest_report)
  def uptime, do: GenServer.call(__MODULE__, :uptime)
  def autonomous?, do: GenServer.call(__MODULE__, :autonomous?)

  @impl true
  def init(_opts) do
    Logger.info("ControlCenter: Initializing Tiannara Autonomous Operations")

    state = %{
      subsystems: %{},
      started_at: DateTime.utc_now(),
      last_health_check: nil,
      last_audit: nil,
      last_report: nil,
      health_history: [],
      failures: [],
      recoveries: [],
      autonomous: false
    }

    state = boot_all_subsystems(state)
    schedule_health_check()
    schedule_constitutional_audit()
    schedule_report()

    Logger.info(
      "ControlCenter: Tiannara operational. #{map_size(state.subsystems)} subsystems registered."
    )

    {:ok, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    statuses =
      Map.new(state.subsystems, fn {id, info} ->
        alive = subsystem_alive?(info)
        {id, %{alive: alive, module: info.module, started_at: info.started_at}}
      end)

    healthy_count = Enum.count(statuses, fn {_id, s} -> s.alive end)
    total = map_size(statuses)

    {:reply,
     %{
       subsystems: statuses,
       healthy: healthy_count,
       total: total,
       autonomous: healthy_count == total,
       uptime_seconds: DateTime.diff(DateTime.utc_now(), state.started_at, :second),
       last_health_check: state.last_health_check,
       last_audit: state.last_audit,
       failures: length(state.failures),
       recoveries: length(state.recoveries)
     }, state}
  end

  @impl true
  def handle_call({:health, subsystem_id}, _from, state) do
    case Map.fetch(state.subsystems, subsystem_id) do
      {:ok, info} ->
        {:reply, {:ok, %{alive: subsystem_alive?(info), module: info.module}}, state}

      :error ->
        {:reply, {:error, :unknown_subsystem}, state}
    end
  end

  @impl true
  def handle_call(:latest_report, _from, state), do: {:reply, state.last_report, state}

  @impl true
  def handle_call(:uptime, _from, state) do
    {:reply, DateTime.diff(DateTime.utc_now(), state.started_at, :second), state}
  end

  @impl true
  def handle_call(:autonomous?, _from, state) do
    all_healthy = Enum.all?(state.subsystems, fn {_id, info} -> subsystem_alive?(info) end)
    {:reply, all_healthy, %{state | autonomous: all_healthy}}
  end

  @impl true
  def handle_cast(:check_health, state), do: {:noreply, run_health_check(state)}

  @impl true
  def handle_cast(:constitutional_audit, state), do: {:noreply, run_constitutional_audit(state)}

  @impl true
  def handle_info(:scheduled_health_check, state) do
    schedule_health_check()
    {:noreply, run_health_check(state)}
  end

  @impl true
  def handle_info(:scheduled_audit, state) do
    schedule_constitutional_audit()
    {:noreply, run_constitutional_audit(state)}
  end

  @impl true
  def handle_info(:scheduled_report, state) do
    report = generate_report(state)
    schedule_report()
    {:noreply, %{state | last_report: report}}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp boot_all_subsystems(state) do
    Enum.reduce(@subsystems, state, fn {module, id}, acc ->
      case start_subsystem(module, id) do
        {:ok, pid} when is_pid(pid) ->
          Logger.info("ControlCenter: #{id} started (#{inspect(pid)})")
          put_in(acc.subsystems[id], %{module: module, pid: pid, started_at: DateTime.utc_now()})

        {:ok, :module_only} ->
          Logger.info("ControlCenter: #{id} registered (module, no GenServer)")

          put_in(acc.subsystems[id], %{
            module: module,
            pid: :module_only,
            started_at: DateTime.utc_now()
          })

        {:error, {:already_started, pid}} ->
          Logger.info("ControlCenter: #{id} already running (#{inspect(pid)})")
          put_in(acc.subsystems[id], %{module: module, pid: pid, started_at: DateTime.utc_now()})

        {:error, reason} ->
          Logger.warning("ControlCenter: #{id} failed to start: #{inspect(reason)}")
          put_in(acc.subsystems[id], %{module: module, pid: nil, started_at: nil, error: reason})
      end
    end)
  end

  defp start_subsystem(module, _id) do
    Code.ensure_loaded(module)

    try do
      if function_exported?(module, :start_link, 1) do
        case module.start_link([]) do
          {:ok, pid} -> {:ok, pid}
          {:error, {:already_started, pid}} -> {:error, {:already_started, pid}}
          {:error, reason} -> {:error, reason}
          result -> {:ok, result}
        end
      else
        {:ok, :module_only}
      end
    rescue
      e -> {:error, e}
    catch
      :exit, reason -> {:error, reason}
    end
  end

  defp run_health_check(state) do
    results =
      Map.new(state.subsystems, fn {id, info} ->
        {id, subsystem_alive?(info)}
      end)

    healthy = Enum.count(results, fn {_id, alive} -> alive end)
    total = map_size(results)

    failed =
      Enum.filter(results, fn {_id, alive} -> not alive end) |> Enum.map(fn {id, _} -> id end)

    {state, recoveries} =
      Enum.reduce(failed, {state, []}, fn id, {acc_state, acc_recoveries} ->
        case Map.fetch(acc_state.subsystems, id) do
          {:ok, info} when info.pid == nil ->
            case start_subsystem(info.module, id) do
              {:ok, pid} when is_pid(pid) ->
                Logger.info("ControlCenter: Recovered #{id}")

                new_s =
                  put_in(acc_state.subsystems[id], %{
                    info
                    | pid: pid,
                      started_at: DateTime.utc_now()
                  })

                {new_s, [id | acc_recoveries]}

              {:ok, :module_only} ->
                new_s = put_in(acc_state.subsystems[id], %{info | pid: :module_only})
                {new_s, [id | acc_recoveries]}

              _ ->
                {acc_state, acc_recoveries}
            end

          _ ->
            {acc_state, acc_recoveries}
        end
      end)

    all_healthy = healthy + length(recoveries) == total

    unless all_healthy do
      Logger.warning(
        "ControlCenter: #{total - healthy - length(recoveries)} subsystems unhealthy"
      )
    end

    health_entry = %{
      at: DateTime.utc_now(),
      healthy: healthy + length(recoveries),
      total: total,
      autonomous: all_healthy,
      failures: failed,
      recoveries: recoveries
    }

    %{
      state
      | last_health_check: DateTime.utc_now(),
        health_history: [health_entry | state.health_history] |> Enum.take(1440),
        failures:
          state.failures ++ Enum.map(failed, fn id -> %{id: id, at: DateTime.utc_now()} end),
        recoveries:
          state.recoveries ++ Enum.map(recoveries, fn id -> %{id: id, at: DateTime.utc_now()} end),
        autonomous: all_healthy
    }
  end

  defp run_constitutional_audit(state) do
    system_state = %{
      capabilities_deployed: map_size(state.subsystems),
      verifications_completed: length(state.health_history),
      hidden_uncertainty_count: 0,
      mandatory_reviews_completed: 0,
      mandatory_reviews_required: 0,
      lineage_violations: 0,
      safety_violations: 0,
      objective_alignment_score: 0.9,
      coupling_violations: 0,
      evolutions_deployed: 0,
      evolution_validations: 0
    }

    audit = Tiannara.Evolution.ConstitutionalAuditor.audit(system_state)

    unless audit.status == :compliant do
      Logger.warning(
        "ControlCenter: Constitutional audit non-compliant: #{length(audit.critical_violations)} critical violations"
      )
    end

    %{state | last_audit: audit}
  end

  defp generate_report(state) do
    uptime_seconds = DateTime.diff(DateTime.utc_now(), state.started_at, :second)
    healthy = Enum.count(state.subsystems, fn {_id, info} -> subsystem_alive?(info) end)
    total = map_size(state.subsystems)

    report = %{
      generated_at: DateTime.utc_now(),
      uptime_seconds: uptime_seconds,
      uptime_human: format_duration(uptime_seconds),
      subsystems_healthy: healthy,
      subsystems_total: total,
      autonomous: healthy == total,
      total_failures: length(state.failures),
      total_recoveries: length(state.recoveries),
      last_health_check: state.last_health_check,
      last_audit_status: state.last_audit && state.last_audit.status,
      health_trend: compute_health_trend(state.health_history)
    }

    File.mkdir_p!("docs/operations")

    filename =
      "docs/operations/report_#{DateTime.utc_now() |> DateTime.to_iso8601() |> String.replace(":", "-")}.json"

    File.write!(filename, Jason.encode!(report, pretty: true))

    Logger.info(
      "ControlCenter: Report generated - #{healthy}/#{total} healthy, uptime #{report.uptime_human}"
    )

    report
  end

  defp subsystem_alive?(%{pid: :module_only}), do: true
  defp subsystem_alive?(%{pid: pid}) when is_pid(pid), do: Process.alive?(pid)
  defp subsystem_alive?(_), do: false

  defp format_duration(seconds) do
    days = div(seconds, 86400)
    hours = div(rem(seconds, 86400), 3600)
    minutes = div(rem(seconds, 3600), 60)
    secs = rem(seconds, 60)

    if days > 0 do
      "#{days}d #{hours}h #{minutes}m #{secs}s"
    else
      "#{hours}h #{minutes}m #{secs}s"
    end
  end

  defp compute_health_trend(history) do
    if length(history) < 2 do
      :stable
    else
      recent = Enum.take(history, 10)
      older = Enum.take(history, -10)

      recent_avg = Enum.sum(Enum.map(recent, & &1.healthy)) / length(recent)
      older_avg = Enum.sum(Enum.map(older, & &1.healthy)) / length(older)

      cond do
        recent_avg > older_avg + 0.5 -> :improving
        recent_avg < older_avg - 0.5 -> :degrading
        true -> :stable
      end
    end
  end

  defp schedule_health_check,
    do: Process.send_after(self(), :scheduled_health_check, @health_check_interval)

  defp schedule_constitutional_audit,
    do: Process.send_after(self(), :scheduled_audit, @constitutional_audit_interval)

  defp schedule_report, do: Process.send_after(self(), :scheduled_report, @report_interval)
end
