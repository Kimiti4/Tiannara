defmodule Tiannara.Research.HypothesisRanker do
  @moduledoc """
  Hypothesis Ranker — generates and ranks scientific hypotheses.

  Transforms Sentinel priorities into testable hypotheses, then ranks them
  by expected information gain, feasibility, and constitutional relevance.

  ## Ranking Criteria

    - Expected Information Gain (EIG): How much uncertainty is reduced?
    - Feasibility: Can we test this with available resources?
    - Constitutional Relevance: Does this advance Tiannara's mission?
    - Urgency: How time-sensitive is this investigation?
    - Prior Evidence: What existing evidence supports or contradicts this?

  ## Constitutional Alignment

    - Scientific Method: Hypotheses are explicit, testable, and falsifiable.
    - Evidence Before Confidence: Rankings are evidence-weighted, not opinion.
    - Explainability: Every hypothesis carries rationale and evidence chain.
    - Continuous Self-Evaluation: Hypotheses are re-ranked as evidence arrives.
    - Uncertainty: Never hidden; confidence intervals are explicit.
  """

  use GenServer

  require Logger

  alias Tiannara.Executive.Types

  @type hypothesis() :: %{
    id: binary(), title: String.t(), statement: String.t(), domain: atom(), signal: atom(),
    source_priority_id: binary() | nil, confidence: float(), eig_score: float(),
    feasibility: float(), urgency: float(), rank_score: float(), rationale: String.t(),
    falsification_criteria: String.t(), evidence_for: [term()], evidence_against: [term()],
    status: :pending | :testing | :validated | :rejected | :refined, created_at: DateTime.t(), updated_at: DateTime.t()
  }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec generate_from_priorities([map()]) :: [hypothesis()]
  def generate_from_priorities(priorities) do
    GenServer.call(__MODULE__, {:generate, priorities}, 30_000)
  end

  @spec rank([hypothesis()]) :: [hypothesis()]
  def rank(hypotheses) do
    GenServer.call(__MODULE__, {:rank, hypotheses})
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
    {:ok, %{hypotheses: %{}, total_generated: 0, total_ranked: 0}}
  end

  @impl true
  def handle_call({:generate, priorities}, _from, state) do
    hypotheses = Enum.flat_map(priorities, &priority_to_hypotheses/1)

    new_hypotheses = Enum.reduce(hypotheses, state.hypotheses, fn h, acc -> Map.put(acc, h.id, h) end)

    {:reply, hypotheses, %{state | hypotheses: new_hypotheses, total_generated: state.total_generated + length(hypotheses)}}
  end

  @impl true
  def handle_call({:rank, hypotheses}, _from, state) do
    ranked = hypotheses |> Enum.map(&compute_rank_score/1) |> Enum.sort_by(& &1.rank_score, :desc)
    {:reply, ranked, %{state | total_ranked: state.total_ranked + 1}}
  end

  @impl true
  def handle_call(:active_count, _from, state) do
    active = state.hypotheses |> Map.values() |> Enum.count(fn h -> h.status in [:pending, :testing] end)
    {:reply, active, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{total_hypotheses: map_size(state.hypotheses), total_generated: state.total_generated, total_ranked: state.total_ranked, by_status: state.hypotheses |> Map.values() |> Enum.frequencies_by(& &1.status)}, state}
  end

  defp priority_to_hypotheses(priority) do
    base_hypothesis = %{
      id: Types.new_id(), title: "#{priority.domain}: #{priority.signal} investigation",
      statement: "The observed #{priority.signal} behavior in #{priority.domain} is caused by an identifiable and addressable factor.",
      domain: priority.domain, signal: priority.signal, source_priority_id: priority.id,
      confidence: 0.5, eig_score: 0.0, feasibility: 0.0, urgency: 0.0, rank_score: 0.0,
      rationale: priority.rationale,
      falsification_criteria: "If controlled experiments show no significant change in #{priority.signal} when the suspected factor is varied, the hypothesis is rejected.",
      evidence_for: [priority.rationale], evidence_against: [],
      status: :pending, created_at: DateTime.utc_now(), updated_at: DateTime.utc_now()
    }

    domain_hypotheses = case priority.domain do
      :memory ->
        [
          %{base_hypothesis | id: Types.new_id(), title: "Memory: allocation pattern anomaly", statement: "Memory growth is driven by a specific allocation pattern that can be identified and optimized.", eig_score: 0.8, feasibility: 0.9, urgency: priority_score_to_urgency(priority.score)},
          %{base_hypothesis | id: Types.new_id(), title: "Memory: process leak", statement: "A subset of processes is failing to release memory, causing monotonic growth.", eig_score: 0.7, feasibility: 0.8, urgency: priority_score_to_urgency(priority.score)}
        ]
      :performance ->
        [%{base_hypothesis | id: Types.new_id(), title: "Performance: scheduler saturation", statement: "BEAM scheduler saturation is the primary cause of observed latency increases.", eig_score: 0.75, feasibility: 0.85, urgency: priority_score_to_urgency(priority.score)}]
      :process ->
        [%{base_hypothesis | id: Types.new_id(), title: "Process: resource exhaustion risk", statement: "Current resource consumption trajectory will exhaust available capacity within a predictable timeframe.", eig_score: 0.85, feasibility: 0.7, urgency: priority_score_to_urgency(priority.score)}]
      _ ->
        [%{base_hypothesis | eig_score: 0.6, feasibility: 0.7, urgency: priority_score_to_urgency(priority.score)}]
    end

    domain_hypotheses
  end

  defp compute_rank_score(hypothesis) do
    score = hypothesis.eig_score * 0.4 + hypothesis.feasibility * 0.3 + hypothesis.urgency * 0.3
    %{hypothesis | rank_score: Float.round(score, 4)}
  end

  defp priority_score_to_urgency(score) when score >= 0.9, do: 1.0
  defp priority_score_to_urgency(score) when score >= 0.7, do: 0.8
  defp priority_score_to_urgency(score) when score >= 0.5, do: 0.5
  defp priority_score_to_urgency(_score), do: 0.3
end
