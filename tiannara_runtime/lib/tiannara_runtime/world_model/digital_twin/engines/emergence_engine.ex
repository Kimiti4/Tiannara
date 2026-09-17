defmodule TiannaraRuntime.WorldModel.DigitalTwin.Engines.EmergenceEngine do
  @moduledoc """
  Phase 17.7.5 — EmergenceEngine.
  Detects emergent behavior in digital twin simulations.
  Covers unexpected equilibria, cascading failures, resilience formation, innovation clusters, systemic instability.
  """

  def analyze(state_history) do
    patterns =
      []
      |> detect_unexpected_equilibria(state_history)
      |> detect_cascading_failures(state_history)
      |> detect_resilience_formation(state_history)
      |> detect_innovation_clusters(state_history)
      |> detect_systemic_instability(state_history)

    {:ok, patterns}
  end

  def detect_unexpected_equilibria(patterns, state_history) do
    if length(state_history) < 10 do
      patterns
    else
      recent = Enum.take(state_history, -10)
      stable = Enum.all?(recent, fn s -> s == hd(recent) end)

      if stable do
        [%{type: :unexpected_equilibrium, tick: hd(recent).tick, confidence: 0.8} | patterns]
      else
        patterns
      end
    end
  end

  def detect_cascading_failures(patterns, state_history) do
    if length(state_history) < 3 do
      patterns
    else
      failures =
        state_history
        |> Enum.chunk_every(3, 1)
        |> Enum.filter(fn chunk -> length(chunk) == 3 end)
        |> Enum.filter(fn [a, b, c] ->
          a_health = extract_health(a)
          b_health = extract_health(b)
          c_health = extract_health(c)
          a_health > b_health and b_health > c_health and (a_health - c_health) > 0.3
        end)

      if failures == [] do
        patterns
      else
        last_failure = List.last(failures)
        [%{type: :cascading_failure, tick: List.last(last_failure).tick, severity: :high} | patterns]
      end
    end
  end

  def detect_resilience_formation(patterns, state_history) do
    if length(state_history) < 20 do
      patterns
    else
      first_half = Enum.take(state_history, div(length(state_history), 2))
      second_half = Enum.drop(state_history, div(length(state_history), 2))

      first_health = avg_health(first_half)
      second_health = avg_health(second_half)

      if second_health > first_health + 0.15 do
        latest = List.last(state_history)
        [%{type: :resilience_formation, tick: latest.tick, improvement: second_health - first_health} | patterns]
      else
        patterns
      end
    end
  end

  def detect_innovation_clusters(patterns, state_history) do
    if length(state_history) < 10 do
      patterns
    else
      discovery_rates =
        state_history
        |> Enum.chunk_every(5, 1)
        |> Enum.map(fn chunk ->
          discoveries = Enum.count(chunk, fn s ->
            model_states = s.model_states || %{}
            Enum.any?(model_states, fn {_id, ms} ->
              Map.get(ms, "discovery_count", 0) > 0 or Map.get(ms, :discovery_count, 0) > 0
            end)
          end)
          discoveries
        end)

      cluster_detected = Enum.any?(discovery_rates, fn rate -> rate >= 3 end)

      if cluster_detected do
        latest = List.last(state_history)
        [%{type: :innovation_cluster, tick: latest.tick, intensity: :high} | patterns]
      else
        patterns
      end
    end
  end

  def detect_systemic_instability(patterns, state_history) do
    if length(state_history) >= 5 do
      recent = Enum.take(state_history, -5)
      healths = Enum.map(recent, &extract_health/1)

      variance =
        if length(healths) >= 2 do
          mean = Enum.sum(healths) / length(healths)
          Enum.reduce(healths, 0, fn h, acc -> acc + (h - mean) * (h - mean) end) / length(healths)
        else
          0.0
        end

      if variance > 0.1 do
        [%{type: :systemic_instability, tick: List.last(state_history).tick, severity: :high, variance: variance} | patterns]
      else
        patterns
      end
    else
      patterns
    end
  end

  defp extract_health(state) do
    model_states = state.model_states || %{}
    health_values =
      Enum.flat_map(model_states, fn {_id, ms} ->
        case Map.get(ms, "health") || Map.get(ms, :health) do
          nil -> []
          v when is_number(v) -> [v]
          _ -> []
        end
      end)

    if health_values == [], do: 0.5, else: Enum.sum(health_values) / length(health_values)
  end

  defp avg_health(states) do
    healths = Enum.map(states, &extract_health/1)
    if healths == [], do: 0.5, else: Enum.sum(healths) / length(healths)
  end
end
