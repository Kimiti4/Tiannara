alias TiannaraRuntime.Mathematics.{MathematicalID, SymbolicEngine, ProofEngine, MathematicsKnowledgeGraph}

defmodule ArtifactProducer do
  def produce do
    MathematicsKnowledgeGraph.init_tables()
    hash_inputs = collect_hash_inputs(100)
    proof_samples = collect_proof_samples(50)
    graph_nodes = collect_graph_nodes(20)
    runtime_inputs = collect_runtime_inputs(50)

    data = %{
      metadata: %{
        generated_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        type: :constitutional_audit_artifacts,
        version: "1.0"
      },
      hash_samples: hash_inputs,
      proof_samples: proof_samples,
      graph_samples: graph_nodes,
      runtime_samples: runtime_inputs
    }

    path = Path.join(__DIR__, "artifact_data.term")
    File.write!(path, :erlang.term_to_binary(data))
    IO.puts("Artifacts written to #{path} (#{byte_size(File.read!(path))} bytes)")
  end

  defp collect_hash_inputs(count) do
    Enum.map(1..count, fn i ->
      input = case rem(i, 5) do
        0 -> %{"type" => "constant", "value" => i, "children" => []}
        1 -> %{"type" => "variable", "value" => "x_#{i}", "children" => []}
        2 -> %{"operator" => :+, "operands" => [%{"const" => i}, %{"var" => "y"}]}
        3 -> %{"z" => i, "a" => "nested_#{i}", "inner" => %{"b" => true, "a" => [1, 2, 3]}}
        4 -> %{"empty_map" => %{}, "empty_list" => [], "string" => "hello_#{i}", "num" => i * 1.5}
      end
      expected = MathematicalID.from_canonical_map(input)
      %{sample_id: i, input: input, expected_hash: expected}
    end)
  end

  defp collect_proof_samples(count) do
    strategies = [:direct, :contradiction, :induction, :constructive, :computational]
    Enum.map(1..count, fn i ->
      strategy = Enum.at(strategies, rem(i, length(strategies)))
      steps = Enum.map(0..2, fn sn ->
        %{
          "step_number" => sn,
          "rule_applied" => "modus_ponens",
          "input_objects" => ["in_#{i}_#{sn}"],
          "output_object" => "out_#{i}_#{sn}"
        }
      end)
      case ProofEngine.build_proof("audit_assertion_#{i}", strategy, ["ax_#{i}"], steps) do
        {:ok, proof} ->
          proof_summary = %{
            proof_id: Map.get(proof, "proof_id"),
            assertion_id: Map.get(proof, "assertion_id"),
            strategy: Map.get(proof, "strategy"),
            assumptions: Map.get(proof, "assumptions", []),
            steps: Enum.map(Map.get(proof, "steps", []), fn s ->
              %{
                step_number: Map.get(s, "step_number"),
                rule_applied: Map.get(s, "rule_applied"),
                input_objects: Map.get(s, "input_objects", []),
                output_object: Map.get(s, "output_object", ""),
                dependency_hashes: Map.get(s, "dependency_hashes", [])
              }
            end),
            dependencies: Map.get(proof, "dependencies", []),
            verification_status: Map.get(proof, "verification_status")
          }
          expected = ProofEngine.fingerprint(proof)
          %{sample_id: i, proof_summary: proof_summary, expected_fingerprint: expected}
        {:error, reason} ->
          %{sample_id: i, proof_summary: nil, error: reason, expected_fingerprint: nil}
      end
    end)
  end

  defp collect_graph_nodes(count) do
    types = MathematicsKnowledgeGraph.valid_node_types()
    Enum.map(1..count, fn i ->
      t = Enum.at(types, rem(i, length(types)))
      case MathematicsKnowledgeGraph.add_node(t, %{"owner" => "audit", "seq" => i}) do
        {:ok, nid} -> %{node_id: nid, node_type: t, owner: "audit", seq: i}
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp collect_runtime_inputs(count) do
    Enum.map(1..count, fn i ->
      case SymbolicEngine.constant(i) do
        {:ok, expr} ->
          expected = SymbolicEngine.expression_hash(expr)
          %{sample_id: i, expression: strip_structs(expr), expected_hash: expected}
        _ ->
          %{sample_id: i, expression: nil, error: "failed to create constant", expected_hash: nil}
      end
    end)
  end

  defp strip_structs(term) when is_map(term) do
    term |> Map.drop([:__struct__]) |> Enum.map(fn {k, v} -> {k, strip_structs(v)} end) |> Enum.into(%{})
  end
  defp strip_structs(term) when is_list(term), do: Enum.map(term, &strip_structs/1)
  defp strip_structs(term), do: term
end

ArtifactProducer.produce()
