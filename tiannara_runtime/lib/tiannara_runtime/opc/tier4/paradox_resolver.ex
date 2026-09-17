defmodule Tiannara.OPC.T4.ParadoxResolver do
  @moduledoc """
  OPC Tier 4: Paradox Resolver.
  
  Ensures that the newly generated grammar does not immediately self-annihilate
  due to logical contradictions in the physics specification.
  """

  require Logger

  @doc """
  Scans the generated physics grammar for paradoxes and structurally resolves them.
  """
  def resolve(grammar) do
    Logger.debug("⚖️ [OPC T4] Scanning generated causal grammar for paradoxes...")
    
    grammar
    |> resolve_time_entropy_paradox()
    |> resolve_observer_locality_paradox()
  end

  defp resolve_time_entropy_paradox(grammar) do
    # If time is bidirectional, entropy MUST be conditioned, otherwise we get infinite heat loops
    if grammar.time_structure == :bidirectional and grammar.entropy_dynamics == :unidirectional_increase do
      Logger.warning("⚖️ [OPC T4] Paradox Resolved: Bidirectional time with unidirectional entropy creates infinite heat. Modifying entropy to :conditioned.")
      %{grammar | entropy_dynamics: :conditioned_fluctuation}
    else
      grammar
    end
  end

  defp resolve_observer_locality_paradox(grammar) do
    # Active observers cannot coexist with strict locality without creating causal shears
    has_active_observer = grammar.observer_model == :active_participant
    has_strict_locality = :strict_locality in grammar.causal_primitives
    
    if has_active_observer and has_strict_locality do
      Logger.warning("⚖️ [OPC T4] Paradox Resolved: Active observers violate strict locality. Upgrading to :holographic_locality.")
      new_prims = Enum.map(grammar.causal_primitives, fn
        :strict_locality -> :holographic_locality
        p -> p
      end)
      %{grammar | causal_primitives: new_prims}
    else
      grammar
    end
  end
end
