Mix.Task.run("app.config")

Process.flag(:trap_exit, true)

[obs_file, out_dir] = System.argv()

unless File.exists?(obs_file) do
  IO.puts("U1CHAIN_RESULT " <> Jason.encode!(%{status: "error", message: "observation file not found: #{obs_file}"}))
  System.halt(1)
end

File.mkdir_p!(out_dir)

observation = obs_file |> File.read!() |> Jason.decode!()
entity_id = Map.get(observation, "entity_id", "repo_tiannara")
payload_hash = obs_file |> File.read!() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)

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

flush_exits = fn flush_exits ->
  receive do
    {:EXIT, _pid, _reason} -> flush_exits.(flush_exits)
  after
    0 -> :ok
  end
end

to_jsonable = fn to_jsonable, term ->
  case term do
    {:ok, v} -> %{"ok" => to_jsonable.(to_jsonable, v)}
    {:error, m} -> %{"error" => to_jsonable.(to_jsonable, m)}
    %{__struct__: _} = s -> to_jsonable.(to_jsonable, Map.from_struct(s))
    list when is_list(list) -> Enum.map(list, &to_jsonable.(to_jsonable, &1))
    map when is_map(map) -> Map.new(map, fn {k, v} -> {to_string(k), to_jsonable.(to_jsonable, v)} end)
    other -> other
  end
end

c1_result =
  phase.(:perception, fn ->
    raw_event =
      attempt.(fn ->
        event = Tiannara.Sentinel.Activation.Event.new(observation)
        %{event_id: if(is_struct(event), do: Map.get(Map.from_struct(event), :id, nil), else: nil)}
      end)

    shaped_event = %{
      id: "u1_" <> Base.encode16(:crypto.strong_rand_bytes(8), case: :lower),
      timestamp: DateTime.utc_now(),
      source: :probe_u1,
      category: :runtime,
      severity: :info,
      observation: Jason.encode!(observation),
      evidence: [],
      causal_links: [],
      metadata: %{payload_hash: payload_hash}
    }

    shaped =
      attempt.(fn ->
        event = Tiannara.Sentinel.Activation.Event.new(shaped_event)
        %{event_id: Map.get(Map.from_struct(event), :id, nil), category: event.category}
      end)

    pipeline =
      attempt.(fn ->
        Tiannara.Sentinel.Activation.Engine.process(shaped_event)
        |> inspect(limit: 30)
      end)

    %{
      raw_json_observation: raw_event,
      shaped_event_contract: shaped,
      pipeline: pipeline,
      payload_hash: payload_hash
    }
  end)

c2_result =
  phase.(:reality_model, fn ->
    case Process.whereis(Tiannara.Graph.UnifiedRealityGraph) do
      nil -> attempt.(fn -> Tiannara.Graph.UnifiedRealityGraph.start_link([]) end)
      _ -> {:already_running, :ok}
    end

    add_node =
      attempt.(fn ->
        {:ok, ^entity_id} =
          Tiannara.Graph.UnifiedRealityGraph.add_node(entity_id, :information, %{
            type: Map.get(observation, "type", "external_observation"),
            payload_hash: payload_hash,
            source: :probe_u1,
            observed_at: Map.get(observation, "timestamp", nil),
            data: Map.get(observation, "data", %{})
          })

        entity_id
      end)

    flush_exits.(flush_exits)

    read_back = attempt.(fn -> Tiannara.Graph.UnifiedRealityGraph.get_node_with_context(entity_id) end)
    stats = attempt.(fn -> Tiannara.Graph.UnifiedRealityGraph.stats() end)

    shadow =
      attempt.(fn ->
        {:ok, Tiannara.World.UnifiedWorldModel.get_entity(entity_id)}
      end)

    %{
      add_node: add_node,
      read_back: read_back,
      graph_stats: stats,
      shadow_world_model: shadow,
      payload_hash: payload_hash
    }
  end)

c3_result =
  phase.(:knowledge, fn ->
    store_dir = Path.join(out_dir, "knowledge")
    {:ok, store} = Tiannara.Memory.KnowledgeStore.open(store_dir)

    artifact =
      Tiannara.Memory.Artifact.new(:knowledge, observation,
        evidence: %{"payload_hash" => payload_hash, "source" => "probe_u1", "trace_phase" => "u1"},
        lineage: [entity_id],
        confidence: 0.95
      )

    :ok = Tiannara.Memory.KnowledgeStore.append(store, artifact)
    artifacts = Tiannara.Memory.KnowledgeStore.all(store)

    %{
      artifacts_written: length(artifacts),
      artifact_ids: Enum.map(artifacts, & &1.id),
      store_dir: store_dir,
      payload_hash: payload_hash
    }
  end)

c4_result =
  phase.(:epistemic, fn ->
    node = %Tiannara.Epistemic.Node{
      id: "u1_#{entity_id}",
      stage: :knowledge,
      content: observation,
      timestamp: DateTime.utc_now(),
      confidence: 0.95,
      responsible_subsystem: :probe_u1,
      disposition: :provisional,
      lineage: [entity_id],
      assumptions: ["synthetic_observation_is_valid"],
      unknowns: ["external_verification_pending"],
      contradictions: [],
      constitutional_checks: [:explainability, :observability]
    }

    rendered = Tiannara.Epistemic.View.render_node(node)

    %{
      node_stage: node.stage,
      confidence: node.confidence,
      assumptions: node.assumptions,
      unknowns: node.unknowns,
      rendered_provenance: rendered,
      payload_hash: payload_hash
    }
  end)

c7_result =
  phase.(:lineage, fn ->
    lineage_path = Path.join(out_dir, "u1_lineage.etf")

    entries =
      Enum.reduce(
        [:perception, :reality_model, :knowledge, :epistemic],
        {[], Tiannara.Lineage.Entry.genesis_hash()},
        fn lineage_type, {acc, parent_hash} ->
          entry = Tiannara.Lineage.Entry.new(%{"phase" => Atom.to_string(lineage_type), "payload_hash" => payload_hash}, lineage_type, parent_hash)
          {[entry | acc], entry.entry_hash}
        end
      )
      |> elem(0)
      |> Enum.reverse()

    Enum.each(entries, &Tiannara.Lineage.Store.persist(&1, lineage_path))
    {:ok, loaded} = Tiannara.Lineage.Store.reconstruct(lineage_path)
    chain_verified = match?(:ok, Tiannara.Lineage.Store.verify_chain(loaded))

    %{
      entries_persisted: length(entries),
      chain_verified: chain_verified,
      head_hash: Tiannara.Lineage.Store.head_hash(loaded),
      lineage_path: lineage_path,
      payload_hash: payload_hash
    }
  end)

result = %{
  status: "complete",
  payload_hash: payload_hash,
  entity_id: entity_id,
  phases: %{
    c1: c1_result,
    c2: c2_result,
    c3: c3_result,
    c4: c4_result,
    c7: c7_result
  }
}

IO.puts("U1CHAIN_RESULT " <> Jason.encode!(to_jsonable.(to_jsonable, result)))