defmodule ObservationBus.CIL.ConfidenceEngine do
  @moduledoc """
  Assigns confidence scores to patterns, anomalies, recommendations, and
  health assessments throughout the Constitutional Intelligence Layer.

  Confidence is computed from:
    * **Sample size** — more observations = higher confidence
    * **Consistency** — stable patterns increase confidence
    * **Recency** — recent observations weighted higher
    * **Source reliability** — trusted sources increase confidence
  """

  use GenServer

  defstruct [:confidence_log, :total_evaluations]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %__MODULE__{confidence_log: :queue.new(), total_evaluations: 0}}
  end

  @doc "Evaluate confidence for an intelligence artifact."
  @spec evaluate(String.t(), atom(), keyword()) :: {:ok, float()}
  def evaluate(artifact_id, category, opts \\ []) do
    GenServer.call(__MODULE__, {:evaluate, artifact_id, category, opts})
  end

  @doc "Return recent confidence evaluations."
  @spec recent_evaluations(pos_integer()) :: [map()]
  def recent_evaluations(count \\ 20) do
    GenServer.call(__MODULE__, {:recent, count})
  end

  @doc "Return engine stats."
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def handle_call({:evaluate, artifact_id, category, opts}, _from, state) do
    sample_size = Keyword.get(opts, :sample_size, 1)
    consistency = Keyword.get(opts, :consistency, 0.5)
    recency_hours = Keyword.get(opts, :recency_hours, 24)
    source_reliability = Keyword.get(opts, :source_reliability, 0.5)

    score = compute_confidence(sample_size, consistency, recency_hours, source_reliability)
    score = max(0.0, min(1.0, score))

    evaluation = %{
      artifact_id: artifact_id,
      category: category,
      confidence: score,
      factors: %{
        sample_size: sample_size,
        consistency: consistency,
        recency_hours: recency_hours,
        source_reliability: source_reliability
      },
      evaluated_at: DateTime.utc_now()
    }

    log = :queue.in(evaluation, state.confidence_log)
    log = if :queue.len(log) > 500 do
      {:value, _} = :queue.out(log)
      log
    else
      log
    end

    {:reply, {:ok, score},
     %{state | confidence_log: log, total_evaluations: state.total_evaluations + 1}}
  end

  def handle_call({:recent, count}, _from, state) do
    all = :queue.to_list(state.confidence_log)
    {:reply, Enum.take(all, count), state}
  end

  def handle_call(:stats, _from, state) do
    {:reply, %{
      total_evaluations: state.total_evaluations,
      recent_log_size: :queue.len(state.confidence_log)
    }, state}
  end

  defp compute_confidence(sample_size, consistency, recency_hours, source_reliability) do
    sample_factor = 1.0 - 1.0 / max(sample_size, 1)
    consistency_factor = consistency
    recency_factor = max(0.0, 1.0 - recency_hours / 720.0)  # 30 days = 0
    reliability_factor = source_reliability

    0.3 * sample_factor +
    0.3 * consistency_factor +
    0.2 * recency_factor +
    0.2 * reliability_factor
  end
end
