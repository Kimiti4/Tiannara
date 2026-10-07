defmodule Tiannara.Research.Director.EvidenceDriven do
  @moduledoc """
  The full evidence-driven Ω.2 Research Director. Implements the complete
  investigation pipeline:

      Observation
        ↓  Evidence assessment
        ↓  Hypothesis generation
        ↓  Prediction
        ↓  Falsifier
        ↓  Evidence requirements
        ↓  Experiment candidate generation
        ↓  Experiment ranking
        ↓  Research proposal
        ↓  Lineage + uncertainty

  AUTHORITY BOUNDARY (constitutional): this director INVESTIGATES and
  PROPOSES only. It never executes experiments (Ω.4 governance), never
  communicates to humans (Ω.3 Cognitive Interface), and never exercises
  judgment (the human). Every proposal is `:proposed`, carries lineage, and
  quantifies uncertainty.

  Constitutional basis: Scientific Method, "Evidence Before Confidence",
  "Capability must never outpace verification", "Uncertainty should never be
  hidden", "Every architectural decision should remain traceable", and the
  augmentation clause.
  """

  alias Tiannara.Sentinel.EpistemicEvent
  alias Tiannara.Research.{EvidenceAssessment, ExperimentRanker}
  alias Tiannara.Sentinel.DiscoveryVerificationRecorder
  alias TiannaraOS.DiscoveryRegistry

  defstruct [:opportunity, :evidence_assessment, :hypotheses,
             :experiment_candidates, :selected, :proposals,
             :lineage, :uncertainty]

  @research_events [:anomaly_detected, :contradiction_detected,
                    :research_opportunity, :discovery_candidate]

  @experiment_archetypes [
    %{type: :direct_test, cost: 0.3, risk: 0.2, reproducibility: 0.6, info_gain_mult: 1.0},
    %{type: :controlled_replication, cost: 0.6, risk: 0.1, reproducibility: 0.9, info_gain_mult: 0.9},
    %{type: :exploratory_probe, cost: 0.2, risk: 0.5, reproducibility: 0.4, info_gain_mult: 1.2}
  ]

  @selected_limit 3

  def research_relevant?(%EpistemicEvent{type: type}), do: type in @research_events
  def research_relevant?(_), do: false

  @doc """
  Run investigation and, when a caller supplies the real discovery-verification
  providers, bind discovery candidates to the evidence lineage automatically.

  The plain investigate/1 path remains proposal-only. This entrypoint is the
  production integration boundary and fails closed when required providers are
  absent.
  """
  @spec investigate_and_record(EpistemicEvent.t(), map()) :: {:ok, map()} | {:error, term()}
  def investigate_and_record(%EpistemicEvent{} = event, opts) when is_map(opts) do
    investigation = investigate(event)

    with {:ok, discovery} <- build_discovery_candidate(investigation, event, opts),
         {:ok, recorded} <-
           DiscoveryVerificationRecorder.verify_and_record(
             discovery,
             Map.get(opts, :related_domains, []),
             Map.get(opts, :domain_verifier),
             opts
           ),
         {:ok, registered} <- register_verified_discovery(discovery, recorded, opts) do
      {:ok, %{investigation: investigation, discovery: discovery, verification: recorded, registry: registered}}
    end
  end

  @doc "Run the full evidence-driven investigation pipeline (deterministic)."
  def investigate(%EpistemicEvent{} = event) do
    opportunity = to_opportunity(event)
    evidence_assessment = EvidenceAssessment.assess(opportunity)

    hypotheses =
      opportunity
      |> generate_hypotheses()
      |> Enum.map(&enrich_hypothesis(&1, evidence_assessment))

    candidates =
      Enum.flat_map(hypotheses, &generate_experiment_candidates(&1, opportunity, evidence_assessment))

    ranked = ExperimentRanker.rank(candidates)
    selected = Enum.take(ranked, @selected_limit)
    proposals = Enum.map(selected, &to_proposal(&1, opportunity, event))
    uncertainty = compute_uncertainty(evidence_assessment, hypotheses)

    %__MODULE__{
      opportunity: opportunity,
      evidence_assessment: evidence_assessment,
      hypotheses: hypotheses,
      experiment_candidates: ranked,
      selected: selected,
      proposals: proposals,
      lineage: [event.type, opportunity.id],
      uncertainty: uncertainty
    }
  end

  defp build_discovery_candidate(investigation, event, opts) do
    builder = Map.get(opts, :discovery_builder)

    if is_function(builder, 2) do
      case builder.(investigation, event) do
        {:ok, discovery} when is_map(discovery) ->
          {:ok, discovery}

        {:error, reason} ->
          {:error, {:discovery_builder_failed, reason}}

        other ->
          {:error, {:invalid_discovery_builder_result, other}}
      end
    else
      {:error, :discovery_builder_unavailable}
    end
  rescue
    exception ->
      {:error, {:discovery_builder_crashed, exception}}
  end

  defp register_verified_discovery(discovery, recorded, opts) do
    registry = Map.get(opts, :discovery_registry, &DiscoveryRegistry.register_verified/2)

    if is_function(registry, 2) do
      case registry.(discovery, recorded) do
        {:ok, registered} -> {:ok, registered}
        {:error, reason} -> {:error, {:discovery_registry_failed, reason}}
        other -> {:error, {:invalid_discovery_registry_result, other}}
      end
    else
      {:error, :discovery_registry_unavailable}
    end
  rescue
    exception ->
      {:error, {:discovery_registry_crashed, exception}}
  end

  # --- opportunity --------------------------------------------------------

  defp to_opportunity(%EpistemicEvent{} = event) do
    %{
      id: :"opp-#{hash(event)}",
      type: event.type,
      payload: event.payload,
      confidence: event.confidence || 0.0,
      evidence: event.evidence || [],
      evidence_envelope: event.evidence_envelope || %{},
      intervention_id: event.intervention_id
    }
  end

  # --- hypothesis generation ---------------------------------------------

  defp generate_hypotheses(%{type: :contradiction_detected} = opp) do
    [
      hypothesis(opp, "source A is accurate; source B has systematic error", 0.6, 0.8),
      hypothesis(opp, "source B is accurate; source A has systematic error", 0.5, 0.8),
      hypothesis(opp, "both are accurate under different conditions", 0.4, 0.5)
    ]
  end

  defp generate_hypotheses(%{type: :anomaly_detected} = opp) do
    [
      hypothesis(opp, "anomaly indicates an unmodeled phenomenon", 0.5, 0.7),
      hypothesis(opp, "anomaly is measurement noise", 0.5, 0.4)
    ]
  end

  defp generate_hypotheses(%{type: :research_opportunity} = opp) do
    [hypothesis(opp, "opportunity generalizes to a testable hypothesis", 0.5, 0.6)]
  end

  defp generate_hypotheses(%{type: :discovery_candidate} = opp) do
    [hypothesis(opp, "candidate discovery extends to a broader domain", 0.5, 0.6)]
  end

  defp generate_hypotheses(_opp), do: []

  defp hypothesis(opp, statement, prior, discriminability) do
    %{
      id: :"hyp-#{hash({opp.id, statement})}",
      opportunity_id: opp.id,
      statement: statement,
      prior_confidence: prior,
      discriminability: discriminability,
      expected_information_gain: info_gain(prior, discriminability),
      uncertainty: Float.round(1.0 - prior, 4)
    }
  end

  # --- enrichment: prediction, falsifier, evidence requirements ----------

  defp enrich_hypothesis(hypothesis, %EvidenceAssessment{} = assessment) do
    prediction = %{
      id: :"pred-#{hypothesis.id}",
      hypothesis_id: hypothesis.id,
      statement: "if #{hypothesis.statement}, a controlled test yields the predicted outcome",
      observable: "measured outcome matching the hypothesis"
    }

    falsifier = %{
      id: :"fals-#{hypothesis.id}",
      hypothesis_id: hypothesis.id,
      statement: "falsified if the controlled test contradicts the prediction",
      would_observe: "outcome inconsistent with the hypothesis"
    }

    required_evidence = [
      %{kind: :controlled_measurement,
        description: "calibrated re-measurement relevant to: #{hypothesis.statement}"}
    ]

    missing_evidence =
      if assessment.sufficiency == :sufficient, do: [], else: required_evidence

    hypothesis
    |> Map.put(:predictions, [prediction])
    |> Map.put(:falsifiers, [falsifier])
    |> Map.put(:required_evidence, required_evidence)
    |> Map.put(:missing_evidence, missing_evidence)
  end

  # --- experiment candidate generation -----------------------------------

  defp generate_experiment_candidates(hypothesis, opportunity, %EvidenceAssessment{} = assessment) do
    feasibility =
      case assessment.sufficiency do
        :sufficient -> 1.0
        :insufficient -> 0.5
        :contradicted -> 0.3
      end

    relevance = opportunity.confidence || 0.0

    Enum.map(@experiment_archetypes, fn archetype ->
      %{
        id: :"exp-#{hypothesis.id}-#{archetype.type}",
        hypothesis_id: hypothesis.id,
        type: archetype.type,
        description: "#{archetype.type} for: #{hypothesis.statement}",
        expected_information_gain: hypothesis.expected_information_gain * archetype.info_gain_mult,
        uncertainty_reduction: hypothesis.uncertainty * archetype.info_gain_mult,
        scientific_relevance: relevance,
        cost: archetype.cost,
        risk: archetype.risk,
        reproducibility: archetype.reproducibility,
        feasibility: feasibility,
        constitutional_ok: :unevaluated,
        dependencies_available: feasibility >= 0.4
      }
    end)
  end

  # --- proposal ----------------------------------------------------------

  defp to_proposal(candidate, opportunity, event) do
    %{
      id: :"prop-#{candidate.id}",
      hypothesis_id: candidate.hypothesis_id,
      experiment_id: candidate.id,
      statement: candidate.description,
      composite_score: candidate.composite_score,
      rank: candidate.rank,
      status: :proposed,
      lineage: [event.type, opportunity.id, candidate.hypothesis_id, candidate.id],
      uncertainty: Float.round(1.0 - candidate.composite_score, 4),
      evidence_envelope: opportunity.evidence_envelope,
      intervention_id: opportunity.intervention_id
    }
  end

  # --- uncertainty -------------------------------------------------------

  defp compute_uncertainty(%EvidenceAssessment{} = assessment, hypotheses) do
    evidence_uncertainty = 1.0 - assessment.strength

    hypothesis_uncertainty =
      if hypotheses == [],
        do: 1.0,
        else: Enum.sum(Enum.map(hypotheses, & &1.uncertainty)) / length(hypotheses)

    Float.round((evidence_uncertainty + hypothesis_uncertainty) / 2, 4)
  end

  # --- helpers -----------------------------------------------------------

  defp info_gain(prior, discriminability),
    do: Float.round(discriminability * entropy(prior), 4)

  defp entropy(0.0), do: 0.0
  defp entropy(1.0), do: 0.0
  defp entropy(p), do: -p * :math.log2(p) - (1 - p) * :math.log2(1 - p)

  defp hash(term) do
    term
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
    |> String.slice(0, 8)
  end
end