defmodule Tiannara.OSE.EntropyAllocator do
  @moduledoc """
  Ontological Selection Ecology: Entropy Allocator.
  
  Implements the entropy-preserving allocation rule:
  B_i = α(Stability) + β(Novelty) + γ(Rediscoverability) - δ(ComputeCost)
  """

  require Logger

  @alpha 1.5
  @beta 2.0
  @gamma 1.0
  @delta 0.5

  @doc """
  Distributes thermodynamic budget across universes based on the allocation equation.
  """
  def allocate_budget(battlefield, evaluated_universes) do
    Logger.info("💰 [OSE] Allocating thermodynamic budget (Entropy-Preserving Distribution)...")
    
    # Calculate scores
    scored = Enum.map(evaluated_universes, fn u ->
      stability = Map.get(u.stress_metrics, :survivability, 0.0)
      novelty = calculate_novelty(u, evaluated_universes -- [u])
      rediscoverability = calculate_rediscoverability(u)
      compute_cost = calculate_compute_cost(u)
      
      allocation = (@alpha * stability) + (@beta * novelty) + (@gamma * rediscoverability) - (@delta * compute_cost)
      allocation = max(5.0, allocation) # minimum baseline
      
      Logger.debug("💰 [OSE] #{u.id} | Allocation: #{Float.round(allocation, 2)} (S:#{Float.round(stability, 1)}, N:#{Float.round(novelty, 1)}, R:#{Float.round(rediscoverability, 1)}, C:#{Float.round(compute_cost, 1)})")
      
      Map.put(u, :budget, allocation)
    end)
    
    %{battlefield | active_universes: scored}
  end

  defp calculate_novelty(universe, others) do
    # Novelty is high if this universe uses primitives no one else does
    unique_prims = Enum.count(universe.causal_primitives, fn p ->
      Enum.all?(others, fn o -> p not in o.causal_primitives end)
    end)
    unique_prims * 15.0
  end

  defp calculate_rediscoverability(universe) do
    # Deterministic and linear systems are easier to independently reconstruct
    base = 10.0
    bonus = if universe.interaction_rules == :deterministic, do: 20.0, else: 0.0
    base + bonus
  end

  defp calculate_compute_cost(universe) do
    # Quantum entanglement and dimensional compression are expensive
    cost = length(universe.causal_primitives) * 5.0
    cost = if :quantum_entanglement in universe.causal_primitives, do: cost + 30.0, else: cost
    cost = if :dimensional_compression in universe.causal_primitives, do: cost + 25.0, else: cost
    cost
  end
end
