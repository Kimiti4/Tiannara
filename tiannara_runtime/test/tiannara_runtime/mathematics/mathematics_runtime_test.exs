defmodule TiannaraRuntime.Mathematics.MathematicsRuntimeTest do
  @moduledoc "Phase 16.X.7 — Mathematics Runtime tests: orchestration, scheduling, execution, verification, replay, archaeology."
  use ExUnit.Case, async: true

  alias TiannaraRuntime.Mathematics.MathematicsRuntime
  alias TiannaraRuntime.Mathematics.MathematicsRuntime.MathematicsScheduler
  alias TiannaraRuntime.Mathematics.MathematicsRuntime.ExpressionExecutor
  alias TiannaraRuntime.Mathematics.MathematicsRuntime.ProofExecutor
  alias TiannaraRuntime.Mathematics.MathematicsRuntime.ConjectureCoordinator
  alias TiannaraRuntime.Mathematics.MathematicsRuntime.VerificationCoordinator
  alias TiannaraRuntime.Mathematics.MathematicsRuntime.ReplayCoordinator
  alias TiannaraRuntime.Mathematics.MathematicsRuntime.ArchaeologyCollector
  alias TiannaraRuntime.Mathematics.MathematicsRuntime.HashCoordinator
  alias TiannaraRuntime.Mathematics.MathematicsRuntime.DependencyResolver
  alias TiannaraRuntime.Mathematics.MathematicsRuntime.RuntimeMonitor

  # ---------------------------------------------------------------------------
  # Top-Level Execution
  # ---------------------------------------------------------------------------

  describe "execute/2" do
    test "executes an expression request through full lifecycle" do
      request = %{
        "type" => "expression",
        "operation" => "simplify",
        "expression_id" => "expr_1",
        "request_id" => "req_1",
        "dependencies" => []
      }

      assert {:ok, archived} = MathematicsRuntime.execute(request)
      assert archived["status"] == "archived"
      assert archived["request_id"] == "req_1"
      assert Map.has_key?(archived, "archaeology")
      assert Map.has_key?(archived, "execution_result")
    end

    test "returns error for unknown type" do
      request = %{"type" => "unknown_type", "request_id" => "req_bad"}
      assert {:error, _} = MathematicsRuntime.execute(request)
    end
  end

  describe "execute_expression/1" do
    test "executes expression request" do
      request = %{"operation" => "simplify", "expression_id" => "e1", "request_id" => "re1", "dependencies" => []}
      assert {:ok, _} = MathematicsRuntime.execute_expression(request)
    end
  end

  describe "execute_proof/1" do
    test "executes proof request" do
      request = %{
        "type" => "proof",
        "assertion_id" => "a1",
        "strategy" => :direct,
        "assumptions" => [],
        "steps" => [%{"step_number" => 0, "rule_applied" => "r1", "input_objects" => ["a"], "output_object" => "b", "dependency_hashes" => [], "fingerprint" => "fp"}],
        "request_id" => "rp1",
        "dependencies" => []
      }

      assert {:ok, _} = MathematicsRuntime.execute_proof(request)
    end
  end

  describe "execute_conjecture/1" do
    test "executes conjecture request" do
      request = %{
        "type" => "conjecture",
        "statement" => "Every group of order p^2 is abelian",
        "source" => "knowledge_gap",
        "request_id" => "rc1",
        "dependencies" => []
      }

      assert {:ok, _} = MathematicsRuntime.execute_conjecture(request)
    end
  end

  describe "execute_verification/1" do
    test "executes verification request" do
      request = %{
        "type" => "verification",
        "target_id" => "t1",
        "target_type" => "symbolic_expression",
        "mode" => :structural,
        "properties" => [:correctness],
        "request_id" => "rv1",
        "dependencies" => []
      }

      assert {:ok, _} = MathematicsRuntime.execute_verification(request)
    end
  end

  # ---------------------------------------------------------------------------
  # MathematicsScheduler
  # ---------------------------------------------------------------------------

  describe "MathematicsScheduler.schedule/2" do
    test "returns scheduled request with timestamp" do
      assert {:ok, scheduled} = MathematicsScheduler.schedule(%{"request_id" => "r1"})
      assert Map.has_key?(scheduled, "scheduled_at")
    end
  end

  describe "MathematicsScheduler.sort_requests/1" do
    test "sorts by dependencies, priority, then id" do
      r1 = %{"request_id" => "A", "dependencies" => [], "priority" => 0.5}
      r2 = %{"request_id" => "B", "dependencies" => ["A"], "priority" => 0.9}
      r3 = %{"request_id" => "C", "dependencies" => [], "priority" => 0.1}

      sorted = MathematicsScheduler.sort_requests([r1, r2, r3])
      assert hd(sorted)["request_id"] == "A"
    end
  end

  # ---------------------------------------------------------------------------
  # ExpressionExecutor
  # ---------------------------------------------------------------------------

  describe "ExpressionExecutor.execute/1" do
    test "executes simplify operation" do
      request = %{"request_id" => "e1", "operation" => "simplify", "expression_id" => "expr_1"}
      assert {:ok, result} = ExpressionExecutor.execute(request)
      assert result["status"] == "completed"
    end

    test "returns error for unknown operation" do
      request = %{"request_id" => "e2", "operation" => "unknown_op"}
      assert {:error, _} = ExpressionExecutor.execute(request)
    end
  end

  # ---------------------------------------------------------------------------
  # ProofExecutor
  # ---------------------------------------------------------------------------

  describe "ProofExecutor.execute/1" do
    test "builds and verifies a proof" do
      request = %{
        "request_id" => "p1",
        "assertion_id" => "a1",
        "strategy" => :direct,
        "assumptions" => [],
        "steps" => [%{"step_number" => 0, "rule_applied" => "r1", "input_objects" => ["a"], "output_object" => "b", "dependency_hashes" => [], "fingerprint" => "fp"}]
      }

      assert {:ok, result} = ProofExecutor.execute(request)
      assert result["status"] == "verified"
    end

    test "fails for invalid strategy" do
      request = %{"assertion_id" => "a1", "strategy" => :bad, "assumptions" => [], "steps" => []}
      assert {:error, _} = ProofExecutor.execute(request)
    end
  end

  # ---------------------------------------------------------------------------
  # ConjectureCoordinator
  # ---------------------------------------------------------------------------

  describe "ConjectureCoordinator.execute/1" do
    test "generates a conjecture" do
      request = %{"request_id" => "c1", "statement" => "Test statement", "source" => "pattern"}
      assert {:ok, result} = ConjectureCoordinator.execute(request)
      assert result["status"] == "completed"
    end
  end

  # ---------------------------------------------------------------------------
  # VerificationCoordinator
  # ---------------------------------------------------------------------------

  describe "VerificationCoordinator.verify/1" do
    test "verifies execution result" do
      result = %{"type" => "proof_execution", "request_id" => "p1"}
      assert {:ok, verified} = VerificationCoordinator.verify(result)
      assert verified["verification_status"] == "verified"
    end
  end

  # ---------------------------------------------------------------------------
  # ReplayCoordinator
  # ---------------------------------------------------------------------------

  describe "ReplayCoordinator.check/1" do
    test "adds replay hash to result" do
      result = %{"request_id" => "r1", "type" => "proof_execution", "status" => "verified"}
      assert {:ok, checked} = ReplayCoordinator.check(result)
      assert is_binary(checked["replay_hash"])
    end
  end

  describe "ReplayCoordinator.replay/1" do
    test "replays archived execution" do
      archived = %{"request_id" => "r1", "type" => "proof_execution", "status" => "archived"}
      assert {:ok, replayed} = ReplayCoordinator.replay(archived)
      assert replayed["status"] == "replayed"
    end
  end

  # ---------------------------------------------------------------------------
  # ArchaeologyCollector
  # ---------------------------------------------------------------------------

  describe "ArchaeologyCollector.collect/1" do
    test "collects archaeology record" do
      executed = %{"request_id" => "r1", "type" => "expression_execution", "status" => "completed", "verification_status" => "verified", "replay_hash" => "abc", "dependencies" => []}
      assert {:ok, collected} = ArchaeologyCollector.collect(executed)
      assert collected["archaeology"]["origin"] == "Phase 16.X.7"
    end
  end

  # ---------------------------------------------------------------------------
  # HashCoordinator
  # ---------------------------------------------------------------------------

  describe "HashCoordinator.hash/1" do
    test "produces deterministic hash" do
      a1 = %{"key" => "value"}
      a2 = %{"key" => "value"}
      assert HashCoordinator.hash(a1) == HashCoordinator.hash(a2)
    end
  end

  describe "HashCoordinator.verify_hash/2" do
    test "verifies matching hash" do
      artifact = %{"data" => "test"}
      h = HashCoordinator.hash(artifact)
      assert HashCoordinator.verify_hash(artifact, h) == true
    end

    test "rejects mismatched hash" do
      artifact = %{"data" => "test"}
      refute HashCoordinator.verify_hash(artifact, "wrong_hash")
    end
  end

  # ---------------------------------------------------------------------------
  # DependencyResolver
  # ---------------------------------------------------------------------------

  describe "DependencyResolver.resolve/1" do
    test "resolves dependencies" do
      request = %{"request_id" => "r1", "dependencies" => ["dep_A", "dep_B"]}
      assert {:ok, resolved} = DependencyResolver.resolve(request)
      assert length(resolved["resolved_dependencies"]) == 2
    end
  end

  describe "DependencyResolver.dependency_depth/2" do
    test "returns dependency count" do
      request = %{"dependencies" => ["a", "b", "c"]}
      assert DependencyResolver.dependency_depth([], request) == 3
    end
  end

  # ---------------------------------------------------------------------------
  # RuntimeMonitor
  # ---------------------------------------------------------------------------

  describe "RuntimeMonitor.metrics/1" do
    test "returns runtime metrics" do
      executions = [
        %{"type" => "proof_execution", "verification_status" => "verified"},
        %{"type" => "expression_execution", "verification_status" => "verified"},
        %{"type" => "replayed_proof", "verification_status" => "verified"}
      ]

      m = RuntimeMonitor.metrics(executions)
      assert m["execution_count"] == 3
      assert is_number(m["replay_success_rate"])
      assert is_number(m["average_dependency_depth"])
    end

    test "returns zero metrics for empty list" do
      m = RuntimeMonitor.metrics([])
      assert m["execution_count"] == 0
    end
  end
end
