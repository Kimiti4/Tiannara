defmodule TiannaraRuntime.SelfCompilation.RuleMutator do
  @moduledoc """
  Phase 5F.13: Rule Mutator - Applies Intelligent Modifications to Rules

  Mutates extracted rules based on:
  - Performance feedback from AdaptiveLearner
  - Modification intensity parameter
  - Subsystem-specific mutation strategies
  - Historical compilation success patterns

  Mutation strategies vary by subsystem to ensure domain-appropriate changes.
  """

  @doc """
  Mutate rules based on intensity and learning data.

  ## Parameters
  - rules: Current rule set to mutate
  - subsystem: Target subsystem
  - intensity: Mutation intensity (0.0-1.0)
  - options: Additional mutation options

  ## Returns
  Mutated rule list ready for validation
  """
  def mutate(rules, subsystem, intensity, options \\ %{}) do
    # Get performance feedback for adaptive mutation
    performance_data = get_performance_feedback(subsystem)

    # Apply mutations based on subsystem type
    Enum.map(rules, fn rule ->
      mutate_rule(rule, subsystem, intensity, performance_data, options)
    end)
  end

  defp mutate_rule(rule, subsystem, intensity, performance_data, options) do
    case subsystem do
      :rrg -> mutate_rrg_rule(rule, intensity, performance_data)
      :omce -> mutate_omce_rule(rule, intensity, performance_data)
      :olef -> mutate_olef_rule(rule, intensity, performance_data)
      :opc -> mutate_opc_rule(rule, intensity, performance_data)
    end
  end

  # --- RRG-Specific Mutations ---

  defp mutate_rrg_rule(%{type: :psi_threshold} = rule, intensity, _perf) do
    # Adjust Ψ threshold based on stability trends
    adjustment = calculate_adjustment(intensity, -0.05, 0.05)
    new_value = clamp(rule.value + adjustment, 0.2, 0.5)

    %{rule | value: new_value}
  end

  defp mutate_rrg_rule(%{type: :novelty_injection_max} = rule, intensity, _perf) do
    # Modify novelty injection ceiling
    adjustment = calculate_adjustment(intensity, -0.02, 0.03)
    new_value = clamp(rule.value + adjustment, 0.1, 0.25)

    %{rule | value: new_value}
  end

  defp mutate_rrg_rule(%{type: :recursion_regulation_threshold} = rule, intensity, _perf) do
    # Adjust recursion regulation trigger point
    adjustment = calculate_adjustment(intensity, -0.05, 0.05)
    new_value = clamp(rule.value + adjustment, 0.6, 0.85)

    %{rule | value: new_value}
  end

  defp mutate_rrg_rule(rule, _intensity, _perf), do: rule

  # --- OMCE-Specific Mutations ---

  defp mutate_omce_rule(%{type: :compression_ratio_aggressive} = rule, intensity, _perf) do
    # Adjust aggressive compression ratio
    adjustment = calculate_adjustment(intensity, -0.05, 0.05)
    new_value = clamp(rule.value + adjustment, 0.3, 0.5)

    %{rule | value: new_value}
  end

  defp mutate_omce_rule(%{type: :identity_merge_threshold} = rule, intensity, _perf) do
    # Modify identity merger sensitivity
    adjustment = calculate_adjustment(intensity, -0.03, 0.03)
    new_value = clamp(rule.value + adjustment, 0.8, 0.95)

    %{rule | value: new_value}
  end

  defp mutate_omce_rule(rule, _intensity, _perf), do: rule

  # --- OLEF-Specific Mutations ---

  defp mutate_olef_rule(%{type: :diffusion_rate} = rule, intensity, _perf) do
    # Adjust load diffusion speed
    adjustment = calculate_adjustment(intensity, -0.02, 0.02)
    new_value = clamp(rule.value + adjustment, 0.05, 0.2)

    %{rule | value: new_value}
  end

  defp mutate_olef_rule(%{type: :pressure_equalization_speed} = rule, intensity, _perf) do
    # Modify pressure equalization rate
    adjustment = calculate_adjustment(intensity, -0.01, 0.01)
    new_value = clamp(rule.value + adjustment, 0.02, 0.1)

    %{rule | value: new_value}
  end

  defp mutate_olef_rule(rule, _intensity, _perf), do: rule

  # --- OPC-Specific Mutations ---

  defp mutate_opc_rule(%{type: :ast_optimization_level} = rule, intensity, _perf) do
    # Adjust AST optimization aggressiveness
    adjustment = trunc(calculate_adjustment(intensity, -1, 1))
    new_value = clamp_integer(rule.value + adjustment, 0, 3)

    %{rule | value: new_value}
  end

  defp mutate_opc_rule(%{type: :shader_cache_ttl} = rule, intensity, _perf) do
    # Modify shader cache lifetime
    adjustment = trunc(calculate_adjustment(intensity, -60, 60))
    new_value = clamp_integer(rule.value + adjustment, 60, 600)

    %{rule | value: new_value}
  end

  defp mutate_opc_rule(%{type: :epsilon_shim_budget} = rule, intensity, _perf) do
    # Adjust AOR epsilon budget to reflect MSCL stability
    adjustment = calculate_adjustment(intensity, -0.05, 0.05)
    new_value = clamp(rule.value + adjustment, 0.2, 1.0)

    %{rule | value: new_value}
  end

  defp mutate_opc_rule(rule, _intensity, _perf), do: rule

  # --- Helper Functions ---

  defp calculate_adjustment(intensity, min_delta, max_delta) do
    # Scale adjustment range by intensity
    range = max_delta - min_delta
    scaled_range = range * intensity

    # Random adjustment within scaled range
    min_delta + (:rand.uniform() * scaled_range)
  end

  defp clamp(value, min_val, max_val) do
    value
    |> max(min_val)
    |> min(max_val)
    |> Float.round(4)
  end

  defp clamp_integer(value, min_val, max_val) do
    value
    |> max(min_val)
    |> min(max_val)
  end

  defp get_performance_feedback(_subsystem) do
    # Placeholder: In production, query AdaptiveLearner for performance metrics
    # For now, return empty feedback
    %{}
  end
end
