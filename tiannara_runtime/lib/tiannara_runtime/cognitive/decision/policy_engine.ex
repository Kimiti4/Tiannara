defmodule TiannaraRuntime.Cognitive.Decision.PolicyEngine do
  @moduledoc "Phase 18.6 — Manages constitutional policies"

  def register_policy(state, policy) do
    {:ok, state ++ [policy]}
  end

  def get_policies(state, scope) do
    {:ok, Enum.filter(state, fn p -> Map.get(p, :scope) == scope end)}
  end

  def default_policies do
    [
      %{id: "pol_mission", name: "Mission Alignment", scope: :global, priority: 1, constraints: [%{type: :required_subsystem, value: :mission}], status: :active},
      %{id: "pol_scientific", name: "Scientific Integrity", scope: :research, priority: 2, constraints: [%{type: :min_score, value: 0.3}], status: :active},
      %{id: "pol_safety", name: "System Safety", scope: :global, priority: 0, constraints: [%{type: :forbidden_subsystem, value: :self_modify}, %{type: :max_cost, value: 1.0}], status: :active},
      %{id: "pol_mathematical", name: "Mathematical Soundness", scope: :research, priority: 2, constraints: [%{type: :min_score, value: 0.2}], status: :active},
      %{id: "pol_governance", name: "Governance Compliance", scope: :global, priority: 1, constraints: [%{type: :required_subsystem, value: :governance}], status: :active},
      %{id: "pol_simulation", name: "Simulation Budget", scope: :simulation, priority: 3, constraints: [%{type: :max_cost, value: 0.7}], status: :active},
      %{id: "pol_resource", name: "Resource Efficiency", scope: :system, priority: 2, constraints: [%{type: :max_cost, value: 0.8}], status: :active}
    ]
  end

  def validate_policy(policy) do
    required = [:id, :name, :scope, :priority, :constraints, :status]
    missing = Enum.reject(required, fn k -> Map.has_key?(policy, k) end)
    case missing do
      [] -> :ok
      _ -> {:error, "Missing required keys: #{Enum.join(missing, ", ")}"}
    end
  end
end
