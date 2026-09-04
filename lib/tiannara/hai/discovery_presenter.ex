defmodule Tiannara.HAI.DiscoveryPresenter do
  alias Tiannara.HAI.Domain.DiscoveryPresentation
  alias Tiannara.Discovery.Discovery

  @spec present(Discovery.t()) :: DiscoveryPresentation.t()
  def present(%Discovery{} = disc) do
    DiscoveryPresentation.new(%{
      discovery_id: disc.id, title: build_title(disc),
      abstract: build_abstract(disc), question: disc.question,
      hypotheses: build_hypotheses_section(disc),
      evidence_summary: build_evidence_summary(disc),
      conclusion: build_conclusion(disc),
      confidence: disc.confidence, uncertainty: disc.uncertainty,
      limitations: build_limitations(disc),
      future_work: build_future_work(disc),
      lineage_summary: build_lineage_summary(disc),
      review_status: disc.status
    })
  end

  @spec render_text(DiscoveryPresentation.t()) :: String.t()
  def render_text(%DiscoveryPresentation{} = pres) do
    """
═══════════════════════════════════════════════════════════
#{pres.title}
═══════════════════════════════════════════════════════════

ABSTRACT
────────
#{pres.abstract}

RESEARCH QUESTION
─────────────────
#{pres.question}

HYPOTHESES (#{length(pres.hypotheses)} competing)
──────────
#{Enum.map_join(pres.hypotheses, "\n", fn h -> "  • #{h.statement} (prior: #{Float.round(h.prior, 2)})" end)}

EVIDENCE SUMMARY
────────────────
#{pres.evidence_summary}

CONCLUSION
──────────
#{pres.conclusion}

CONFIDENCE: #{Float.round(pres.confidence, 3)} ± #{Float.round(pres.uncertainty, 3)}

LIMITATIONS
───────────
#{Enum.map_join(pres.limitations, "\n", fn l -> "  • #{l}" end)}

FUTURE WORK
───────────
#{Enum.map_join(pres.future_work, "\n", fn f -> "  • #{f}" end)}

LINEAGE
───────
#{pres.lineage_summary}

STATUS: #{pres.review_status}
Generated: #{pres.generated_at}
═══════════════════════════════════════════════════════════
"""
  end

  defp build_title(%Discovery{} = disc) do
    domain = if disc.gap, do: disc.gap.domain, else: :unknown
    "Autonomous Discovery: #{domain} — #{String.slice(disc.question, 0, 80)}"
  end

  defp build_abstract(%Discovery{} = disc) do
    hyp_count = length(disc.hypotheses)
    exp_count = length(disc.experiments)
    ev_count = length(disc.evidence)
    "This discovery investigated: #{disc.question} " <>
    "#{hyp_count} competing hypotheses were generated and tested through #{exp_count} experiments, " <>
    "yielding #{ev_count} evidence items. " <>
    "Final confidence: #{Float.round(disc.confidence, 2)} (uncertainty: #{Float.round(disc.uncertainty, 2)}). " <>
    "Status: #{disc.status}."
  end

  defp build_hypotheses_section(%Discovery{} = disc) do
    Enum.map(disc.hypotheses, fn hyp ->
      %{id: hyp.id, statement: hyp.statement, prior: hyp.prior,
        expected_information_gain: hyp.expected_information_gain,
        falsifiable: hyp.falsifiable}
    end)
  end

  defp build_evidence_summary(%Discovery{} = disc) do
    if disc.evidence == [] do
      "No evidence collected yet."
    else
      outcomes = Enum.group_by(disc.evidence, & &1.outcome)
      confirmed = length(Map.get(outcomes, :supported, []) ++ Map.get(outcomes, :confirmed, []))
      refuted = length(Map.get(outcomes, :falsified, []))
      inconclusive = length(Map.get(outcomes, :inconclusive, []))
      "#{length(disc.evidence)} evidence items: #{confirmed} confirmed, #{refuted} refuted, #{inconclusive} inconclusive. " <>
      "Net confidence delta: #{Float.round(Enum.reduce(disc.evidence, 0.0, fn r, acc -> acc + r.confidence_delta end), 3)}."
    end
  end

  defp build_conclusion(%Discovery{conclusion: nil}), do: "No conclusion reached yet."
  defp build_conclusion(%Discovery{conclusion: conclusion}), do: Map.get(conclusion, :summary, "Conclusion reached.")

  defp build_limitations(%Discovery{} = disc) do
    (if length(disc.evidence) < 3, do: ["Limited evidence base (#{length(disc.evidence)} items)"], else: []) ++
    (if disc.uncertainty > 0.4, do: ["High residual uncertainty (#{Float.round(disc.uncertainty, 2)})"], else: []) ++
    (if disc.status == :abandoned, do: ["Discovery was abandoned before completion"], else: []) ++
    ["Results have not been independently replicated"]
  end

  defp build_future_work(%Discovery{} = disc) do
    work = ["Independent replication of key findings"]
    work = if disc.uncertainty > 0.3, do: ["Additional experiments to reduce uncertainty below 0.3" | work], else: work
    work = if disc.gap, do: ["Investigate related gaps in #{disc.gap.domain} domain" | work], else: work
    work ++ ["Cross-domain validation of conclusions"]
  end

  defp build_lineage_summary(%Discovery{} = disc) do
    "Gap: #{disc.gap && disc.gap.id} → " <>
    "#{length(disc.hypotheses)} hypotheses → " <>
    "#{length(disc.predictions)} predictions → " <>
    "#{length(disc.experiments)} experiments → " <>
    "#{length(disc.evidence)} evidence → " <>
    "#{if disc.conclusion, do: "conclusion", else: "pending"} " <>
    "(#{length(disc.lineage)} lineage events)"
  end
end
