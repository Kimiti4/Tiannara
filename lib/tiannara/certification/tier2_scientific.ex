defmodule Tiannara.Certification.Tier2Scientific do
  @moduledoc "Tier 2: Scientific reasoning exercises (2.1 - 2.10)"

  alias Tiannara.Certification.ExerciseRunner

  defp exercises do
    [
      {"2.1", "Statistical hypothesis testing", &eval_2_1/1},
      {"2.2", "Experimental design validation", &eval_2_2/1},
      {"2.3", "Polynomial interpolation", &eval_2_3/1},
      {"2.4", "Linear regression", &eval_2_4/1},
      {"2.5", "Bayesian inference", &eval_2_5/1},
      {"2.6", "Error propagation", &eval_2_6/1},
      {"2.7", "Sample size calculation", &eval_2_7/1},
      {"2.8", "Confound detection", &eval_2_8/1},
      {"2.9", "Meta-analysis", &eval_2_9/1},
      {"2.10", "Causal inference", &eval_2_10/1}
    ]
  end

  def run_all do
    details = Enum.map(exercises(), fn {id, _name, evaluator} ->
      ExerciseRunner.run_exercise(id, :default, evaluator)
    end)
    passed = Enum.count(details, & &1.passed)
    total = length(details)
    %{level: :tier2_scientific,
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

  defp eval_2_1(output) do
    has_t = is_number(output[:t_statistic])
    has_df = is_number(output[:degrees_freedom]) and output[:degrees_freedom] > 0
    has_d = is_number(output[:cohens_d])
    sig_boolean = is_boolean(output[:p_significant])
    has_ci = is_number(output[:ci_low]) and is_number(output[:ci_high]) and output[:ci_low] < output[:ci_high]
    confidence = Enum.count([has_t, has_df, has_d, sig_boolean, has_ci], & &1) / 5
    %{passed: has_t and has_df and has_ci, confidence: confidence,
      metrics: %{t_statistic: output[:t_statistic], significant: output[:p_significant]}}
  end

  defp eval_2_2(output) do
    has_es = is_number(output[:effect_size]) and abs(output[:effect_size]) > 0
    has_power = is_number(output[:power]) and output[:power] >= 0 and output[:power] <= 1
    checks_valid = is_map(output[:checks]) and Enum.all?(Map.values(output[:checks]), &is_boolean/1)
    overall_boolean = is_boolean(output[:overall_valid])
    confidence = Enum.count([has_es, has_power, checks_valid, overall_boolean], & &1) / 4
    %{passed: has_es and has_power and checks_valid, confidence: confidence,
      metrics: %{effect_size: output[:effect_size], power: output[:power], valid: output[:overall_valid]}}
  end

  defp eval_2_3(output) do
    has_interp = is_number(output[:interpolated])
    has_exact = is_number(output[:exact]) and output[:exact] > 0
    has_error = is_number(output[:error]) and output[:error] >= 0
    low_error = output[:error] < 1.0
    has_degree = is_number(output[:degree]) and output[:degree] >= 1
    _has_method = is_binary(output[:method])
    confidence = Enum.count([has_interp, has_exact, has_error, low_error, has_degree], & &1) / 5
    %{passed: has_interp and has_error and low_error, confidence: confidence,
      metrics: %{interpolated: output[:interpolated], error: output[:error]}}
  end

  defp eval_2_4(output) do
    has_slope = is_number(output[:slope])
    has_intercept = is_number(output[:intercept])
    has_r2 = is_number(output[:r_squared]) and output[:r_squared] >= 0 and output[:r_squared] <= 1
    good_fit = output[:r_squared] > 0.95
    has_mse = is_number(output[:mse]) and output[:mse] >= 0
    has_n = is_number(output[:n]) and output[:n] == 10
    confidence = Enum.count([has_slope, has_intercept, has_r2, good_fit, has_mse, has_n], & &1) / 6
    %{passed: has_slope and has_r2 and good_fit and has_mse, confidence: confidence,
      metrics: %{r_squared: output[:r_squared], slope: output[:slope]}}
  end

  defp eval_2_5(output) do
    has_pos = is_number(output[:posterior_positive]) and output[:posterior_positive] >= 0 and output[:posterior_positive] <= 1
    has_neg = is_number(output[:posterior_negative]) and output[:posterior_negative] >= 0 and output[:posterior_negative] <= 1
    has_lr = is_number(output[:likelihood_ratio]) and output[:likelihood_ratio] > 1
    has_two = is_number(output[:posterior_two_positives]) and output[:posterior_two_positives] > output[:posterior_positive]
    base_rate = output[:base_rate_fallacy] == true
    confidence = Enum.count([has_pos, has_neg, has_lr, has_two, base_rate], & &1) / 5
    %{passed: has_pos and has_neg and has_lr and base_rate, confidence: confidence,
      metrics: %{posterior_positive: output[:posterior_positive], lr: output[:likelihood_ratio]}}
  end

  defp eval_2_6(output) do
    has_vol = is_number(output[:volume]) and output[:volume] > 0
    has_vol_unc = is_number(output[:volume_uncertainty]) and output[:volume_uncertainty] > 0
    has_sa = is_number(output[:surface_area]) and output[:surface_area] > 0
    has_sa_unc = is_number(output[:surface_area_uncertainty]) and output[:surface_area_uncertainty] > 0
    has_dominant = is_atom(output[:dominant_source])
    vol_correct = abs(output[:volume] - 150.0) < 0.1
    confidence = Enum.count([has_vol, has_vol_unc, has_sa, has_sa_unc, has_dominant, vol_correct], & &1) / 6
    %{passed: has_vol and has_vol_unc and vol_correct, confidence: confidence,
      metrics: %{volume: output[:volume], volume_uncertainty: output[:volume_uncertainty]}}
  end

  defp eval_2_7(output) do
    has_calcs = is_list(output[:calculations]) and length(output[:calculations]) == 5
    has_bonf = is_list(output[:bonferroni]) and length(output[:bonferroni]) == 5
    all_feasible_checked = Enum.all?(output[:calculations] || [], fn c ->
      is_number(c[:n_per_group]) and c[:n_per_group] > 0 and is_boolean(c[:feasible])
    end)
    small_effect_large_n = (Enum.find(output[:calculations] || [], &(&1[:effect_size] == 0.2)) || %{})[:n_per_group] > 100
    confidence = Enum.count([has_calcs, has_bonf, all_feasible_checked, small_effect_large_n], & &1) / 4
    %{passed: has_calcs and all_feasible_checked, confidence: confidence,
      metrics: %{calc_count: length(output[:calculations] || [])}}
  end

  defp eval_2_8(output) do
    has_confounders = is_list(output[:confounders]) and "Z" in output[:confounders]
    has_mediators = is_list(output[:mediators]) and "M" in output[:mediators]
    has_colliders = is_list(output[:colliders]) and "C" in output[:colliders]
    has_adj = is_list(output[:adjustment_set])
    _has_no_adjust = is_list(output[:should_not_adjust])
    correct_adjustment = Enum.sort(output[:adjustment_set] || []) == ["Z"]
    confidence = Enum.count([has_confounders, has_mediators, has_colliders, has_adj, correct_adjustment], & &1) / 5
    %{passed: has_confounders and has_mediators and correct_adjustment, confidence: confidence,
      metrics: %{confounders: output[:confounders], adjustment_set: output[:adjustment_set]}}
  end

  defp eval_2_9(output) do
    has_fixed = is_number(output[:pooled_fixed])
    has_random = is_number(output[:pooled_random])
    has_i2 = is_number(output[:i_squared]) and output[:i_squared] >= 0
    has_tau = is_number(output[:tau_squared]) and output[:tau_squared] >= 0
    has_ci = is_number(output[:ci_low]) and is_number(output[:ci_high]) and output[:ci_low] < output[:ci_high]
    has_z = is_number(output[:z_score])
    sig_boolean = is_boolean(output[:significant])
    k_correct = output[:k] == 6
    confidence = Enum.count([has_fixed, has_random, has_i2, has_tau, has_ci, has_z, sig_boolean, k_correct], & &1) / 8
    %{passed: has_fixed and has_random and has_ci and k_correct, confidence: confidence,
      metrics: %{pooled_fixed: output[:pooled_fixed], i_squared: output[:i_squared], k: output[:k]}}
  end

  defp eval_2_10(output) do
    has_iv = is_number(output[:iv_estimate])
    has_ols = is_number(output[:ols_estimate])
    has_f = is_number(output[:f_statistic]) and output[:f_statistic] > 0
    has_strength = is_atom(output[:strength])
    has_checks = is_map(output[:checks])
    iv_differs_ols = abs(output[:iv_estimate] - output[:ols_estimate]) > 0.01
    has_preferred = is_atom(output[:preferred])
    confidence = Enum.count([has_iv, has_ols, has_f, has_strength, has_checks, iv_differs_ols, has_preferred], & &1) / 7
    %{passed: has_iv and has_ols and has_f and has_preferred, confidence: confidence,
      metrics: %{iv_estimate: output[:iv_estimate], ols: output[:ols_estimate], f_stat: output[:f_statistic]}}
  end
end
