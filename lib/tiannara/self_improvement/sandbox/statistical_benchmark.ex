defmodule Tiannara.SelfImprovement.Sandbox.StatisticalBenchmark do
  @moduledoc """
  Statistical benchmarking: run a benchmark N times, compute descriptive
  statistics, and compare baseline vs patched distributions with statistical
  significance rather than a single noisy sample.

  A regression is only flagged when it is:
    * in the worse direction,
    * statistically significant (|t| >= significance threshold, or a definitive
      zero-variance difference), and
    * practically meaningful (relative change > tolerance).

  Constitutional basis: "Evidence Before Confidence", "Never optimize for
  appearing correct", "quantify uncertainty", "Truth has priority over
  confidence."
  """

  defstruct [:direction, :samples, :stats]

  def from_samples(samples, direction) when length(samples) >= 2 do
    %__MODULE__{direction: direction, samples: samples, stats: compute_stats(samples)}
  end

  def compute_stats(samples) do
    n = length(samples)
    mean = Enum.sum(samples) / n

    variance =
      if n > 1,
        do: Enum.sum(Enum.map(samples, fn x -> (x - mean) * (x - mean) end)) / (n - 1),
        else: 0.0

    std_dev = :math.sqrt(variance)
    sorted = Enum.sort(samples)
    se = if n > 0, do: std_dev / :math.sqrt(n), else: 0.0
    ci = 1.96 * se

    %{
      n: n,
      mean: mean,
      variance: variance,
      std_dev: std_dev,
      median: median(sorted),
      min: hd(sorted),
      max: List.last(sorted),
      standard_error: se,
      ci95: {mean - ci, mean + ci}
    }
  end

  defp median(sorted) do
    n = length(sorted)
    mid = div(n, 2)

    if rem(n, 2) == 1,
      do: Enum.at(sorted, mid),
      else: (Enum.at(sorted, mid - 1) + Enum.at(sorted, mid)) / 2
  end

  def compare(%__MODULE__{} = baseline, %__MODULE__{} = patched, opts \\ []) do
    direction = Keyword.get(opts, :direction, baseline.direction)
    significance = Keyword.get(opts, :significance, 2.0)
    tolerance = Keyword.get(opts, :tolerance, 0.0)

    delta = patched.stats.mean - baseline.stats.mean

    se =
      :math.sqrt(
        baseline.stats.variance / baseline.stats.n +
          patched.stats.variance / patched.stats.n
      )


    {t, significant?} =
      cond do
        se > 0 ->
          t = delta / se
          {t, abs(t) >= significance}


        delta != 0.0 ->
          {:infinity, true}

        true ->
          {0.0, false}
      end

    worse? =
      case direction do
        :lower_better -> delta > 0
        :higher_better -> delta < 0
      end

    relative_change =
      if baseline.stats.mean != 0,
        do: abs(delta) / abs(baseline.stats.mean),
        else: 0.0

    practically_meaningful? = relative_change > tolerance
    regressed? = worse? and significant? and practically_meaningful?

    %{
      regressed: regressed?,
      significant: significant?,
      practically_meaningful: practically_meaningful?,
      worse_direction: worse?,
      delta: delta,
      t_statistic: t,
      relative_change: relative_change,
      baseline: baseline.stats,
      patched: patched.stats
    }
  end
end