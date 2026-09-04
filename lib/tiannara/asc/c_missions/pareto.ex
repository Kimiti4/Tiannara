defmodule Tiannara.ASC.CMissions.Pareto do
  @moduledoc """
  Pareto dominance over the two measured objectives of K-AE003.

  Objectives (per candidate stat `s`):
    - latency improvement   (s.ci_95 = {lo, hi}; higher is better)
    - retained memory delta (s.retained_ci = {lo, hi}; lower is better)

  Rules (pre-declared in the K-AE003 contract):
    - `not_worse?/2` — the candidate's CI is not strictly worse than the
      other's, i.e. the CIs overlap (or the candidate is strictly better).
    - `better?/2`    — the CIs are strictly separated (no overlap).
    - `dominates?/2` — not worse on ALL objectives and better on at least one.
    - `front/1`      — the set of candidates not dominated by any other.
  """

  @type stat :: map()

  @doc "CI-overlap (or strictly better) on latency: a's CI high >= b's CI low."
  def not_worse_latency?(%{ci_95: {_a_lo, a_hi}}, %{ci_95: {b_lo, _b_hi}}) do
    a_hi >= b_lo
  end

  @doc "CI-overlap (or strictly better) on retained: a's CI low <= b's CI high."
  def not_worse_retained?(%{retained_ci: {a_lo, _a_hi}}, %{retained_ci: {_b_lo, b_hi}}) do
    a_lo <= b_hi
  end

  @doc "Strictly separated CIs on latency (a higher than b): a_lo > b_hi."
  def better_latency?(%{ci_95: {a_lo, _a_hi}}, %{ci_95: {_b_lo, b_hi}}) do
    a_lo > b_hi
  end

  @doc "Strictly separated CIs on retained (a lower than b): a_hi < b_lo."
  def better_retained?(%{retained_ci: {_a_lo, a_hi}}, %{retained_ci: {b_lo, _b_hi}}) do
    a_hi < b_lo
  end

  @doc """
  a dominates b: not worse on all objectives and better on at least one.
  """
  def dominates?(a, b) do
    not_worse_latency?(a, b) and not_worse_retained?(a, b) and
      (better_latency?(a, b) or better_retained?(a, b))
  end

  @doc """
  The Pareto front: candidates not dominated by any other candidate.
  Returns the stat maps in input order.
  """
  def front(stats) do
    Enum.filter(stats, fn a ->
      not Enum.any?(stats, fn b ->
        b.candidate != a.candidate and dominates?(b, a)
      end)
    end)
  end
end