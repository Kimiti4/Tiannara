defmodule Tiannara.ASC.CMissions.Contract do
  @moduledoc """
  K-AE003 — the pre-declared tradeoff-aware decision contract.

  The contract is authored BEFORE any measurement, hashed into the PROTOCOL
  ledger entry, and the mission must not invent the value function after
  seeing candidate results. Pure decision logic: statuses, Pareto front,
  final verdict. Unit-tested.

  ## Candidate statuses (from measured CIs)

    - `:rejected_peak`       — transient peak CI low > peak_ceiling
    - `:rejected_memory`     — retained CI low > retained_reject_floor
    - `:rejected_no_effect`  — latency CI high < latency_no_effect_ceiling
    - `:eligible`            — retained CI high <= retained_ceiling AND
                               latency CI low >= latency_adoption_floor
    - `:review_band`         — retained CI high <= review_band_retained_max AND
                               latency CI low >= review_band_latency_min
    - `:insufficient`        — everything else

  ## Final decision (over the Pareto front of eligible+review_band)

    - lone :eligible member -> {:accept_eligible, [id]}
    - empty front           -> {:reject_no_adoption, []}
    - otherwise             -> {:review, front_ids} (human review required)
  """

  alias Tiannara.ASC.CMissions.Pareto

  @doc """
  Status of one candidate under the contract thresholds.

  `s` is a per-candidate stat map with `:ci_95`, `:peak_ci`, `:retained_ci`
  (all `{lo, hi}` tuples of relative deltas). `c` is the contract map of
  pre-declared thresholds.
  """
  def candidate_status(s, c) do
    {peak_lo, _peak_hi} = s.peak_ci
    {ret_lo, ret_hi} = s.retained_ci
    {lat_lo, lat_hi} = s.ci_95

    cond do
      peak_lo > c.peak_ceiling ->
        :rejected_peak

      ret_lo > c.retained_reject_floor ->
        :rejected_memory

      lat_hi < c.latency_no_effect_ceiling ->
        :rejected_no_effect

      ret_hi <= c.retained_ceiling and lat_lo >= c.latency_adoption_floor ->
        :eligible

      ret_hi <= c.review_band_retained_max and lat_lo >= c.review_band_latency_min ->
        :review_band

      true ->
        :insufficient
    end
  end

  @doc """
  Final mission decision from per-candidate statused stats.

  Returns `{verdict, front_ids}`. The verdict is one of `:accept_eligible`,
  `:review`, or `:reject_no_adoption`. Adoption (`:accept_eligible`) is only
  ever a recommendation: the human gate still applies.
  """
  def final_decision(statused_stats) do
    relevant = Enum.filter(statused_stats, &(&1.status in [:eligible, :review_band]))
    front = Pareto.front(relevant)
    front_ids = Enum.map(front, & &1.candidate) |> Enum.uniq()

    case front_ids do
      [single] ->
        entry = Enum.find(relevant, &(&1.candidate == single))
        if entry.status == :eligible, do: {:accept_eligible, [single]}, else: {:review, [single]}

      [] ->
        {:reject_no_adoption, []}

      _ ->
        {:review, front_ids}
    end
  end
end