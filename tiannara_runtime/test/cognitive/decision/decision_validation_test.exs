defmodule TiannaraRuntime.Cognitive.Decision.DecisionValidationTest do
  use ExUnit.Case, async: false
  @moduletag :decision

  alias TiannaraRuntime.Cognitive.Decision.{
    DecisionSession, DecisionPolicy, PolicyEvaluation,
    DecisionCandidate, DecisionScore, RiskAssessment,
    ExecutionAuthorization, ExecutionIntent,
    DecisionReplay, DecisionArchaeology
  }

  describe "Tier 1 — Decision Session Creation" do
    test "new creates session with :open status" do
      session = %DecisionSession{id: "dse_abc", status: :open, mission_id: "m1", plan_id: "p1"}
      assert session.status == :open
      assert String.starts_with?(session.id, "dse_")
    end

    test "new generates unique id" do
      s1 = %DecisionSession{id: "dse_001", mission_id: "m1"}
      s2 = %DecisionSession{id: "dse_002", mission_id: "m1"}
      assert s1.id != s2.id
    end

    test "validate passes for valid session" do
      session = %DecisionSession{id: "dse_abc", schema_version: 1}
      assert DecisionSession.validate(session) == :ok
    end
  end

  describe "Tier 2 — Policy Construction & Validation" do
    test "new creates policy with :active status" do
      policy = %DecisionPolicy{id: "dp_001", name: "safety", scope: :execution, status: :active}
      assert policy.status == :active
      assert String.starts_with?(policy.id, "dp_")
    end

    test "validate passes for valid policy" do
      policy = %DecisionPolicy{id: "dp_001", name: "safety", scope: :execution, schema_version: 1}
      assert DecisionPolicy.validate(policy) == :ok
    end

    test "validate catches missing name" do
      policy = %DecisionPolicy{id: "dp_001", scope: :execution, schema_version: 1}
      assert {:error, errors} = DecisionPolicy.validate(policy)
      assert {:name, :required} in errors
    end
  end

  describe "Tier 3 — Policy Evaluation Record" do
    test "new creates evaluation with passed/failed lists" do
      eval = %PolicyEvaluation{id: "pe_001", candidate_id: "c1", passed_policies: ["p1"], failed_policies: []}
      assert eval.passed_policies == ["p1"]
      assert eval.failed_policies == []
    end

    test "new defaults can be empty" do
      eval = %PolicyEvaluation{id: "pe_002", candidate_id: "c1", passed_policies: [], failed_policies: []}
      assert eval.passed_policies == []
      assert eval.failed_policies == []
    end

    test "validate passes for valid evaluation" do
      eval = %PolicyEvaluation{id: "pe_001", candidate_id: "c1", schema_version: 1}
      assert PolicyEvaluation.validate(eval) == :ok
    end
  end

  describe "Tier 4 — Candidate Construction" do
    test "new creates candidate with score and risk" do
      cand = %DecisionCandidate{id: "dc_001", session_id: "s1", plan_id: "p1", score: %{total: 0.8}, risk: %{overall: 0.2}}
      assert cand.score == %{total: 0.8}
      assert cand.risk == %{overall: 0.2}
    end

    test "new defaults policies to empty list when set" do
      cand = %DecisionCandidate{id: "dc_002", session_id: "s1", plan_id: "p1", policies: []}
      assert cand.policies == []
    end

    test "validate passes for valid candidate" do
      cand = %DecisionCandidate{id: "dc_001", session_id: "s1", plan_id: "p1", schema_version: 1}
      assert DecisionCandidate.validate(cand) == :ok
    end
  end

  describe "Tier 5 — Scoring Dimensions" do
    test "new creates score with 10 dimension fields" do
      score = %DecisionScore{id: "ds_001", candidate_id: "c1", mission_value: 0.9, scientific_value: 0.8, mathematical_value: 0.7, risk_score: 0.3, cost: 0.4, memory: 0.5, simulation_budget: 0.6, resource_util: 0.7, constitutional_simplicity: 0.8, optionality: 0.9}
      assert score.mission_value == 0.9
      assert score.scientific_value == 0.8
      assert score.mathematical_value == 0.7
      assert score.risk_score == 0.3
      assert score.cost == 0.4
      assert score.memory == 0.5
      assert score.simulation_budget == 0.6
      assert score.resource_util == 0.7
      assert score.constitutional_simplicity == 0.8
      assert score.optionality == 0.9
    end

    test "validate passes for valid score" do
      score = %DecisionScore{id: "ds_001", candidate_id: "c1", mission_value: 0.5, schema_version: 1}
      assert DecisionScore.validate(score) == :ok
    end

    test "score fields can be set individually" do
      score = %DecisionScore{id: "ds_001", candidate_id: "c1", mission_value: 0.9, scientific_value: 0.8, mathematical_value: 0.7, risk_score: 0.3, cost: 0.4, memory: 0.5, simulation_budget: 0.6, resource_util: 0.7, constitutional_simplicity: 0.8, optionality: 0.9}
      assert score.mission_value == 0.9
      assert score.optionality == 0.9
    end
  end

  describe "Tier 6 — Risk Assessment Dimensions" do
    test "new creates risk with 6 dimension fields" do
      risk = %RiskAssessment{id: "ra_001", candidate_id: "c1", execution_risk: 0.1, scientific_risk: 0.2, governance_risk: 0.3, resource_risk: 0.4, uncertainty: 0.5, constitutional_complexity: 0.6}
      assert risk.execution_risk == 0.1
      assert risk.scientific_risk == 0.2
      assert risk.governance_risk == 0.3
      assert risk.resource_risk == 0.4
      assert risk.uncertainty == 0.5
      assert risk.constitutional_complexity == 0.6
    end

    test "validate passes for valid risk" do
      risk = %RiskAssessment{id: "ra_001", candidate_id: "c1", execution_risk: 0.1, schema_version: 1}
      assert RiskAssessment.validate(risk) == :ok
    end

    test "risk defaults are nil" do
      risk = %RiskAssessment{id: "ra_001", candidate_id: "c1"}
      assert risk.execution_risk == nil
    end
  end

  describe "Tier 7 — Authorization" do
    test "new creates authorization with :pending state" do
      auth = %ExecutionAuthorization{id: "ea_001", session_id: "s1", candidate_id: "c1", decision_id: "d1", state: :pending}
      assert auth.state == :pending
    end

    test "validate passes for valid authorization" do
      auth = %ExecutionAuthorization{id: "ea_001", session_id: "s1", candidate_id: "c1", decision_id: "d1", schema_version: 1}
      assert ExecutionAuthorization.validate(auth) == :ok
    end

    test "authorized_at can be set" do
      ts = :erlang.system_time(:millisecond)
      auth = %ExecutionAuthorization{id: "ea_001", session_id: "s1", candidate_id: "c1", decision_id: "d1", state: :authorized, authorized_at: ts}
      assert auth.authorized_at == ts
    end
  end

  describe "Tier 8 — Execution Intent" do
    test "new creates intent with all required fields" do
      intent = %ExecutionIntent{id: "ei_001", session_id: "s1", authorization_id: "a1", mission: %{objective: "test"}, plan: %{steps: []}, replay_root: "root_hash"}
      assert intent.session_id == "s1"
      assert intent.authorization_id == "a1"
      assert intent.replay_root == "root_hash"
    end

    test "validate passes for valid intent" do
      intent = %ExecutionIntent{id: "ei_001", session_id: "s1", authorization_id: "a1", mission: %{}, plan: %{}, replay_root: "rh", schema_version: 1}
      assert ExecutionIntent.validate(intent) == :ok
    end

    test "intent replay_root is string" do
      intent = %ExecutionIntent{id: "ei_001", session_id: "s1", authorization_id: "a1", mission: %{}, plan: %{}, replay_root: "abc123"}
      assert is_binary(intent.replay_root)
      assert intent.replay_root != ""
    end
  end

  describe "Tier 9 — Decision Replay" do
    test "new creates replay record with decision_root" do
      replay = %DecisionReplay{id: "dr_001", session_id: "s1", decision_root: "root_hash"}
      assert replay.decision_root == "root_hash"
    end

    test "validate passes for valid replay" do
      replay = %DecisionReplay{id: "dr_001", session_id: "s1", decision_root: "root", schema_version: 1}
      assert DecisionReplay.validate(replay) == :ok
    end

    test "replay can have 5 root fields" do
      replay = %DecisionReplay{id: "dr_001", session_id: "s1", decision_root: "dr", policy_root: "pr", score_root: "sr", auth_root: "ar", intent_root: "ir"}
      assert replay.decision_root == "dr"
      assert replay.policy_root == "pr"
      assert replay.score_root == "sr"
      assert replay.auth_root == "ar"
      assert replay.intent_root == "ir"
    end
  end

  describe "Tier 10 — Decision Archaeology" do
    test "new creates archaeology record with selection_reason" do
      arch = %DecisionArchaeology{id: "da_001", session_id: "s1", selection_reason: "highest_score", origin: :evaluation}
      assert arch.selection_reason == "highest_score"
    end

    test "validate passes for valid archaeology" do
      arch = %DecisionArchaeology{id: "da_001", session_id: "s1", selection_reason: "reason", origin: :test, schema_version: 1}
      assert DecisionArchaeology.validate(arch) == :ok
    end

    test "archaeology has 9 fields total" do
      arch = %DecisionArchaeology{id: "da_001", session_id: "s1", selection_reason: "reason", origin: :test, rejected_alternatives: [], policy_outcomes: [], risk_outcomes: [], score_breakdown: nil, auth_reason: nil}
      assert arch.rejected_alternatives == []
      assert arch.policy_outcomes == []
    end
  end

  describe "Tier 11 — Failure Injection" do
    test "DecisionSession.validate missing id returns error" do
      session = %DecisionSession{id: nil, schema_version: 1}
      assert {:error, errors} = DecisionSession.validate(session)
      assert {:id, :required} in errors
    end

    test "DecisionPolicy.validate missing name returns error" do
      policy = %DecisionPolicy{id: "dp_001", schema_version: 1}
      assert {:error, errors} = DecisionPolicy.validate(policy)
      assert {:name, :required} in errors
    end

    test "DecisionSession.validate version mismatch returns error" do
      session = %DecisionSession{id: "dse_001", schema_version: 999}
      assert {:error, errors} = DecisionSession.validate(session)
      assert {:schema_version, :mismatch} in errors
    end
  end

  describe "Tier 12 — Stress" do
    test "100 candidate records" do
      candidates =
        1..100
        |> Enum.map(fn i -> %DecisionCandidate{id: "dc_#{i}", session_id: "stress_s", plan_id: "p#{i}", score: %{total: i / 100}, risk: %{overall: 0.1}} end)
      assert length(candidates) == 100
      assert Enum.all?(candidates, fn c -> String.starts_with?(c.id, "dc_") end)
    end

    test "100 decision sessions" do
      sessions =
        1..100
        |> Enum.map(fn i -> %DecisionSession{id: "dse_#{i}", mission_id: "m#{i}", plan_id: "p#{i}", status: :open} end)
      ids = Enum.map(sessions, & &1.id)
      assert length(Enum.uniq(ids)) == 100
    end
  end
end
