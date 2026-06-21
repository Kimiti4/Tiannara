defmodule Tiannara.Core.WorldModel.EpistemicGenome do
  @moduledoc """
  Represents a civilization's "Ways of Knowing" - the underlying cognitive evolution
  that dictates how it reasons, learns, and discovers.
  """

  @derive Jason.Encoder
  defstruct [
    empiricism_bias: 0.5,
    abstraction_bias: 0.5,
    contradiction_tolerance: 0.5,
    novelty_seeking: 0.5,
    memory_depth: 0.5,
    exploration_bias: 0.5,
    exploitation_bias: 0.5,
    uncertainty_tolerance: 0.5,
    cooperative_tendency: 0.5,
    formalism_bias: 0.5,
    statistical_reasoning: 0.5,
    causal_reasoning: 0.5
  ]

  @doc "Create a new genome with randomized baseline traits [0.3 - 0.7]."
  def new do
    %__MODULE__{
      empiricism_bias: rand_baseline(),
      abstraction_bias: rand_baseline(),
      contradiction_tolerance: rand_baseline(),
      novelty_seeking: rand_baseline(),
      memory_depth: rand_baseline(),
      exploration_bias: rand_baseline(),
      exploitation_bias: rand_baseline(),
      uncertainty_tolerance: rand_baseline(),
      cooperative_tendency: rand_baseline(),
      formalism_bias: rand_baseline(),
      statistical_reasoning: rand_baseline(),
      causal_reasoning: rand_baseline()
    }
  end

  @doc "Mutate a genome slightly (for reproduction) or heavily (for fission)."
  def mutate(%__MODULE__{} = parent_genome, intensity \\ 0.1) do
    parent_genome
    |> Map.from_struct()
    |> Enum.map(fn {k, v} -> 
      # Shift value by up to +/- intensity, clamped to [0.0, 1.0]
      shift = (:rand.uniform() * 2.0 - 1.0) * intensity
      {k, max(0.0, min(1.0, v + shift))}
    end)
    |> Enum.into(%{})
    |> then(&struct(__MODULE__, &1))
  end

  defp rand_baseline, do: 0.3 + :rand.uniform() * 0.4
end
