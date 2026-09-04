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
    atom when is_atom(atom) -> Atom.to_string(atom)
    other -> other
  end
end
result = case mode do
  "investigate" ->
    attempt.(fn ->
      {:ok, _} = Application.ensure_all_started(:tiannara)
      Process.sleep(1200)
      # Phase A: Failure mechanics
      disc_sup_pid = Process.whereis(Tiannara.Discovery.DiscoverySupervisor)
      metrics_pid = Process.whereis(Tiannara.Discovery.DiscoveryMetrics)
      engine_pid = Process.whereis(Tiannara.Discovery.DiscoveryEngine)
      # Try to start Metrics manually to see result
      start_result = try do
        case Tiannara.Discovery.DiscoveryMetrics.start_link([]) do
          {:ok, pid} -> {:ok, pid}
          {:error, {:already_started, pid}} -> {:already_started, pid}
          other -> other
        end
      catch kind, reason -> {:exit, kind, reason}
      end
      # Check supervisor child specs
      sup_children = try do
        # DiscoverySupervisor is a Supervisor, use Supervisor.which_children
        Supervisor.which_children(Tiannara.Discovery.DiscoverySupervisor)
      catch _, _ -> []
      end
      # Check restart spec via Supervisor.which_children details
      # For metrics, check if it's in children and what its restart is
      metrics_spec = Enum.find(sup_children, fn {id, _, _, _} -> id == Tiannara.Discovery.DiscoveryMetrics end)
      # Phase B: Dependency and ordering - check what Metrics needs
      # Metrics init has no deps, but check if any dependency is missing at boot time
      # Check boot order: when does DiscoverySupervisor start relative to others?
      report = Tiannara.CEL.Kernel.boot_report()
      disc_boot_state = report.services[:discovery_supervisor]
      # Phase C: Intent discovery - read moduledoc and check consumers
      moduledoc = try do
        {:docs_v1, _, _, _, %{"en" => doc}, _, _} = Code.fetch_docs(Tiannara.Discovery.DiscoveryMetrics)
        doc
      catch _, _ -> "no docs"
      end
      # Trace consumers: search for usages of DiscoveryMetrics in codebase (we can grep via file read)
      # For now, check if any GenServer calls DiscoveryMetrics
      consumers = try do
        # Check if DiscoveryEngine or Scheduler call Metrics
        # We can inspect by looking at which modules have been loaded that reference Metrics
        # Simple heuristic: check if Metrics is used in DiscoverySupervisor's health
        health = Tiannara.Discovery.DiscoverySupervisor.health()
        %{health: health, has_metrics_consumer: health == {:degraded, [:discovery_metrics]}}
      catch _, _ -> %{error: true}
      end
      %{
        mode: "investigate",
        phase_a: %{
          disc_sup_pid: disc_sup_pid != nil,
          metrics_pid: metrics_pid != nil,
          engine_pid: engine_pid != nil,
          start_result: start_result,
          sup_children: Enum.map(sup_children, fn {id, pid, type, mods} -> %{id: inspect(id), pid: pid != nil, type: type, mods: inspect(mods)} end),
          metrics_spec: metrics_spec != nil,
          disc_boot_state: disc_boot_state
        },
        phase_b: %{
          report_services: report.services,
          disc_boot_state: disc_boot_state,
          metrics_needs: "none in init, pure state map"
        },
        phase_c: %{
          moduledoc_snippet: String.slice(to_string(moduledoc), 0..500),
          consumers: consumers,
          intent_evidence: "health contract penalizes absence, but moduledoc describes metrics as tracking discovery velocity and success rates - likely required for observability but not for core discovery"
        }
      }
    end)
end
IO.puts("AE009CHAIN_RESULT " <> Jason.encode!(to_jsonable.(to_jsonable, %{status: "complete", mode: mode, phase: result})))
