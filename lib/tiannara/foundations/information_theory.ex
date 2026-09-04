defmodule Tiannara.Foundations.InformationTheory do
  @moduledoc """
  The foundational substrate for entropy, uncertainty, and information gain.
  Pure functions. No state. No beliefs.
  """

  @doc "Calculates Shannon Entropy: H(X) = -Σ p(x) log2 p(x)"
  def shannon_entropy(probabilities) when is_list(probabilities) do
    probabilities
    |> Enum.filter(&(&1 > 0))
    |> Enum.reduce(0.0, fn p, acc -> acc - (p * :math.log2(p)) end)
  end

  @doc "Calculates Kullback-Leibler Divergence: D_KL(P || Q)"
  def kl_divergence(dist_p, dist_q) do
    Enum.zip(dist_p, dist_q)
    |> Enum.reduce(0.0, fn {p, q}, acc ->
      if p > 0 and q > 0, do: acc + p * :math.log2(p / q), else: acc
    end)
  end
end
