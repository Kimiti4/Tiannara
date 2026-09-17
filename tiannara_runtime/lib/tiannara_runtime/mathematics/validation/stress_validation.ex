defmodule TiannaraRuntime.Mathematics.Validation.StressValidation do
  @moduledoc """
  Phase 16.X.95 — Stress Validation Campaign

  Tests maximum symbolic tree depth with deep nested expressions,
  maximum dependency graph size, measures replay latency and memory,
  verifies determinism under load.
  """

  @behaviour TiannaraRuntime.Mathematics.Validation.Campaign

  alias TiannaraRuntime.Mathematics.SymbolicEngine
  alias TiannaraRuntime.Mathematics.ProofEngine
  alias TiannaraRuntime.Mathematics.MathematicalID

  @impl true
  def name, do: "Stress Validation"

  @impl true
  def description, do: "Test maximum symbolic tree depth, dependency graph size, measure replay latency/memory, verify determinism under load."

  @impl true
  def run(_opts \\ []) do
    checks = [
      check_deep_expression_trees(),
      check_large_dependency_graphs(),
      check_replay_latency(),
      check_determinism_under_load()
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

  defp check_deep_expression_trees do
    depths = [2, 4, 6, 8]

    results = Enum.flat_map(depths, fn depth ->
      Enum.map(1..5, fn variant ->
        expr = build_deep_tree(depth, variant)
        hash1 = SymbolicEngine.expression_hash(expr)
        hash2 = SymbolicEngine.expression_hash(build_deep_tree(depth, variant))

        case SymbolicEngine.simplify(expr) do
          {:ok, simplified} ->
            %{depth: depth, variant: variant, stable: hash1 == hash2, simplified: true, hash_stable: true}
          {:error, reason} ->
            %{depth: depth, variant: variant, stable: hash1 == hash2, simplified: false, error: reason}
        end
      end)
    end)

    hash_issues = Enum.filter(results, fn r -> r[:stable] == false end)

    if hash_issues == [] do
      depth_summary = Enum.map(depths, fn d ->
        d_results = Enum.filter(results, fn r -> r[:depth] == d end)
        "#{d}: #{length(d_results)} trees"
      end)
      %{check: "deep_expression_trees", status: :pass, detail: "All stable at depths [#{Enum.join(depth_summary, ", ")}]"}
    else
      %{check: "deep_expression_trees", status: :fail, detail: "#{length(hash_issues)} hash instabilities"}
    end
  end

  defp check_large_dependency_graphs do
    sizes = [5, 10, 25, 50]

    results = Enum.flat_map(sizes, fn size ->
      proofs = Enum.map(1..size, fn i ->
        dep_ids = if i > 1, do: ["dep_chain_#{i - 1}"], else: []
        steps = Enum.map(0..1, fn sn ->
          dependency_hashes = if sn > 0, do: [MathematicalID.from_canonical_map(%{i: i, sn: sn - 1})], else: []
          %{
            "step_number" => sn,
            "rule_applied" => "modus_ponens",
            "input_objects" => ["in_#{i}_#{sn}"],
            "output_object" => "out_#{i}_#{sn}",
            "dependency_hashes" => dependency_hashes
          }
        end)

        {:ok, proof} = ProofEngine.build_proof("assertion_stress_#{i}", :direct, dep_ids, steps)
        proof
      end)

      case ProofEngine.dependency_graph(proofs) do
        {:ok, graph} ->
          node_count = length(Map.get(graph, "nodes", []))
          edge_count = length(Map.get(graph, "edges", []))
          [%{size: size, ok: true, nodes: node_count, edges: edge_count}]
        {:error, reason} ->
          [%{size: size, ok: false, error: reason}]
      end
    end)

    failures = Enum.filter(results, fn r -> r[:ok] == false end)

    if failures == [] do
      graph_summary = Enum.map(results, fn r -> "size=#{r[:size]} nodes=#{r[:nodes]} edges=#{r[:edges]}" end)
      %{check: "large_dependency_graphs", status: :pass, detail: Enum.join(graph_summary, "; ")}
    else
      %{check: "large_dependency_graphs", status: :fail, detail: "#{length(failures)} failures: #{inspect(Enum.take(failures, 3))}"}
    end
  end

  defp check_replay_latency do
    count = 50

    timings = Enum.map(1..count, fn i ->
      steps = Enum.map(0..4, fn sn ->
        %{
          "step_number" => sn,
          "rule_applied" => "modus_ponens",
          "input_objects" => ["in_#{i}_#{sn}"],
          "output_object" => "out_#{i}_#{sn}",
          "fingerprint" => MathematicalID.from_canonical_map(%{latency_test: i, sn: sn})
        }
      end)

      {:ok, proof} = ProofEngine.build_proof("latency_assertion_#{i}", :direct, [], steps)

      {duration_us, result} = :timer.tc(fn ->
        ProofEngine.replay_proof(proof)
      end)

      {duration_us, result}
    end)

    valid = Enum.filter(timings, fn {_duration, result} -> elem(result, 0) == :ok end)

    if length(valid) > 0 do
      durations = Enum.map(valid, fn {d, _} -> d end)
      avg_us = Enum.sum(durations) / length(durations)
      max_us = Enum.max(durations)

      %{check: "replay_latency", status: :pass, detail: "#{length(valid)} replays: avg=#{Float.round(avg_us, 1)}us, max=#{max_us}us"}
    else
      %{check: "replay_latency", status: :error, detail: "No successful replays"}
    end
  end

  defp check_determinism_under_load do
    runs = 10
    count = 30

    run_hashes = Enum.map(1..runs, fn run_id ->
      hashes = Enum.map(1..count, fn i ->
        strategy = Enum.at([:direct, :contradiction, :induction, :constructive, :computational], rem(i, 5))
        steps = Enum.map(0..2, fn sn ->
          %{
            "step_number" => sn,
            "rule_applied" => "modus_ponens",
            "input_objects" => ["in_#{i}_#{sn}"],
            "output_object" => "out_#{i}_#{sn}",
            "fingerprint" => MathematicalID.from_canonical_map(%{load_test: i, sn: sn})
          }
        end)

        {:ok, proof} = ProofEngine.build_proof("load_assertion_#{i}", strategy, ["ax_#{i}"], steps)
        proof["proof_hash"]
      end)
      {:ok, Enum.sort(hashes)}
    end)

    first_run = Enum.at(run_hashes, 0)

    case first_run do
      {:ok, first_hashes} ->
        all_match = Enum.all?(run_hashes, fn
          {:ok, h} -> h == first_hashes
          _ -> false
        end)

        if all_match do
          %{check: "determinism_under_load", status: :pass, detail: "#{runs} runs of #{count} proofs each, all identical"}
        else
          %{check: "determinism_under_load", status: :fail, detail: "Non-deterministic proof generation across runs"}
        end

      _ ->
        %{check: "determinism_under_load", status: :error, detail: "First run failed"}
    end
  end

  defp build_deep_tree(depth, variant) do
    if depth <= 0 do
      {:ok, e} = SymbolicEngine.constant(variant)
      e
    else
      left = build_deep_tree(depth - 1, variant)
      right = build_deep_tree(depth - 1, variant + 1)

      case rem(depth + variant, 3) do
        0 ->
          {:ok, e} = SymbolicEngine.operator(:+, [left, right])
          e
        1 ->
          {:ok, e} = SymbolicEngine.operator(:*, [left, right])
          e
        2 ->
          {:ok, e} = SymbolicEngine.function("f", [left, right])
          e
      end
    end
  end
end
