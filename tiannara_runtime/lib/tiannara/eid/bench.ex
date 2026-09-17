defmodule Tiannara.EID.Bench do
  @moduledoc """
  EID-Bench: Emergent Intelligence Detection Benchmark Suite.
  Evaluates systemic world metrics to detect intelligence emergence thresholds.
  """

  @doc """
  Evaluates the current state of simulated worlds and returns:
  - `{:meta_intelligence, score}`
  - `{:emergent_intelligence, score}`
  - `{:proto_intelligence, score}`
  - `{:non_emergent, score}`
  """
  def evaluate(state) do
    n = novelty_persistence(state)
    c = cross_world_transfer(state)
    a = autonomous_optimization(state)
    s = stability_under_drift(state)
    m = meta_awareness(state)

    slef = sigmoid(0.25 * n + 0.20 * c + 0.20 * a + 0.20 * s + 0.15 * m)

    {classify(slef), slef}
  end

  def sigmoid(x) do
    1.0 / (1.0 + :math.exp(-x))
  end

  def classify(score) when score > 0.9, do: :meta_intelligence
  def classify(score) when score > 0.75, do: :emergent_intelligence
  def classify(score) when score > 0.6, do: :proto_intelligence
  def classify(_), do: :non_emergent

  # ==================== Metric Estimators ====================

  def novelty_persistence(state) do
    worlds = get_worlds(state)
    if Enum.empty?(worlds) do
      0.5
    else
      avg_branches = Enum.reduce(worlds, 0, &(&1.active_branches + &2)) / length(worlds)
      clamp(avg_branches / 24.0, 0.0, 1.0)
    end
  end

  def cross_world_transfer(state) do
    worlds = get_worlds(state)
    if Enum.empty?(worlds) do
      0.5
    else
      avg_div = Enum.reduce(worlds, 0.0, &(&1.semantic_diversity + &2)) / length(worlds)
      clamp(avg_div, 0.0, 1.0)
    end
  end

  def autonomous_optimization(state) do
    worlds = get_worlds(state)
    if Enum.empty?(worlds) do
      0.5
    else
      # High when average fitness is high and stabilizer overreach is low (self-steering adaptability)
      avg_fitness = Enum.reduce(worlds, 0.0, &((Map.get(&1, :fitness) || 0.5) + &2)) / length(worlds)
      avg_overreach = Enum.reduce(worlds, 0.0, &(&1.stabilizer_overreach + &2)) / length(worlds)
      clamp(avg_fitness - avg_overreach * 0.3, 0.0, 1.0)
    end
  end

  def stability_under_drift(state) do
    worlds = get_worlds(state)
    if Enum.empty?(worlds) do
      0.5
    else
      # Sud = 1.0 - (drift / collapse risk) -> mapped using entropy & coherence
      avg_entropy = Enum.reduce(worlds, 0.0, &(&1.entropy + &2)) / length(worlds)
      avg_coherence = Enum.reduce(worlds, 0.0, &(&1.coherence + &2)) / length(worlds)
      clamp(avg_coherence * (1.0 - abs(avg_entropy - 0.7)), 0.0, 1.0)
    end
  end

  def meta_awareness(state) do
    worlds = get_worlds(state)
    if Enum.empty?(worlds) do
      0.5
    else
      # Average MSG pressure correlation
      avg_pressure = Enum.reduce(worlds, 0.0, &(&1.msg_pressure + &2)) / length(worlds)
      clamp(avg_pressure, 0.0, 1.0)
    end
  end

  # ==================== Helpers ====================

  defp get_worlds(state) do
    cond do
      is_map(state) and Map.has_key?(state, :worlds) -> Map.values(state.worlds)
      is_map(state) -> Map.values(state)
      is_list(state) -> state
      true -> []
    end
  end

  defp clamp(val, min, max) do
    max(min, min(val, max))
  end
end
