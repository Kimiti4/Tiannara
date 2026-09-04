Mix.Task.run("app.config")
Process.flag(:trap_exit, true)
[mode, out_dir] = System.argv()
File.mkdir_p!(out_dir)
attempt = fn f -> try do {:ok, f.()} rescue e -> {:error, "rescue: #{Exception.message(e)}"} catch kind, reason -> {:error, "exit #{inspect(kind)}: #{inspect(reason)}"} end end
to_jsonable = fn to_jsonable, term ->
  case term do
    {:ok, v} -> %{"ok" => to_jsonable.(to_jsonable, v)}
    {:error, m} -> %{"error" => to_jsonable.(to_jsonable, m)}
    %{__struct__: _} = s -> to_jsonable.(to_jsonable, Map.from_struct(s))
    tuple when is_tuple(tuple) -> tuple |> Tuple.to_list() |> then(fn l -> to_jsonable.(to_jsonable, l) end)
    list when is_list(list) -> Enum.map(list, &to_jsonable.(to_jsonable, &1))
    map when is_map(map) -> Map.new(map, fn {k, v} -> {to_string(k), to_jsonable.(to_jsonable, v)} end)
    pid when is_pid(pid) -> inspect(pid)
    bool when is_boolean(bool) -> bool
    atom when is_atom(atom) -> Atom.to_string(atom)
    other -> other
  end
end
patch = fn path, replacements ->
  src = File.read!(path)
  Enum.reduce(replacements, src, fn {old, new}, acc ->
    if String.contains?(acc, old) do
      String.replace(acc, old, new, global: false)
    else
      raise "PATCH FAILED in #{Path.basename(path)}: #{String.slice(old, 0..80)}"
    end
  end)
end
# Remove duplicate ownership from ControlCenter
old_cc = "    {Tiannara.Discovery.DiscoveryEngine, :discovery_engine},\n    {Tiannara.Discovery.DiscoveryScheduler, :discovery_scheduler},"
new_cc = "    # AE-010: DiscoveryEngine/Scheduler removed — sole owner is DiscoverySupervisor"
result = case mode do
  "characterize" ->
    attempt.(fn ->
      {:ok, _} = Application.ensure_all_started(:tiannara)
      Process.sleep(1200)
      report = Tiannara.CEL.Kernel.boot_report()
      disc_pid = Process.whereis(Tiannara.Discovery.DiscoverySupervisor)
      engine_pid = Process.whereis(Tiannara.Discovery.DiscoveryEngine)
      metrics_pid = Process.whereis(Tiannara.Discovery.DiscoveryMetrics)
      # Count owners for Engine
      # Check ControlCenter's subsystems
      cc_status = try do Tiannara.ControlCenter.status() catch _, _ -> %{subsystems: %{}} end
      cc_has_engine = Map.has_key?(cc_status.subsystems, :discovery_engine)
      # Check DiscoverySupervisor children
      disc_children = try do Supervisor.which_children(Tiannara.Discovery.DiscoverySupervisor) catch _, _ -> [] end
      disc_has_engine = Enum.any?(disc_children, fn {id, _, _, _} -> id == Tiannara.Discovery.DiscoveryEngine end)
      owner_count = (if cc_has_engine, do: 1, else: 0) + (if disc_has_engine, do: 1, else: 0) + (if engine_pid != nil and not cc_has_engine and not disc_has_engine, do: 1, else: 0)
      %{
        mode: "characterize",
        disc_sup_pid: disc_pid != nil,
        engine_pid: engine_pid != nil,
        metrics_pid: metrics_pid != nil,
        cc_has_engine: cc_has_engine,
        disc_has_engine: disc_has_engine,
        owner_count_engine: owner_count,
        duplicate_ownership: owner_count > 1 or (cc_has_engine and disc_has_engine),
        eos_status: report.status,
        failed_critical: report.failed_critical,
        discovery_state: report.services[:discovery_supervisor]
      }
    end)
  "candidate" ->
    attempt.(fn ->
      patched = patch.("lib/tiannara/control_center.ex", [{old_cc, new_cc}])
      Code.compile_string(patched)
      {:ok, _} = Application.ensure_all_started(:tiannara)
      Process.sleep(1500)
      report = Tiannara.CEL.Kernel.boot_report()
      disc_pid = Process.whereis(Tiannara.Discovery.DiscoverySupervisor)
      engine_pid = Process.whereis(Tiannara.Discovery.DiscoveryEngine)
      scheduler_pid = Process.whereis(Tiannara.Discovery.DiscoveryScheduler)
      metrics_pid = Process.whereis(Tiannara.Discovery.DiscoveryMetrics)
      disc_health = try do Tiannara.Discovery.DiscoverySupervisor.health() catch _, e -> {:error, inspect(e)} end
      # Ownership checks
      cc_status = try do Tiannara.ControlCenter.status() catch _, _ -> %{subsystems: %{}} end
      cc_has_engine = Map.has_key?(cc_status.subsystems, :discovery_engine)
      cc_has_scheduler = Map.has_key?(cc_status.subsystems, :discovery_scheduler)
      disc_children = try do Supervisor.which_children(Tiannara.Discovery.DiscoverySupervisor) catch _, _ -> [] end
      disc_has_engine = Enum.any?(disc_children, fn {id, _, _, _} -> id == Tiannara.Discovery.DiscoveryEngine end)
      disc_has_scheduler = Enum.any?(disc_children, fn {id, _, _, _} -> id == Tiannara.Discovery.DiscoveryScheduler end)
      disc_has_metrics = Enum.any?(disc_children, fn {id, _, _, _} -> id == Tiannara.Discovery.DiscoveryMetrics end)
      # Gates
      t_ownership_engine = not cc_has_engine and disc_has_engine
      t_ownership_scheduler = not cc_has_scheduler and disc_has_scheduler
      t_supervisor_alive = disc_pid != nil
      t_metrics_alive = metrics_pid != nil
      t_health_healthy = disc_health == :healthy
      t_eos_no_critical = report.failed_critical == []
      t_runtime_no_emergency = report.status in [:ready, :degraded] and Tiannara.CEL.Kernel.runtime_state() != :emergency
      t_regression_es = try do Tiannara.CEL.Services.EventStore.healthy?() catch _, _ -> false end
      t_regression_em = try do Tiannara.CEL.Services.ExecutiveMemory.health() == :healthy catch _, _ -> false end
      t_c2_cis = Process.whereis(Tiannara.World.UnifiedRealityGraph) != nil and Process.whereis(Tiannara.CIS.Supervisor) != nil
      t_grounded = try do
        r = Tiannara.CIS.CollapsePredictor.assess_risk(%{executive_memory_health: :healthy, event_store_healthy: true, event_bus_health: :healthy, memory_pressure: 0.1, dets_health: true})
        r_nil = Tiannara.CIS.CollapsePredictor.assess_risk(nil)
        match?(%{risk_score: _}, r) and match?({:unknown, _, _}, r_nil)
      catch _, _ -> false
      end
      %{
        mode: "candidate",
        cc_has_engine: cc_has_engine,
        cc_has_scheduler: cc_has_scheduler,
        disc_has_engine: disc_has_engine,
        disc_has_scheduler: disc_has_scheduler,
        disc_has_metrics: disc_has_metrics,
        disc_sup_pid: disc_pid != nil,
        engine_pid: engine_pid != nil,
        scheduler_pid: scheduler_pid != nil,
        metrics_pid: metrics_pid != nil,
        disc_health: disc_health,
        eos_status: report.status,
        failed_critical: report.failed_critical,
        runtime_state: Tiannara.CEL.Kernel.runtime_state(),
        event_store_healthy: t_regression_es,
        executive_memory_healthy: t_regression_em,
        c2_cis_alive: t_c2_cis,
        grounded_ok: t_grounded,
        gates: %{
          ownership_engine: t_ownership_engine,
          ownership_scheduler: t_ownership_scheduler,
          supervisor_alive: t_supervisor_alive,
          metrics_alive: t_metrics_alive,
          health_healthy: t_health_healthy,
          eos_no_critical: t_eos_no_critical,
          runtime_no_emergency: t_runtime_no_emergency,
          regression_es: t_regression_es,
          regression_em: t_regression_em,
          c2_cis: t_c2_cis,
          grounded: t_grounded
        },
        overall_pass: t_ownership_engine and t_ownership_scheduler and t_supervisor_alive and t_metrics_alive and t_health_healthy and t_eos_no_critical and t_runtime_no_emergency
      }
    end)
end
IO.puts("AE010CHAIN_RESULT " <> Jason.encode!(to_jsonable.(to_jsonable, %{status: "complete", mode: mode, phase: result})))
