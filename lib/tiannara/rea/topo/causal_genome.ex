defmodule Tiannara.REA.Topo.CausalGenome do
  @moduledoc """
  The topological genome owned by a MetaGenome.
  It maps channel IDs to their specific weights, delays, decays, and toggle states.
  """

  @type t :: %__MODULE__{
    id: binary(),
    topological_plasticity: float(),
    mutation_rate: float(),
    channel_genes: %{binary() => map()},
    novel_proposals: [map()]
  }

  defstruct [
    :id,
    topological_plasticity: 0.05,
    mutation_rate: 0.05,
    channel_genes: %{},
    novel_proposals: []
  ]

  @doc "Generate a random, baseline causal genome."
  def random do
    # Fetch base topology from graph
    base_channels = Tiannara.REA.Causal.Graph.all()
    
    genes = Enum.map(base_channels, fn ch -> 
      {ch.id, %{
        enabled: ch.enabled,
        weight_modifier: 1.0,
        delay_modifier: 0,
        decay_modifier: 1.0,
        mutation_protection: 0.0
      }}
    end) |> Map.new()

    %__MODULE__{
      id: :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower),
      topological_plasticity: 0.05 + (:rand.uniform() * 0.05),
      mutation_rate: 0.05 + (:rand.uniform() * 0.05),
      channel_genes: genes
    }
  end
end
