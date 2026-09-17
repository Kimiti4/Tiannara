defmodule TiannaraRuntime.Cognitive.Reflection.PatternDetector do
  def detect(outcomes) do
    {:ok, freq} = frequency_pattern(outcomes)
    {:ok, seq} = sequence_pattern(outcomes)
    {:ok, anom} = anomaly_pattern(outcomes)
    patterns = Enum.filter([freq, seq, anom], fn p -> Map.get(p, :confidence, 0.0) > 0.0 end)
    {:ok, patterns}
  end

  def frequency_pattern(outcomes) do
    bands = Enum.reduce(outcomes, %{low: 0, medium: 0, high: 0}, fn o, acc ->
      score = Map.get(o, :success_score, 0.0)
      cond do
        score < 0.3 -> %{acc | low: Map.get(acc, :low) + 1}
        score < 0.7 -> %{acc | medium: Map.get(acc, :medium) + 1}
        true -> %{acc | high: Map.get(acc, :high) + 1}
      end
    end)
    n = length(outcomes)
    confidence = if n >= 3, do: min(0.5 + (n - 3) * 0.1, 0.95), else: 0.0
    {:ok, %{id: :erlang.unique_integer([:positive]), type: :frequency, data: bands, confidence: confidence}}
  end

  def sequence_pattern(outcomes) do
    scores = Enum.map(outcomes, fn o -> Map.get(o, :success_score, 0.0) end)
    {direction, slope, confidence} = cond do
      length(scores) < 3 -> {:none, 0.0, 0.0}
      scores == Enum.sort(scores) -> {:improving, if(length(scores) > 1, do: (List.last(scores) - hd(scores)) / (length(scores) - 1), else: 0.0), 0.6}
      scores == Enum.reverse(Enum.sort(scores)) -> {:declining, if(length(scores) > 1, do: (List.last(scores) - hd(scores)) / (length(scores) - 1), else: 0.0), 0.6}
      true -> {:fluctuating, 0.0, 0.3}
    end
    {:ok, %{id: :erlang.unique_integer([:positive]), type: :sequence, data: %{direction: direction, slope: slope}, confidence: confidence}}
  end

  def anomaly_pattern(outcomes) do
    scores = Enum.map(outcomes, fn o -> Map.get(o, :success_score, 0.0) end)
    n = length(scores)
    mean = if n == 0, do: 0.0, else: Enum.sum(scores) / n
    variance = if n == 0, do: 0.0, else: Enum.sum(Enum.map(scores, fn s -> :math.pow(s - mean, 2) end)) / n
    stddev = :math.sqrt(variance)
    threshold = stddev * 2.0
    outliers = Enum.filter(outcomes, fn o ->
      score = Map.get(o, :success_score, 0.0)
      abs(score - mean) > threshold
    end)
    confidence = if stddev > 0 and length(outliers) > 0, do: min(0.3 + length(outliers) * 0.15, 0.9), else: 0.0
    {:ok, %{id: :erlang.unique_integer([:positive]), type: :anomaly, data: %{anomaly_count: length(outliers), threshold: threshold, outliers: Enum.map(outliers, fn o -> Map.get(o, :id) end)}, confidence: confidence}}
  end
end
