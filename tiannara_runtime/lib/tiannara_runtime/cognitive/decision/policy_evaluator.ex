defmodule TiannaraRuntime.Cognitive.Decision.PolicyEvaluator do
  @moduledoc "Phase 18.6 — Evaluates candidates against policies"

  def evaluate(candidate, policies) do
    evaluation_id = "pev_#{:erlang.unique_integer([:positive]) |> abs() |> Integer.to_string()}"
    {passed, failed_blocked} =
      Enum.split_with(policies, fn p ->
        constraints = Map.get(p, :constraints, [])
        Enum.all?(constraints, fn c -> check_constraint(candidate, c) == :pass end)
      end)
    blocked = Enum.filter(failed_blocked, fn p ->
      Enum.any?(Map.get(p, :constraints, []), fn c ->
        check_constraint(candidate, c) != :pass
      end)
    end)
    passed_ids = Enum.map(passed, fn p -> Map.get(p, :id) end)
    failed_ids = Enum.map(failed_blocked, fn p -> Map.get(p, :id) end)
    {:ok, %{passed: passed_ids, failed: failed_ids, warnings: [], blocking: Enum.map(blocked, fn p -> Map.get(p, :id) end), evaluation_id: evaluation_id}}
  end

  def check_constraint(candidate, constraint) do
    case Map.get(constraint, :type) do
      :max_cost ->
        cost = Map.get(candidate, :cost, 0)
        max_val = Map.get(constraint, :value, 1.0)
        if cost <= max_val, do: :pass, else: {:fail, "cost #{cost} exceeds max #{max_val}"}
      :min_score ->
        score = Map.get(candidate, :score, 0)
        min_val = Map.get(constraint, :value, 0)
        if score >= min_val, do: :pass, else: {:fail, "score #{score} below min #{min_val}"}
      :required_subsystem ->
        subsystems = Map.get(candidate, :subsystems, [])
        required = Map.get(constraint, :value)
        if required in subsystems, do: :pass, else: {:fail, "missing required subsystem #{required}"}
      :forbidden_subsystem ->
        subsystems = Map.get(candidate, :subsystems, [])
        forbidden = Map.get(constraint, :value)
        if forbidden not in subsystems, do: :pass, else: {:fail, "uses forbidden subsystem #{forbidden}"}
      _ ->
        :pass
    end
  end

  def summarize(evaluations) do
    passed = Enum.reduce(evaluations, 0, fn e, acc -> acc + length(Map.get(e, :passed, [])) end)
    failed = Enum.reduce(evaluations, 0, fn e, acc -> acc + length(Map.get(e, :failed, [])) end)
    %{total_evaluations: length(evaluations), total_passed: passed, total_failed: failed}
  end
end
