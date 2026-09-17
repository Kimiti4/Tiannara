defmodule TiannaraRuntime.WorldModel.AutonomousResearch.Engines.ResearchMathVerification do
  @moduledoc """
  Phase 17.8.7 — Research Math Verification engine.
  Verifies experiment design correctness, portfolio optimization validity, statistical assumptions,
  symbolic consistency, and computes deterministic fingerprints.
  """

  def verify_experiment(experiment) when is_map(experiment) do
    checks = [
      verify_variables(experiment),
      verify_controls(experiment),
      verify_treatments(experiment),
      verify_statistical_assumptions(experiment)
    ]

    failures = Enum.filter(checks, fn c -> c.status != :pass end)
    details = %{checks: checks, verified: failures == []}

    proof_content =
      checks
      |> Enum.map(fn c -> "#{c.check}:#{c.status}" end)
      |> Enum.join("|")
    proof_hash = :crypto.hash(:sha256, proof_content) |> Base.encode16(case: :lower)

    if failures == [] do
      {:ok, proof_hash, details}
    else
      {:ok, proof_hash, Map.put(details, :warnings, failures)}
    end
  end

  def verify_optimization(portfolio, budget) when is_map(portfolio) do
    allocated = Map.get(portfolio, :allocated_budget, Map.get(portfolio, "allocated_budget", %{}))
    allocated_units = Map.get(allocated, :max_compute_units, Map.get(allocated, "max_compute_units", 0))
    priority_weight = Map.get(allocated, :priority_weight, Map.get(allocated, "priority_weight", 0.0))
    total_experiments = length(Map.get(portfolio, :experiments, Map.get(portfolio, "experiments", [])))

    checks = [
      %{check: :budget_constraint, status: if(allocated_units <= budget, do: :pass, else: :fail),
        allocated: allocated_units, budget: budget},
      %{check: :non_negative_budget, status: if(allocated_units >= 0, do: :pass, else: :fail),
        allocated: allocated_units},
      %{check: :priority_weight_valid, status: if(priority_weight >= 0.0 and priority_weight <= 1.0, do: :pass, else: :fail),
        weight: priority_weight},
      %{check: :has_experiments, status: if(total_experiments > 0, do: :pass, else: :fail),
        experiment_count: total_experiments}
    ]

    failures = Enum.filter(checks, fn c -> c.status != :pass end)

    proof_content =
      checks
      |> Enum.map(fn c -> "#{c.check}:#{c.status}" end)
      |> Enum.join("|")
    proof_hash = :crypto.hash(:sha256, proof_content) |> Base.encode16(case: :lower)

    {:ok, proof_hash, %{checks: checks, valid: failures == [], portfolio_id: Map.get(portfolio, :portfolio_id, Map.get(portfolio, "portfolio_id", nil))}}
  end

  def verify_statistical_assumptions(experiment) when is_map(experiment) do
    sample_size = Map.get(experiment, :sample_size, Map.get(experiment, "sample_size", 30))
    effect_size = Map.get(experiment, :effect_size, Map.get(experiment, "effect_size", 0.3)) |> abs()
    power = Map.get(experiment, :statistical_power, Map.get(experiment, "statistical_power", 0.8))

    normality =
      if sample_size >= 30, do: :pass, else: :warning
    independence = :pass
    sample_size_ok =
      if sample_size >= 10, do: :pass, else: :fail

    min_power = 0.8
    power_ok =
      if power >= min_power, do: :pass, else: :warning

    effect_size_ok =
      if effect_size >= 0.1, do: :pass, else: :warning

    checks = [
      %{check: :normality, status: normality, note: "Central limit theorem applies for n>=30", sample_size: sample_size},
      %{check: :independence, status: independence, note: "Assumed independent observations"},
      %{check: :sample_size, status: sample_size_ok, note: "Minimum sample size check", sample_size: sample_size},
      %{check: :statistical_power, status: power_ok, note: "Power >= 0.8 recommended", power: power},
      %{check: :effect_size, status: effect_size_ok, note: "Effect size >= 0.1 recommended", effect_size: effect_size}
    ]

    overall_status = if Enum.all?(checks, fn c -> c.status == :pass end), do: :pass, else: :warning
    %{check: :statistical_assumptions, status: overall_status, checks: checks}
  end

  def verify_symbolic_consistency(theory) when is_map(theory) do
    equations = Map.get(theory, :equations, Map.get(theory, "equations", []))
    predictions = Map.get(theory, :predictions, Map.get(theory, "predictions", %{}))

    equation_checks =
      Enum.map(equations, fn eq_str ->
        has_equals = String.contains?(eq_str, "=")
        has_variable_left = String.match?(eq_str, ~r/^[a-zA-Z_]+[a-zA-Z0-9_]*\s*=/)
        %{equation: eq_str, has_equals: has_equals, has_variable_left: has_variable_left,
          status: if(has_equals and has_variable_left, do: :pass, else: :fail)}
      end)

    prediction_checks =
      Enum.map(predictions, fn {var, val} ->
        valid_val =
          is_number(val) or is_boolean(val) or
          (is_binary(val) and String.length(val) > 0)
        %{variable: var, value: val, valid: valid_val,
          status: if(valid_val, do: :pass, else: :fail)}
      end)

    all_passing =
      Enum.all?(equation_checks, fn c -> c.status == :pass end) and
      Enum.all?(prediction_checks, fn c -> c.status == :pass end)

    %{check: :symbolic_consistency, status: if(all_passing, do: :pass, else: :fail),
      equation_count: length(equations), prediction_count: map_size(predictions),
      equation_checks: equation_checks, prediction_checks: prediction_checks}
  end

  def fingerprint(artifact) when is_map(artifact) do
    sorted =
      artifact
      |> Map.drop([:fingerprint, :timestamp, :created_at, :updated_at])
      |> Enum.sort_by(fn {k, _} -> to_string(k) end)
      |> Enum.map(fn {k, v} -> "#{k}:#{serialize_value(v)}" end)
      |> Enum.join("|")

    hash = :crypto.hash(:sha256, sorted) |> Base.encode16(case: :lower)
    "fp_" <> hash
  end

  defp verify_variables(experiment) do
    iv_count = length(Map.get(experiment, :independent_variables, Map.get(experiment, "independent_variables", [])))
    dv_count = length(Map.get(experiment, :dependent_variables, Map.get(experiment, "dependent_variables", [])))
    status =
      cond do
        iv_count == 0 and dv_count == 0 -> :fail
        iv_count == 0 -> :warning
        dv_count == 0 -> :warning
        true -> :pass
      end
    %{check: :variables, status: status, independent_count: iv_count, dependent_count: dv_count}
  end

  defp verify_controls(experiment) do
    controls = Map.get(experiment, :control_variables, Map.get(experiment, "control_variables", []))
    status = if is_list(controls) and length(controls) > 0, do: :pass, else: :warning
    %{check: :controls, status: status, control_count: length(controls)}
  end

  defp verify_treatments(experiment) do
    treatments = Map.get(experiment, :treatments, Map.get(experiment, "treatments", []))
    status = if is_list(treatments) and length(treatments) > 0, do: :pass, else: :warning
    %{check: :treatments, status: status, treatment_count: length(treatments)}
  end

  defp serialize_value(v) when is_map(v), do: Jason.encode!(v)
  defp serialize_value(v) when is_list(v), do: Enum.map(v, &serialize_value/1) |> Enum.join(",")
  defp serialize_value(v), do: to_string(v)
end
