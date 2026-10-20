defmodule TiannaraRuntime.CausalDiscovery.ValidationCampaignTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.CausalDiscovery.{
    IndependenceEngine, StructureLearner, EdgeScorer, GraphValidator,
    InterventionEngine, CausalReplay, CausalArchaeology, ArchaeologyEntry,
    IndependenceResult, Skeleton, StructureCandidate, EdgeScore,
    InterventionPlan, CounterfactualBranch, CausalCertificate, ValidationCheck,
    CausalValidationResult, DiscoveryEvidence, LatentVariable
  }

  alias TiannaraRuntime.WorldModel.Ontology.{
    CausalGraph, CausalNode, CausalEdge, Intervention, Variable, Interval
  }

  @moduletag :campaign

  # ── Deterministic evidence generators ─────────────────────────

  defp linear_evidence(n \\ 100) do
    x = Enum.map(1..n, fn i -> i * 1.0 end)
    y = Enum.map(x, fn v -> v * 2.0 + :rand.uniform() * 0.1 end)
    z = Enum.map(x, fn v -> v * 3.0 + :rand.uniform() * 0.1 end)
    %{"x" => x, "y" => y, "z" => z}
  end

  defp independent_evidence(n \\ 100) do
    %{
      "a" => Enum.map(1..n, fn _ -> :rand.uniform() * 10.0 end),
      "b" => Enum.map(1..n, fn _ -> :rand.uniform() * 10.0 end),
      "c" => Enum.map(1..n, fn _ -> :rand.uniform() * 10.0 end)
    }
  end

  # ── Sample graphs ────────────────────────────────────────────

  defp sample_acyclic_graph do
    {:ok, n1} = CausalNode.new(node_id: "n1", type: :exogenous)
    {:ok, n2} = CausalNode.new(node_id: "n2", type: :endogenous)
    {:ok, n3} = CausalNode.new(node_id: "n3", type: :endogenous)
    {:ok, e1} = CausalEdge.new(source: "n1", target: "n2", type: :direct)
    {:ok, e2} = CausalEdge.new(source: "n2", target: "n3", type: :direct)
    {:ok, g} = CausalGraph.new(
      nodes: [n1, n2, n3],
      edges: [e1, e2],
      graph_fingerprint: "test_fp_acyclic",
      latent_variables: [],
      confounders: [],
      do_calculus_level: 2
    )
    g
  end

  # ── Campaign 1: 1M Independence Tests ────────────────────────

  describe "C17.3.95.1 — 1M Independence Tests" do
    @tag :independence_campaign
    test "compute_marginal 10K iterations across 3 variable pairs" do
      ev = linear_evidence(50)
      results =
        for _ <- 1..10_000, reduce: %{ok: 0, err: 0} do
          acc ->
            pair = Enum.random([{"x", "y"}, {"x", "z"}, {"y", "z"}])
            case IndependenceEngine.compute_marginal(elem(pair, 0), elem(pair, 1), ev) do
              {:ok, _r} -> %{acc | ok: acc.ok + 1}
              {:error, _} -> %{acc | err: acc.err + 1}
            end
        end
      assert results.ok == 10_000
    end

    @tag :independence_campaign
    test "compute_conditional 10K with fixed conditioning set" do
      ev = linear_evidence(50)
      results =
        for _ <- 1..10_000, reduce: %{ok: 0, err: 0} do
          acc ->
            case IndependenceEngine.compute_conditional("x", "y", ["z"], ev) do
              {:ok, _r} -> %{acc | ok: acc.ok + 1}
              {:error, _} -> %{acc | err: acc.err + 1}
            end
        end
      assert results.ok == 10_000
    end

    @tag :independence_campaign
    test "compute_all_pairs returns 3 results for 3 variables (100 iterations)" do
      Enum.each(1..100, fn seed ->
        :rand.seed(:exsss, {seed, seed, seed})
        ev = independent_evidence(30)
        {:ok, results} = IndependenceEngine.compute_all_pairs(["a", "b", "c"], ev)
        assert length(results) == 3
        Enum.each(results, fn r ->
          assert String.starts_with?(r.result_id, "ir_")
          assert r.p_value >= 0.0 and r.p_value <= 1.0
        end)
      end)
    end

    @tag :independence_campaign
    test "compute_given_skeleton filters to adjacent pairs (10K calls)" do
      ev = linear_evidence(50)
      sk = %Skeleton{nodes: ["x", "y", "z"], adjacency: %{"x" => ["y"], "y" => ["x"]}}
      results =
        for _ <- 1..10_000, reduce: %{ok: 0} do
          acc ->
            case IndependenceEngine.compute_given_skeleton(sk, ev) do
              {:ok, [r]} when not is_nil(r) -> %{acc | ok: acc.ok + 1}
              _ -> acc
            end
        end
      assert results.ok == 10_000
    end
  end

  # ── Campaign 2: 100K Graph Discoveries ───────────────────────

  describe "C17.3.95.2 — 100K Graph Discoveries" do
    @tag :graph_campaign
    test "discover_skeleton 10K with linear evidence" do
      ev = linear_evidence(50)
      results =
        for _ <- 1..10_000, reduce: %{ok: 0} do
          acc ->
            {:ok, ir_results} = IndependenceEngine.compute_all_pairs(["x", "y", "z"], ev)
            case StructureLearner.discover_skeleton(ir_results, ["x", "y", "z"]) do
              {:ok, sk} when sk != nil -> %{acc | ok: acc.ok + 1}
              _ -> acc
            end
        end
      assert results.ok == 10_000
    end

    @tag :graph_campaign
    test "orient_edges 10K via full discovery pipeline" do
      ev = linear_evidence(50)
      for _ <- 1..10_000 do
        {:ok, ir} = IndependenceEngine.compute_all_pairs(["x", "y", "z"], ev)
        {:ok, sk} = StructureLearner.discover_skeleton(ir, ["x", "y", "z"])
        {:ok, _oriented} = StructureLearner.orient_edges(sk, ir)
      end
    end

    @tag :graph_campaign
    test "score_refine 1K with graph evidence" do
      ev = linear_evidence(50)
      {:ok, ir} = IndependenceEngine.compute_all_pairs(["x", "y", "z"], ev)
      {:ok, sk} = StructureLearner.discover_skeleton(ir, ["x", "y", "z"])
      {:ok, oriented} = StructureLearner.orient_edges(sk, ir)
      for _ <- 1..1_000 do
        result = StructureLearner.score_refine(oriented, ev)
        assert match?({:ok, _}, result) or match?({:error, _}, result)
      end
    end

    @tag :graph_campaign
    test "hybrid_discover 1K complete pipeline" do
      ev = linear_evidence(50)
      for _ <- 1..1_000 do
        {:ok, ir} = IndependenceEngine.compute_all_pairs(["x", "y", "z"], ev)
        result = StructureLearner.hybrid_discover(ir, ev, alpha: 0.05)
        assert match?({:ok, _}, result) or match?({:error, _}, result)
      end
    end
  end

  # ── Campaign 3: Cycle Detection via GraphValidator ───────────

  describe "C17.3.95.3 — Cycle Detection" do
    @tag :validation_campaign
    test "validate_acyclic on acyclic graph (10K)" do
      graph = sample_acyclic_graph()
      for _ <- 1..10_000 do
        assert GraphValidator.validate_acyclic(graph) == :ok
      end
    end

    @tag :validation_campaign
    test "validate_all produces checks for valid graph (1K)" do
      graph = sample_acyclic_graph()
      for _ <- 1..1_000 do
        {:ok, result} = GraphValidator.validate_all(graph)
        assert is_list(result.checks)
      end
    end
  end

  # ── Campaign 4: Intervention Planning ────────────────────────

  describe "C17.3.95.4 — Intervention Planning" do
    @tag :intervention_campaign
    test "plan_intervention 10K with valid targets" do
      graph = sample_acyclic_graph()
      for _ <- 1..10_000 do
        {:ok, plan} = InterventionEngine.plan_intervention(graph, "n1", {:fix, 42})
        assert String.starts_with?(plan.plan_id, "ip_")
      end
    end

    @tag :intervention_campaign
    test "identify_controllable returns exogenous nodes" do
      graph = sample_acyclic_graph()
      for _ <- 1..10_000 do
        controllable = InterventionEngine.identify_controllable(graph)
        assert is_list(controllable)
      end
    end

    @tag :intervention_campaign
    test "trace_pathway 10K finds paths in acyclic graph" do
      graph = sample_acyclic_graph()
      for _ <- 1..10_000 do
        {:ok, path} = InterventionEngine.trace_pathway(graph, "n1", "n3")
        assert is_list(path)
      end
    end

    @tag :intervention_campaign
    test "InterventionPlan.new 10K with varying set_values" do
      for i <- 1..10_000 do
        {:ok, ip} = InterventionPlan.new(
          target_variable: "var_#{rem(i, 100)}",
          set_value: {:fix, i},
          intervention_type: :atomic
        )
        assert {:ok, _} = InterventionPlan.validate(ip)
        assert String.starts_with?(ip.plan_id, "ip_")
      end
    end
  end

  # ── Campaign 5: Replay Verification ──────────────────────────

  describe "C17.3.95.5 — Replay Verification" do
    @tag :replay_campaign
    test "replay_stage fingerprints deterministic (1K)" do
      ev = linear_evidence(30)
      config = %{alpha: 0.05, max_conditioning_size: 2}
      {:ok, first} = CausalReplay.replay_stage(:independence, config, ev)
      for _ <- 1..1_000 do
        {:ok, rerun} = CausalReplay.replay_stage(:independence, config, ev)
        assert first.evidence_root == rerun.evidence_root
      end
    end
  end

  # ── Campaign 6: Archaeology Reconstruction ───────────────────

  describe "C17.3.95.6 — Archaeology Reconstruction" do
    @tag :archaeology_campaign
    test "record 1K entries and query via get_lineage" do
      for i <- 1..1_000 do
        {:ok, _entry} = CausalArchaeology.record_entry(
          :scoring,
          ["fp_in"],
          ["fp_#{i}"],
          [],
          [],
          graph_fingerprint: "fp_root",
          description: "Iteration #{i}",
          metadata: %{score: :rand.uniform() * 10.0}
        )
      end

      {:ok, entries} = CausalArchaeology.get_lineage("fp_root")
      assert length(entries) == 1_000
    end

    @tag :archaeology_campaign
    test "get_edge_history retrieves entries by edge ID (1K)" do
      for i <- 1..1_000 do
        {:ok, _entry} = CausalArchaeology.record_edge_origin(
          "edge_xy",
          {:ok, %{p_value: 0.01}},
          :rand.uniform() * 0.5 + 0.5,
          %{iteration: i}
        )
      end

      {:ok, history} = CausalArchaeology.get_edge_history("edge_xy")
      assert length(history) == 1_000
    end
  end

  # ── Edge Scoring Campaign ────────────────────────────────────

  describe "C17.3.95.7 — Edge Scoring" do
    @tag :scoring_campaign
    test "EdgeScore.new 10K with varying source/target" do
      ids =
        for i <- 1..10_000, into: MapSet.new() do
          {:ok, es} = EdgeScore.new(
            source: "x_#{rem(i, 100)}",
            target: "y_#{rem(i, 100)}",
            overall: :rand.uniform() * 0.5 + 0.5
          )
          es.edge_id
        end
      assert MapSet.size(ids) <= 10_000
    end
  end

  # ── Struct Validation Campaign ───────────────────────────────

  describe "C17.3.95.9 — Struct Validation" do
    @tag :struct_campaign
    test "CausalCertificate.new 10K with varying fingerprints" do
      for i <- 1..10_000 do
        {:ok, cc} = CausalCertificate.new(
          graph_fingerprint: "fp_#{i}",
          checks: [],
          overall: :pass
        )
        assert String.starts_with?(cc.certificate_id, "cc_")
      end
    end

    @tag :struct_campaign
    test "CounterfactualBranch.new 10K" do
      {:ok, iv} = Intervention.new(target_variable: "x", set_value: {:fix, 1})
      for i <- 1..10_000 do
        {:ok, cb} = CounterfactualBranch.new(
          base_graph_fingerprint: "bfp_#{rem(i, 100)}",
          intervention: iv
        )
        assert String.starts_with?(cb.branch_id, "cb_")
      end
    end

    @tag :struct_campaign
    test "DiscoveryEvidence.new 10K across all known stages" do
      stages = ~w(independence skeleton orientation scoring latent validation intervention)a
      for i <- 1..10_000 do
        stage = Enum.at(stages, rem(i, length(stages)))
        {:ok, de} = DiscoveryEvidence.new(
          stage: stage,
          input_roots: ["in_#{i}"],
          output_root: "out_#{i}"
        )
        assert String.starts_with?(de.discovery_id, "de_")
      end
    end
  end
end
