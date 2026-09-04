defmodule Tiannara.Omega.ResearchDirector do
  @moduledoc """
  Ω.2 Research Director integration handler. Consumes epistemic events and
  produces ranked experiment proposals:

      epistemic event -> research opportunity -> candidate hypotheses ->
      rank by expected information gain -> experiment proposals (PROPOSED only)

  It PROPOSES; it never executes. Every proposal carries lineage back to the
  triggering event and is marked `:proposed`.

  Constitutional basis: Scientific Method, "Evidence Before Confidence",
  "Capability must never outpace verification", augmentation clause,
  "Every architectural decision should remain traceable."
  """

  alias Tiannara.Sentinel.EpistemicEvent

  defstruct [:opportunity, :hypotheses, :proposals, :lineage]

  @research_events [:anomaly_detected, :contradiction_detected,
                    :research_opportunity, :discovery_candidate]

  def research_relevant?(%EpistemicEvent{type: t}), do: t in @research_events
  def research_relevant?(_), do: false

  @doc "Run the Ω.2 pipeline on an epistemic event."
  def investigate(%EpistemicEvent{} = event) do
    opportunity = to_opportunity(event)
    hypotheses = opportunity |> generate_hypotheses() |> rank()
    proposals = Enum.map(hypotheses, &to_proposal(&1, opportunity, event))


    %__MODULE__{
      opportunity: opportunity,
      hypotheses: hypotheses,
      proposals: proposals,
      lineage: [event.type, opportunity.id]
    }
  end

  # --- internals ----------------------------------------------------------

  defp to_opportunity(%EpistemicEvent{} = e) do
    %{id: :"opp-#{hash(e)}", type: e.type, payload: e.payload,
      confidence: e.confidence, evidence: e.evidence}
  end

  defp generate_hypotheses(%{type: :contradiction_detected} = opp) do
    [
      hyp(opp, "source A is accurate; source B has systematic error", 0.6, 0.8),
      hyp(opp, "source B is accurate; source A has systematic error", 0.5, 0.8),
      hyp(opp, "both are accurate under different conditions", 0.4, 0.5)
    ]
  end

  defp generate_hypotheses(%{type: :anomaly_detected} = opp) do
    [
      hyp(opp, "anomaly indicates an unmodeled phenomenon", 0.5, 0.7),
      hyp(opp, "anomaly is measurement noise", 0.5, 0.4)
    ]
  end

  defp generate_hypotheses(%{type: :research_opportunity} = opp) do
    [hyp(opp, "opportunity generalizes to a testable hypothesis", 0.5, 0.6)]
  end

  defp generate_hypotheses(%{type: :discovery_candidate} = opp) do
    [hyp(opp, "candidate discovery extends to a broader domain", 0.5, 0.6)]
  end

  defp generate_hypotheses(_opp), do: []


  defp hyp(opp, statement, prior, discriminability) do
    %{
      id: :"hyp-#{hash({opp.id, statement})}",
      opportunity_id: opp.id,
      statement: statement,
      prior_confidence: prior,
      discriminability: discriminability,
      expected_information_gain: info_gain(prior, discriminability)
    }
  end

  # Expected information gain = discriminability × binary entropy of the prior.
  defp info_gain(prior, discriminability) do
    Float.round(discriminability * entropy(prior), 4)
  end

  defp entropy(0.0), do: 0.0
  defp entropy(1.0), do: 0.0
  defp entropy(p), do: -p * :math.log2(p) - (1 - p) * :math.log2(1 - p)

  defp rank(hypotheses) do
    hypotheses
    |> Enum.sort_by(&(-&1.expected_information_gain))
    |> Enum.with_index(1)
    |> Enum.map(fn {h, r} -> Map.put(h, :rank, r) end)
  end

  defp to_proposal(h, opp, event) do
    %{
      id: :"prop-#{h.id}",
      hypothesis_id: h.id,
      opportunity_id: opp.id,
      statement: h.statement,
      rank: h.rank,
      expected_information_gain: h.expected_information_gain,
      status: :proposed,
      lineage: [event.type, opp.id, h.id]
    }
  end

  defp hash(term) do
    term
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
    |> String.slice(0, 8)
  end
end