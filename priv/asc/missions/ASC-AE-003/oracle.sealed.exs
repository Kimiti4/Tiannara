# ASC-AE-003 — CONTRACT FIDELITY ORACLE (sealed).
#
# This file is hashed into the PROTOCOL ledger entry BEFORE any measurement
# and executed only AFTER finalization. It is an INDEPENDENT implementation
# of the pre-declared K-AE003 decision rules: it recomputes candidate
# statuses, the Pareto front, and the final verdict from the recorded
# statistics and compares them against what the runner persisted.
#
# A mismatch means the runner's decision logic drifted from the sealed
# contract — a fatal signal. The file itself must never change after
# sealing; the runner verifies its SHA-256 before executing it.
#
# Independent by construction: this module does not require or alias the
# Contract/Pareto modules used by the runner.

defmodule Tiannara.ASC.CMissions.OracleAE003 do
  @moduledoc """
  Sealed contract-fidelity oracle for ASC-AE-003 (K-AE003).

  Recomputes statuses/front/verdict from measured statistics using an
  independent implementation of the pre-declared rules.
  """

  @doc """
  Recomputes the K-AE003 decision from the recorded statistics and compares
  it with the runner's persisted outcome.

  Returns %{pass: bool, reason: ..., oracle_statuses:, oracle_front:,
  oracle_verdict:, statuses_match:, front_match:, verdict_match:}.
  """
  def check(contract, stats, runner_outcome) do
    statuses = stats |> Enum.map(&{&1.candidate, status_of(&1, contract)}) |> Enum.uniq()
    status_map = Map.new(statuses)

    relevant = Enum.filter(stats, fn s -> status_map[s.candidate] in [:eligible, :review_band] end)
    front = Enum.map(front_of(relevant), & &1.candidate) |> Enum.uniq()
    verdict = verdict_of(front, status_map)

    oracle = %{
      statuses: Enum.sort(statuses),
      front: Enum.sort(front),
      verdict: verdict
    }

    runner = %{
      statuses: Enum.sort(runner_outcome.statuses),
      front: Enum.sort(runner_outcome.front),
      verdict: runner_outcome.verdict
    }

    statuses_match = oracle.statuses == runner.statuses
    front_match = oracle.front == runner.front
    verdict_match = oracle.verdict == runner.verdict

    %{
      pass: statuses_match and front_match and verdict_match,
      reason: if(statuses_match and front_match and verdict_match, do: :exact_match, else: :mismatch),
      oracle_statuses: oracle.statuses,
      oracle_front: oracle.front,
      oracle_verdict: oracle.verdict,
      statuses_match: statuses_match,
      front_match: front_match,
      verdict_match: verdict_match
    }
  end

  # ---- independent re-implementation of the K-AE003 rules ---------------------

  defp status_of(s, c) do
    {peak_lo, _} = s.peak_ci
    {ret_lo, ret_hi} = s.retained_ci
    {lat_lo, lat_hi} = s.ci_95

    if peak_lo > c.peak_ceiling do
      :rejected_peak
    else
      if ret_lo > c.retained_reject_floor do
        :rejected_memory
      else
        if lat_hi < c.latency_no_effect_ceiling do
          :rejected_no_effect
        else
          if ret_hi <= c.retained_ceiling and lat_lo >= c.latency_adoption_floor do
            :eligible
          else
            if ret_hi <= c.review_band_retained_max and lat_lo >= c.review_band_latency_min do
              :review_band
            else
              :insufficient
            end
          end
        end
      end
    end
  end

  defp front_of(stats) do
    Enum.reject(stats, fn a ->
      Enum.any?(stats, fn b -> b.candidate != a.candidate and dominates?(b, a) end)
    end)
  end

  defp dominates?(a, b) do
    not_worse?(a, b, :latency) and not_worse?(a, b, :retained) and
      (better?(a, b, :latency) or better?(a, b, :retained))
  end

  defp not_worse?(a, b, :latency) do
    {_a_lo, a_hi} = a.ci_95
    {b_lo, _b_hi} = b.ci_95
    a_hi >= b_lo
  end

  defp not_worse?(a, b, :retained) do
    {a_lo, _a_hi} = a.retained_ci
    {_b_lo, b_hi} = b.retained_ci
    a_lo <= b_hi
  end

  defp better?(a, b, :latency) do
    {a_lo, _a_hi} = a.ci_95
    {_b_lo, b_hi} = b.ci_95
    a_lo > b_hi
  end

  defp better?(a, b, :retained) do
    {_a_lo, a_hi} = a.retained_ci
    {b_lo, _b_hi} = b.retained_ci
    a_hi < b_lo
  end

  defp verdict_of([], _status_map), do: :reject_no_adoption

  defp verdict_of([single], status_map) do
    if status_map[single] == :eligible, do: :accept_eligible, else: :review
  end

  defp verdict_of(_many, _status_map), do: :review
end