defmodule TiannaraRuntime.Cognitive.Reflection.OutcomeAnalyzer do
  def analyze(decision, plan, mission) do
    goals = Map.get(mission, :goals, [])
    completed = Map.get(mission, :completed_goals, [])
    goal_count = length(goals)
    raw = if goal_count == 0, do: 0.5, else: length(completed) / goal_count
    success_score = max(0.0, min(raw, 1.0))
    status = if success_score >= 0.7, do: :success, else: if success_score >= 0.3, do: :partial, else: :failure
    evidence_raw = "#{Map.get(decision, :id)}_#{Map.get(plan, :id)}_#{:erlang.unique_integer([:positive])}"
    outcome = %{
      id: :erlang.unique_integer([:positive]),
      session_id: Map.get(decision, :session_id),
      decision_id: Map.get(decision, :id),
      plan_id: Map.get(plan, :id),
      mission_id: Map.get(mission, :id),
      status: status,
      success_score: success_score,
      dimensions: %{
        mission: max(0.0, min(success_score * 0.9 + 0.1, 1.0)),
        scientific: max(0.0, min(success_score * 0.8 + 0.2, 1.0)),
        operational: max(0.0, min(success_score * 0.85 + 0.15, 1.0)),
        temporal: max(0.0, min(success_score * 0.7 + 0.3, 1.0)),
        resource: max(0.0, min(success_score * 0.75 + 0.25, 1.0))
      },
      occurred_at: :erlang.unique_integer([:positive]),
      evidence_hash: :crypto.hash(:sha256, evidence_raw) |> Base.encode16(case: :lower)
    }
    {:ok, outcome}
  end

  def score(outcome) do
    dims = Map.get(outcome, :dimensions, %{})
    values = Map.values(dims)
    overall = if values == [], do: 0.0, else: Enum.sum(values) / length(values)
    {:ok, %{
      mission: Map.get(dims, :mission, 0.0),
      scientific: Map.get(dims, :scientific, 0.0),
      operational: Map.get(dims, :operational, 0.0),
      temporal: Map.get(dims, :temporal, 0.0),
      resource: Map.get(dims, :resource, 0.0),
      overall: overall,
      success_score: Map.get(outcome, :success_score, 0.0)
    }}
  end

  def compare(outcomes) do
    scores = Enum.map(outcomes, fn o -> Map.get(o, :success_score, 0.0) end)
    sorted = Enum.sort(scores)
    best = List.last(sorted) || 0.0
    worst = List.first(sorted) || 0.0
    avg = if scores == [], do: 0.0, else: Enum.sum(scores) / length(scores)
    trend = cond do
      length(scores) < 3 -> :insufficient
      scores == Enum.sort(scores) -> :improving
      scores == Enum.reverse(Enum.sort(scores)) -> :declining
      best == worst -> :stable
      true -> :fluctuating
    end
    {:ok, %{best: best, worst: worst, average: avg, trend: trend, count: length(scores)}}
  end

  def summarize(outcome) do
    score = Map.get(outcome, :success_score, 0.0)
    status = Map.get(outcome, :status, :unknown)
    {:ok, "Outcome #{Map.get(outcome, :id)}: #{status} (score: #{Float.round(score, 3)})"}
  end
end
