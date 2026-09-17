defmodule TiannaraRuntime.Cognitive.Decision.DecisionManager do
  @moduledoc "Phase 18.6 — Orchestrates the constitutional decision pipeline"

  def create_session(mission, plan) do
    session_id = "dse_#{:erlang.unique_integer([:positive]) |> abs() |> Integer.to_string()}"
    %{session_id: session_id, mission: mission, plan: plan, candidates: [], selected: nil, status: :created, evaluations: [], authorizations: [], evidence: [], created_at: :erlang.unique_integer([:positive])}
  end

  def evaluate_candidates(session, candidates) do
    updated = %{session | candidates: candidates, status: :evaluating}
    {:ok, updated}
  end

  def select_candidate(session, candidate_id) do
    candidate = Enum.find(session.candidates, fn c -> Map.get(c, :id) == candidate_id end)
    case candidate do
      nil -> {:error, :candidate_not_found}
      _ -> {:ok, %{session | selected: candidate, status: :selected}}
    end
  end

  def authorize(session, authorization) do
    auths = session.authorizations ++ [authorization]
    {:ok, %{session | authorizations: auths, status: :authorized}}
  end

  def get_status(session), do: {:ok, Map.get(session, :status)}
end
