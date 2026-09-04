defmodule Tiannara.ASC.Constitution do
  @moduledoc """
  Phase 9.1: The Civilizational Constitution.
  Defines Goals, Modes, and the universal Value Formula that gates all action.
  """

  defmodule Goal do
    defstruct [
      :id,
      :objective,
      :success_metric,
      :target_value,
      :compute_budget,
      :deadline_epochs,
      mode: :mission,       # :mission (execute) | :exploration (research)
      status: :active       # :active | :achieved | :failed | :aborted
    ]
  end

  @doc """
  The Universal Value Formula.
  Value = (Alignment + Utility + InfoGain) - (Complexity + Compute + Risk)
  If Value <= 0, the action is forbidden.
  """
  def evaluate_value(action_proposal, %Goal{} = goal, _context) do
    alignment = calculate_alignment(action_proposal, goal)
    do_evaluate(action_proposal, alignment)
  end

  def evaluate_value(action_proposal, _goal, _context) do
    do_evaluate(action_proposal, 0.0)
  end

  defp do_evaluate(action_proposal, alignment) do
    utility = Map.get(action_proposal, :expected_utility, 0.0)
    info_gain = Map.get(action_proposal, :info_gain, 0.0)

    complexity = Map.get(action_proposal, :complexity_cost, 0.0)
    compute = Map.get(action_proposal, :compute_cost, 0.0)
    risk = Map.get(action_proposal, :risk_factor, 0.0)

    value = (alignment + utility + info_gain) - (complexity + compute + risk)

    if value <= 0.0 do
      {:reject, "Value Formula <= 0 (Score: #{Float.round(value, 2)}). Action forbidden."}
    else
      {:approve, value}
    end
  end

  defp calculate_alignment(action, goal) do
    # Heuristic alignment: Does the action's target domain match the goal's objective?
    action_domain = Map.get(action, :domain, :unknown)
    
    cond do
      String.contains?(goal.objective, Atom.to_string(action_domain)) -> 1.0
      action_domain == :general_refactor -> 0.2 # Low alignment for generic refactors
      true -> 0.0
    end
  end
end
