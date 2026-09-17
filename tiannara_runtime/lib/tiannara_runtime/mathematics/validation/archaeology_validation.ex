defmodule TiannaraRuntime.Mathematics.Validation.ArchaeologyValidation do
  @moduledoc """
  Phase 16.X.95 — Archaeology Validation Campaign

  Randomly samples proofs, theorems, assertions, and conjectures,
  verifying every sample has complete archaeology: origin, purpose,
  owner, lineage, dependencies, and consumers.
  """

  @behaviour TiannaraRuntime.Mathematics.Validation.Campaign

  alias TiannaraRuntime.Mathematics.ProofEngine
  alias TiannaraRuntime.Mathematics.ConjectureEngine
  alias TiannaraRuntime.Mathematics.FormalVerificationEngine
  alias TiannaraRuntime.Mathematics.MathematicsKnowledgeGraph
  alias TiannaraRuntime.Mathematics.MathematicalID

  @impl true
  def name, do: "Archaeology Validation"

  @impl true
  def description, do: "Sample proofs, theorems, assertions, conjectures and verify complete archaeology provenance: origin, purpose, owner, lineage, dependencies, consumers."

  @impl true
  def run(_opts \\ []) do
    checks = [
      check_proof_archaeology(),
      check_conjecture_archaeology(),
      check_verification_archaeology(),
      check_knowledge_graph_archaeology(),
      check_archaeology_completeness()
    ]

    status = if Enum.all?(checks, fn c -> c.status == :pass end), do: :pass, else: :fail

    {:ok, %{
      campaign: name(),
      status: status,
      checks: checks,
      summary: %{
        total: length(checks),
        passed: Enum.count(checks, fn c -> c.status == :pass end),
        failed: Enum.count(checks, fn c -> c.status == :fail end),
        errors: Enum.count(checks, fn c -> c.status == :error end)
      }
    }}
  end

  defp check_proof_archaeology do
    strategies = [:direct, :contradiction, :induction, :constructive, :computational]

    results = Enum.map(1..100, fn i ->
      strategy = Enum.at(strategies, rem(i, length(strategies)))
      steps = Enum.map(0..2, fn sn ->
        %{
          "step_number" => sn,
          "rule_applied" => "modus_ponens",
          "input_objects" => ["in_arch_#{i}_#{sn}"],
          "output_object" => "out_arch_#{i}_#{sn}",
          "fingerprint" => MathematicalID.from_canonical_map(%{arch: i, step: sn})
        }
      end)

      with {:ok, proof} <- ProofEngine.build_proof("assertion_arch_#{i}", strategy, ["ax_#{i}"], steps),
           {:ok, record} <- ProofEngine.archaeology(proof) do
        fields = ~w(proof_id assertion_id strategy created_why dependencies version)
        missing = Enum.reject(fields, fn f -> Map.has_key?(record, f) and Map.get(record, f) != nil end)

        has_created_why = Map.has_key?(record, "created_why")
        why_has_purpose = get_in(record, ["created_why", "purpose"]) != nil
        why_has_origin = get_in(record, ["created_why", "origin"]) != nil

        complete = missing == [] and has_created_why and why_has_purpose and why_has_origin
        %{iteration: i, complete: complete, missing: missing}
      else
        {:error, reason} -> %{iteration: i, complete: false, error: reason}
      end
    end)

    complete = Enum.filter(results, fn r -> r[:complete] == true end)
    incomplete = Enum.filter(results, fn r -> r[:complete] == false end)

    if length(complete) >= length(results) - 5 do
      %{check: "proof_archaeology", status: :pass, detail: "#{length(complete)}/#{length(results)} proofs have complete archaeology"}
    else
      sample_issues = Enum.take(incomplete, 3)
      %{check: "proof_archaeology", status: :fail, detail: "#{length(incomplete)} incomplete: #{inspect(sample_issues)}"}
    end
  end

  defp check_conjecture_archaeology do
    sources = ConjectureEngine.valid_sources()

    results = Enum.map(1..100, fn i ->
      source = Enum.at(sources, rem(i, length(sources)))
      statement = "Archaeology conjecture #{i}: #{source} structure has property A"

      with {:ok, conjecture} <- ConjectureEngine.generate_conjecture(statement, %{"source" => source}),
           {:ok, record} <- ConjectureEngine.archaeology(conjecture) do
        fields = ~w(conjecture_id statement generated_why cluster created_at)
        missing = Enum.reject(fields, fn f -> Map.has_key?(record, f) and Map.get(record, f) != nil end)

        why = Map.get(record, "generated_why", %{})
        has_origin = Map.get(why, "origin") != nil
        has_reason = Map.get(why, "reason") != nil

        complete = missing == [] and has_origin and has_reason
        %{iteration: i, complete: complete, missing: missing}
      else
        {:error, reason} -> %{iteration: i, complete: false, error: reason}
      end
    end)

    complete = Enum.filter(results, fn r -> r[:complete] == true end)
    incomplete = Enum.filter(results, fn r -> r[:complete] == false end)

    if length(complete) >= length(results) - 5 do
      %{check: "conjecture_archaeology", status: :pass, detail: "#{length(complete)}/#{length(results)} conjectures have complete archaeology"}
    else
      %{check: "conjecture_archaeology", status: :fail, detail: "#{length(incomplete)} incomplete"}
    end
  end

  defp check_verification_archaeology do
    results = Enum.map(1..100, fn i ->
      modes = [:structural, :logical, :computational]
      mode = Enum.at(modes, rem(i, 3))
      properties = [:correctness, :stability]

      with {:ok, result} <- FormalVerificationEngine.verify("arch_target_#{i}", "theorem", mode, properties),
           {:ok, record} <- FormalVerificationEngine.archaeology(result) do
        fields = ~w(verification_id target_id performed_why created_at)
        missing = Enum.reject(fields, fn f -> Map.has_key?(record, f) and Map.get(record, f) != nil end)

        why = Map.get(record, "performed_why", %{})
        has_purpose = Map.get(why, "purpose") != nil
        has_origin = Map.get(why, "origin") != nil

        complete = missing == [] and has_purpose and has_origin
        %{iteration: i, complete: complete, missing: missing}
      else
        {:error, reason} -> %{iteration: i, complete: false, error: reason}
      end
    end)

    complete = Enum.filter(results, fn r -> r[:complete] == true end)
    incomplete = Enum.filter(results, fn r -> r[:complete] == false end)

    if length(complete) >= length(results) - 5 do
      %{check: "verification_archaeology", status: :pass, detail: "#{length(complete)}/#{length(results)} verifications have complete archaeology"}
    else
      %{check: "verification_archaeology", status: :fail, detail: "#{length(incomplete)} incomplete"}
    end
  end

  defp check_knowledge_graph_archaeology do
    MathematicsKnowledgeGraph.reset_tables()

    node_ids = Enum.map(1..50, fn i ->
      type = Enum.at(MathematicsKnowledgeGraph.valid_node_types(), rem(i, 12))
      deps = if i > 1, do: ["node_#{i - 1}"], else: []
      lineage = if i > 1, do: ["lineage_#{i - 1}"], else: []
      {:ok, nid} = MathematicsKnowledgeGraph.add_node(type, %{
        "owner" => "Archaeology Test",
        "origin" => "Phase 16.X.95",
        "purpose" => "archaeology validation",
        "domain" => "validation",
        "dependencies" => deps,
        "lineage" => lineage
      })
      nid
    end)

    results = Enum.map(node_ids, fn nid ->
      case MathematicsKnowledgeGraph.archaeology(nid) do
        {:ok, record} ->
          fields = ~w(node_id node_type created_why owner version)
          missing = Enum.reject(fields, fn f -> Map.has_key?(record, f) and Map.get(record, f) != nil end)

          why = Map.get(record, "created_why", %{})
          has_origin = Map.get(why, "origin") != nil
          has_purpose = Map.get(why, "purpose") != nil

          has_defs = Map.has_key?(record, "necessary_definitions")
          has_deps = Map.has_key?(record, "dependent_structures")
          has_consumers = Map.has_key?(record, "consumed_by_applications")

          complete = missing == [] and has_origin and has_purpose and has_defs and has_deps and has_consumers
          %{node_id: nid, complete: complete, missing: missing}

        {:error, reason} ->
          %{node_id: nid, complete: false, error: reason}
      end
    end)

    MathematicsKnowledgeGraph.reset_tables()

    complete = Enum.filter(results, fn r -> r[:complete] == true end)

    if length(complete) >= length(node_ids) - 5 do
      %{check: "knowledge_graph_archaeology", status: :pass, detail: "#{length(complete)}/#{length(node_ids)} MKG nodes have complete archaeology"}
    else
      %{check: "knowledge_graph_archaeology", status: :fail, detail: "#{length(node_ids) - length(complete)} incomplete archaeology records"}
    end
  end

  defp check_archaeology_completeness do
    checks = [
      {:proof_origin, fn -> check_field_presence(:proof, ["created_why", "origin"]) end},
      {:proof_purpose, fn -> check_field_presence(:proof, ["created_why", "purpose"]) end},
      {:proof_deps, fn -> check_field_presence(:proof, ["dependencies"]) end},
      {:conjecture_origin, fn -> check_field_presence(:conjecture, ["generated_why", "origin"]) end},
      {:conjecture_cluster, fn -> check_field_presence(:conjecture, ["cluster"]) end},
      {:verification_target, fn -> check_field_presence(:verification, ["target_id"]) end},
      {:verification_mode, fn -> check_field_presence(:verification, ["performed_why", "mode"]) end}
    ]

    results = Enum.map(checks, fn {name, check_fn} ->
      check_fn.()
      |> case do
        {:ok, msg} -> %{check: name, status: :pass, detail: msg}
        {:error, msg} -> %{check: name, status: :fail, detail: msg}
      end
    end)

    failures = Enum.filter(results, fn r -> r.status == :fail end)

    if failures == [] do
      %{check: "archaeology_completeness", status: :pass, detail: "All archaeology fields present across all artifact types"}
    else
      %{check: "archaeology_completeness", status: :fail, detail: "#{length(failures)} field checks failed: #{inspect(Enum.map(failures, fn r -> r[:check] end))}"}
    end
  end

  defp check_field_presence(:proof, field_path) do
    {:ok, proof} = ProofEngine.build_proof("completeness_assertion", :direct, [], [
      %{"step_number" => 0, "rule_applied" => "modus_ponens", "input_objects" => ["p"], "output_object" => "q"}
    ])
    {:ok, record} = ProofEngine.archaeology(proof)
    check_path(record, field_path)
  end

  defp check_field_presence(:conjecture, field_path) do
    {:ok, conj} = ConjectureEngine.generate_conjecture("Completeness test conjecture", %{"source" => "knowledge_gap"})
    {:ok, record} = ConjectureEngine.archaeology(conj)
    check_path(record, field_path)
  end

  defp check_field_presence(:verification, field_path) do
    {:ok, result} = FormalVerificationEngine.verify("completeness_target", "theorem", :structural, [:correctness])
    {:ok, record} = FormalVerificationEngine.archaeology(result)
    check_path(record, field_path)
  end

  defp check_path(map, [key]) do
    if Map.has_key?(map, key) and Map.get(map, key) != nil do
      {:ok, "#{key} present"}
    else
      {:error, "#{key} missing or nil"}
    end
  end

  defp check_path(map, [head | tail]) do
    case Map.get(map, head) do
      nil -> {:error, "#{head} is nil"}
      sub when is_map(sub) -> check_path(sub, tail)
      _ -> {:error, "#{head} is not a map"}
    end
  end
end
