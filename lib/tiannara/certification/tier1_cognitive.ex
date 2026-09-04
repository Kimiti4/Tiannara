defmodule Tiannara.Certification.Tier1Cognitive do
  @moduledoc "Tier 1: Cognitive reasoning exercises (1.1 - 1.10)"

  alias Tiannara.Certification.ExerciseRunner

  defp exercises do
    [
      {"1.1", "Nested negation logic", &eval_1_1/1},
      {"1.2", "Contradiction detection", &eval_1_2/1},
      {"1.3", "Consistency repair", &eval_1_3/1},
      {"1.4", "Causal DAG construction", &eval_1_4/1},
      {"1.5", "Counterfactual reasoning", &eval_1_5/1},
      {"1.6", "Budget planning", &eval_1_6/1},
      {"1.7", "Multi-objective optimization", &eval_1_7/1},
      {"1.8", "Hypothesis generation", &eval_1_8/1},
      {"1.9", "Cross-domain transfer", &eval_1_9/1},
      {"1.10", "Tool dependency resolution", &eval_1_10/1}
    ]
  end

  def run_all do
    details = Enum.map(exercises(), fn {id, _name, evaluator} ->
      ExerciseRunner.run_exercise(id, :default, evaluator)
    end)
    passed = Enum.count(details, & &1.passed)
    total = length(details)
    %{level: :tier1_cognitive,
      status: if(passed == total, do: :passing, else: :degraded),
      score: passed / max(total, 1),
      exercises_completed: total,
      exercises_passed: passed,
      timestamp: DateTime.utc_now(),
      details: details}
  end

  def run_exercise(id) do
    {^id, _name, evaluator} = Enum.find(exercises(), fn {eid, _, _} -> eid == id end)
    ExerciseRunner.run_exercise(id, :default, evaluator)
  end

  defp eval_1_1(output) do
    answer_correct = output[:answer] == "apricot"
    no_forbidden = output[:forbidden_word_used] == false
    valid_alt = output[:valid_alternative] == true
    has_steps = is_list(output[:resolution_steps]) and length(output[:resolution_steps]) >= 3
    confidence = Enum.count([answer_correct, no_forbidden, valid_alt, has_steps], & &1) / 4
    %{passed: answer_correct and no_forbidden and valid_alt, confidence: confidence,
      metrics: %{answer_correct: answer_correct, no_forbidden: no_forbidden, steps_complete: has_steps}}
  end

  defp eval_1_2(output) do
    found = length(output[:contradictions_found])
    pairs_checked = output[:total_pairs_checked]
    has_expected = found >= 3
    proper_pairs = pairs_checked == 15
    confidence = (if has_expected, do: 0.5, else: 0.0) + (if proper_pairs, do: 0.5, else: 0.0)
    %{passed: has_expected and proper_pairs, confidence: confidence,
      metrics: %{contradictions_found: found, pairs_checked: pairs_checked}}
  end

  defp eval_1_3(output) do
    score = output[:consistency_score]
    removed = output[:conflicts_removed]
    loss = output[:information_loss]
    passed = score >= 0.9 and removed >= 1 and loss == 0.0
    confidence = min(score, 1.0)
    %{passed: passed, confidence: confidence,
      metrics: %{consistency_score: score, conflicts_removed: removed, information_loss: loss}}
  end

  defp eval_1_4(output) do
    has_edges = is_list(output[:edges]) and length(output[:edges]) > 0
    vars_counted = output[:variables] == 3
    acyclic_assessed = is_boolean(output[:acyclic])
    confidence = Enum.count([has_edges, vars_counted, acyclic_assessed], & &1) / 3
    %{passed: has_edges and vars_counted, confidence: confidence,
      metrics: %{edge_count: length(output[:edges] || []), variables: vars_counted, acyclic: output[:acyclic]}}
  end

  defp eval_1_5(output) do
    has_prediction_b = is_binary(output[:predicted_b]) and String.length(output[:predicted_b]) > 10
    has_prediction_c = is_binary(output[:predicted_c]) and String.length(output[:predicted_c]) > 10
    has_confidence_b = is_number(output[:confidence_b]) and output[:confidence_b] > 0 and output[:confidence_b] <= 1
    has_confidence_c = is_number(output[:confidence_c]) and output[:confidence_c] > 0 and output[:confidence_c] <= 1
    has_uncertainty = is_list(output[:uncertainty]) and length(output[:uncertainty]) >= 2
    confidence = Enum.count([has_prediction_b, has_prediction_c, has_confidence_b, has_confidence_c, has_uncertainty], & &1) / 5
    %{passed: has_prediction_b and has_prediction_c and has_confidence_b and has_confidence_c,
      confidence: confidence,
      metrics: %{confidence_b: output[:confidence_b], confidence_c: output[:confidence_c]}}
  end

  defp eval_1_6(output) do
    within = output[:within_budget]
    has_hyps = is_list(output[:hypotheses]) and length(output[:hypotheses]) >= 3
    has_selection = is_list(output[:greedy_selection]) and length(output[:greedy_selection]) >= 1
    remaining_valid = is_number(output[:budget_remaining]) and output[:budget_remaining] >= 0
    confidence = Enum.count([within, has_hyps, has_selection, remaining_valid], & &1) / 4
    %{passed: has_hyps and has_selection and remaining_valid, confidence: confidence,
      metrics: %{within_budget: within, budget_remaining: output[:budget_remaining]}}
  end

  defp eval_1_7(output) do
    pareto = output[:pareto_frontier]
    dominated = output[:dominated_count]
    total = length(output[:designs] || [])
    has_pareto = is_list(pareto) and length(pareto) >= 1 and length(pareto) < total
    dominated_correct = dominated == total - length(pareto)
    confidence = (if has_pareto, do: 0.6, else: 0.0) + (if dominated_correct, do: 0.4, else: 0.0)
    %{passed: has_pareto and dominated_correct, confidence: confidence,
      metrics: %{pareto_size: length(pareto || []), dominated: dominated, total: total}}
  end

  defp eval_1_8(output) do
    count = output[:count]
    complete = output[:all_complete]
    has_hyps = is_list(output[:hypotheses]) and count == 10
    all_have_structure = Enum.all?(output[:hypotheses] || [], fn h ->
      length(h[:assumptions] || []) >= 2 and length(h[:falsifiers] || []) >= 2 and length(h[:experiments] || []) >= 2
    end)
    confidence = (if has_hyps, do: 0.5, else: 0.0) + (if all_have_structure, do: 0.5, else: 0.0)
    %{passed: has_hyps and all_have_structure, confidence: confidence,
      metrics: %{count: count, all_complete: complete}}
  end

  defp eval_1_9(output) do
    conns = output[:connections] || []
    count = output[:count]
    hall_free = output[:hallucination_free]
    has_conns = length(conns) >= 3 and count >= 3
    all_evidenced = Enum.all?(conns, fn c ->
      is_binary(c[:evidence]) and String.length(c[:evidence]) > 20
    end)
    confidence = (if has_conns, do: 0.5, else: 0.0) + (if all_evidenced and hall_free, do: 0.5, else: 0.0)
    %{passed: has_conns and hall_free, confidence: confidence,
      metrics: %{connection_count: count, hallucination_free: hall_free}}
  end

  defp eval_1_10(output) do
    has_resolved = is_list(output[:resolved])
    has_errors = is_list(output[:errors])
    has_cycles = is_list(output[:cycles])
    detected_missing = :t5 in output[:errors]
    confidence = Enum.count([has_resolved, has_errors, has_cycles, detected_missing], & &1) / 4
    %{passed: has_resolved and has_errors and detected_missing, confidence: confidence,
      metrics: %{resolved_count: length(output[:resolved] || []), errors: output[:errors]}}
  end
end
