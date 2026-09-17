defmodule TiannaraRuntime.Cognitive.Decision.DecisionMetrics do
  @moduledoc "Phase 18.6 — Tracks decision pipeline metrics"

  def initialize do
    %{decision_count: 0, policy_failures: 0, auth_latencies: [], decision_latencies: [], risk_latencies: [], replay_costs: [], archaeology_costs: [], scores: [], deferred_count: 0, blocked_count: 0, created_at: :erlang.unique_integer([:positive])}
  end

  def record_decision(metrics, score) do
    %{metrics | decision_count: Map.get(metrics, :decision_count, 0) + 1, scores: Map.get(metrics, :scores, []) ++ [score]}
  end

  def record_policy_failure(metrics) do
    %{metrics | policy_failures: Map.get(metrics, :policy_failures, 0) + 1}
  end

  def record_auth_latency(metrics, latency) do
    %{metrics | auth_latencies: Map.get(metrics, :auth_latencies, []) ++ [latency]}
  end

  def summary(metrics) do
    scores = Map.get(metrics, :scores, [])
    auth_lats = Map.get(metrics, :auth_latencies, [])
    avg_score = if scores == [], do: 0.0, else: Enum.sum(scores) / length(scores)
    avg_auth_lat = if auth_lats == [], do: 0.0, else: Enum.sum(auth_lats) / length(auth_lats)
    {:ok, %{decision_count: Map.get(metrics, :decision_count, 0), policy_failures: Map.get(metrics, :policy_failures, 0), total_auth_latencies: length(auth_lats), average_auth_latency: avg_auth_lat, average_score: avg_score, deferred_count: Map.get(metrics, :deferred_count, 0), blocked_count: Map.get(metrics, :blocked_count, 0)}}
  end

  def from_session(session) do
    selected = Map.get(session, :selected)
    score_total = case selected do
      nil -> nil
      _ -> Map.get(Map.get(selected, :score, %{}), :total)
    end
    metrics = initialize()
    metrics = if score_total != nil, do: record_decision(metrics, score_total), else: metrics
    status = Map.get(session, :status)
    metrics = case status do
      :deferred -> %{metrics | deferred_count: 1}
      _ -> metrics
    end
    {:ok, metrics}
  end
end
