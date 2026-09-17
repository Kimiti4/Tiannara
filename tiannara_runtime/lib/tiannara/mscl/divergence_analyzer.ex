defmodule Tiannara.MSCL.DivergenceAnalyzer do
  @moduledoc """
  Computes divergence baseline asynchronously.
  """
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{divergence: 0.0}}
  end

  def handle_info({:analyze, data}, state) do
    divergence = compute_divergence(data)
    {:noreply, %{state | divergence: divergence}}
  end

  defp compute_divergence(data) when is_list(data), do: :math.log(length(data) + 1)
  defp compute_divergence(_), do: 0.0

  def analyze_pairwise_divergence(observer_a, observer_b, state_a, state_b) do
    score = compute_state_divergence(state_a, state_b)
    status = classify_divergence(score)
    %{divergence_score: score, status: status, observer_a: observer_a, observer_b: observer_b}
  end

  def analyze_global_divergence(observer_states) do
    pairs = for {id_a, _} <- observer_states,
                 {id_b, _} <- observer_states,
                 id_a < id_b,
                 do: {id_a, id_b}
    divergences = Enum.map(pairs, fn {a, b} ->
      compute_state_divergence(Map.get(observer_states, a, %{}), Map.get(observer_states, b, %{}))
    end)
    %{
      mean_divergence: if(length(divergences) > 0, do: Enum.sum(divergences) / length(divergences), else: 0.0),
      max_divergence: if(length(divergences) > 0, do: Enum.max(divergences), else: 0.0),
      total_pairs: length(pairs)
    }
  end

  def detect_anomalies(history, threshold) do
    anomalous = Enum.filter(history, fn entry ->
      Map.get(entry, :rate_of_change, 0.0) > threshold
    end)
    anomalous_observers = Enum.flat_map(anomalous, fn entry ->
      [Map.get(entry, :observer_a), Map.get(entry, :observer_b)]
    end) |> Enum.uniq()
    %{anomalies_detected: length(anomalous), anomalous_observers: anomalous_observers}
  end

  defp compute_state_divergence(state_a, state_b) do
    keys = Map.keys(state_a) ++ Map.keys(state_b) |> Enum.uniq()
    if length(keys) == 0 do
      0.0
    else
      diff = Enum.reduce(keys, 0.0, fn k, acc ->
        a = Map.get(state_a, k, 0)
        b = Map.get(state_b, k, 0)
        acc + abs(divergence_value(a) - divergence_value(b))
      end)
      min(1.0, diff / length(keys) / 100.0)
    end
  end

  defp divergence_value(v) when is_number(v), do: v
  defp divergence_value(v) when is_list(v), do: Enum.sum(v)
  defp divergence_value(_), do: 0.0

  defp classify_divergence(score) when score < 0.3, do: :safe
  defp classify_divergence(score) when score < 0.6, do: :elevated
  defp classify_divergence(score) when score < 0.9, do: :critical
  defp classify_divergence(_), do: :emergency
end
