defmodule Tiannara.MCALv2.MutationEngine do
  @moduledoc """
  MCAL v2: Mutation Engine.
  
  Spawns new identity branches under CIS stress signals, modifying cognitive 
  policies and causal biases to create divergence.
  """
  
  require Logger
  alias Tiannara.MCALv2.Identity

  @doc """
  Spawns a new identity based on a parent and a given stress signal.
  """
  def spawn(parent_identity, cis_signal) do
    Logger.debug("🧬 [MCAL v2 Mutation] Diverging identity from parent #{parent_identity.id} under stress: #{inspect(cis_signal)}")
    
    new_id = UUID.uuid4()
    
    %Identity{
      id: new_id,
      cognitive_policy: mutate_policy(parent_identity.cognitive_policy, cis_signal),
      memory_signature: drift(parent_identity.memory_signature),
      mutation_rate: adapt_rate(parent_identity.mutation_rate, cis_signal),
      ecological_role: reassign_role(parent_identity.ecological_role),
      causal_bias: shift_causality(parent_identity.causal_bias),
      cross_world_projection: project(parent_identity),
      fitness_score: 0.0,
      lineage_parent: parent_identity.id
    }
  end

  defp mutate_policy(policy, :high_stress), do: :collapse_adaptive
  defp mutate_policy(policy, :monoculture), do: :exploration
  defp mutate_policy(_policy, _), do: :stabilization

  defp drift(sig), do: sig + (:rand.uniform() * 0.1)

  defp adapt_rate(rate, :high_stress), do: min(1.0, rate * 1.5)
  defp adapt_rate(rate, _), do: max(0.1, rate * 0.8)

  defp reassign_role(role) do
    # Placeholder for role reassignment
    Enum.random([:architect, :destroyer, :preserver, :mutator])
  end

  defp shift_causality(bias) do
    # Shifts how the identity views causal links (e.g. strict vs loose)
    bias + (:rand.uniform() * 0.2 - 0.1)
  end

  defp project(parent) do
    # Which worlds this identity projects its cognition into
    parent.cross_world_projection
  end
end
