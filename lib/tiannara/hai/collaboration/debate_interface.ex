defmodule Tiannara.HAI.Collaboration.DebateInterface do
  alias Tiannara.Discovery.Discovery
  alias Tiannara.Discovery.Domain.{HypothesisSpec, PredictionSpec}

  @spec structure_debate(Discovery.t()) :: map()
  def structure_debate(%Discovery{} = disc) do
    hypotheses = disc.hypotheses
    predictions = disc.predictions
    evidence = disc.evidence

    %{
      discovery_id: disc.id,
      question: disc.question,
      context: build_context(disc),
      positions: build_positions(hypotheses, predictions, evidence),
      evidence_summary: build_evidence_summary(evidence),
      points_of_agreement: find_agreements(hypotheses),
      points_of_contention: find_contentions(hypotheses),
      missing_evidence: identify_missing_evidence(disc),
      decision_criteria: build_decision_criteria(disc),
      system_recommendation: build_system_recommendation(disc),
      confidence_disclosure: %{
        system_confidence: disc.confidence,
        system_uncertainty: disc.uncertainty,
        note: "This is the system's current belief. You may override it."
      },
      generated_at: DateTime.utc_now()
    }
  end

  @spec render(map()) :: String.t()
  def render(debate) do
    positions_text =
      Enum.map_join(debate.positions, "\n\n", fn pos ->
        """
        --- Position #{pos.rank}: #{pos.label} ---
        Hypothesis: #{pos.statement}
        Prior: #{Float.round(pos.prior, 3)}
        Expected Information Gain: #{Float.round(pos.expected_information_gain, 3)}

        Strengths:
        #{Enum.map_join(pos.strengths, "\n", fn s -> "  #{s}" end)}

        Weaknesses:
        #{Enum.map_join(pos.weaknesses, "\n", fn w -> "  #{w}" end)}

        Predictions:
        #{Enum.map_join(pos.predictions, "\n", fn p -> "  #{p.statement} (confidence: #{Float.round(p.confidence, 2)})" end)}

        Supporting Evidence: #{pos.supporting_evidence_count} items
        Contradicting Evidence: #{pos.contradicting_evidence_count} items
        """
      end)

    """
    SCIENTIFIC DEBATE: #{debate.question}

    CONTEXT
    -------
    #{debate.context}

    COMPETING POSITIONS (#{length(debate.positions)})
    ---------------------
    #{positions_text}

    EVIDENCE SUMMARY
    ----------------
    #{debate.evidence_summary}

    POINTS OF AGREEMENT
    -------------------
    #{Enum.map_join(debate.points_of_agreement, "\n", fn a -> "  #{a}" end)}

    POINTS OF CONTENTION
    --------------------
    #{Enum.map_join(debate.points_of_contention, "\n", fn c -> "  #{c}" end)}

    MISSING EVIDENCE
    ----------------
    #{Enum.map_join(debate.missing_evidence, "\n", fn m -> "  #{m}" end)}

    DECISION CRITERIA
    -----------------
    #{Enum.map_join(debate.decision_criteria, "\n", fn d -> "  #{d}" end)}

    SYSTEM RECOMMENDATION
    ---------------------
    #{debate.system_recommendation}

    CONFIDENCE DISCLOSURE
    ---------------------
    System confidence: #{Float.round(debate.confidence_disclosure.system_confidence, 3)}
    System uncertainty: #{Float.round(debate.confidence_disclosure.system_uncertainty, 3)}
    Note: #{debate.confidence_disclosure.note}

    """
  end

  defp build_context(%Discovery{} = disc) do
    gap_desc = if disc.gap, do: disc.gap.description, else: "Unknown gap"
    domain = if disc.gap, do: disc.gap.domain, else: :unknown

    "This debate arises from a knowledge gap in #{domain}: #{gap_desc}. " <>
    "#{length(disc.hypotheses)} competing hypotheses were generated. " <>
    "#{length(disc.evidence)} evidence items have been collected."
  end

  defp build_positions(hypotheses, predictions, evidence) do
    hypotheses
    |> Enum.sort_by(& &1.prior, :desc)
    |> Enum.with_index()
    |> Enum.map(fn {hyp, idx} ->
      hyp_predictions = Enum.filter(predictions, &(&1.hypothesis_id == hyp.id))
      hyp_evidence = Enum.filter(evidence, &(&1.hypothesis_id == hyp.id))

      supporting = Enum.count(hyp_evidence, &(&1.outcome == :confirmed))
      contradicting = Enum.count(hyp_evidence, &(&1.outcome == :refuted))

      %{
        rank: idx + 1,
        label: "Hypothesis #{idx + 1}",
        hypothesis_id: hyp.id,
        statement: hyp.statement,
        prior: hyp.prior,
        expected_information_gain: hyp.expected_information_gain,
        novelty: Map.get(hyp.metadata, :novelty, 0.5),
        strengths: identify_strengths(hyp, supporting),
        weaknesses: identify_weaknesses(hyp, contradicting),
        predictions: hyp_predictions,
        supporting_evidence_count: supporting,
        contradicting_evidence_count: contradicting
      }
    end)
  end

  defp identify_strengths(%HypothesisSpec{} = hyp, supporting_count) do
    strengths = []

    strengths =
      if hyp.prior > 0.3 do
        ["Strong prior probability (#{Float.round(hyp.prior, 2)})" | strengths]
      else
        strengths
      end

    strengths =
      if hyp.expected_information_gain > 0.5 do
        ["High expected information gain (#{Float.round(hyp.expected_information_gain, 2)})" | strengths]
      else
        strengths
      end

    strengths =
      if supporting_count > 0 do
        ["#{supporting_count} confirming evidence items" | strengths]
      else
        strengths
      end

    novelty = Map.get(hyp.metadata, :novelty, 0.5)
    strengths =
      if novelty > 0.6 do
        ["High novelty -- could open new research directions" | strengths]
      else
        strengths
      end

    if strengths == [], do: ["Falsifiable and testable"], else: strengths
  end

  defp identify_weaknesses(%HypothesisSpec{} = hyp, contradicting_count) do
    weaknesses = []

    weaknesses =
      if hyp.prior < 0.2 do
        ["Low prior probability (#{Float.round(hyp.prior, 2)})" | weaknesses]
      else
        weaknesses
      end

    weaknesses =
      if contradicting_count > 0 do
        ["#{contradicting_count} refuting evidence items" | weaknesses]
      else
        weaknesses
      end

    weaknesses =
      if hyp.risk > 0.5 do
        ["High risk (#{Float.round(hyp.risk, 2)})" | weaknesses]
      else
        weaknesses
      end

    if weaknesses == [], do: ["No significant weaknesses identified"], else: weaknesses
  end

  defp build_evidence_summary(evidence) do
    if evidence == [] do
      "No evidence collected yet."
    else
      confirmed = Enum.count(evidence, &(&1.outcome == :confirmed))
      refuted = Enum.count(evidence, &(&1.outcome == :refuted))
      inconclusive = Enum.count(evidence, &(&1.outcome == :inconclusive))

      "#{length(evidence)} total evidence items: " <>
      "#{confirmed} confirming, #{refuted} refuting, #{inconclusive} inconclusive."
    end
  end

  defp find_agreements(hypotheses) do
    if hypotheses == [] do
      []
    else
      agreements = []

      agreements =
        if Enum.all?(hypotheses, & &1.falsifiable) do
          ["All hypotheses are falsifiable" | agreements]
        else
          agreements
        end

      agreements =
        if Enum.all?(hypotheses, &(&1.domain == hd(hypotheses).domain)) do
          ["All hypotheses address the same domain (#{hd(hypotheses).domain})" | agreements]
        else
          agreements
        end

      agreements ++ ["All hypotheses are testable through experimentation"]
    end
  end

  defp find_contentions(hypotheses) do
    contentions = []

    causal_models = Enum.map(hypotheses, fn h -> Map.get(h.metadata, :causal_model, :unknown) end) |> Enum.uniq()

    contentions =
      if length(causal_models) > 1 do
        ["Disagree on causal mechanism: #{Enum.join(causal_models, " vs. ")}" | contentions]
      else
        contentions
      end

    strategies = Enum.map(hypotheses, fn h -> Map.get(h.metadata, :strategy, :unknown) end) |> Enum.uniq()

    contentions =
      if length(strategies) > 1 do
        ["Propose different investigation strategies: #{Enum.join(strategies, ", ")}" | contentions]
      else
        contentions
      end

    if contentions == [], do: ["No major points of contention identified"], else: contentions
  end

  defp identify_missing_evidence(%Discovery{} = disc) do
    missing = []

    missing =
      if disc.evidence == [] do
        ["No experimental evidence collected yet" | missing]
      else
        missing
      end

    missing =
      if length(disc.evidence) < 3 do
        ["Insufficient evidence (#{length(disc.evidence)} items, minimum 3 recommended)" | missing]
      else
        missing
      end

    missing =
      if not Enum.any?(disc.evidence, &(&1.outcome == :refuted)) and length(disc.evidence) > 0 do
        ["No disconfirming evidence found -- potential confirmation bias" | missing]
      else
        missing
      end

    missing ++ ["Independent replication not yet performed"]
  end

  defp build_decision_criteria(%Discovery{} = disc) do
    [
      "1. Which hypothesis best explains ALL available evidence?",
      "2. Which hypothesis makes the most specific, falsifiable predictions?",
      "3. Which hypothesis has the strongest supporting evidence?",
      "4. Which hypothesis is most consistent with established principles?",
      "5. Which hypothesis opens the most productive research directions?",
      "6. Are there any hypotheses that should be eliminated based on current evidence?"
    ]
  end

  defp build_system_recommendation(%Discovery{} = disc) do
    if disc.hypotheses == [] do
      "No hypotheses available for recommendation."
    else
      best = Enum.max_by(disc.hypotheses, & &1.prior)

      "The system currently favors: '#{String.slice(best.statement, 0, 100)}...' " <>
      "(prior: #{Float.round(best.prior, 3)}). " <>
      "However, this is a recommendation, not a decision. " <>
      "Human judgment may override this based on domain expertise, " <>
      "context not available to the system, or strategic considerations."
    end
  end
end
