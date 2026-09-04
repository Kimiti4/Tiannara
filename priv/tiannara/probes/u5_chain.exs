Mix.Task.run("app.config")

Process.flag(:trap_exit, true)

[payload_file, signature, out_dir] = System.argv()

unless File.exists?(payload_file) do
  IO.puts("U5CHAIN_RESULT " <> Jason.encode!(%{status: "error", message: "payload file not found: #{payload_file}"}))
  System.halt(1)
end

File.mkdir_p!(out_dir)

payload_bytes = File.read!(payload_file)
payload_hash = :crypto.hash(:sha256, payload_bytes) |> Base.encode16(case: :lower)
signature_verified = payload_hash == signature

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
    other -> other
  end
end

# ============================================================================
# C11: External Reality Boundary (INGRESS ONLY — read + verify, never write)
# ============================================================================

c11_result =
  phase.(:c11_ingress, fn ->
    external_event =
      payload_bytes
      |> Jason.decode!()
      |> then(fn ev -> Map.put(ev, "external_received_at", now_iso.()) end)

    governance_consult =
      attempt.(fn ->
        institution = TiannaraOS.Governance.ConstitutionalInstitution.define_observatory()
        TiannaraOS.Governance.CapabilityChecker.authorize?(institution, :can_observe, :observability)
      end)

    %{
      external_source: Path.basename(payload_file),
      payload_hash: payload_hash,
      signature: signature,
      signature_verified: signature_verified,
      governance_consult: governance_consult,
      governance_institution: "Observatory (:can_observe @ :observability)",
      provenance: "filesystem ingress + sha256 signature verification (read-only; no external writes)",
      timestamp: now_iso.(),
      event_keys: external_event |> Map.keys() |> Enum.sort()
    }
  end)

# ============================================================================
# C1: Perception / Ingestion
# ============================================================================

c1_result =
  if signature_verified do
    phase.(:c1_perception, fn ->
      external_event =
        payload_bytes
        |> Jason.decode!()

      shaped_event = %{
        id: "ext-" <> Base.encode16(:crypto.strong_rand_bytes(8), case: :lower),
        timestamp: now_iso.(),
        source: :external_reality,
        category: :runtime,
        severity: :info,
        observation: Jason.encode!(external_event),
        evidence: [payload_hash],
        causal_links: [%{trace_id: "c11_ingress", phase: "c11_ingress"}],
        metadata: %{"payload_hash" => payload_hash, "external_source" => Path.basename(payload_file)}
      }

      event = Tiannara.Sentinel.Activation.Event.new(shaped_event)
      engine = attempt.(fn -> Tiannara.Sentinel.Activation.Engine.process(shaped_event) end)

      %{
        event_id: event.id,
        event_source: event.source,
        event_category: event.category,
        event_severity: event.severity,
        engine: engine,
        provenance: "Tiannara.Sentinel.Activation.Event.new/1 + Engine.process/1",
        timestamp: now_iso.(),
        payload_hash: payload_hash
      }
    end)
  else
    %{"skipped" => true, "reason" => "rejected at C11 ingress (signature not verified)"}
  end

# ============================================================================
# C2: Unified Reality Graph (attempt; known deferred dependency)
# ============================================================================

c2_result =
  if signature_verified do
    phase.(:c2_reality_model, fn ->
      entity_id = "ext_entity_" <> Base.encode16(:crypto.strong_rand_bytes(6), case: :lower)

      # MUST attempt. If ExecutiveMemory :noproc surfaces, it is recorded as a
      # causal break — never masked.
      add =
        attempt.(fn ->
          Tiannara.Graph.UnifiedRealityGraph.add_node(
            %{id: entity_id, name: "external_reality_event"},
            :information,
            %{payload_hash: payload_hash, source: :probe_u5}
          )
        end)

      %{
        entity_id: entity_id,
        add_node: add,
        provenance: "Tiannara.Graph.UnifiedRealityGraph.add_node/3",
        timestamp: now_iso.(),
        payload_hash: payload_hash
      }
    end)
  else
    %{"skipped" => true, "reason" => "rejected at C11 ingress (signature not verified)"}
  end

c2_ok =
  case c2_result do
    %{"ok" => %{"add_node" => %{"ok" => _}}} -> true
    _ -> false
  end

# ============================================================================
# C3: Knowledge (only if the causal chain is intact)
# ============================================================================

c3_result =
  cond do
    not signature_verified ->
      %{"skipped" => true, "reason" => "rejected at C11 ingress (signature not verified)"}

    not c2_ok ->
      %{"skipped" => true, "reason" => "causal chain broken at C1->C2 (C2 deferred); cannot accept state without canonical reality model"}

    true ->
      phase.(:c3_knowledge, fn ->
        store_dir = Path.join(out_dir, "knowledge")
        {:ok, store} = Tiannara.Memory.KnowledgeStore.open(store_dir)

        artifact =
          Tiannara.Memory.Artifact.new(:knowledge, %{"external_event" => payload_bytes |> Jason.decode!()},
            evidence: %{"payload_hash" => payload_hash, "source" => "probe_u5", "causal_chain" => "C11->C1->C2->C3"},
            confidence: 0.9
          )

        :ok = Tiannara.Memory.KnowledgeStore.append(store, artifact)
        artifacts = Tiannara.Memory.KnowledgeStore.all(store)

        %{
          knowledge_id: List.first(artifacts).id,
          artifacts_written: length(artifacts),
          provenance: "Tiannara.Memory.KnowledgeStore.open/1 + append/2 + all/1",
          timestamp: now_iso.(),
          payload_hash: payload_hash
        }
      end)
  end

result = %{
  status: "complete",
  payload_hash: payload_hash,
  signature: signature,
  signature_verified: signature_verified,
  causal_break: signature_verified and not c2_ok,
  phases: %{c11: c11_result, c1: c1_result, c2: c2_result, c3: c3_result}
}

IO.puts("U5CHAIN_RESULT " <> Jason.encode!(to_jsonable.(to_jsonable, result)))