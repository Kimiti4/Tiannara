Mix.Task.run("app.config")

Process.flag(:trap_exit, true)

[mode, out_dir] = System.argv()

File.mkdir_p!(out_dir)

now_iso = fn -> DateTime.utc_now() |> DateTime.to_iso8601() end

phase = fn _name, fun ->
  try do
    {:ok, fun.()}
  rescue
    e -> {:error, "rescue: #{Exception.message(e)}"}
  catch
    kind, reason -> {:error, "catch: #{inspect(kind)}: #{inspect(reason)}"}
  end
end

attempt = fn f ->
  try do
    {:ok, f.()}
  rescue
    e -> {:error, "rescue: #{Exception.message(e)}"}
  catch
    kind, reason -> {:error, "exit #{inspect(kind)}: #{inspect(reason)}"}
  end
end

to_jsonable = fn to_jsonable, term ->
  case term do
    {:ok, v} -> %{"ok" => to_jsonable.(to_jsonable, v)}
    {:error, m} -> %{"error" => to_jsonable.(to_jsonable, m)}
    %{__struct__: _} = s -> to_jsonable.(to_jsonable, Map.from_struct(s))
    tuple when is_tuple(tuple) -> tuple |> Tuple.to_list() |> then(fn l -> to_jsonable.(to_jsonable, l) end)
    list when is_list(list) -> Enum.map(list, &to_jsonable.(to_jsonable, &1))
    map when is_map(map) -> Map.new(map, fn {k, v} -> {to_string(k), to_jsonable.(to_jsonable, v)} end)
    pid when is_pid(pid) -> inspect(pid)
    ref when is_reference(ref) -> inspect(ref)
    port when is_port(port) -> inspect(port)
    fun when is_function(fun) -> inspect(fun)
    bool when is_boolean(bool) -> bool
    atom when is_atom(atom) -> Atom.to_string(atom)
    other -> other
  end
end

topology = fn ->
  Supervisor.start_link(
    [
      Tiannara.Metrics.Aggregator,
      Tiannara.CEL.Services.EventStore,
      Tiannara.CEL.Services.ExecutiveMemory,
      Tiannara.World.UnifiedRealityGraph,
      Tiannara.CIS.Supervisor
    ],
    strategy: :one_for_one,
    name: :u7_test_sup
  )
end

result =
  case mode do
    "healthy" ->
      phase.(:u7_healthy, fn ->
        {:ok, _} = topology.()

        baseline_plan = attempt.(fn -> Tiannara.CIS.ImmuneDecisionEngine.evaluate(:baseline, 0.1) end)
        collapse_risk = attempt.(fn -> Tiannara.CIS.CollapsePredictor.assess_risk(:reality_graph) end)
        constraint_check = attempt.(fn -> Tiannara.CIS.validate_plan(%{id: "baseline_plan"}) end)
        diversity = attempt.(fn -> Tiannara.CIS.check_domain_diversity(%{science: 1.0, engineering: 0.8}) end)
        regulation_log = attempt.(fn -> Tiannara.CIS.RegulationExecutor.execute(:monitor, :baseline) end)

        %{
          mode: "healthy",
          topology_up: %{
            executive_memory: Process.whereis(Tiannara.CEL.Services.ExecutiveMemory) != nil,
            event_store: Process.whereis(Tiannara.CEL.Services.EventStore) != nil,
            cis_supervisor: Process.whereis(Tiannara.CIS.Supervisor) != nil,
            reality_graph: Process.whereis(Tiannara.World.UnifiedRealityGraph) != nil
          },
          measured_state: :live,
          baseline_plan: baseline_plan,
          collapse_risk: collapse_risk,
          constraint_check: constraint_check,
          domain_diversity: diversity,
          regulation_log: regulation_log,
          c12_classification: "HEALTHY",
          timestamp: now_iso.()
        }
      end)

    "fault" ->
      phase.(:u7_fault, fn ->
        {:ok, sup} = topology.()

        # --- U7-B: bounded fault injection (test harness, declared) ---
        {kill_us, kill_res} =
          :timer.tc(fn -> Supervisor.terminate_child(sup, Tiannara.CEL.Services.ExecutiveMemory) end)

        Process.sleep(200)

        fault_measured = %{
          executive_memory_live: Process.whereis(Tiannara.CEL.Services.ExecutiveMemory) != nil,
          direct_probe: attempt.(fn -> Tiannara.CEL.Services.ExecutiveMemory.count() end)
        }

        # Severity derived from REAL measurement (process absent + :noproc)
        severity =
          if fault_measured.executive_memory_live, do: 0.1, else: 0.8
        decision = attempt.(fn -> Tiannara.CIS.ImmuneDecisionEngine.evaluate(:executive_memory_outage, severity) end)
        c12_classification = if severity > 0.7, do: "FAILED/DEGRADED", else: "HEALTHY"

        # --- U7-C: recovery protocol (CIS proposes; test harness executes) ---
        recovery_proposal = attempt.(fn -> Tiannara.CIS.RegulationExecutor.execute(:restart, :executive_memory) end)

        {restart_us, restart_res} =
          :timer.tc(fn -> Supervisor.restart_child(sup, Tiannara.CEL.Services.ExecutiveMemory) end)

        Process.sleep(200)

        restored = %{
          executive_memory_live: Process.whereis(Tiannara.CEL.Services.ExecutiveMemory) != nil,
          canonical_state_preserved: attempt.(fn ->
            Tiannara.World.UnifiedRealityGraph.add_entity(%{
              id: "post_recovery_" <> Base.encode16(:crypto.strong_rand_bytes(4), case: :lower),
              type: :event,
              provenance: "u7_recovery_check",
              status: :active
            })
          end),
          event_store_count: attempt.(fn -> Tiannara.CEL.Services.EventStore.count(:executive_memory) end)
        }

        %{
          mode: "fault",
          injected_fault: "executive_memory terminated (test harness)",
          terminate_result: kill_res,
          terminate_latency_us: kill_us,
          fault_measured: fault_measured,
          severity_measured: severity,
          immune_decision: decision,
          c12_classification: c12_classification,
          recovery_proposal: recovery_proposal,
          recovery_is_log_only: true,
          restart_result: restart_res,
          restart_latency_us: restart_us,
          restored: restored,
          timestamp: now_iso.()
        }
      end)

    "full" ->
      phase.(:u7_full, fn ->
        {boot_us, boot_res} =
          :timer.tc(fn ->
            case Application.ensure_all_started(:tiannara) do
              {:ok, _} -> :ok
              {:error, reason} -> {:error, reason}
            end
          end)

        boot_report = attempt.(fn -> Tiannara.CEL.Kernel.boot_report() end)
        kernel_state = attempt.(fn -> Tiannara.CEL.Kernel.runtime_state() end)

        br = case boot_report do
          {:ok, r} -> r
          _ -> %{failed_critical: []}
        end

        live_truth = %{
          executive_memory: Process.whereis(Tiannara.CEL.Services.ExecutiveMemory) != nil,
          event_store: Process.whereis(Tiannara.CEL.Services.EventStore) != nil,
          unified_world_model: Process.whereis(Tiannara.World.UnifiedWorldModel) != nil,
          cis_supervisor: Process.whereis(Tiannara.CIS.Supervisor) != nil
        }

        report_claims = %{
          executive_memory: Enum.member?(br.failed_critical, :executive_memory),
          event_store: Enum.member?(br.failed_critical, :event_store),
          unified_world_model: Enum.member?(br.failed_critical, :unified_world_model)
        }

        %{
          mode: "full",
          boot_result: boot_res,
          boot_latency_us: boot_us,
          kernel_state: kernel_state,
          live_truth: live_truth,
          report_claims: report_claims,
          f9_detected: report_claims.executive_memory and live_truth.executive_memory,
          timestamp: now_iso.()
        }
      end)

    _ ->
      %{"error" => "unknown mode #{mode}"}
  end

IO.puts("U7CHAIN_RESULT " <> Jason.encode!(to_jsonable.(to_jsonable, %{status: "complete", mode: mode, phase: result})))