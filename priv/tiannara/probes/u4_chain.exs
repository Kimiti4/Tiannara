Mix.Task.run("app.config")

Process.flag(:trap_exit, true)

[intent_file, out_dir, forced_decision] = System.argv()

unless File.exists?(intent_file) do
  IO.puts("U4CHAIN_RESULT " <> Jason.encode!(%{status: "error", message: "intent file not found: #{intent_file}"}))
  System.halt(1)
end

File.mkdir_p!(out_dir)

intent = intent_file |> File.read!() |> Jason.decode!()
payload_hash = intent_file |> File.read!() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)

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

c3_result =
  phase.(:knowledge, fn ->
    store_dir = Path.join(out_dir, "knowledge")
    {:ok, store} = Tiannara.Memory.KnowledgeStore.open(store_dir)

    artifact =
      Tiannara.Memory.Artifact.new(:knowledge, intent,
        evidence: %{"payload_hash" => payload_hash, "source" => "probe_u4"},
        confidence: 0.9
      )

    :ok = Tiannara.Memory.KnowledgeStore.append(store, artifact)
    artifacts = Tiannara.Memory.KnowledgeStore.all(store)

    %{
      knowledge_id: List.first(artifacts).id,
      artifacts_written: length(artifacts),
      context_payload: Map.take(intent, ["objective", "constraints"]),
      provenance: "Tiannara.Memory.KnowledgeStore.open/1 + append/2 + all/1",
      timestamp: now_iso.(),
      payload_hash: payload_hash
    }
  end)

c8_result =
  phase.(:engineering, fn ->
    domains = Tiannara.World.CanonicalWorldState.domains()
    entity_types = Tiannara.World.CanonicalWorldState.domain_entity_types()
    memory_stages = Tiannara.World.CanonicalWorldState.memory_stages()
    required_fields = Tiannara.World.CanonicalWorldState.required_entity_fields()

    validation =
      attempt.(fn ->
        Tiannara.World.CanonicalWorldState.validate_entity(%{
          domain: :knowledge,
          type: "artifact",
          id: "u4_knowledge_artifact",
          confidence: 0.9,
          uncertainty: 0.1,
          provenance: "probe_u4",
          owner_subsystem: :probe_u4,
          version: 1,
          created_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now(),
          status: :active,
          payload_hash: payload_hash
        })
      end)

    %{
      world_domains: domains,
      entity_types: entity_types,
      memory_stages: memory_stages,
      required_fields: required_fields,
      entity_validation: validation,
      provenance: "Tiannara.World.CanonicalWorldState (schema)",
      timestamp: now_iso.(),
      payload_hash: payload_hash
    }
  end)

institution = TiannaraOS.Governance.ConstitutionalInstitution.define_review_board()
capability = :can_review
domain = :science

real_verdict = TiannaraOS.Governance.CapabilityChecker.authorize?(institution, capability, domain)
real_deny_sample = TiannaraOS.Governance.CapabilityChecker.authorize?(institution, :can_deploy, :migration)

decision =
  case forced_decision do
    "ALLOW" -> "ALLOW"
    "DENY" -> "DENY"
    _ -> if real_verdict == :ok, do: "ALLOW", else: "DENY"
  end

injected = forced_decision in ["ALLOW", "DENY"]

decision_hash =
  %{
    "decision" => decision,
    "capability" => Atom.to_string(capability),
    "domain" => Atom.to_string(domain),
    "rule_consulted" => "TiannaraOS.Governance.CapabilityChecker.authorize?/3",
    "institution" => institution.name
  }
  |> Jason.encode!()
  |> then(&:crypto.hash(:sha256, &1))
  |> Base.encode16(case: :lower)

c14_result =
  phase.(:governance, fn ->
    %{
      decision: decision,
      real_verdict: real_verdict,
      real_deny_sample: real_deny_sample,
      injected: injected,
      capability: capability,
      domain: domain,
      institution: institution.name,
      rule_consulted: "TiannaraOS.Governance.CapabilityChecker.authorize?/3 (Review Board, :can_review @ :science)",
      decision_hash: decision_hash,
      timestamp: now_iso.(),
      payload_hash: payload_hash
    }
  end)

c9_result =
  phase.(:asc, fn ->
    project_id = "u4_" <> Base.encode16(:crypto.strong_rand_bytes(8), case: :lower)
    project_world = %Tiannara.ASC.ProjectWorld{}
    plan = Tiannara.ASC.Implementation.Planner.generate_plan(project_world, project_id)

    allowed = decision == "ALLOW"

    candidate_hash =
      %{
        "plan" => Map.from_struct(plan) |> Map.drop([:created_at]),
        "governance_decision_ref" => decision_hash
      }
      |> Jason.encode!()
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)

    %{
      candidate_id: project_id,
      governance_decision_ref: decision_hash,
      candidate_hash: candidate_hash,
      is_eligible: allowed,
      executable: allowed,
      adoptable: allowed,
      architecture_style: plan.architecture_style,
      complexity_score: plan.complexity_score,
      confidence: plan.confidence,
      components: length(plan.components),
      provenance: "Tiannara.ASC.Implementation.Planner.generate_plan/2",
      timestamp: now_iso.(),
      payload_hash: payload_hash
    }
  end)

result = %{
  status: "complete",
  payload_hash: payload_hash,
  forced_decision: forced_decision,
  phases: %{c3: c3_result, c8: c8_result, c14: c14_result, c9: c9_result}
}

IO.puts("U4CHAIN_RESULT " <> Jason.encode!(to_jsonable.(to_jsonable, result)))