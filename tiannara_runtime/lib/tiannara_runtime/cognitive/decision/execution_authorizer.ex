defmodule TiannaraRuntime.Cognitive.Decision.ExecutionAuthorizer do
  @moduledoc "Phase 18.6 — Authorizes execution based on policy and risk"

  def authorize(candidate, policy_eval, risk_assessment) do
    decision_id = "eauth_#{:erlang.unique_integer([:positive]) |> abs() |> Integer.to_string()}"
    failed_policies = Map.get(policy_eval, :failed, [])
    risk_overall = Map.get(risk_assessment, :overall, 0)
    score_total = Map.get(Map.get(candidate, :score, %{}), :total, 0)
    candidate_id = Map.get(candidate, :id)
    policy_fp = :crypto.hash(:sha256, inspect(policy_eval)) |> Base.encode16(case: :lower)
    decision_fp = :crypto.hash(:sha256, "#{candidate_id}_#{decision_id}") |> Base.encode16(case: :lower)
    authorized_at = :erlang.unique_integer([:positive])
    cond do
      length(failed_policies) > 0 or risk_overall >= 0.9 ->
        {:ok, %{candidate_id: candidate_id, decision_id: decision_id, state: :denied, reason: "Policy failure or high risk", policy_fingerprint: policy_fp, decision_fingerprint: decision_fp, authorized_at: authorized_at, policy_eval: policy_eval, risk_assessment: risk_assessment}}
      risk_overall >= 0.8 and risk_overall < 0.9 ->
        {:ok, %{candidate_id: candidate_id, decision_id: decision_id, state: :deferred, reason: "Risk threshold requires review", policy_fingerprint: policy_fp, decision_fingerprint: decision_fp, authorized_at: authorized_at, policy_eval: policy_eval, risk_assessment: risk_assessment}}
      score_total >= 0.2 and score_total < 0.3 ->
        {:ok, %{candidate_id: candidate_id, decision_id: decision_id, state: :requires_review, reason: "Score below threshold, requires review", policy_fingerprint: policy_fp, decision_fingerprint: decision_fp, authorized_at: authorized_at, policy_eval: policy_eval, risk_assessment: risk_assessment}}
      length(failed_policies) == 0 and risk_overall < 0.8 and score_total >= 0.3 ->
        {:ok, %{candidate_id: candidate_id, decision_id: decision_id, state: :authorized, reason: "All checks passed", policy_fingerprint: policy_fp, decision_fingerprint: decision_fp, authorized_at: authorized_at, policy_eval: policy_eval, risk_assessment: risk_assessment}}
      true ->
        {:ok, %{candidate_id: candidate_id, decision_id: decision_id, state: :denied, reason: "Failed authorization criteria", policy_fingerprint: policy_fp, decision_fingerprint: decision_fp, authorized_at: authorized_at, policy_eval: policy_eval, risk_assessment: risk_assessment}}
    end
  end

  def generate_intent(authorization, candidate, mission) do
    session_id = Map.get(candidate, :session_id)
    authorization_id = Map.get(authorization, :decision_id)
    policy_fingerprint = Map.get(authorization, :policy_fingerprint)
    replay_root = "replay_#{:erlang.unique_integer([:positive]) |> abs() |> Integer.to_string()}"
    {:ok, %{session_id: session_id, authorization_id: authorization_id, mission: mission, plan: Map.get(candidate, :plan), alternative: Map.get(candidate, :alternative), policy_fingerprint: policy_fingerprint, replay_root: replay_root}}
  end
end
