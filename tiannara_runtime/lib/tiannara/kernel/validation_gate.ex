defmodule Tiannara.Kernel.ValidationGate do
  @moduledoc """
  Ensures that evolved/mutated rule ASTs preserve core invariants and do not expose substrate internals.
  """

  @required_invariants [
    :causal_conservation,
    :observer_safety,
    :entropy_non_decrease,
    :psi_stability_bound
  ]

  @spec verify(candidate_rules :: map(), stability_threshold :: float()) ::
    {:ok, map()} | {:error, String.t()}
  def verify(candidate_rules, stability_threshold) do
    with :ok <- check_invariants(candidate_rules),
         :ok <- simulate_stability_impact(candidate_rules, stability_threshold),
         :ok <- verify_observer_safety(candidate_rules),
         :ok <- Tiannara.Kernel.CategoryTheoreticValidator.verify(candidate_rules) do
      {:ok, candidate_rules}
    end
  end

  defp check_invariants(rules) do
    invalid = Enum.filter(rules, fn {_key, rule} ->
      not Enum.all?(@required_invariants, &(&1 in rule.invariants))
    end)

    if invalid == [] do
      :ok
    else
      {:error, "Missing required invariants in: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}"}
    end
  end

  defp simulate_stability_impact(rules, threshold) do
    estimated_psi_delta = estimate_psi_impact(rules)

    if estimated_psi_delta > -threshold do
      :ok
    else
      {:error, "Rule mutations would destabilize Ψ below threshold (ΔΨ=#{estimated_psi_delta})"}
    end
  end

  defp estimate_psi_impact(rules) do
    Enum.reduce(rules, 0.0, fn {_key, rule}, acc ->
      criticality = get_subsystem_criticality(rule.type)
      perturbation = measure_rule_perturbation(rule)
      acc + criticality * perturbation
    end)
  end

  defp get_subsystem_criticality(:horizon_gc_policy), do: 2.0
  defp get_subsystem_criticality(:causal_lattice_policy), do: 1.5
  defp get_subsystem_criticality(:diffusion_policy), do: 1.8
  defp get_subsystem_criticality(_), do: 1.0

  defp measure_rule_perturbation(rule) do
    case extract_threshold(rule.body) do
      new_t when is_number(new_t) and new_t > 0 ->
        old_t = get_original_threshold(rule.type)
        -abs(new_t - old_t) / old_t

      _ ->
        0.0
    end
  end

  defp get_original_threshold(:horizon_gc_policy), do: 12.0
  defp get_original_threshold(:causal_lattice_policy), do: 0.75
  defp get_original_threshold(:diffusion_policy), do: 0.05
  defp get_original_threshold(_), do: 0.7

  defp extract_threshold({:if, {:>, _var, t}, _, _}) when is_number(t), do: t
  defp extract_threshold(_), do: nil

  defp verify_observer_safety(rules) do
    unsafe = Enum.filter(rules, fn {_key, rule} ->
      exposes_substrate?(rule.body) or enables_recursion_exploit?(rule.body)
    end)

    if unsafe == [] do
      :ok
    else
      {:error, "Observer safety violation in: #{Enum.map_join(unsafe, ", ", &elem(&1, 0))}"}
    end
  end

  defp exposes_substrate?({:apply, :direct_memory_access, _}), do: true
  defp exposes_substrate?({:apply, :bypass_osl, _}), do: true
  defp exposes_substrate?({op, a, b}) when is_tuple(op) or is_atom(op), do: exposes_substrate?(a) or exposes_substrate?(b)
  defp exposes_substrate?({op, a, b, c}) when is_tuple(op) or is_atom(op), do: exposes_substrate?(a) or exposes_substrate?(b) or exposes_substrate?(c)
  defp exposes_substrate?(_), do: false

  defp enables_recursion_exploit?(body) do
    contains_self_modification?(body) and not has_recursion_guard?(body)
  end

  defp contains_self_modification?({:apply, :modify_rule, _}), do: true
  defp contains_self_modification?({op, a, b}) when is_tuple(op) or is_atom(op), do: contains_self_modification?(a) or contains_self_modification?(b)
  defp contains_self_modification?(_), do: false

  defp has_recursion_guard?(body) do
    contains_termination_condition?(body)
  end

  defp contains_termination_condition?({:if, {:<=, :compilation_depth, _max}, _, _}), do: true
  defp contains_termination_condition?({op, a, b}) when is_tuple(op) or is_atom(op), do: contains_termination_condition?(a) or contains_termination_condition?(b)
  defp contains_termination_condition?(_), do: false
end
