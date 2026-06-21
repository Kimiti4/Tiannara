defmodule Tiannara.OAVL.DiscoveryVerifier do
  @moduledoc """
  Evaluates the structural coherence of a discovery.
  Does not reject it outright; sets `stability` score.
  Unstable discoveries slowly degrade predictive accuracy.
  """

  require Logger

  @doc "Evaluates a discovery and returns a mutated version with updated stability."
  def evaluate(discovery) do
    # In reality, this would perform graph traversal on the World Model to check coherence.
    # For now, we simulate stability based on domain and random chance, or just
    # keep the stability assigned by the DiscoveryEngine but log the evaluation.
    stability = discovery.stability
    
    cond do
      stability < 0.2 ->
        Logger.warn("👁️‍🗨️ [OAVL] Discovery #{discovery.name} is structurally incoherent (Delusional).")
      stability < 0.5 ->
        Logger.info("👁️‍🗨️ [OAVL] Discovery #{discovery.name} has weak coherence.")
      true ->
        Logger.debug("👁️‍🗨️ [OAVL] Discovery #{discovery.name} is coherent.")
    end

    discovery
  end
end
