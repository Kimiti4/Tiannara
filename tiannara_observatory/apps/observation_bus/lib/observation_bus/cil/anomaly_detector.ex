defmodule ObservationBus.CIL.AnomalyDetector do
  @moduledoc """
  Detects abnormal behavior across all constitutional categories.

  Maintains baselines per category (runtime, scientific, engineering,
  knowledge, planetary, civilization, evolution, security, governance)
  and compares incoming events against these baselines.

  Each anomaly includes severity (1-10), confidence (0.0-1.0),
  likely cause, evidence, and recommended action.
  """

  use GenServer

  @categories ~w(runtime scientific engineering knowledge planetary civilization evolution security governance)a

  defstruct [:baselines, :anomaly_log, :total_anomalies, :detection_threshold]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    baselines = Enum.into(@categories, %{}, &{&1, default_baseline()})
    {:ok, %__MODULE__{
      baselines: baselines,
      anomaly_log: :queue.new(),
      total_anomalies: 0,
      detection_threshold: 2.0
    }}
  end

  @doc "Feed an event for anomaly analysis."
  @spec analyze(map()) :: :ok | {:anomaly, map()}
  def analyze(event) do
    GenServer.call(__MODULE__, {:analyze, event}, :infinity)
  end

  @doc "Return recent anomalies."
  @spec recent_anomalies(pos_integer()) :: [map()]
  def recent_anomalies(count \\ 20) do
    GenServer.call(__MODULE__, {:recent, count})
  end

  @doc "Get current baselines."
  @spec baselines() :: map()
  def baselines do
    GenServer.call(__MODULE__, :baselines)
  end

  @doc "Get anomaly stats."
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @doc "Set detection sensitivity (lower = more sensitive)."
  @spec set_threshold(float()) :: :ok
  def set_threshold(threshold) do
    GenServer.cast(__MODULE__, {:set_threshold, threshold})
  end

  @impl true
  def handle_call({:analyze, event}, _from, state) do
    category = categorize_event(event)

    case detect_anomaly(event, category, state) do
      nil ->
        new_state = update_baseline(state, category, event)
        {:reply, :ok, new_state}

      anomaly ->
        log = :queue.in(anomaly, state.anomaly_log)
        log = if :queue.len(log) > 1000 do
          {:value, _} = :queue.out(log)
          log
        else
          log
        end
        {:reply, {:anomaly, anomaly},
         %{state | anomaly_log: log, total_anomalies: state.total_anomalies + 1}}
    end
  end

  def handle_call({:recent, count}, _from, state) do
    all = :queue.to_list(state.anomaly_log)
    {:reply, Enum.take(all, count), state}
  end

  def handle_call(:baselines, _from, state) do
    {:reply, state.baselines, state}
  end

  def handle_call(:stats, _from, state) do
    {:reply, %{
      total_anomalies: state.total_anomalies,
      current_queue: :queue.len(state.anomaly_log),
      threshold: state.detection_threshold,
      categories: Map.keys(state.baselines)
    }, state}
  end

  @impl true
  def handle_cast({:set_threshold, threshold}, state) do
    {:noreply, %{state | detection_threshold: threshold}}
  end

  defp categorize_event(event) do
    domain = Map.get(event, :domain, "runtime") |> String.to_existing_atom()
    if domain in @categories, do: domain, else: :runtime
  rescue
    _ -> :runtime
  end

  defp detect_anomaly(event, category, state) do
    baseline = Map.get(state.baselines, category, default_baseline())
    score = compute_anomaly_score(event, baseline)

    if score >= state.detection_threshold do
      %{
        category: category,
        severity: min(10, trunc(score * 2)),
        confidence: min(1.0, (score - state.detection_threshold) / 5.0),
        score: score,
        timestamp: DateTime.utc_now(),
        event_id: Map.get(event, :id),
        likely_cause: infer_cause(event, category),
        evidence: [%{event_id: Map.get(event, :id), domain: Map.get(event, :domain)}],
        recommended_action: recommend_action(category, score)
      }
    end
  end

  defp compute_anomaly_score(event, baseline) do
    event_rate = rate_from_event(event)
    baseline_rate = Map.get(baseline, :rate, 1.0)

    cond do
      baseline_rate == 0 -> if event_rate > 0, do: 3.0, else: 0.0
      true -> abs(event_rate - baseline_rate) / baseline_rate
    end
  end

  defp rate_from_event(event) do
    case Map.get(event, :domain) do
      "runtime" -> Map.get(event, :payload, %{}) |> Map.get(:cpu, 0) |> then(& &1 / 100)
      "discovery" -> 1.0
      "experiment" -> 0.5
      _ -> 0.1
    end
  end

  defp infer_cause(event, category) do
    Map.get(event, :payload, %{})
    |> Map.get(:error, "unexpected #{category} event pattern")
    |> to_string()
  end

  defp recommend_action(:runtime, score) when score > 4, do: "Scale resources and investigate runtime"
  defp recommend_action(:runtime, _), do: "Monitor runtime health"
  defp recommend_action(:scientific, score) when score > 4, do: "Review experiment configuration"
  defp recommend_action(:scientific, _), do: "Monitor discovery pipeline"
  defp recommend_action(:engineering, score) when score > 4, do: "Audit engineering workflow"
  defp recommend_action(:engineering, _), do: "Review engineering metrics"
  defp recommend_action(:knowledge, score) when score > 4, do: "Analyze knowledge graph gaps"
  defp recommend_action(:knowledge, _), do: "Monitor knowledge synthesis"
  defp recommend_action(:security, _), do: "Escalate to security review"
  defp recommend_action(_, _), do: "Review and investigate"

  defp update_baseline(state, category, event) do
    baseline = Map.get(state.baselines, category, default_baseline())
    new_rate = moving_average(baseline.rate, rate_from_event(event))
    updated = %{baseline | rate: new_rate, sample_count: baseline.sample_count + 1}
    put_in(state, [:baselines, category], updated)
  end

  defp moving_average(old, new, alpha \\ 0.1) do
    old * (1 - alpha) + new * alpha
  end

  defp default_baseline do
    %{rate: 0.1, sample_count: 0, established: DateTime.utc_now()}
  end
end
