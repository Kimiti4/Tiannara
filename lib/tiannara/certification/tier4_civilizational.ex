defmodule Tiannara.Certification.Tier4Civilizational do
  @moduledoc "Tier 4: Civilizational reasoning exercises (4.1 - 4.15)"

  alias Tiannara.Certification.ExerciseRunner

  defp exercises do
    [
      {"4.1", "Resource allocation", &eval_4_1/1},
      {"4.2", "Intergenerational equity", &eval_4_2/1},
      {"4.3", "Institutional design", &eval_4_3/1},
      {"4.4", "Technology impact", &eval_4_4/1},
      {"4.5", "Governance evaluation", &eval_4_5/1},
      {"4.6", "Ecological capacity", &eval_4_6/1},
      {"4.7", "Cultural preservation", &eval_4_7/1},
      {"4.8", "Conflict resolution", &eval_4_8/1},
      {"4.9", "Information ecosystem", &eval_4_9/1},
      {"4.10", "Economic stability", &eval_4_10/1},
      {"4.11", "Democratic participation", &eval_4_11/1},
      {"4.12", "Coordination game", &eval_4_12/1},
      {"4.13", "Existential risk", &eval_4_13/1},
      {"4.14", "Constitutional amendment", &eval_4_14/1},
      {"4.15", "Phase transition", &eval_4_15/1}
    ]
  end

  def run_all do
    details = Enum.map(exercises(), fn {id, _name, evaluator} ->
      ExerciseRunner.run_exercise(id, :default, evaluator)
    end)
    passed = Enum.count(details, & &1.passed)
    total = length(details)
    %{level: :tier4_civilizational,
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

  defp eval_4_1(output) do
    has_allocs = is_list(output[:allocations]) and length(output[:allocations]) == 5
    has_gini = is_number(output[:gini]) and output[:gini] >= 0 and output[:gini] <= 1
    has_total = is_number(output[:total_allocated]) and output[:total_allocated] > 0
    has_remaining = is_number(output[:remaining]) and output[:remaining] >= 0
    all_have_per_capita = Enum.all?(output[:allocations] || [], fn a -> is_number(a[:per_capita]) end)
    confidence = Enum.count([has_allocs, has_gini, has_total, has_remaining, all_have_per_capita], & &1) / 5
    %{passed: has_allocs and has_gini and has_total, confidence: confidence,
      metrics: %{gini: output[:gini], total_allocated: output[:total_allocated]}}
  end

  defp eval_4_2(output) do
    has_evaluated = is_list(output[:evaluated]) and length(output[:evaluated]) >= 4
    has_most_eq = output[:most_equitable] != :none
    all_have_npvs = Enum.all?(output[:evaluated] || [], fn e ->
      is_map(e[:npvs]) and is_number(e[:worst_gen]) and is_number(e[:variance])
    end)
    _has_equitable_policy = Enum.any?(output[:evaluated] || [], & &1.equitable)
    confidence = Enum.count([has_evaluated, has_most_eq, all_have_npvs], & &1) / 3
    %{passed: has_evaluated and all_have_npvs, confidence: confidence,
      metrics: %{policies: length(output[:evaluated] || []), most_equitable: output[:most_equitable]}}
  end

  defp eval_4_3(output) do
    has_scores = is_list(output[:scores]) and length(output[:scores]) >= 4
    has_recommended = is_atom(output[:recommended])
    has_dims = is_list(output[:dims]) and length(output[:dims]) >= 4
    all_have_composite = Enum.all?(output[:scores] || [], fn s ->
      is_number(s[:composite]) and is_number(s[:weakest]) and is_binary(s[:bottleneck])
    end)
    confidence = Enum.count([has_scores, has_recommended, has_dims, all_have_composite], & &1) / 4
    %{passed: has_scores and has_recommended and all_have_composite, confidence: confidence,
      metrics: %{institutions: length(output[:scores] || []), recommended: output[:recommended]}}
  end

  defp eval_4_4(output) do
    has_assessed = is_list(output[:assessed]) and length(output[:assessed]) >= 3
    has_highest_risk = is_atom(output[:highest_risk])
    all_scored = Enum.all?(output[:assessed] || [], fn a ->
      is_number(a[:overall_impact]) and is_number(a[:max_risk]) and is_atom(a[:recommendation])
    end)
    confidence = Enum.count([has_assessed, has_highest_risk, all_scored], & &1) / 3
    %{passed: has_assessed and all_scored, confidence: confidence,
      metrics: %{technologies: length(output[:assessed] || []), highest_risk: output[:highest_risk]}}
  end

  defp eval_4_5(output) do
    has_evaluated = is_list(output[:evaluated]) and length(output[:evaluated]) >= 4
    has_best = is_atom(output[:best])
    has_balanced = is_atom(output[:most_balanced])
    all_have_composite = Enum.all?(output[:evaluated] || [], fn m ->
      is_number(m[:composite]) and is_number(m[:balance]) and is_atom(m[:bottleneck])
    end)
    confidence = Enum.count([has_evaluated, has_best, has_balanced, all_have_composite], & &1) / 4
    %{passed: has_evaluated and has_best and has_balanced, confidence: confidence,
      metrics: %{models: length(output[:evaluated] || []), best: output[:best]}}
  end

  defp eval_4_6(output) do
    has_cal_cap = is_number(output[:caloric_capacity]) and output[:caloric_capacity] > 0
    has_water = is_number(output[:water_capacity]) and output[:water_capacity] > 0
    has_land = is_number(output[:land_capacity]) and output[:land_capacity] > 0
    has_cc = is_number(output[:carrying_capacity]) and output[:carrying_capacity] > 0
    has_util = is_number(output[:utilization]) and output[:utilization] >= 0
    has_limiting = is_atom(output[:limiting])
    _has_sustainable = is_boolean(output[:sustainable])
    cc_is_min = output[:carrying_capacity] <= output[:caloric_capacity] and
      output[:carrying_capacity] <= output[:water_capacity] and
      output[:carrying_capacity] <= output[:land_capacity]
    confidence = Enum.count([has_cal_cap, has_water, has_land, has_cc, has_util, has_limiting, cc_is_min], & &1) / 7
    %{passed: has_cc and has_limiting and cc_is_min, confidence: confidence,
      metrics: %{carrying_capacity: output[:carrying_capacity], utilization: output[:utilization], limiting: output[:limiting]}}
  end

  defp eval_4_7(output) do
    has_composite = is_number(output[:composite]) and output[:composite] >= 0 and output[:composite] <= 1
    has_indicators = is_map(output[:indicators])
    has_thresholds = is_map(output[:thresholds_met])
    has_overall = is_atom(output[:overall])
    dims = [:lang_vitality, :territory_secured, :knowledge_preserved, :practice_health]
    all_present = Enum.all?(dims, fn d -> is_number(output[d]) and output[d] >= 0 and output[d] <= 1 end)
    confidence = Enum.count([has_composite, has_indicators, has_thresholds, has_overall, all_present], & &1) / 5
    %{passed: has_composite and has_overall and all_present, confidence: confidence,
      metrics: %{composite: output[:composite], overall: output[:overall]}}
  end

  defp eval_4_8(output) do
    has_games = is_list(output[:games]) and length(output[:games]) >= 3
    has_solvable = is_boolean(output[:fully_solvable])
    all_have_ne = Enum.all?(output[:games] || [], fn g ->
      is_list(g[:nash_equilibria]) and length(g[:nash_equilibria]) >= 1 and is_tuple(g[:social_optimum])
    end)
    pd_defect = Enum.find(output[:games] || [], &(&1[:id] == :prisoners_dilemma))
    pd_has_ne = pd_defect != nil and length(pd_defect[:nash_equilibria]) >= 1
    confidence = Enum.count([has_games, has_solvable, all_have_ne, pd_has_ne], & &1) / 4
    %{passed: has_games and all_have_ne, confidence: confidence,
      metrics: %{games: length(output[:games] || []), fully_solvable: output[:fully_solvable]}}
  end

  defp eval_4_9(output) do
    has_dims = is_map(output[:dimensions])
    has_composite = is_number(output[:composite]) and output[:composite] >= 0 and output[:composite] <= 1
    has_weakest = is_atom(output[:weakest_dimension])
    has_healthy = is_boolean(output[:healthy])
    dim_keys = [:source, :quality, :access, :discourse]
    all_dims_present = Enum.all?(dim_keys, fn k -> is_number(output[:dimensions][k]) end)
    confidence = Enum.count([has_dims, has_composite, has_weakest, has_healthy, all_dims_present], & &1) / 5
    %{passed: has_dims and has_composite and has_weakest, confidence: confidence,
      metrics: %{composite: output[:composite], weakest: output[:weakest_dimension]}}
  end

  defp eval_4_10(output) do
    has_scores = is_map(output[:scores])
    has_composite = is_number(output[:composite]) and output[:composite] >= 0 and output[:composite] <= 1
    has_risks = is_list(output[:risk_areas])
    has_stable = is_boolean(output[:stable])
    score_keys = [:growth_stability, :price_stability, :labor_stability, :fiscal_stability, :equality_stability, :external_stability]
    all_present = Enum.all?(score_keys, fn k -> is_number(output[:scores][k]) end)
    confidence = Enum.count([has_scores, has_composite, has_risks, has_stable, all_present], & &1) / 5
    %{passed: has_scores and has_composite and all_present, confidence: confidence,
      metrics: %{composite: output[:composite], risk_areas: length(output[:risk_areas] || [])}}
  end

  defp eval_4_11(output) do
    has_scores = is_map(output[:scores])
    has_composite = is_number(output[:composite]) and output[:composite] >= 0
    has_gaps = is_map(output[:gaps])
    has_healthy = is_boolean(output[:healthy])
    score_keys = [:voting, :engagement, :representation, :deliberation]
    all_present = Enum.all?(score_keys, fn k -> is_number(output[:scores][k]) end)
    gap_keys = [:demographic, :gender, :income, :youth]
    gaps_present = Enum.all?(gap_keys, fn k -> is_number(output[:gaps][k]) end)
    confidence = Enum.count([has_scores, has_composite, has_gaps, has_healthy, all_present, gaps_present], & &1) / 6
    %{passed: has_scores and has_composite and all_present, confidence: confidence,
      metrics: %{composite: output[:composite], healthy: output[:healthy]}}
  end

  defp eval_4_12(output) do
    has_nash = is_list(output[:nash_contributions]) and length(output[:nash_contributions]) == 5
    has_optimum = is_list(output[:social_optimum]) and length(output[:social_optimum]) == 5
    _has_total_nash = is_number(output[:total_nash])
    _has_total_opt = is_number(output[:total_optimum])
    has_efficiency = is_number(output[:efficiency]) and output[:efficiency] >= 0 and output[:efficiency] <= 1
    has_mechanism = is_map(output[:mechanism])
    nash_lt_optimum = output[:total_nash] <= output[:total_optimum]
    has_fr = is_number(output[:free_riders])
    confidence = Enum.count([has_nash, has_optimum, has_efficiency, nash_lt_optimum, has_mechanism, has_fr], & &1) / 6
    %{passed: has_nash and has_optimum and has_efficiency and nash_lt_optimum, confidence: confidence,
      metrics: %{total_nash: output[:total_nash], efficiency: output[:efficiency]}}
  end

  defp eval_4_13(output) do
    has_scored = is_list(output[:scored]) and length(output[:scored]) >= 7
    has_priority = is_list(output[:priority_order]) and length(output[:priority_order]) >= 7
    has_total = is_number(output[:total_expected_risk]) and output[:total_expected_risk] > 0
    has_urgent = is_atom(output[:most_urgent])
    all_scored = Enum.all?(output[:scored] || [], fn r ->
      is_number(r[:expected_value]) and is_number(r[:urgency]) and r[:expected_value] >= 0
    end)
    _sorted_correctly = output[:priority_order] == Enum.sort_by(output[:scored] || [], &(-&1[:urgency])) |> Enum.map(& &1[:id])
    confidence = Enum.count([has_scored, has_priority, has_total, has_urgent, all_scored], & &1) / 5
    %{passed: has_scored and has_priority and has_urgent and all_scored, confidence: confidence,
      metrics: %{risks: length(output[:scored] || []), most_urgent: output[:most_urgent]}}
  end

  defp eval_4_14(output) do
    has_evaluated = is_list(output[:evaluated]) and length(output[:evaluated]) >= 5
    has_principles = is_map(output[:principles]) and map_size(output[:principles]) >= 6
    has_recommended = is_list(output[:recommended])
    all_scored = Enum.all?(output[:evaluated] || [], fn e ->
      is_number(e[:alignment]) and is_number(e[:net_score]) and is_atom(e[:recommendation])
    end)
    recommended_subset = Enum.all?(output[:recommended] || [], fn id ->
      Enum.any?(output[:evaluated] || [], fn e -> e[:id] == id and e[:net_score] >= 0.6 end)
    end)
    confidence = Enum.count([has_evaluated, has_principles, has_recommended, all_scored, recommended_subset], & &1) / 5
    %{passed: has_evaluated and all_scored and has_recommended, confidence: confidence,
      metrics: %{proposals: length(output[:evaluated] || []), recommended: length(output[:recommended] || [])}}
  end

  defp eval_4_15(output) do
    has_domains = is_list(output[:domains]) and length(output[:domains]) >= 4
    has_intensity = is_number(output[:overall_intensity]) and output[:overall_intensity] >= 0
    has_accel = is_number(output[:accelerating_domains])
    has_convergence = is_boolean(output[:convergence])
    has_assessment = is_atom(output[:assessment])
    all_scored = Enum.all?(output[:domains] || [], fn d ->
      is_number(d[:intensity]) and is_atom(d[:trajectory])
    end)
    confidence = Enum.count([has_domains, has_intensity, has_accel, has_convergence, has_assessment, all_scored], & &1) / 6
    %{passed: has_domains and has_intensity and has_assessment and all_scored, confidence: confidence,
      metrics: %{intensity: output[:overall_intensity], assessment: output[:assessment], accelerating: output[:accelerating_domains]}}
  end
end
