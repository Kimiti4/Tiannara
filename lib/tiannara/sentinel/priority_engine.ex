defmodule Tiannara.Sentinel.PriorityEngine do
  @moduledoc """
  Priority Engine — generates prioritized research and action requests.

  Transforms anomalies and patterns into actionable priorities that feed
  the Executive Runtime's research queue and attention scheduler.

  ## Priority Levels

    - `:immediate` — Requires action within the current cycle.
    - `:urgent` — Requires action within the next few cycles.
    - `:scheduled` — Should be investigated in normal course.
    - `:background` — Low priority; monitor for escalation.

  ## Constitutional Alignment

    - Bottleneck Discovery: Priorities explicitly target bottlenecks.
    - Evidence Before Confidence: Priority scores are evidence-weighted.
    - Explainability: Every priority carries rationale and evidence chain.
    - Safety: Critical anomalies always receive :immediate priority.
    - Scientific Method: Priorities become hypotheses for the Research Director.
  """

  use GenServer

  require Logger

  @type priority_level() :: :immediate | :urgent | :scheduled | :background

  @type priority() :: %{
    id: binary(), level: priority_level(), score: float(), source_type: :anomaly | :pattern,
    source_id: binary(), domain: atom(), signal: atom(), title: String.t(),
    rationale: String.t(), recommended_action: String.t(), created_at: DateTime.t(), expires_at: DateTime.t() | nil
  }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec update([map()], [map()]) :: :ok
  def update(anomalies, patterns) do
    GenServer.cast(__MODULE__, {:update, anomalies, patterns})
  end

  @spec priorities() :: [priority()]
  def priorities do
    GenServer.call(__MODULE__, :priorities)
  end

  @spec active_count() :: non_neg_integer()
  def active_count do
    GenServer.call(__MODULE__, :active_count)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(_opts) do
    {:ok, %{priorities: [], total_generated: 0, last_update_at: nil}}
  end

  @impl true
  def handle_cast({:update, anomalies, patterns}, state) do
    priorities = generate_priorities(anomalies, patterns)

    :telemetry.execute([:tiannara, :sentinel, :priorities_generated], %{count: length(priorities)}, %{levels: Enum.map(priorities, & &1.level)})

    new_state = %{state | priorities: priorities, total_generated: state.total_generated + length(priorities), last_update_at: DateTime.utc_now()}

    {:noreply, new_state}
  end

  @impl true
  def handle_call(:priorities, _from, state) do
    {:reply, state.priorities, state}
  end

  @impl true
  def handle_call(:active_count, _from, state) do
    {:reply, length(state.priorities), state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{active_priorities: length(state.priorities), total_generated: state.total_generated, last_update_at: state.last_update_at, levels: Enum.frequencies(Enum.map(state.priorities, & &1.level))}, state}
  end

  defp generate_priorities(anomalies, patterns) do
    anomaly_priorities = Enum.map(anomalies, &anomaly_to_priority/1)
    pattern_priorities = Enum.map(patterns, &pattern_to_priority/1)

    (anomaly_priorities ++ pattern_priorities)
    |> Enum.sort_by(& &1.score, :desc)
    |> Enum.take(50)
  end

  defp anomaly_to_priority(anomaly) do
    level = severity_to_level(anomaly.severity)
    score = compute_score(anomaly.severity, anomaly.confidence)

    %{id: Tiannara.Executive.Types.new_id(), level: level, score: score, source_type: :anomaly, source_id: anomaly.id, domain: anomaly.domain, signal: anomaly.signal, title: "#{anomaly.domain}: #{anomaly.signal} #{anomaly.type}", rationale: anomaly.rationale, recommended_action: recommend_action(anomaly), created_at: DateTime.utc_now(), expires_at: nil}
  end

  defp pattern_to_priority(pattern) do
    level = cond do
      pattern.confidence > 0.9 -> :urgent
      pattern.confidence > 0.7 -> :scheduled
      true -> :background
    end

    %{id: Tiannara.Executive.Types.new_id(), level: level, score: pattern.confidence * 0.6, source_type: :pattern, source_id: pattern.id, domain: :performance, signal: pattern.signal, title: "Pattern: #{pattern.signal} #{pattern.direction}", rationale: pattern.rationale, recommended_action: "Investigate #{pattern.signal} trend; validate with targeted experiment.", created_at: DateTime.utc_now(), expires_at: nil}
  end

  defp severity_to_level(:emergency), do: :immediate
  defp severity_to_level(:critical), do: :immediate
  defp severity_to_level(:warning), do: :urgent
  defp severity_to_level(:info), do: :scheduled

  defp compute_score(:emergency, confidence), do: 1.0 * confidence
  defp compute_score(:critical, confidence), do: 0.9 * confidence
  defp compute_score(:warning, confidence), do: 0.6 * confidence
  defp compute_score(:info, confidence), do: 0.3 * confidence

  defp recommend_action(%{domain: :memory, type: :threshold}), do: "Investigate memory allocation; identify top consumers; consider GC tuning or process consolidation."
  defp recommend_action(%{domain: :process, signal: :atom_count}), do: "Audit atom creation; identify dynamic atom generation; consider atom pooling or string keys."
  defp recommend_action(%{domain: :performance, type: :trend}), do: "Profile the trending signal; identify causal factors; design targeted intervention experiment."
  defp recommend_action(_), do: "Investigate anomaly; gather additional evidence; formulate hypothesis for Research Director."
end
