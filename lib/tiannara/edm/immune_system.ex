defmodule Tiannara.EDM.ImmuneSystem do
  @moduledoc """
  Defines baseline Epistemic Immune System adaptations as formal Discoveries.
  Civilizations must discover these to combat Epistemic Diseases.
  """
  
  alias Tiannara.Core.WorldModel.Discovery

  @baseline_immune_discoveries [
    %{name: "Peer Review", domain: :methodology, stability: 0.85, complexity_cost: 15},
    %{name: "Replication Science", domain: :methodology, stability: 0.90, complexity_cost: 30},
    %{name: "Contradiction Audits", domain: :cognition, stability: 0.88, complexity_cost: 25},
    %{name: "Adversarial Verification", domain: :governance, stability: 0.92, complexity_cost: 40},
    %{name: "Blind Validation", domain: :methodology, stability: 0.80, complexity_cost: 20}
  ]

  @doc "Returns a randomly sampled immune adaptation discovery."
  def sample_immune_adaptation(civ_id) do
    spec = Enum.random(@baseline_immune_discoveries)
    
    Discovery.new(%{
      id: "immune_#{:crypto.strong_rand_bytes(4) |> Base.encode16()}",
      name: spec.name,
      domain: spec.domain,
      originator_civ_id: civ_id,
      complexity_cost: spec.complexity_cost,
      stability: spec.stability,
      is_immune_adaptation: true
    })
  end
end
