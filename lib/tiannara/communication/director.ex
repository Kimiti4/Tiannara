defmodule Tiannara.Communication.Contract do
  @moduledoc "Ω.3 contract: significance → human relevance → decision."
  @callback assess_significance(event :: term()) :: float()
  @callback assess_relevance(event :: term()) :: map()
  @callback decide(event :: term(), context :: map()) :: Tiannara.Communication.Decision.t()
end

defmodule Tiannara.Communication.Director do
  @moduledoc """
  Reference communication-decision maker (Ω.3). Prepares proactive
  communication WITHOUT activating autonomous conversation: it decides and
  proposes; a separate human-facing delivery layer performs notification.

  Constitutional basis: augmentation clause, "Evidence Before Confidence",
  Explainability, "Uncertainty should never be hidden."
  """
  @behaviour Tiannara.Communication.Contract

  alias Tiannara.Sentinel.EpistemicEvent
  alias Tiannara.Communication.{Decision, DedupLedger}

  @base_significance %{
    constitutional_concern: 1.0,
    system_degradation: 0.9,
    anomaly_detected: 0.7,
    contradiction_detected: 0.7,
    discovery_candidate: 0.6,
    research_opportunity: 0.5,
    improvement_proposed: 0.5,
    experiment_completed: 0.3,
    knowledge_updated: 0.2
  }

  @severity_mult %{low: 0.5, medium: 1.0, high: 1.3, critical: 1.5}

  @impl true
  def assess_significance(%EpistemicEvent{} = e) do
    base = Map.get(@base_significance, e.type, 0.3)
    sev = Map.get(@severity_mult, e.severity, 1.0)
    conf = 0.5 + e.confidence * 0.5
    Float.round(min(1.0, base * sev * conf), 4)
  end

  @impl true
  def assess_relevance(%EpistemicEvent{} = e) do
    case e.type do
      :constitutional_concern -> %{category: :actionable, relevance: 1.0, action: "review constitutional concern"}
      :system_degradation -> %{category: :actionable, relevance: 0.9, action: "investigate degraded subsystem"}
      :improvement_proposed -> %{category: :actionable, relevance: 0.7, action: "approve or reject proposal"}
      :anomaly_detected -> %{category: :actionable, relevance: 0.6, action: "triage anomaly"}
      :contradiction_detected -> %{category: :actionable, relevance: 0.6, action: "resolve contradiction"}
      :discovery_candidate -> %{category: :informational, relevance: 0.6, action: nil}
      :research_opportunity -> %{category: :research, relevance: 0.4, action: nil}
      :experiment_completed -> %{category: :informational, relevance: 0.3, action: nil}
      :knowledge_updated -> %{category: :informational, relevance: 0.2, action: nil}
      _ -> %{category: :informational, relevance: 0.2, action: nil}
    end
  end

  def dedup_key(%EpistemicEvent{} = e), do: {e.type, e.payload}

  @impl true
  def decide(%EpistemicEvent{} = e, context \\ %{}) do
    ledger = Map.get(context, :ledger, DedupLedger.new())
    threshold = Map.get(context, :significance_threshold, 0.4)

    significance = assess_significance(e)
    rel = assess_relevance(e)
    key = dedup_key(e)
    already? = DedupLedger.member?(ledger, key)

    {notify?, suppress_reason} =
      cond do
        already? -> {false, :already_notified}
        e.type == :constitutional_concern -> {true, nil}
        significance < threshold -> {false, :below_significance_threshold}
        true -> {true, nil}
      end

    %Decision{
      event_type: e.type,
      notify: notify?,
      urgency: urgency(significance, e.type),
      significance: significance,
      human_relevance: rel.relevance,
      category: rel.category,
      reason: reason(notify?, significance, rel),
      suppress_reason: suppress_reason,
      evidence: e.evidence,
      uncertainty: e.uncertainty,
      recommended_action: rel.action,
      dedup_key: key,
      already_notified: already?
    }
  end

  defp urgency(_s, :constitutional_concern), do: :critical
  defp urgency(s, _) when s >= 0.8, do: :critical
  defp urgency(s, _) when s >= 0.6, do: :high
  defp urgency(s, _) when s >= 0.4, do: :medium
  defp urgency(_, _), do: :low

  defp reason(true, significance, rel),
    do: "significant (#{significance}) and #{rel.category}; warrants human awareness"
  defp reason(false, _, _), do: "suppressed (see suppress_reason)"
end