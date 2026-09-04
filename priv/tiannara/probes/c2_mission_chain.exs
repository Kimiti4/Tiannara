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

get_ok = fn r ->
  case r do
    {:ok, v} -> v
    {:error, e} -> %{"error" => e}
    %{"ok" => v} -> v
    %{"error" => e} -> %{"error" => e}
    other -> other
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
    atom when is_atom(atom) -> Atom.to_string(atom)
    other -> other
  end
end

# ============================================================================
# BOOT (Candidate A: full supervised topology / Candidate B: minimal bootstrap)
# ============================================================================

boot_result =
  phase.(:boot, fn ->
    case mode do
      "minimal" ->
        # Candidate B — safe lazy initialization: probe-local minimal topology
        # EventStore -> ExecutiveMemory -> canonical graph -> legacy graph
        {boot_us, boot_res} =
          :timer.tc(fn ->
            Supervisor.start_link(
              [
                {Tiannara.CEL.Services.EventStore, []},
                {Tiannara.CEL.Services.ExecutiveMemory, []},
                {Tiannara.World.UnifiedRealityGraph, []},
                {Tiannara.Graph.UnifiedRealityGraph, []}
              ],
              strategy: :one_for_one,
              name: :c2_mission_sup
            )
          end)

        event_store_path = Tiannara.Storage.Paths.dets("cel_event_store")

        %{
          candidate: "B_minimal_bootstrap",
          topology: "EventStore -> ExecutiveMemory -> World.UnifiedRealityGraph -> Graph.UnifiedRealityGraph",
          start_result: boot_res,
          start_us: boot_us,
          executive_memory_pid: Process.whereis(Tiannara.CEL.Services.ExecutiveMemory) != nil,
          event_store_pid: Process.whereis(Tiannara.CEL.Services.EventStore) != nil,
          canonical_graph_pid: Process.whereis(Tiannara.World.UnifiedRealityGraph) != nil,
          legacy_graph_pid: Process.whereis(Tiannara.Graph.UnifiedRealityGraph) != nil,
          event_store_dets_path: to_string(event_store_path),
          event_store_dets_exists: File.exists?(event_store_path),
          memory_total_bytes: :erlang.memory(:total),
          ets_table_count: length(:ets.all()),
          dets_table_count: length(:dets.all())
        }

      "full" ->
        # Candidate A — supervised bootstrap: the production topology
        {boot_us, boot_res} =
          :timer.tc(fn ->
            case Application.ensure_all_started(:tiannara) do
              {:ok, _} ->
                :ok
              {:error, reason} ->
                {:error, reason}
            end
          end)

        %{
          candidate: "A_supervised_bootstrap",
          topology: "Tiannara.Application full supervision tree + CEL Kernel boot",
          start_result: boot_res,
          start_us: boot_us,
          executive_memory_pid: Process.whereis(Tiannara.CEL.Services.ExecutiveMemory) != nil,
          event_store_pid: Process.whereis(Tiannara.CEL.Services.EventStore) != nil,
          canonical_graph_pid: Process.whereis(Tiannara.World.UnifiedRealityGraph) != nil,
          legacy_graph_pid: Process.whereis(Tiannara.Graph.UnifiedRealityGraph) != nil,
          kernel_state: attempt.(fn -> Tiannara.CEL.Kernel.runtime_state() end),
          boot_report: attempt.(fn -> Tiannara.CEL.Kernel.boot_report() end),
          memory_total_bytes: :erlang.memory(:total),
          ets_table_count: length(:ets.all()),
          dets_table_count: length(:dets.all())
        }

      _ ->
        {:error, "unknown mode #{mode}"}
    end
  end)

executive_memory_up = boot_result |> get_ok.() |> Map.get(:executive_memory_pid, false)

# ============================================================================
# C1: Perception (identical wiring to U5/U6)
# ============================================================================

payload = %{
  "type" => "external_reality_commit",
  "repository" => "tiannara-mindcache-prosthetic",
  "payload_hash" => "c2-rem-001-mission-probe",
  "content" => %{"files_changed" => ["docs/audit/U0_capability_matrix_update_post_U5U6.md"]},
  "timestamp" => now_iso.()
}

payload_json = Jason.encode!(payload)
payload_hash = :crypto.hash(:sha256, payload_json) |> Base.encode16(case: :lower)

c1_result =
  phase.(:c1_perception, fn ->
    shaped_event = %{
      id: "ext-" <> Base.encode16(:crypto.strong_rand_bytes(8), case: :lower),
      timestamp: now_iso.(),
      source: :external_reality,
      category: :runtime,
      severity: :info,
      observation: payload_json,
      evidence: [payload_hash],
      causal_links: [%{trace_id: "c2_mission", phase: "ingress"}],
      metadata: %{"payload_hash" => payload_hash, "mission" => "C2-REM-001"}
    }

    event = Tiannara.Sentinel.Activation.Event.new(shaped_event)
    engine = attempt.(fn -> Tiannara.Sentinel.Activation.Engine.process(shaped_event) end)

    %{
      event_id: event.id,
      engine: engine,
      provenance: "Tiannara.Sentinel.Activation.Event.new/1 + Engine.process/1",
      timestamp: now_iso.(),
      payload_hash: payload_hash
    }
  end)

# ============================================================================
# C2: Canonical reality graph mutation (Tiannara.World.UnifiedRealityGraph)
# ============================================================================

entity_id = "ext_entity_" <> Base.encode16(:crypto.strong_rand_bytes(6), case: :lower)

c2_canonical_result =
  phase.(:c2_canonical, fn ->
    entity_spec = %{
      id: entity_id,
      type: :event,
      domain: :external_reality,
      payload_hash: payload_hash,
      provenance: "probe_c2_rem_001",
      confidence: 0.8,
      uncertainty: 0.2,
      status: :active,
      mission: "C2-REM-001",
      ingested_at: now_iso.()
    }

    {add_us, add_res} =
      :timer.tc(fn -> Tiannara.World.UnifiedRealityGraph.add_entity(entity_spec) end)

    {get_us, get_res} =
      :timer.tc(fn -> Tiannara.World.UnifiedRealityGraph.get_entity(entity_id) end)

    stats = attempt.(fn -> Tiannara.World.UnifiedRealityGraph.stats() end)

    %{
      entity_id: entity_id,
      add_entity: add_res,
      add_latency_us: add_us,
      get_entity: get_res,
      get_latency_us: get_us,
      stats: stats,
      provenance: "Tiannara.World.UnifiedRealityGraph.add_entity/1 + get_entity/1",
      timestamp: now_iso.(),
      payload_hash: payload_hash
    }
  end)

canonical_ok =
  case c2_canonical_result do
    {:ok, %{add_entity: {:ok, _}}} -> true
    _ -> false
  end

# ============================================================================
# C2b: Legacy graph path (the module U1/U5 probed) — lineage via ExecutiveMemory
# ============================================================================

c2_legacy_result =
  phase.(:c2_legacy, fn ->
    legacy_id = "legacy_node_" <> Base.encode16(:crypto.strong_rand_bytes(6), case: :lower)

    {add_us, add_res} =
      :timer.tc(fn ->
        Tiannara.Graph.UnifiedRealityGraph.add_node(legacy_id, :information, %{
          payload_hash: payload_hash,
          source: :probe_c2_rem_001
        })
      end)

    %{
      node_id: legacy_id,
      add_node: add_res,
      add_latency_us: add_us,
      executive_memory_count: attempt.(fn -> Tiannara.CEL.Services.ExecutiveMemory.count() end),
      event_store_count: attempt.(fn -> Tiannara.CEL.Services.EventStore.count(:executive_memory) end),
      lineage_events: attempt.(fn -> Tiannara.CEL.Services.ExecutiveMemory.get_lineage(payload_hash) end),
      provenance: "Tiannara.Graph.UnifiedRealityGraph.add_node/3 -> ExecutiveMemory.record_event/4 -> EventStore.append/2",
      timestamp: now_iso.(),
      payload_hash: payload_hash
    }
  end)

# ============================================================================
# C3: Knowledge persistence (only on intact canonical chain)
# ============================================================================

c3_result =
  if canonical_ok do
    phase.(:c3_knowledge, fn ->
      store_dir = Path.join(out_dir, "knowledge")
      {:ok, store} = Tiannara.Memory.KnowledgeStore.open(store_dir)

      artifact =
        Tiannara.Memory.Artifact.new(:knowledge, payload,
          evidence: %{
            "payload_hash" => payload_hash,
            "entity_id" => entity_id,
            "source" => "probe_c2_rem_001",
            "causal_chain" => "C1->C2(canonical)->C3"
          },
          confidence: 0.9
        )

      {append_us, append_res} = :timer.tc(fn -> Tiannara.Memory.KnowledgeStore.append(store, artifact) end)
      artifacts = Tiannara.Memory.KnowledgeStore.all(store)

      %{
        knowledge_id: List.first(artifacts).id,
        artifacts_written: length(artifacts),
        append_latency_us: append_us,
        append_result: append_res,
        provenance: "Tiannara.Memory.KnowledgeStore.open/1 + append/2 + all/1",
        timestamp: now_iso.(),
        payload_hash: payload_hash
      }
    end)
  else
    %{"skipped" => true, "reason" => "canonical C2 mutation failed; no shadow state created"}
  end

# ============================================================================
# M4: Failure recovery — stop ExecutiveMemory, observe legacy + canonical behavior
# ============================================================================

failure_recovery_result =
  phase.(:failure_recovery, fn ->
    if executive_memory_up do
      {stop_us, stop_res} =
        :timer.tc(fn ->
          try do
            GenServer.stop(Tiannara.CEL.Services.ExecutiveMemory, :normal, 5_000)
            :stopped
          catch
            kind, reason -> {:error, {:stop_failed, kind, reason}}
          end
        end)

      # Legacy graph: log_mutation rescue/1 does NOT catch exits (F2) —
      # expect the graph process to die from the :noproc exit.
      legacy_after =
        attempt.(fn ->
          Tiannara.Graph.UnifiedRealityGraph.add_node(
            "post_stop_" <> Base.encode16(:crypto.strong_rand_bytes(4), case: :lower),
            :information,
            %{source: :probe_c2_rem_001, after_executive_memory_stop: true}
          )
        end)

      # Canonical graph: add_entity does not depend on ExecutiveMemory at runtime
      canonical_after =
        attempt.(fn ->
          Tiannara.World.UnifiedRealityGraph.add_entity(%{
            id: "post_stop_entity_" <> Base.encode16(:crypto.strong_rand_bytes(4), case: :lower),
            type: :event,
            payload_hash: payload_hash,
            provenance: "probe_c2_rem_001",
            status: :active
          })
        end)

      %{
        stop_result: stop_res,
        stop_latency_us: stop_us,
        legacy_graph_after_stop: legacy_after,
        canonical_graph_after_stop: canonical_after,
        interpretation: if(match?({:error, _}, legacy_after),
          do: "legacy graph: non-graceful (F2 defect confirmed)",
          else: "legacy graph: degraded gracefully"),
        timestamp: now_iso.()
      }
    else
      %{"skipped" => true, "reason" => "executive memory never came up in this mode"}
    end
  end)

# ============================================================================
# Result
# ============================================================================

result = %{
  status: "complete",
  mode: mode,
  payload_hash: payload_hash,
  canonical_ok: canonical_ok,
  executive_memory_up: executive_memory_up,
  boot: boot_result,
  phases: %{c1: c1_result, c2_canonical: c2_canonical_result, c2_legacy: c2_legacy_result, c3: c3_result},
  failure_recovery: failure_recovery_result,
  resources: %{
    memory_total_bytes: :erlang.memory(:total),
    ets_table_count: length(:ets.all()),
    dets_table_count: length(:dets.all())
  }
}

IO.puts("C2CHAIN_RESULT " <> Jason.encode!(to_jsonable.(to_jsonable, result)))