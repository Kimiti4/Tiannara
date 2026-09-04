Mix.Task.run("app.config")

Process.flag(:trap_exit, true)

[mode, out_dir] = System.argv()

File.mkdir_p!(out_dir)

now_iso = fn -> DateTime.utc_now() |> DateTime.to_iso8601() end

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

patch = fn path, replacements ->
  src = File.read!(path)
  Enum.reduce(replacements, src, fn {old, new}, acc ->
    if String.contains?(acc, old) do
      String.replace(acc, old, new, global: false)
    else
      raise "PATCH FAILED in #{Path.basename(path)}: #{old}"
    end
  end)
end

f12_event_store = fn ->
  patch.("lib/tiannara/cel/services/event_store.ex", [
    {"healthy = match?({:ok, _}, :dets.info(@table))",
     "healthy = is_list(:dets.info(@table))"}
  ])
end

f12_executive_memory = fn ->
  patch.("lib/tiannara/cel/services/executive_memory.ex", [
    {"case :dets.info(@table_name) do\n      {:ok, _} -> :healthy\n      _ -> :unhealthy\n    end",
     "case :dets.info(@table_name) do\n      info when is_list(info) -> :healthy\n      _ -> :unhealthy\n    end"}
  ])
end

f12_event_bus = fn ->
  patch.("lib/tiannara/cel/services/event_bus.ex", [
    {"case :dets.info(@dlq_table_name) do\n      {:ok, _} -> :healthy\n      _ -> :unhealthy\n    end",
     "case :dets.info(@dlq_table_name) do\n      info when is_list(info) -> :healthy\n      _ -> :unhealthy\n    end"}
  ])
end

eos_kernel = fn ->
  patch.("lib/tiannara/cel/kernel.ex", [
    {"if apply(mod, fun, args), do: :healthy, else: :unhealthy",
     "case apply(mod, fun, args) do\n        :healthy -> :healthy\n        :unhealthy -> :unhealthy\n        true -> :healthy\n        false -> :unhealthy\n        _ -> :unhealthy\n      end"},
    {"defp start_service(spec, dyn_sup) do\n    child = %{id: spec.id, start: {spec.module, :start_link, [[]]}, restart: :temporary}\n    DynamicSupervisor.start_child(dyn_sup, child)\n  end",
     "defp start_service(spec, dyn_sup) do\n    child = %{id: spec.id, start: {spec.module, :start_link, [[]]}, restart: :temporary}\n    case DynamicSupervisor.start_child(dyn_sup, child) do\n      {:ok, pid} -> {:ok, pid}\n      {:error, {:already_started, pid}} -> {:ok, pid}\n      other -> other\n    end\n  end"}
  ])
end

eos_registry = fn ->
  patch.("lib/tiannara/cel/kernel/service_registry.ex", [
    {"health_check: {Tiannara.CEL.Services.EventStore, :health, []}",
     "health_check: {Tiannara.CEL.Services.EventStore, :healthy?, []}"}
  ])
end

boot = fn ->
  case Tiannara.CEL.Kernel.boot() do
    {:ok, report} -> report
    report -> report
  end
end

result =
  case mode do
    "characterize" ->
      attempt.(fn ->
        {:ok, _} = Application.ensure_all_started(:tiannara)

        report = Tiannara.CEL.Kernel.boot_report()
        runtime_state = Tiannara.CEL.Kernel.runtime_state()

        failed_ids = Map.get(report, :failed_critical, [])

        failed_gate_evidence =
          Enum.map(failed_ids, fn id ->
            %{
              service: id,
              gate_results: Map.get(report, :gate_results, %{}) |> Map.get(id, %{}),
              whereis_alive: Process.whereis(elem(Tiannara.CEL.Kernel.ServiceRegistry.get(id), 1).module) != nil
            }
          end)

        %{
          mode: "characterize",
          boot_report_status: report.status,
          boot_report_services: report.services,
          failed_critical: failed_ids,
          gate_results: report.gate_results,
          failed_gate_evidence: failed_gate_evidence,
          runtime_state: runtime_state,
          event_store_healthy: Tiannara.CEL.Services.EventStore.healthy?(),
          event_store_health: Tiannara.CEL.Services.EventStore.health(),
          executive_memory_health: Tiannara.CEL.Services.ExecutiveMemory.health(),
          dets_info_open_shape: :dets.info(:cel_event_store),
          dets_info_closed_shape: :dets.info(:nonexistent_probe_table),
          event_store_live: Process.whereis(Tiannara.CEL.Services.EventStore) != nil,
          executive_memory_live: Process.whereis(Tiannara.CEL.Services.ExecutiveMemory) != nil,
          unified_world_model_live: Process.whereis(Tiannara.World.UnifiedWorldModel) != nil
        }
      end)

    "candidate_f12" ->
      attempt.(fn ->
        src_es = f12_event_store.()
        src_em = f12_executive_memory.()
        Code.compile_string(src_es)
        Code.compile_string(src_em)

        {:ok, _} =
          Supervisor.start_link(
            [
              Tiannara.Council.Supervisor,
              Tiannara.CEL.Kernel.ServiceRegistry,
              Tiannara.CEL.Kernel
            ],
            strategy: :one_for_one,
            name: :ae004_f12_sup
          )

        boot1 = boot.()

        specificity = %{
          event_store_healthy: Tiannara.CEL.Services.EventStore.healthy?(),
          event_store_health: Tiannara.CEL.Services.EventStore.health(),
          executive_memory_health: Tiannara.CEL.Services.ExecutiveMemory.health(),
          dets_info_open_shape: :dets.info(:cel_event_store),
          boot_report_status: boot1.status,
          runtime_state: Tiannara.CEL.Kernel.runtime_state()
        }

        em_pid = Process.whereis(Tiannara.CEL.Services.ExecutiveMemory)
        Process.exit(em_pid, :kill)
        Process.sleep(300)

        health_after_kill = attempt.(fn -> Tiannara.CEL.Services.ExecutiveMemory.health() end)

        normalized_health =
          case health_after_kill do
            {:ok, :healthy} -> :healthy
            {:ok, :unhealthy} -> :unhealthy
            {:ok, true} -> :healthy
            {:ok, false} -> :unhealthy
            _ -> :unhealthy
          end

        sensitivity = %{
          executive_memory_whereis_after_kill: Process.whereis(Tiannara.CEL.Services.ExecutiveMemory) != nil,
          health_endpoint_after_kill: health_after_kill,
          eos_legacy_classifier: if(health_after_kill == {:ok, :unhealthy} or health_after_kill == {:ok, false} or health_after_kill == {:ok, nil}, do: :healthy, else: :healthy),
          eos_normalized_classifier: normalized_health,
          classifier_sensitivity_lost: normalized_health == :healthy
        }

        %{
          mode: "candidate_f12",
          specificity: specificity,
          sensitivity: sensitivity
        }
      end)

    "candidate_f12_eos" ->
      attempt.(fn ->
        Code.compile_string(f12_event_store.())
        Code.compile_string(f12_executive_memory.())
        Code.compile_string(f12_event_bus.())
        Code.compile_string(eos_kernel.())
        Code.compile_string(eos_registry.())

        topology = fn ->
          Supervisor.start_link(
            [
              Tiannara.Council.Supervisor,
              Tiannara.CEL.Kernel.ServiceRegistry,
              Tiannara.CEL.Kernel
            ],
            strategy: :one_for_one,
            name: :ae004_eos_sup
          )
        end

        # --- Boot 1: SPECIFICITY (fully healthy) ---
        {:ok, _} = topology.()
        boot1 = boot.()

        dets_path = Tiannara.Storage.Paths.dets("cel_event_store")

        specificity = %{
          event_store_healthy: Tiannara.CEL.Services.EventStore.healthy?(),
          event_store_health: Tiannara.CEL.Services.EventStore.health(),
          executive_memory_health: Tiannara.CEL.Services.ExecutiveMemory.health(),
          boot_report_status: boot1.status,
          boot_report_services: boot1.services,
          failed_critical: boot1.failed_critical,
          runtime_state: Tiannara.CEL.Kernel.runtime_state(),
          dets_path: dets_path
        }

        # --- Boot 2: SENSITIVITY (storage fault: dets path blocked by directory) ---
        Process.exit(Process.whereis(:ae004_eos_sup), :kill)
        Process.sleep(400)

        fault_applied = attempt.(fn ->
          File.rm(dets_path)
          File.mkdir_p(dets_path)
          :ok
        end)

        {:ok, _} = topology.()
        boot2 = boot.()

        sensitivity = %{
          fault_applied: fault_applied,
          event_store_healthy: attempt.(fn -> Tiannara.CEL.Services.EventStore.healthy?() end),
          event_store_health: attempt.(fn -> Tiannara.CEL.Services.EventStore.health() end),
          event_store_stats: attempt.(fn -> Tiannara.CEL.Services.EventStore.stats() end),
          boot_report_status: boot2.status,
          failed_critical: boot2.failed_critical,
          runtime_state: Tiannara.CEL.Kernel.runtime_state()
        }

        # --- Boot 3: RECOVERY (fault removed; fresh store) ---
        Process.exit(Process.whereis(:ae004_eos_sup), :kill)
        Process.sleep(400)

        recovery_applied = attempt.(fn ->
          File.rmdir(dets_path)
          :ok
        end)

        {:ok, _} = topology.()
        boot3 = boot.()

        recovery = %{
          recovery_applied: recovery_applied,
          event_store_healthy: Tiannara.CEL.Services.EventStore.healthy?(),
          executive_memory_health: Tiannara.CEL.Services.ExecutiveMemory.health(),
          boot_report_status: boot3.status,
          failed_critical: boot3.failed_critical,
          runtime_state: Tiannara.CEL.Kernel.runtime_state(),
          not_stuck_in_emergency: Tiannara.CEL.Kernel.runtime_state() != :emergency
        }

        %{
          mode: "candidate_f12_eos",
          specificity: specificity,
          sensitivity: sensitivity,
          recovery: recovery
        }
      end)

    "candidate_eos_full" ->
      attempt.(fn ->
        Code.compile_string(f12_event_store.())
        Code.compile_string(f12_executive_memory.())
        Code.compile_string(f12_event_bus.())
        Code.compile_string(eos_kernel.())
        Code.compile_string(eos_registry.())

        {:ok, _} = Application.ensure_all_started(:tiannara)

        report = Tiannara.CEL.Kernel.boot_report()

        %{
          mode: "candidate_eos_full",
          boot_report_status: report.status,
          boot_report_services: report.services,
          failed_critical: report.failed_critical,
          gate_results: report.gate_results,
          runtime_state: Tiannara.CEL.Kernel.runtime_state(),
          event_store_healthy: Tiannara.CEL.Services.EventStore.healthy?(),
          event_store_health: Tiannara.CEL.Services.EventStore.health(),
          executive_memory_health: Tiannara.CEL.Services.ExecutiveMemory.health(),
          event_bus_health: Tiannara.CEL.Services.EventBus.health(),
          f9_resolved: report.status == :ready and Tiannara.CEL.Kernel.runtime_state() == :operational
        }
      end)

    _ ->
      %{"error" => "unknown mode #{mode}"}
  end

IO.puts("AE004CHAIN_RESULT " <> Jason.encode!(to_jsonable.(to_jsonable, %{status: "complete", mode: mode, phase: result})))