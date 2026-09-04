defmodule Tiannara.Contradiction.Engine do
  @moduledoc """
  The Contradiction engine. Detects contradictions from claims, classifies
  type/severity/confidence, manages the resolution lifecycle, and emits
  `:contradiction_detected` epistemic events for the Sentinel / Ω.2 Research
  Director to consume.

  Lifecycle:
      detected → investigating → experiment_proposed → experiment_running →
        resolved | dismissed

  This gives the soak a scientifically meaningful path: Contradiction →
  Sentinel → Research Opportunity → Hypothesis → Experiment → Resolution.

  Constitutional basis: Scientific Method, "Evidence Before Confidence",
  "Uncertainty should never be hidden", "Capability must never outpace
  verification", "Maintain audit trails" (resolution lineage).
  """

  alias Tiannara.Contradiction.Record
  alias Tiannara.Sentinel.EpistemicEvent
  alias Tiannara.Logic.Contradiction, as: KernelContradiction

  @transitions %{
    detected: [:investigating, :dismissed],
    investigating: [:experiment_proposed, :dismissed],
    experiment_proposed: [:experiment_running, :dismissed],
    experiment_running: [:resolved, :dismissed],
    resolved: [],
    dismissed: []
  }

  # --- detection ----------------------------------------------------------

  @doc """
  Detect contradictions from a set of claims. Each claim is a map with
  `:subject`, `:value`, `:evidence`, `:timestamp`, `:source`.

  This is now a thin shim over the canonical kernel
  `Tiannara.Logic.Contradiction.detect/2` (archaeology §4): grouping, verdict
  delegation, and record building live here, but the structural contradiction
  verdict itself is always the kernel's. Classification, severity, and
  confidence remain Engine concerns (Logic sits ABOVE Math; it never computes
  confidence itself).
  """
  def detect(claims) when is_list(claims) do
    claims
    |> Enum.group_by(& &1.subject)
    |> Enum.flat_map(fn {subject, group} -> detect_conflicts(subject, group) end)
  end

  defp detect_conflicts(subject, group) do
    for {a, b} <- pairs(group),
        KernelContradiction.detect(a, b) == :contradiction do
      build_contradiction(subject, a, b)
    end
  end

  defp pairs(list) do
    list
    |> Enum.with_index()
    |> Enum.flat_map(fn {a, i} ->
      list
      |> Enum.drop(i + 1)
      |> Enum.map(fn b -> {a, b} end)
    end)
  end

  defp build_contradiction(subject, a, b) do
    type = classify_type(a, b)
    severity = classify_severity(type)
    confidence = compute_confidence(a, b)

    %Record{
      id: :"contra-#{hash({subject, a.value, b.value})}",
      claim_a: %{subject: subject, value: a.value, source: a.source},
      claim_b: %{subject: subject, value: b.value, source: b.source},
      evidence_a: a.evidence,
      evidence_b: b.evidence,
      type: type,
      severity: severity,
      confidence: confidence,
      temporal_context: %{a_at: a.timestamp, b_at: b.timestamp},
      affected_knowledge: [subject],
      resolution_status: :detected,
      detected_at: System.system_time(:second),
      lineage: [a.source, b.source]
    }
  end

  defp classify_type(a, b) do
    if a.timestamp != nil and b.timestamp != nil and a.timestamp != b.timestamp do
      :temporal_conflict
    else
      :value_conflict
    end
  end

  defp classify_severity(:value_conflict), do: :high
  defp classify_severity(:temporal_conflict), do: :medium
  defp classify_severity(:logical_inconsistency), do: :critical
  defp classify_severity(:scope_conflict), do: :medium

  defp compute_confidence(a, b) do
    ea = length(a.evidence || [])
    eb = length(b.evidence || [])
    coverage = min(1.0, (ea + eb) / 4)
    Float.round(0.3 + coverage * 0.7, 4)
  end

  # --- lifecycle ----------------------------------------------------------

  @doc "Advance a contradiction to a legal next status."
  def advance(%Record{} = contradiction, new_status) do
    current = contradiction.resolution_status

    if new_status in Map.get(@transitions, current, []) do
      {:ok,
       %{contradiction
         | resolution_status: new_status,
           lineage: contradiction.lineage ++ [new_status]}}
    else
      {:error, {:illegal_transition, current, new_status}}
    end
  end

  @doc """
  Resolve a contradiction that is currently running an experiment. Attaches the
  resolution detail (which claim won, or a synthesis).
  """
  def resolve(%Record{resolution_status: :experiment_running} = contradiction, resolution_detail) do
    {:ok,
     %{contradiction
       | resolution_status: :resolved,
         resolution: resolution_detail,
         lineage: contradiction.lineage ++ [:resolved]}}
  end

  def resolve(%Record{} = contradiction, _resolution_detail) do
    {:error, {:cannot_resolve_from, contradiction.resolution_status}}
  end

  # --- epistemic event emission ------------------------------------------

  @doc "Emit a `:contradiction_detected` epistemic event for the Ω loop."
  def to_epistemic_event(%Record{} = contradiction) do
    evidence =
      for claim <- [contradiction.claim_a, contradiction.claim_b],
          do: %{quantity: claim.subject, value: claim.value, source: claim.source}

    %EpistemicEvent{
      type: :contradiction_detected,
      severity: contradiction.severity,
      payload: %{
        contradiction_id: contradiction.id,
        subject: List.first(contradiction.affected_knowledge),
        claim_a: contradiction.claim_a,
        claim_b: contradiction.claim_b,
        type: contradiction.type
      },
      confidence: contradiction.confidence,
      evidence: evidence
    }
  end

  @doc "Emit epistemic events for a batch of contradictions."
  def to_epistemic_events(contradictions), do: Enum.map(contradictions, &to_epistemic_event/1)

  # --- helpers ------------------------------------------------------------

  defp hash(term) do
    term
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
    |> String.slice(0, 8)
  end
end