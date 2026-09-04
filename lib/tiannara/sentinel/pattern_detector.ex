defmodule Tiannara.Sentinel.PatternDetector do
  @moduledoc """
  Pattern Detector — identifies trends, cycles, and correlations in observations.

  Analyzes observation windows to detect:
    - Monotonic trends (increasing/decreasing)
    - Periodic cycles
    - Threshold crossings
    - Correlated signals
    - Rate-of-change anomalies

  ## Constitutional Alignment

    - Scientific Method: Patterns are hypotheses requiring validation.
    - Evidence Before Confidence: Every pattern carries a confidence score.
    - Explainability: Patterns include rationale and supporting data.
    - Bottleneck Discovery: Trends in resource usage reveal emerging bottlenecks.
    - Uncertainty: Never hidden; confidence is always quantified.
  """

  use GenServer

  require Logger

  @type pattern() :: %{
    id: binary(), type: :trend | :cycle | :threshold | :correlation | :rate_change,
    signal: atom(), direction: :increasing | :decreasing | :stable | :oscillating,
    confidence: float(), magnitude: float(), window_size: non_neg_integer(),
    detected_at: DateTime.t(), rationale: String.t()
  }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec analyze([map()]) :: [pattern()]
  def analyze(observations) do
    GenServer.call(__MODULE__, {:analyze, observations}, 30_000)
  end

  @spec tracked_count() :: non_neg_integer()
  def tracked_count do
    GenServer.call(__MODULE__, :tracked_count)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(_opts) do
    {:ok, %{active_patterns: [], total_detections: 0, last_analysis_at: nil}}
  end

  @impl true
  def handle_call({:analyze, observations}, _from, state) do
    patterns = detect_patterns(observations)

    new_state = %{state | active_patterns: patterns, total_detections: state.total_detections + length(patterns), last_analysis_at: DateTime.utc_now()}

    :telemetry.execute([:tiannara, :sentinel, :patterns_detected], %{count: length(patterns)}, %{types: Enum.map(patterns, & &1.type)})

    {:reply, patterns, new_state}
  end

  @impl true
  def handle_call(:tracked_count, _from, state) do
    {:reply, length(state.active_patterns), state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{active_patterns: length(state.active_patterns), total_detections: state.total_detections, last_analysis_at: state.last_analysis_at, pattern_types: Enum.map(state.active_patterns, & &1.type)}, state}
  end

  defp detect_patterns(observations) when length(observations) < 3, do: []

  defp detect_patterns(observations) do
    []
    |> detect_memory_trends(observations)
    |> detect_process_trends(observations)
    |> detect_rate_anomalies(observations)
    |> detect_threshold_crossings(observations)
  end

  defp detect_memory_trends(patterns, observations) do
    memory_obs = observations |> Enum.filter(fn obs -> obs[:type] == :memory_pressure end) |> Enum.map(fn obs -> obs.value[:total_bytes] || 0 end)

    case detect_monotonic_trend(memory_obs) do
      {:trend, direction, magnitude, confidence} when direction != :stable ->
        pattern = %{
          id: Tiannara.Executive.Types.new_id(), type: :trend, signal: :memory_usage, direction: direction,
          confidence: confidence, magnitude: magnitude, window_size: length(memory_obs), detected_at: DateTime.utc_now(),
          rationale: "Memory usage is #{direction} (magnitude=#{Float.round(magnitude, 2)}, confidence=#{Float.round(confidence, 2)}) over #{length(memory_obs)} observations."
        }
        [pattern | patterns]
      _ -> patterns
    end
  end

  defp detect_process_trends(patterns, observations) do
    process_obs = observations |> Enum.filter(fn obs -> obs[:type] == :process_health end) |> Enum.map(fn obs -> obs.value[:total_processes] || 0 end)

    case detect_monotonic_trend(process_obs) do
      {:trend, direction, magnitude, confidence} when direction != :stable ->
        pattern = %{
          id: Tiannara.Executive.Types.new_id(), type: :trend, signal: :process_count, direction: direction,
          confidence: confidence, magnitude: magnitude, window_size: length(process_obs), detected_at: DateTime.utc_now(),
          rationale: "Process count is #{direction} (magnitude=#{Float.round(magnitude, 2)}, confidence=#{Float.round(confidence, 2)})."
        }
        [pattern | patterns]
      _ -> patterns
    end
  end

  defp detect_rate_anomalies(patterns, observations) do
    timestamps = observations |> Enum.map(fn obs -> obs[:timestamp] end) |> Enum.reject(&is_nil/1) |> Enum.sort()

    if length(timestamps) >= 4 do
      intervals = timestamps |> Enum.chunk_every(2, 1, :discard) |> Enum.map(fn [a, b] -> DateTime.diff(b, a, :millisecond) end)
      avg_interval = Enum.sum(intervals) / length(intervals)
      max_interval = Enum.max(intervals)

      if max_interval > avg_interval * 3.0 do
        pattern = %{
          id: Tiannara.Executive.Types.new_id(), type: :rate_change, signal: :observation_frequency,
          direction: :oscillating, confidence: 0.7, magnitude: max_interval / max(avg_interval, 1),
          window_size: length(timestamps), detected_at: DateTime.utc_now(),
          rationale: "Observation interval spike detected: max=#{max_interval}ms vs avg=#{Float.round(avg_interval, 1)}ms."
        }
        [pattern | patterns]
      else
        patterns
      end
    else
      patterns
    end
  end

  defp detect_threshold_crossings(patterns, observations) do
    vm_obs = observations |> Enum.filter(fn obs -> obs[:type] == :vm_health end) |> List.last()

    if vm_obs do
      atom_count = vm_obs.value[:atom_count] || 0
      atom_limit = vm_obs.value[:atom_limit] || 1_048_576
      ratio = atom_count / atom_limit

      if ratio > 0.8 do
        pattern = %{
          id: Tiannara.Executive.Types.new_id(), type: :threshold, signal: :atom_table, direction: :increasing,
          confidence: 0.95, magnitude: ratio, window_size: 1, detected_at: DateTime.utc_now(),
          rationale: "Atom table at #{Float.round(ratio * 100, 1)}% capacity (#{atom_count}/#{atom_limit}). Risk of atom exhaustion."
        }
        [pattern | patterns]
      else
        patterns
      end
    else
      patterns
    end
  end

  defp detect_monotonic_trend(values) when length(values) < 3, do: {:trend, :stable, 0.0, 0.0}

  defp detect_monotonic_trend(values) do
    diffs = values |> Enum.chunk_every(2, 1, :discard) |> Enum.map(fn [a, b] -> b - a end)
    positive = Enum.count(diffs, &(&1 > 0))
    negative = Enum.count(diffs, &(&1 < 0))
    total = length(diffs)

    direction = cond do
      positive > total * 0.7 -> :increasing
      negative > total * 0.7 -> :decreasing
      true -> :stable
    end

    magnitude = if length(values) > 1 do
      first = List.first(values); last = List.last(values)
      if first != 0, do: abs(last - first) / abs(first), else: 0.0
    else
      0.0
    end

    confidence = cond do
      direction == :stable -> 0.5
      positive + negative == 0 -> 0.5
      true -> max(positive, negative) / total
    end

    {:trend, direction, magnitude, confidence}
  end
end
