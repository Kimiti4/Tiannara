defmodule TiannaraRuntime.Cognitive.Reflection.LessonExtractor do
  def extract(outcomes, patterns, biases) do
    actionable = Enum.map(outcomes, fn o -> {:ok, l} = actionable_lesson(o); l end)
    reusable = Enum.map(patterns, fn p -> {:ok, l} = reusable_lesson(p); l end)
    transferable = Enum.map(biases, fn b -> {:ok, l} = transferable_lesson(b); l end)
    all = actionable ++ reusable ++ transferable
    {:ok, refined} = refine_lessons(all)
    {:ok, refined}
  end

  def actionable_lesson(outcome) do
    score = Map.get(outcome, :success_score, 0.0)
    description = if score >= 0.7, do: "Successful outcome (#{Float.round(score, 3)}) — repeat approach", else: if score >= 0.3, do: "Partial outcome (#{Float.round(score, 3)}) — adjust approach", else: "Failed outcome (#{Float.round(score, 3)}) — avoid approach"
    {:ok, %{id: :erlang.unique_integer([:positive]), type: :actionable, description: description, applicability: if(score >= 0.5, do: 0.8, else: 0.4), success_rate: score, source_pattern_id: nil, source_outcome_id: Map.get(outcome, :id)}}
  end

  def reusable_lesson(pattern) do
    ptype = Map.get(pattern, :type)
    pdata = Map.get(pattern, :data, %{})
    description = case ptype do
      :frequency -> "Frequency pattern detected: #{Map.get(pdata, :low, 0)} low, #{Map.get(pdata, :medium, 0)} medium, #{Map.get(pdata, :high, 0)} high outcomes"
      :sequence -> "Sequence pattern: #{Map.get(pdata, :direction)} trend (slope: #{Float.round(Map.get(pdata, :slope, 0.0), 4)})"
      :anomaly -> "Anomaly pattern: #{Map.get(pdata, :anomaly_count, 0)} outliers detected"
      _ -> "Pattern of type #{ptype}"
    end
    {:ok, %{id: :erlang.unique_integer([:positive]), type: :reusable, description: description, applicability: Map.get(pattern, :confidence, 0.0), success_rate: 0.5, source_pattern_id: Map.get(pattern, :id), source_outcome_id: nil}}
  end

  def transferable_lesson(bias) do
    btype = Map.get(bias, :type)
    severity = Map.get(bias, :severity, 0.0)
    description = "Bias mitigation for #{btype} (severity: #{Float.round(severity, 3)}) — #{Map.get(bias, :recommendation, "Monitor for bias")}"
    {:ok, %{id: :erlang.unique_integer([:positive]), type: :transferable, description: description, applicability: 1.0 - severity, success_rate: 0.5, source_pattern_id: nil, source_outcome_id: nil}}
  end

  def refine_lessons(lessons) do
    {:ok, Enum.uniq_by(lessons, fn l -> Map.get(l, :description) end)}
  end
end
