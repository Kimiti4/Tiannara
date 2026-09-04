defmodule Tiannara.Discovery.Validation.EvidenceAuditor do
  alias Tiannara.Discovery.Discovery

  @spec audit(Discovery.t()) :: {float(), [map()]}
  def audit(%Discovery{} = disc) do
    findings = []

    {source_score, source_findings} = audit_source_diversity(disc)
    findings = findings ++ source_findings

    {independence_score, independence_findings} = audit_independence(disc)
    findings = findings ++ independence_findings

    {completeness_score, completeness_findings} = audit_completeness(disc)
    findings = findings ++ completeness_findings

    {consistency_score, consistency_findings} = audit_consistency(disc)
    findings = findings ++ consistency_findings

    {temporal_score, temporal_findings} = audit_temporal_validity(disc)
    findings = findings ++ temporal_findings

    overall = (
      source_score * 0.20 +
      independence_score * 0.25 +
      completeness_score * 0.20 +
      consistency_score * 0.20 +
      temporal_score * 0.15
    )

    {overall, findings}
  end

  @doc """
  Audits the integrity of an evidence chain, ensuring each link references
  the previous one and no gaps exist.
  """
  def audit_chain(evidence_list) when is_list(evidence_list) do
    sorted = Enum.sort_by(evidence_list, &Map.get(&1, :timestamp, DateTime.utc_now()), DateTime)
    {integrity, gaps} =
      Enum.reduce(sorted, {true, 0}, fn item, {ok, gaps} ->
        parent_id = Map.get(item, :parent_evidence_id)
        if parent_id != nil and not Enum.any?(sorted, &(&1.id == parent_id)) do
          {false, gaps + 1}
        else
          {ok, gaps}
        end
      end)
    %{chain_integrity: integrity, gaps: gaps, total_links: length(evidence_list)}
  end

  def audit_chain(_), do: %{chain_integrity: false, gaps: 0, total_links: 0}

  defp audit_source_diversity(%Discovery{evidence: evidence}) do
    sources = evidence
      |> Enum.flat_map(fn r -> Enum.map(r.evidence, &Map.get(&1, :source, :unknown)) end)
      |> Enum.uniq()

    score = min(1.0, length(sources) / 3.0)
    findings = if length(sources) < 2, do: [%{type: :low_source_diversity, detail: "Only #{length(sources)} unique evidence sources", sources: sources}], else: []
    {score, findings}
  end

  defp audit_independence(%Discovery{evidence: evidence}) do
    experiment_ids = Enum.map(evidence, & &1.experiment_id)
    unique_experiments = Enum.uniq(experiment_ids)
    score = if experiment_ids == [], do: 0.0, else: length(unique_experiments) / length(experiment_ids)
    findings = if score < 0.5 and length(evidence) > 2, do: [%{type: :low_independence, detail: "Evidence items share experiments (#{length(unique_experiments)}/#{length(experiment_ids)} unique)"}], else: []
    {score, findings}
  end

  defp audit_completeness(%Discovery{evidence: evidence, experiments: experiments}) do
    exp_count = length(experiments)
    ev_count = length(evidence)
    score = cond do
      exp_count == 0 -> 0.0
      ev_count == 0 -> 0.0
      true -> min(1.0, ev_count / max(1, exp_count))
    end
    findings = if ev_count < 3, do: [%{type: :insufficient_evidence, detail: "Only #{ev_count} evidence items (minimum 3 recommended)"}], else: []
    {score, findings}
  end

  defp audit_consistency(%Discovery{evidence: evidence}) do
    outcomes = Enum.map(evidence, & &1.outcome)
    if outcomes == [] do
      {0.0, [%{type: :no_evidence, detail: "No evidence to assess consistency"}]}
    else
      confirmed = Enum.count(outcomes, &(&1 == :confirmed))
      refuted = Enum.count(outcomes, &(&1 == :refuted))
      majority = max(confirmed, refuted)
      score = majority / length(outcomes)
      findings = if score < 0.6, do: [%{type: :inconsistent_evidence, detail: "Evidence is inconsistent (#{confirmed} confirmed, #{refuted} refuted out of #{length(outcomes)})"}], else: []
      {score, findings}
    end
  end

  defp audit_temporal_validity(%Discovery{evidence: evidence}) do
    now = DateTime.utc_now()
    max_age_days = 365
    {recent, stale} = Enum.split_with(evidence, fn r ->
      case r.completed_at do
        nil -> true
        ts -> DateTime.diff(now, ts, :day) <= max_age_days
      end
    end)
    score = if evidence == [], do: 0.0, else: length(recent) / length(evidence)
    findings = if length(stale) > 0, do: [%{type: :stale_evidence, detail: "#{length(stale)} evidence items older than #{max_age_days} days"}], else: []
    {score, findings}
  end
end
