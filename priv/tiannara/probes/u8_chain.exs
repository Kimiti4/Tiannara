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

topology = fn ->
  Supervisor.start_link(
    [
      Tiannara.CEL.Services.EventStore,
      Tiannara.CEL.Services.ExecutiveMemory,
      Tiannara.World.UnifiedRealityGraph
    ],
    strategy: :one_for_one,
    name: :u8_test_sup
  )
end

result =
  case mode do
    "cycle" ->
      corr_id = "u8_#{Base.encode16(:crypto.strong_rand_bytes(8), case: :lower)}"
      entity_id = "entity_#{Base.encode16(:crypto.strong_rand_bytes(6), case: :lower)}"
      store_dir = Path.join(out_dir, "u8_store_#{Base.encode16(:crypto.strong_rand_bytes(4), case: :lower)}")

      # ---- S0: baseline (S0 -> E -> K) ----
      s0_phase = attempt.(fn ->
        {:ok, sup} = topology.()

        {:ok, store} = Tiannara.Memory.KnowledgeStore.open(store_dir)

        {:ok, event_id} =
          Tiannara.CEL.Services.ExecutiveMemory.record_decision(
            corr_id,
            :ingest,
            %{entity_id: entity_id, source: "u8_probe", stage: :baseline},
            %{}
          )

        {:ok, ^entity_id} =
          Tiannara.World.UnifiedRealityGraph.add_entity(%{
            id: entity_id,
            type: :event,
            provenance: "u8_continuity",
            status: :active
          })

        artifact =
          Tiannara.Memory.Artifact.new(
            :knowledge,
            %{entity_id: entity_id, correlation_id: corr_id, claim: "entity observed at S0"},
            lineage: [corr_id],
            confidence: 0.9
          )

        :ok = Tiannara.Memory.KnowledgeStore.append(store, artifact)

        before_events =
          Tiannara.CEL.Services.EventStore.read_topic(:executive_memory)

        %{
          sup: sup,
          store: store,
          event_id: event_id,
          artifact: artifact,
          latest_offset: Tiannara.CEL.Services.EventStore.latest_offset(:executive_memory),
          before_events_count: length(before_events),
          before_matching: before_events |> Enum.filter(fn {_o, e, _ts} -> e.correlation_id == corr_id end) |> length(),
          graph_entity: Tiannara.World.UnifiedRealityGraph.get_entity(entity_id),
          event_store_dets_path: Tiannara.Storage.Paths.dets("cel_event_store"),
          executive_memory_dets: File.exists?("cel_memory_v2.dets"),
          executive_memory_count: Tiannara.CEL.Services.ExecutiveMemory.count()
        }
      end)

      s0_ok = match?({:ok, _}, s0_phase)
      sup = if s0_ok, do: s0_phase |> elem(1) |> Map.get(:sup), else: nil
      store = if s0_ok, do: s0_phase |> elem(1) |> Map.get(:store), else: nil
      event_id = if s0_ok, do: s0_phase |> elem(1) |> Map.get(:event_id), else: nil
      artifact = if s0_ok, do: s0_phase |> elem(1) |> Map.get(:artifact), else: nil

      # ---- Failure: SIGKILL the test topology ----
      kill_phase =
        if s0_ok do
          attempt.(fn ->
            Process.exit(sup, :kill)
            Process.sleep(500)
            %{
              executive_memory_live: Process.whereis(Tiannara.CEL.Services.ExecutiveMemory) != nil,
              event_store_live: Process.whereis(Tiannara.CEL.Services.EventStore) != nil,
              graph_live: Process.whereis(Tiannara.World.UnifiedRealityGraph) != nil
            }
          end)
        else
          %{"error" => "s0_failed_skipped"}
        end

      # ---- Recovery: fresh topology + reopen knowledge store ----
      recovery_phase =
        if s0_ok do
          attempt.(fn ->
            {:ok, sup2} = topology.()
            {:ok, store2} = Tiannara.Memory.KnowledgeStore.open(store_dir)
            %{sup: sup2, store: store2}
          end)
        else
          %{"error" => "s0_failed_skipped"}
        end

      recovery_ok = match?({:ok, _}, recovery_phase)
      sup2 = if recovery_ok, do: recovery_phase |> elem(1) |> Map.get(:sup), else: nil
      store2 = if recovery_ok, do: recovery_phase |> elem(1) |> Map.get(:store), else: nil

      # ---- S1: verification ----
      s1_phase =
        if recovery_ok do
          attempt.(fn ->
            after_events = Tiannara.CEL.Services.EventStore.read_topic(:executive_memory)
            after_matching = after_events |> Enum.filter(fn {_o, e, _ts} -> e.correlation_id == corr_id end)
            knowledge_after = Tiannara.Memory.KnowledgeStore.all(store2)

            %{
              graph_entity_lookup: Tiannara.World.UnifiedRealityGraph.get_entity(entity_id),
              matching_events_after: length(after_matching),
              matching_ids: after_matching |> Enum.map(fn {_o, e, _ts} -> e.id end),
              matching_entity_ids: after_matching |> Enum.map(fn {_o, e, _ts} -> e.payload.entity_id end),
              first_matching_payload: after_matching |> List.first() |> then(fn
                {_o, e, _ts} -> e.payload
                _ -> nil
              end),
              latest_offset_after: Tiannara.CEL.Services.EventStore.latest_offset(:executive_memory),
              replay_found: Tiannara.CEL.Services.EventStore.replay(:executive_memory, 0)
                |> then(fn {:ok, evs} -> Enum.any?(evs, fn {_o, e, _ts} -> e.correlation_id == corr_id end) end),
              knowledge_after_count: length(knowledge_after),
              knowledge_after_ids: knowledge_after |> Enum.map(fn a -> a.id end),
              knowledge_after_lineage: knowledge_after |> Enum.map(fn a -> a.lineage end),
              executive_memory_count_after: Tiannara.CEL.Services.ExecutiveMemory.count(),
              event_store_healthy: Tiannara.CEL.Services.EventStore.healthy?(),
              executive_memory_health: Tiannara.CEL.Services.ExecutiveMemory.health()
            }
          end)
        else
          %{"error" => "recovery_failed_skipped"}
        end

      # ---- U8-4: Recovery honesty — deliberately trigger F8 ----
      honesty_phase = %{
        get_lineage_attempt: attempt.(fn -> Tiannara.CEL.Services.ExecutiveMemory.get_lineage(corr_id) end),
        snapshot_attempt: attempt.(fn -> Tiannara.CEL.Services.ExecutiveMemory.snapshot() end)
      }

      honest_break =
        case honesty_phase.get_lineage_attempt do
          {:error, _} -> true
          {:ok, _} -> false
        end

      %{
        mode: "cycle",
        correlation_id: corr_id,
        entity_id: entity_id,
        event_id: event_id,
        store_dir: store_dir,
        s0: s0_phase,
        kill: kill_phase,
        recovery: recovery_phase,
        s1: s1_phase,
        honesty: honesty_phase,
        honest_break_reported: honest_break,
        no_fabrication: honest_break,
        timestamp: now_iso.()
      }

    _ ->
      %{"error" => "unknown mode #{mode}"}
  end

IO.puts("U8CHAIN_RESULT " <> Jason.encode!(to_jsonable.(to_jsonable, %{status: "complete", mode: mode, phase: result})))