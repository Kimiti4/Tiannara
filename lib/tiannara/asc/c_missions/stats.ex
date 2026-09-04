defmodule Tiannara.ASC.CMissions.Stats do
  @moduledoc """
  Statistical decision core for C-missions v2+. Pure, deterministic
  (fixed-seed bootstrap), unit-tested. Tiers:
    :eligible               — CI lower bound >= gate
    :rejected               — CI upper bound <  gate
    :insufficient_evidence  — CI straddles the gate
  """

  def median(list) do
    s = Enum.sort(list)
    n = length(s)

    case rem(n, 2) do
      1 -> Enum.at(s, div(n, 2))
      0 -> (Enum.at(s, div(n, 2) - 1) + Enum.at(s, div(n, 2))) / 2
    end
  end

  def bootstrap_ci(deltas, opts \\ []) do
    iterations = Keyword.get(opts, :iterations, 10_000)
    seed = Keyword.get(opts, :seed, {12_345, 67_890, 24_680})
    alpha = (1 - Keyword.get(opts, :confidence, 0.95)) / 2

    :rand.seed(:exsplus, seed)
    n = length(deltas)
    arr = List.to_tuple(deltas)

    medians =
      for _ <- 1..iterations do
        sample = for _ <- 1..n, do: elem(arr, :rand.uniform(n) - 1)
        median(sample)
      end

    sorted = Enum.sort(medians)

    {Enum.at(sorted, trunc(alpha * iterations)),
     Enum.at(sorted, min(iterations - 1, trunc((1 - alpha) * iterations) - 1))}
  end

  def decide(_median_delta, {ci_low, _ci_high}, gate) when ci_low >= gate, do: :eligible
  def decide(_median_delta, {_ci_low, ci_high}, gate) when ci_high < gate, do: :rejected
  def decide(_median_delta, _ci, _gate), do: :insufficient_evidence

  def rounds_negative(deltas), do: Enum.count(deltas, &(&1 < 0))
end