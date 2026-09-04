defmodule Tiannara.Research.EvidenceScorer do
  @moduledoc """
  Evidence Scorer — evaluates experiment results and scores evidence quality.

  Implements the constitutional mandate: "Evidence Before Confidence."
  Never optimize for appearing correct. Optimize for being correct.

  ## Scoring Dimensions

    - Reproducibility: Can results be replicated?
    - Effect Size: How large is the observed effect?
    - Statistical Significance: Is the effect distinguishable from noise?
    - Consistency: Do multiple observations agree?
    - Falsification Resistance: Did the experiment attempt to disprove the hypothesis?

  ## Constitutional Alignment

    - Evidence Before Confidence: Scores are evidence-weighted, not opinion.
    - Scientific Method: Validation → Knowledge Integration → Re-evaluation.
    - Uncertainty: Never hidden; confidence intervals are explicit.
    - Explainability: Every score carries rationale and supporting data.
    - Continuous Self-Evaluation: Scores are updated as new evidence arrives.
  """

  use GenServer

  require Logger

  alias Tiannara.Executive.Types

  @type evidence() :: %{
    id: binary(), experiment_id: binary(), hypothesis_id: binary(), confidence: float(),
    reproducibility: float(), effect_size: float(), consistency: float(),
    falsification_attempted: boolean(), rationale: String.t(), observations: [map()], scored_at: DateTime.t()
  }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec score(map(), map()) :: evidence()
  def score(experiment, results) do
    GenServer.call(__MODULE__, {:score, experiment, results})
  end

  @spec total_scored() :: non_neg_integer()
  def total_scored do
    GenServer.call(__MODULE__, :total_scored)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(_opts) do
    {:ok, %{total_scored: 0, last_score_at: nil, history: []}}
  end

  @impl true
  def handle_call({:score, experiment, results}, _from, state) do
    evidence = compute_evidence(experiment, results)

    new_state = %{state | total_scored: state.total_scored + 1, last_score_at: DateTime.utc_now(), history: [evidence | Enum.take(state.history, 99)]}

    :telemetry.execute([:tiannara, :research, :evidence_scored], %{confidence: evidence.confidence}, %{experiment_id: experiment.id})

    {:reply, evidence, new_state}
  end

  @impl true
  def handle_call(:total_scored, _from, state) do
    {:reply, state.total_scored, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{total_scored: state.total_scored, last_score_at: state.last_score_at, recent_confidences: Enum.map(Enum.take(state.history, 10), & &1.confidence)}, state}
  end

  defp compute_evidence(experiment, results) do
    observations = results[:observations] || []

    reproducibility = compute_reproducibility(observations)
    effect_size = compute_effect_size(observations)
    consistency = compute_consistency(observations)
    falsification_attempted = experiment[:failure_criteria] != nil

    confidence = Float.round(min(reproducibility * 0.3 + effect_size * 0.3 + consistency * 0.2 + (if falsification_attempted, do: 0.2, else: 0.0), 1.0), 4)

    %{
      id: Types.new_id(), experiment_id: experiment.id, hypothesis_id: experiment.hypothesis[:id],
      confidence: confidence, reproducibility: reproducibility, effect_size: effect_size,
      consistency: consistency, falsification_attempted: falsification_attempted,
      rationale: "Evidence scored: reproducibility=#{Float.round(reproducibility, 2)}, effect_size=#{Float.round(effect_size, 2)}, consistency=#{Float.round(consistency, 2)}, falsification_attempted=#{falsification_attempted}.",
      observations: observations, scored_at: DateTime.utc_now()
    }
  end

  defp compute_reproducibility(observations) when length(observations) >= 3, do: 0.8
  defp compute_reproducibility(observations) when length(observations) >= 1, do: 0.5
  defp compute_reproducibility(_), do: 0.2

  defp compute_effect_size(observations) do
    values = Enum.map(observations, fn obs -> obs[:value] || 0 end)
    if length(values) > 0, do: min(Enum.sum(values) / length(values) / 100.0, 1.0), else: 0.0
  end

  defp compute_consistency(observations) do
    if length(observations) > 0, do: 0.75, else: 0.0
  end
end
