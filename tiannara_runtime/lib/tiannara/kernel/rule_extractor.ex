defmodule Tiannara.Kernel.RuleExtractor do
  @moduledoc """
  Extracts active runtime configurations into rule ASTs with standard preservation invariants.
  """

  @required_invariants [
    :causal_conservation,
    :observer_safety,
    :entropy_non_decrease,
    :psi_stability_bound
  ]

  @spec extract(active_rules :: map()) :: {:ok, map()} | {:error, String.t()}
  def extract(active_rules) do
    try do
      extracted = Map.new(active_rules, fn {subsystem, config} ->
        {subsystem, to_rule_ast(subsystem, config)}
      end)
      {:ok, extracted}
    rescue
      e -> {:error, "Rule extraction failed: #{inspect(e)}"}
    end
  end

  defp to_rule_ast(:omce, %{compression_strategy: strategy, threshold: t}) do
    %{
      type: :compression_policy,
      body: {:if, {:>, :ontology_density, t}, {:apply, strategy, [:aggressive]}, {:apply, strategy, [:conservative]}},
      invariants: @required_invariants
    }
  end

  defp to_rule_ast(:olef, %{diffusion_rate: rate, pressure_cap: cap}) do
    %{
      type: :diffusion_policy,
      body: {:diffuse, :pressure_field, rate, {:cap, cap}},
      invariants: @required_invariants
    }
  end

  defp to_rule_ast(:hsv, %{curvature_threshold: c_t, archive_retention_ms: ret}) do
    %{
      type: :horizon_gc_policy,
      body: {:if, {:>, :curvature_stress, c_t}, {:archive, ret}, :ignore},
      invariants: @required_invariants
    }
  end

  defp to_rule_ast(:ctl, %{stress_threshold: s_t, reconciliation_budget: b}) do
    %{
      type: :causal_lattice_policy,
      body: {:if, {:>, :causal_stress, s_t}, {:fork, b}, :reconcile},
      invariants: @required_invariants
    }
  end

  defp to_rule_ast(_subsystem, config) do
    # Fallback mapper for remaining subsystems
    %{
      type: :generic_policy,
      body: {:apply, :default, [config]},
      invariants: @required_invariants
    }
  end
end
