defmodule TiannaraRuntime.Cognitive.Reflection.BiasDetector do
  def assess(session) do
    outcomes = Map.get(session, :outcomes, [])
    patterns = Map.get(session, :patterns, [])
    {:ok, cb} = confirmation_bias(outcomes, patterns)
    {:ok, ab} = availability_bias(outcomes)
    {:ok, anc} = anchoring_bias(outcomes, Map.get(session, :first_plan))
    {:ok, oc} = overconfidence_bias(length(patterns), length(outcomes))
    {:ok, [cb, ab, anc, oc]}
  end

  def confirmation_bias(outcomes, patterns) do
    positive_patterns = Enum.filter(patterns, fn p -> Map.get(p, :type) == :sequence and Map.get(Map.get(p, :data, %{}), :direction) == :improving end)
    all_scores = Enum.map(outcomes, fn o -> Map.get(o, :success_score, 0.0) end)
    has_negative = Enum.any?(all_scores, fn s -> s < 0.5 end)
    severity = if length(positive_patterns) > 0 and has_negative, do: min(0.3 + length(positive_patterns) * 0.15, 0.9), else: 0.0
    confidence = if length(outcomes) >= 3, do: 0.6, else: 0.3
    {:ok, %{id: :erlang.unique_integer([:positive]), type: :confirmation, severity: severity, confidence: confidence, dimensions: %{selective_attention: min(severity + 0.1, 1.0), interpretation_bias: min(severity * 0.8, 1.0)}, evidence: [%{type: :pattern_analysis, detail: "Positive-only patterns: #{length(positive_patterns)}, mixed outcomes: #{length(outcomes)}"}], recommendation: "Consider negative outcomes equally when forming patterns."}}
  end

  def availability_bias(outcomes) do
    sorted = Enum.sort_by(outcomes, fn o -> Map.get(o, :occurred_at, 0) end, :desc)
    recent = Enum.take(sorted, 3)
    older = Enum.drop(sorted, 3)
    recent_avg = if recent == [], do: 0.0, else: Enum.sum(Enum.map(recent, fn o -> Map.get(o, :success_score, 0.0) end)) / length(recent)
    older_avg = if older == [], do: 0.0, else: Enum.sum(Enum.map(older, fn o -> Map.get(o, :success_score, 0.0) end)) / length(older)
    diff = abs(recent_avg - older_avg)
    severity = if length(outcomes) >= 4 and diff > 0.2, do: min(diff * 1.5, 0.95), else: 0.0
    confidence = if length(outcomes) >= 5, do: 0.7, else: 0.3
    recency_effect = if recent_avg > older_avg and severity > 0, do: 1.0, else: 0.0
    {:ok, %{id: :erlang.unique_integer([:positive]), type: :availability, severity: severity, confidence: confidence, dimensions: %{recency_effect: recency_effect, salience: min(diff * 2.0, 1.0)}, evidence: [%{type: :temporal_analysis, detail: "Recent avg: #{Float.round(recent_avg, 3)}, Older avg: #{Float.round(older_avg, 3)}"}], recommendation: "Weight all outcomes equally regardless of recency."}}
  end

  def anchoring_bias(outcomes, _first_plan) do
    first_outcome = List.first(outcomes)
    anchor_score = if first_outcome != nil, do: Map.get(first_outcome, :success_score, 0.0), else: 0.5
    later_scores = Enum.map(Enum.drop(outcomes, 1), fn o -> Map.get(o, :success_score, 0.0) end)
    later_avg = if later_scores == [], do: 0.0, else: Enum.sum(later_scores) / length(later_scores)
    deviation = abs(later_avg - anchor_score)
    n_anchored = Enum.count(later_scores, fn s -> abs(s - anchor_score) < 0.15 end)
    severity = if length(later_scores) > 0, do: min(deviation * 1.2, 0.85), else: 0.0
    confidence = if length(later_scores) >= 3, do: 0.65, else: 0.3
    {:ok, %{id: :erlang.unique_integer([:positive]), type: :anchoring, severity: severity, confidence: confidence, dimensions: %{anchor_strength: min(n_anchored / max(length(later_scores), 1), 1.0), adjustment: min(deviation * 2.0, 1.0)}, evidence: [%{type: :anchor_analysis, detail: "Anchor score: #{Float.round(anchor_score, 3)}, Later avg: #{Float.round(later_avg, 3)}"}], recommendation: "Re-evaluate each outcome independently without reference to initial results."}}
  end

  def overconfidence_bias(pattern_count, outcome_count) do
    ratio = if outcome_count > 0, do: pattern_count / outcome_count, else: 0.0
    severity = if ratio > 0.5 and outcome_count < 5, do: min((ratio - 0.5) * 2.0, 0.95), else: 0.0
    confidence = if outcome_count > 0, do: 0.5, else: 0.0
    {:ok, %{id: :erlang.unique_integer([:positive]), type: :overconfidence, severity: severity, confidence: confidence, dimensions: %{pattern_to_outcome_ratio: min(ratio, 1.0), evidence_quality: if(outcome_count >= 5, do: 0.7, else: 0.3)}, evidence: [%{type: :ratio_analysis, detail: "#{pattern_count} patterns from #{outcome_count} outcomes (ratio: #{Float.round(ratio, 3)})"}], recommendation: "Gather more evidence before forming patterns."}}
  end
end
