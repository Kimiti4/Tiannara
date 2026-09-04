defmodule Tiannara.Discovery.Steps.ValidationStep do
  @moduledoc """
  A REAL, minimal validation step. It validates an evidence record produced
  upstream (by ExperimentStep) and emits a validation evidence record whose
  provenance carries LINEAGE to the evidence it validated (rules.md: "Every
  architectural decision should remain traceable"; Memory Philosophy —
  evidence climbs toward Knowledge only when a decisive, confident measurement
  exists).

  The evidence under validation is accepted from `input[:evidence]` (inline)
  or `context[:last_evidence]` (engine-threaded). If neither is present the
  step yields :inconclusive rather than crashing — so an engine that does not
  yet thread step outputs produces a named, honest gap in the gauge, not a
  step crash (rules.md: "Recover gracefully"; "Detect degraded performance").

  Outcome vocabulary stays within [:confirmed, :refuted, :inconclusive] so
  the existing EvidenceAuditor contract is not broken (rules.md: "Verification
  First" — do not break a validator that already exists). Here :confirmed
  means "validated as promotable", :refuted means "not promotable".
  """

  @behaviour Tiannara.Discovery.Step

  alias Tiannara.Discovery.Step

  @impl true
  def step_type, do: :validation

  @impl true
  def required_capability, do: :evidence_validation

  @impl true
  def validate_input(input) do
    if is_map(input), do: :ok, else: {:error, :missing_input}
  end

  @impl true
  def execute(input, ctx) do
    threshold = Map.get(input, :promotion_threshold, 0.5)
    evidence = Map.get(input, :evidence) || Map.get(ctx || %{}, :last_evidence)

    case evidence do
      nil ->
        {:ok, output(input, nil, :inconclusive, 0.0, threshold)}

      ev ->
        outcome = Map.get(ev, :outcome, :inconclusive)
        conf = Map.get(ev, :confidence, 0.0)
        promotable? = Step.decisive?(outcome) and conf >= threshold

        # Validation confidence: a decisive, confident measurement validates
        # cleanly; an indecisive one validates weakly (uncertainty surfaced).
        v_conf = if Step.decisive?(outcome), do: conf, else: conf * 0.3

        v_outcome =
          cond do
            not Step.decisive?(outcome) -> :inconclusive
            promotable? -> :confirmed
            true -> :refuted
          end

        {:ok, output(input, ev, v_outcome, v_conf, threshold)}
    end
  end

  @impl true
  def compensate(_input, _result, _ctx), do: :ok

  @impl true
  def metadata, do: %{description: "Validates upstream evidence for promotion"}

  # ── private ────────────────────────────────────────────

  defp output(input, source_ev, outcome, confidence, threshold) do
    val_evidence = %{
      outcome: outcome,
      confidence: confidence,
      uncertainty: 1.0 - confidence,
      validation: %{
        promotion_threshold: threshold,
        promotable: outcome == :confirmed,
        source_outcome: source_ev && Map.get(source_ev, :outcome),
        source_confidence: source_ev && Map.get(source_ev, :confidence)
      },
      provenance: %{
        origin: :validation_step,
        produced_by: __MODULE__,
        produced_at: DateTime.utc_now(),
        derived_from: source_ev && get_in(source_ev, [:provenance]),
        source_entities: source_ev && Map.get(source_ev, :source_entities, []),
        validated_step_id: Map.get(input, :id),
        note: "Validation of upstream evidence — lineage preserved."
      }
    }

    %{
      evidence: [val_evidence],
      confidence: confidence,
      quality_metrics: %{
        promotable: outcome == :confirmed,
        source_outcome: source_ev && Map.get(source_ev, :outcome)
      },
      resource_usage: %{reads: 0},
      validation: val_evidence
    }
  end
end
