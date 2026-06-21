defmodule Tiannara.ACM.EpistemicDisease do
  @moduledoc """
  EDM (Epistemic Disease Model).
  Certain discoveries are actually cognitive diseases (e.g. Conspiracy Ontology).
  They increase maintenance costs exponentially over time until shed or cured.
  """

  require Logger
  alias Tiannara.Core.WorldModel.Discovery

  @diseases [
    {:conspiracy_ontology, "Conspiracy Ontology"},
    {:circular_logic, "Circular Logic"},
    {:self_sealing_belief, "Self-Sealing Belief System"},
    {:infinite_regression, "Infinite Regression Model"},
    {:cargo_cult_science, "Cargo Cult Science"}
  ]

  @doc "Randomly generate a disease discovery for a civilization."
  def infect(civ_id) do
    {type, name} = Enum.random(@diseases)
    Logger.warn("🦠 [EDM] Civilization #{civ_id} infected with Epistemic Disease: #{name}")
    
    # Diseases look like normal discoveries but have 0 stability and high complexity
    Discovery.new(%{
      id: "disease_#{type}_#{:crypto.strong_rand_bytes(4) |> Base.encode16()}",
      name: name,
      domain: :cognition,
      originator_civ_id: civ_id,
      complexity_cost: 100, # Starts high
      stability: 0.0
    })
  end

  @doc "Worsens the disease if the civilization's genome can't cure it."
  def progress_disease(%Discovery{} = disease, genome) do
    # Can it be cured?
    cured = case disease.name do
      "Conspiracy Ontology" -> genome.empiricism_bias > 0.8
      "Circular Logic" -> genome.formalism_bias > 0.8
      "Self-Sealing Belief System" -> genome.contradiction_tolerance < 0.2
      "Infinite Regression Model" -> genome.abstraction_bias < 0.2
      "Cargo Cult Science" -> genome.causal_reasoning > 0.8
      _ -> false
    end

    if cured do
      {:cured, disease.id}
    else
      # Disease complexity doubles
      new_complexity = disease.complexity_cost * 2
      Logger.debug("🦠 [EDM] #{disease.name} progressing. Maintenance cost increased to #{new_complexity}")
      {:progressed, %{disease | complexity_cost: new_complexity}}
    end
  end
end
