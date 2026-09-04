Process.flag(:trap_exit, true)

attempt = fn f ->
  try do
    {:ok, f.()}
  rescue
    e -> {:error, "rescue: #{Exception.message(e)}"}
  catch
    kind, reason -> {:error, "exit #{inspect(kind)}: #{inspect(reason)}"}
  end
end

jsonable = fn jsonable, term ->
  case term do
    {:ok, v} -> %{"ok" => jsonable.(jsonable, v)}
    {:error, m} -> %{"error" => jsonable.(jsonable, m)}
    tuple when is_tuple(tuple) -> tuple |> Tuple.to_list() |> then(fn l -> jsonable.(jsonable, l) end)
    list when is_list(list) -> Enum.map(list, &jsonable.(jsonable, &1))
    map when is_map(map) -> Map.new(map, fn {k, v} -> {to_string(k), jsonable.(jsonable, v)} end)
    pid when is_pid(pid) -> inspect(pid)
    atom when is_atom(atom) -> Atom.to_string(atom)
    other -> other
  end
end

result =
  attempt.(fn ->
    {:ok, _} = Application.ensure_all_started(:tiannara)

    start_result =
      case DynamicSupervisor.start_child(
             Process.whereis(Tiannara.CEL.ServiceSupervisor),
             %{id: :discovery_supervisor_probe, start: {Tiannara.Discovery.DiscoverySupervisor, :start_link, [[]]}, restart: :temporary}
           ) do
        {:ok, pid} -> {:started, pid}
        other -> other
      end

    %{
      start_result: start_result,
      engine_live: Process.whereis(Tiannara.Discovery.DiscoveryEngine) != nil,
      scheduler_live: Process.whereis(Tiannara.Discovery.DiscoveryScheduler) != nil,
      metrics_live: Process.whereis(Tiannara.Discovery.DiscoveryMetrics) != nil
    }
  end)

IO.puts("DIAG2_RESULT " <> Jason.encode!(jsonable.(jsonable, result)))