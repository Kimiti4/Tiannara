defmodule TiannaraRuntime.Mathematics.FormalVerificationEngineTest do
  @moduledoc "Phase 16.X.6 — Formal Verification Engine tests: verification, modes, properties, counterexamples, replay, archaeology."
  use ExUnit.Case, async: true

  alias TiannaraRuntime.Mathematics.FormalVerificationEngine

  # ---------------------------------------------------------------------------
  # Verification Execution
  # ---------------------------------------------------------------------------

  describe "verify/5" do
    test "runs verification and returns result with all fields" do
      assert {:ok, result} = FormalVerificationEngine.verify("target_1", "symbolic_expression", :structural, [:correctness, :consistency])
      assert result["target_id"] == "target_1"
      assert result["target_type"] == "symbolic_expression"
      assert result["verification_mode"] == :structural
      assert result["status"] == "pass"
      assert String.starts_with?(result["verification_id"], "verification_")
      assert is_list(result["properties_checked"])
      assert is_list(result["counterexamples"])
      assert is_list(result["verification_steps"])
    end

    test "rejects invalid mode" do
      assert {:error, _} = FormalVerificationEngine.verify("t1", "symbolic_expression", :invalid_mode, [:correctness])
    end

    test "rejects invalid target type" do
      assert {:error, _} = FormalVerificationEngine.verify("t1", "invalid_target", :structural, [:correctness])
    end
  end

  # ---------------------------------------------------------------------------
  # Verification Modes
  # ---------------------------------------------------------------------------

  describe "structural_verify/3" do
    test "runs structural verification" do
      assert {:ok, result} = FormalVerificationEngine.structural_verify("t1", "proof", [:correctness])
      assert result["verification_mode"] == :structural
    end
  end

  describe "logical_verify/3" do
    test "runs logical verification" do
      assert {:ok, result} = FormalVerificationEngine.logical_verify("t1", "theorem", [:consistency])
      assert result["verification_mode"] == :logical
    end
  end

  describe "computational_verify/3" do
    test "runs computational verification" do
      assert {:ok, result} = FormalVerificationEngine.computational_verify("t1", "algorithm", [:correctness, :termination])
      assert result["verification_mode"] == :computational
    end
  end

  describe "constraint_verify/3" do
    test "runs constraint verification" do
      assert {:ok, result} = FormalVerificationEngine.constraint_verify("t1", "constraint_system", [:constraint_satisfaction])
      assert result["verification_mode"] == :constraint
    end
  end

  describe "invariant_verify/3" do
    test "runs invariant verification" do
      assert {:ok, result} = FormalVerificationEngine.invariant_verify("t1", "graph_structure", [:invariant_satisfaction])
      assert result["verification_mode"] == :invariant
    end
  end

  describe "replay_verify/3" do
    test "runs replay verification" do
      assert {:ok, result} = FormalVerificationEngine.replay_verify("t1", "symbolic_expression", [:correctness])
      assert result["verification_mode"] == :replay
    end
  end

  describe "cross_verify/3" do
    test "runs cross verification" do
      assert {:ok, result} = FormalVerificationEngine.cross_verify("t1", "linear_system", [:stability, :convergence])
      assert result["verification_mode"] == :cross
    end
  end

  # ---------------------------------------------------------------------------
  # Property Checking
  # ---------------------------------------------------------------------------

  describe "check_property/5" do
    test "all properties pass by default" do
      for prop <- FormalVerificationEngine.valid_properties() do
        assert {:pass, %{}} == FormalVerificationEngine.check_property("t1", "symbolic_expression", :structural, prop, [])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Counterexamples
  # ---------------------------------------------------------------------------

  describe "build_counterexample/3" do
    test "builds deterministic counterexample" do
      ce = FormalVerificationEngine.build_counterexample("t1", :correctness, %{minimal_example: "x ≠ x", reconstruction_path: ["step_0"], dependency_chain: ["dep_A"]})
      assert ce["violated_property"] == "correctness"
      assert ce["minimal_example"] == "x ≠ x"
      assert is_binary(ce["replay_hash"])
    end
  end

  # ---------------------------------------------------------------------------
  # Replay
  # ---------------------------------------------------------------------------

  describe "replay_verification/1" do
    test "replays verification deterministically" do
      {:ok, original} = FormalVerificationEngine.verify("target_1", "symbolic_expression", :structural, [:correctness])
      assert {:ok, replayed} = FormalVerificationEngine.replay_verification(original)
      assert replayed["verification_id"] == original["verification_id"]
      assert replayed["status"] == original["status"]
    end

    test "returns error for incomplete result" do
      assert {:error, _} = FormalVerificationEngine.replay_verification(%{})
    end
  end

  # ---------------------------------------------------------------------------
  # Archaeology
  # ---------------------------------------------------------------------------

  describe "archaeology/1" do
    test "returns provenance record" do
      {:ok, result} = FormalVerificationEngine.verify("target_1", "symbolic_expression", :structural, [:correctness])
      assert {:ok, record} = FormalVerificationEngine.archaeology(result)
      assert record["verification_id"] == result["verification_id"]
      assert record["target_id"] == "target_1"
    end

    test "returns error for incomplete result" do
      assert {:error, _} = FormalVerificationEngine.archaeology(%{})
    end
  end

  # ---------------------------------------------------------------------------
  # Metrics
  # ---------------------------------------------------------------------------

  describe "metrics/1" do
    test "returns aggregate metrics" do
      {:ok, r1} = FormalVerificationEngine.verify("t1", "symbolic_expression", :structural, [:correctness])
      {:ok, r2} = FormalVerificationEngine.verify("t2", "proof", :logical, [:consistency])

      m = FormalVerificationEngine.metrics([r1, r2])
      assert m["verification_count"] == 2
      assert m["success_rate"] == 1.0
      assert is_integer(m["counterexample_count"])
    end

    test "returns zero metrics for empty list" do
      m = FormalVerificationEngine.metrics([])
      assert m["verification_count"] == 0
    end
  end

  # ---------------------------------------------------------------------------
  # Valid types
  # ---------------------------------------------------------------------------

  describe "valid_modes/0" do
    test "returns all seven modes" do
      modes = FormalVerificationEngine.valid_modes()
      assert :structural in modes
      assert :cross in modes
      assert length(modes) == 7
    end
  end

  describe "valid_properties/0" do
    test "returns all ten properties" do
      props = FormalVerificationEngine.valid_properties()
      assert :correctness in props
      assert :constraint_satisfaction in props
      assert length(props) == 10
    end
  end

  describe "valid_target_types/0" do
    test "returns all target types" do
      types = FormalVerificationEngine.valid_target_types()
      assert "symbolic_expression" in types
      assert "world_model_component" in types
      assert length(types) == 12
    end
  end
end
