defmodule Tiannara.MemoryGraph do
  @moduledoc """
  The historical memory structure of a civilization.
  Tracks stable lemmas, failed theories, epochs, and myths.
  """
  defstruct [
    :lemmas,               # %{ id => %LemmaNode{} }
    :failed_theories,      # %{ id => %FailedTheory{} }
    :contradictions,
    :cross_field_mappings,
    :historical_epochs,
    :rivalries,
    :alliances,
    :collapse_events,
    :cultural_embeddings,
    :theorem_mythology     # Maps abstract beliefs to irrational persistences
  ]

  defmodule LemmaNode do
    defstruct [
      :id,
      :field,
      :structure_embedding,
      :stability_score,
      :novelty_score,
      :inherited_from,
      :timestamp,
      :importance,   # Used for decay: I = alpha*R + beta*U + gamma*S
      :recency,
      :reuse_count
    ]
  end

  defmodule FailedTheory do
    defstruct [
      :id,
      :assumptions,
      :collapse_reason,
      :entropy_spike,
      :preserved_for_future_analysis
    ]
  end

  defmodule Epoch do
    defstruct [
      :name,
      :dominant_field,
      :discoveries,
      :collapses,
      :entropy_average,
      :duration
    ]
  end

  def new do
    %__MODULE__{
      lemmas: %{},
      failed_theories: %{},
      contradictions: [],
      cross_field_mappings: %{},
      historical_epochs: [],
      rivalries: %{},
      alliances: %{},
      collapse_events: [],
      cultural_embeddings: %{},
      theorem_mythology: %{}
    }
  end

  @doc """
  Consolidates memory using Importance Decay.
  Low importance memories decay. I_t = alpha*R + beta*U + gamma*S
  """
  def consolidate(%__MODULE__{} = graph) do
    alpha = 0.5
    beta = 0.3
    gamma = 0.2

    # Prune low importance lemmas
    updated_lemmas =
      Enum.reduce(graph.lemmas, %{}, fn {id, lemma}, acc ->
        importance = (alpha * lemma.reuse_count) + (beta * lemma.novelty_score) + (gamma * lemma.stability_score)
        
        # Mythology provides irrational persistence!
        myth_boost = Map.get(graph.theorem_mythology, lemma.field, 0.0)
        final_importance = importance + myth_boost

        if final_importance > 0.2 do
          Map.put(acc, id, %{lemma | importance: final_importance})
        else
          # Memory decays/forgotten
          acc
        end
      end)

    %{graph | lemmas: updated_lemmas}
  end
end

defmodule Tiannara.CivilizationRuin do
  @moduledoc """
  Remnants of a collapsed civilization.
  Used to seed future dynasties or be scavenged.
  """
  defstruct [
    :memory_shards,
    :collapsed_theories,
    :residual_biases,
    :entropy_field
  ]
end
