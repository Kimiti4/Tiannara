defmodule Tiannara.Math.Probability do
  require Logger

  @doc "Bayesian update: P(H|E) = (P(E|H) * P(H)) / P(E)"
  def bayes_update(prior, likelihood, evidence_prob) when evidence_prob > 0 do
    start = System.monotonic_time(:microsecond)
    posterior = (likelihood * prior) / evidence_prob
    :telemetry.execute([:tiannara, :math, :operation], %{duration: System.monotonic_time(:microsecond) - start}, %{module: __MODULE__, operation: :bayes_update})
    {:ok, posterior}
  end

  def bayes_update(_, _, _), do: {:error, :evidence_probability_zero}

  @doc "Shannon Entropy: H(X) = -Σ p(x) log2 p(x)"
  def shannon_entropy(probabilities) when is_list(probabilities) do
    start = System.monotonic_time(:microsecond)
    entropy = probabilities |> Enum.filter(&(&1 > 0)) |> Enum.reduce(0.0, fn p, acc -> acc - (p * :math.log2(p)) end)
    :telemetry.execute([:tiannara, :math, :operation], %{duration: System.monotonic_time(:microsecond) - start}, %{module: __MODULE__, operation: :shannon_entropy})
    {:ok, entropy}
  end
end
