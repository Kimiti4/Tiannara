defmodule TiannaraRuntime.Mathematics.ProofEngineTest do
  @moduledoc "Phase 16.X.4 — Proof Engine tests: construction, strategies, verification, replay, archaeology, dependency graphs."
  use ExUnit.Case, async: true

  alias TiannaraRuntime.Mathematics.ProofEngine

  defp make_step(n, rule, inputs, output, deps \\ [], fp \\ nil) do
    %{
      "step_number" => n,
      "rule_applied" => rule,
      "input_objects" => inputs,
      "output_object" => output,
      "dependency_hashes" => deps,
      "fingerprint" => fp || "fp_#{n}"
    }
  end

  # ---------------------------------------------------------------------------
  # Proof Construction
  # ---------------------------------------------------------------------------

  describe "build_proof/4" do
    test "builds a proof with all required fields" do
      steps = [make_step(0, "modus_ponens", ["A", "A→B"], "B")]

      assert {:ok, proof} = ProofEngine.build_proof("assert_1", :direct, ["A", "A→B"], steps)
      assert proof["assertion_id"] == "assert_1"
      assert proof["strategy"] == :direct
      assert proof["verification_status"] == "unverified"
      assert proof["version"] == "1.0.0"
      assert String.starts_with?(proof["proof_id"], "proof_")
    end

    test "rejects invalid strategy" do
      assert {:error, _} = ProofEngine.build_proof("assert_1", :invalid_strat, [], [])
    end
  end

  describe "direct_proof/3" do
    test "builds a direct proof" do
      steps = [make_step(0, "identity", ["A"], "A")]
      assert {:ok, proof} = ProofEngine.direct_proof("assert_1", ["A"], steps)
      assert proof["strategy"] == :direct
    end
  end

  describe "contradiction_proof/3" do
    test "builds a contradiction proof" do
      steps = [make_step(0, "negation_intro", ["¬A→⊥"], "A")]
      assert {:ok, proof} = ProofEngine.contradiction_proof("assert_2", ["¬A→⊥"], steps)
      assert proof["strategy"] == :contradiction
    end
  end

  describe "induction_proof/4" do
    test "builds an induction proof from base and inductive steps" do
      base = [make_step(0, "base_case", ["P(0)"], "P(0)")]
      inductive = [make_step(1, "inductive_step", ["P(k)→P(k+1)"], "∀k P(k)→P(k+1)")]
      assert {:ok, proof} = ProofEngine.induction_proof("assert_3", ["P(0)"], base, inductive)
      assert proof["strategy"] == :induction
      assert length(proof["steps"]) == 2
    end
  end

  describe "constructive_proof/3" do
    test "builds a constructive proof" do
      steps = [make_step(0, "witness", ["∃x P(x)"], "P(42)")]
      assert {:ok, proof} = ProofEngine.constructive_proof("assert_4", [], steps)
      assert proof["strategy"] == :constructive
    end
  end

  describe "computational_proof/3" do
    test "builds a computational proof" do
      steps = [make_step(0, "exhaustive_check", ["∀x in {1..100}"], "verified")]
      assert {:ok, proof} = ProofEngine.computational_proof("assert_5", [], steps)
      assert proof["strategy"] == :computational
    end
  end

  # ---------------------------------------------------------------------------
  # Verification
  # ---------------------------------------------------------------------------

  describe "verify_proof/1" do
    test "passes verification for a well-formed proof" do
      steps = [make_step(0, "modus_ponens", ["A"], "B")]
      {:ok, proof} = ProofEngine.build_proof("assert_1", :direct, ["A"], steps)

      assert {:ok, verified} = ProofEngine.verify_proof(proof)
      assert verified["verification_status"] == "verified"
    end

    test "fails structural verification for missing fields" do
      assert {:error, reason} = ProofEngine.verify_proof(%{})
      assert String.contains?(reason, "structural")
    end
  end

  describe "structural_verify/1" do
    test "passes for complete proof" do
      steps = [make_step(0, "r", ["a"], "b")]
      {:ok, proof} = ProofEngine.build_proof("a1", :direct, [], steps)
      assert {:ok, _} = ProofEngine.structural_verify(proof)
    end

    test "fails for missing assertion_id" do
      assert {:error, _} = ProofEngine.structural_verify(%{})
    end
  end

  describe "logical_verify/1" do
    test "passes for sequential steps" do
      steps = [
        make_step(0, "r1", ["a"], "b"),
        make_step(1, "r2", ["b"], "c")
      ]
      {:ok, proof} = ProofEngine.build_proof("a1", :direct, [], steps)
      assert {:ok, _} = ProofEngine.logical_verify(proof)
    end

    test "fails for non-sequential steps" do
      steps = [
        make_step(0, "r1", ["a"], "b"),
        make_step(2, "r2", ["b"], "c")
      ]
      {:ok, proof} = ProofEngine.build_proof("a1", :direct, [], steps)
      assert {:error, _} = ProofEngine.logical_verify(proof)
    end
  end

  describe "dependency_verify/1" do
    test "passes when all dependencies satisfied" do
      steps = [make_step(0, "r1", ["a"], "b")]
      {:ok, proof} = ProofEngine.build_proof("a1", :direct, [], steps)
      assert {:ok, _} = ProofEngine.dependency_verify(proof)
    end
  end

  # ---------------------------------------------------------------------------
  # Replay
  # ---------------------------------------------------------------------------

  describe "replay_proof/1" do
    test "replays a proof deterministically" do
      steps = [make_step(0, "modus_ponens", ["A"], "B")]
      {:ok, proof} = ProofEngine.build_proof("assert_1", :direct, ["A"], steps)

      assert {:ok, replayed} = ProofEngine.replay_proof(proof)
      assert replayed["proof_hash"] == proof["proof_hash"]
      assert replayed["proof_id"] == proof["proof_id"]
    end

    test "returns error for incomplete proof" do
      assert {:error, _} = ProofEngine.replay_proof(%{})
    end
  end

  # ---------------------------------------------------------------------------
  # Dependency Graph
  # ---------------------------------------------------------------------------

  describe "dependency_graph/1" do
    test "builds a dependency graph without cycles" do
      proofs = [
        %{"proof_id" => "proof_A", "dependencies" => []},
        %{"proof_id" => "proof_B", "dependencies" => ["proof_A"]},
        %{"proof_id" => "proof_C", "dependencies" => ["proof_B"]}
      ]

      assert {:ok, graph} = ProofEngine.dependency_graph(proofs)
      assert length(graph["nodes"]) == 3
      assert length(graph["edges"]) == 2
    end

    test "detects cycles" do
      proofs = [
        %{"proof_id" => "proof_A", "dependencies" => ["proof_C"]},
        %{"proof_id" => "proof_B", "dependencies" => ["proof_A"]},
        %{"proof_id" => "proof_C", "dependencies" => ["proof_B"]}
      ]

      assert {:error, _} = ProofEngine.dependency_graph(proofs)
    end
  end

  describe "detect_cycles/2" do
    test "returns :no_cycles for acyclic graph" do
      nodes = [%{"node_id" => "A"}, %{"node_id" => "B"}]
      edges = [%{"from" => "A", "to" => "B"}]
      assert {:ok, :no_cycles} = ProofEngine.detect_cycles(nodes, edges)
    end

    test "detects a cycle" do
      nodes = [%{"node_id" => "A"}, %{"node_id" => "B"}]
      edges = [%{"from" => "A", "to" => "B"}, %{"from" => "B", "to" => "A"}]
      assert {:error, cycles} = ProofEngine.detect_cycles(nodes, edges)
      assert length(cycles) > 0
    end
  end

  # ---------------------------------------------------------------------------
  # Metrics
  # ---------------------------------------------------------------------------

  describe "proof_depth/1" do
    test "returns number of steps" do
      proof = %{"steps" => [%{}, %{}, %{}]}
      assert ProofEngine.proof_depth(proof) == 3
    end
  end

  describe "proof_width/1" do
    test "returns number of dependencies" do
      proof = %{"dependencies" => ["a", "b"]}
      assert ProofEngine.proof_width(proof) == 2
    end
  end

  describe "complexity/1" do
    test "computes steps * (deps + 1)" do
      proof = %{"steps" => [%{}, %{}], "dependencies" => ["a"]}
      assert ProofEngine.complexity(proof) == 4
    end
  end

  describe "metrics/2" do
    test "returns all metric fields" do
      proof = %{"proof_id" => "p1", "steps" => [%{}], "dependencies" => []}
      m = ProofEngine.metrics(proof, [proof])
      assert m["proof_depth"] == 1
      assert m["complexity"] == 1
      assert is_number(m["replay_cost"])
    end
  end

  # ---------------------------------------------------------------------------
  # Archaeology
  # ---------------------------------------------------------------------------

  describe "archaeology/1" do
    test "returns provenance record" do
      steps = [make_step(0, "modus_ponens", ["A"], "B")]
      {:ok, proof} = ProofEngine.build_proof("assert_1", :direct, ["A"], steps)

      assert {:ok, record} = ProofEngine.archaeology(proof)
      assert record["proof_id"] == proof["proof_id"]
      assert record["assertion_id"] == "assert_1"
      assert record["strategy"] == :direct
    end

    test "returns error for incomplete proof" do
      assert {:error, _} = ProofEngine.archaeology(%{})
    end
  end

  # ---------------------------------------------------------------------------
  # Fingerprint
  # ---------------------------------------------------------------------------

  describe "fingerprint/1" do
    test "produces deterministic content-addressed hash" do
      p1 = %{"proof_id" => "p1", "assertion_id" => "a1", "strategy" => :direct, "assumptions" => [], "steps" => [], "dependencies" => [], "verification_status" => "unverified"}
      p2 = %{"proof_id" => "p1", "assertion_id" => "a1", "strategy" => :direct, "assumptions" => [], "steps" => [], "dependencies" => [], "verification_status" => "unverified"}
      assert ProofEngine.fingerprint(p1) == ProofEngine.fingerprint(p2)
    end
  end

  # ---------------------------------------------------------------------------
  # Valid strategy types
  # ---------------------------------------------------------------------------

  describe "valid_strategies/0" do
    test "returns all five strategies" do
      assert ProofEngine.valid_strategies() == [:direct, :contradiction, :induction, :constructive, :computational]
    end
  end
end
