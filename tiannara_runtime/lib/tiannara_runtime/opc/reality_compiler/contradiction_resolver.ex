defmodule Tiannara.OPC.RealityCompiler.ContradictionResolver do
  @moduledoc """
  Contradiction Resolver - Rule Conflict Engine for the Observer Reality Compiler.
  
  Handles conflicts between physics rules that may contradict each other,
  implementing resolution strategies to maintain system consistency.
  """

  defstruct [
    :conflict_resolution_strategy,
    :priority_resolver,
    :consistency_checker
  ]

  alias Tiannara.OPC.IR.PhysicsRule

  @doc """
  Resolves conflicts between potentially contradictory physics rules.
  """
  def resolve_conflicts(rules) when is_list(rules) do
    conflicts = detect_conflicts(rules)
    
    Enum.reduce(conflicts, rules, fn conflict, acc ->
      resolve_single_conflict(conflict, acc)
    end)
  end

  @doc """
  Detects potential conflicts between physics rules.
  """
  def detect_conflicts(rules) do
    rules
    |> Enum.with_index()
    |> Enum.flat_map(fn {rule1, idx1} ->
      rules
      |> Enum.with_index()
      |> Enum.drop(idx1 + 1)
      |> Enum.filter(fn {rule2, _idx2} -> 
        conflicting?(rule1, rule2)
      end)
      |> Enum.map(fn {rule2, idx2} -> 
        {rule1, rule2, idx1, idx2}
      end)
    end)
  end

  @doc """
  Checks if two physics rules conflict with each other.
  """
  def conflicting?(%PhysicsRule{} = rule1, %PhysicsRule{} = rule2) do
    # Two rules conflict if they have overlapping conditions but incompatible effects
    conditions_overlap?(rule1.condition, rule2.condition) and
    effects_conflict?(rule1.effect, rule2.effect)
  end

  defp conditions_overlap?(cond1, cond2) do
    # Check if conditions overlap (same type match or shared invariants)
    Map.get(cond1, :type_match) == Map.get(cond2, :type_match) or
    !MapSet.disjoint?(
      MapSet.new(Map.get(cond1, :invariants, [])),
      MapSet.new(Map.get(cond2, :invariants, []))
    )
  end

  defp effects_conflict?(effect1, effect2) do
    # Check if effects would cause contradictory system modifications
    mscl_conflict?(Map.get(effect1, :mscl_modifier, 0), Map.get(effect2, :mscl_modifier, 0)) or
    olef_conflict?(Map.get(effect1, :olef_pressure_bias, 0), Map.get(effect2, :olef_pressure_bias, 0))
  end

  defp mscl_conflict?(m1, m2) when m1 > 0 and m2 < 0, do: true
  defp mscl_conflict?(m1, m2) when m1 < 0 and m2 > 0, do: true
  defp mscl_conflict?(_, _), do: false

  defp olef_conflict?(o1, o2) when o1 > 0 and o2 < 0, do: true
  defp olef_conflict?(o1, o2) when o1 < 0 and o2 > 0, do: true
  defp olef_conflict?(_, _), do: false

  defp resolve_single_conflict({rule1, rule2, idx1, idx2}, rules) do
    resolved_rule = merge_or_select(rule1, rule2)
    
    # Replace the conflicting rules with the resolved rule
    rules
    |> List.delete_at(idx2)
    |> List.delete_at(idx1)
    |> Kernel.++([resolved_rule])
  end

  defp merge_or_select(rule1, rule2) do
    # Select the rule with higher weight, or merge if they complement each other
    if rule1.weight >= rule2.weight do
      prioritize_rule(rule1, rule2)
    else
      prioritize_rule(rule2, rule1)
    end
  end

  defp prioritize_rule(primary_rule, secondary_rule) do
    # Keep primary rule but adjust if needed based on secondary
    %PhysicsRule{
      primary_rule |
      weight: (primary_rule.weight + secondary_rule.weight) / 2,
      effect: merge_effects(primary_rule.effect, secondary_rule.effect)
    }
  end

  defp merge_effects(effect1, effect2) do
    %{
      mscl_modifier: (Map.get(effect1, :mscl_modifier, 0) + Map.get(effect2, :mscl_modifier, 0)) / 2,
      olef_pressure_bias: (Map.get(effect1, :olef_pressure_bias, 0) + Map.get(effect2, :olef_pressure_bias, 0)) / 2
    }
  end

  @doc """
  Validates that a set of rules maintains consistency.
  """
  def validate_consistency(rules) do
    conflicts = detect_conflicts(rules)
    %{consistent: length(conflicts) == 0, conflicts: conflicts}
  end
end
