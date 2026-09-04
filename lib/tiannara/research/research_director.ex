defmodule Tiannara.Research.ResearchDirector do
  @moduledoc """
  Research Director — TIA-OMEGA-2

  The autonomous scientific investigation engine for Tiannara.
  Receives priorities from Sentinel, generates hypotheses, plans and
  executes experiments, scores evidence, and integrates validated
  knowledge into Executive Memory.

  ## Scientific Method Pipeline

      Observation (from Sentinel)
          ↓
      Hypothesis Generation
          ↓
      Hypothesis Ranking (expected information gain)
          ↓
      Experiment Planning
          ↓
      Experiment Execution
          ↓
      Evidence Scoring
          ↓
      Validation
          ↓
      Knowledge Integration (into Executive Memory)

  ## Constitutional Alignment

    - Scientific Method: The entire pipeline IS the scientific method.
    - Evidence Before Confidence: Never optimize for appearing correct.
    - Continuous Self-Evaluation: Hypotheses are continuously re-evaluated.
    - Memory Philosophy: Data → Information → Knowledge → Patterns → Principles.
    - Verification First: No knowledge is integrated without validation.
    - Safety: Capability never outpaces verification.
    - Explainability: Every hypothesis carries rationale and evidence chain.
    - Modularity: Each pipeline stage is an isolated, replaceable module.
  """

  use Supervisor

  require Logger

  alias Tiannara.Research.{HypothesisRanker, ExperimentPlanner, ResearchQueue, KnowledgeIntegrator, EvidenceScorer}

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec status() :: map()
  def status do
    %{queue: ResearchQueue.status(), ranker: HypothesisRanker.status(), planner: ExperimentPlanner.status(), scorer: EvidenceScorer.status(), integrator: KnowledgeIntegrator.status()}
  end

  @spec health() :: map()
  def health do
    %{status: :healthy, active_hypotheses: HypothesisRanker.active_count(), pending_experiments: ResearchQueue.pending_count(), running_experiments: ResearchQueue.running_count(), validated_knowledge: KnowledgeIntegrator.total_integrated(), evidence_scored: EvidenceScorer.total_scored()}
  end

  @spec ingest_priorities([map()]) :: {:ok, non_neg_integer()}
  def ingest_priorities(priorities) do
    GenServer.call(__MODULE__.Pipeline, {:ingest, priorities}, 30_000)
  end

  @spec advance() :: :ok
  def advance do
    GenServer.cast(__MODULE__.Pipeline, :advance)
  end

  @spec validated_knowledge() :: [map()]
  def validated_knowledge do
    KnowledgeIntegrator.real_knowledge(50)
  end

  @spec quarantined_count() :: non_neg_integer()
  def quarantined_count do
    GenServer.call(__MODULE__.Pipeline, :quarantined_count)
  end

  @impl true
  def init(opts) do
    Logger.info("[ResearchDirector] Starting Research Director...")

    children = [
      %{id: ResearchQueue, start: {ResearchQueue, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: HypothesisRanker, start: {HypothesisRanker, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: ExperimentPlanner, start: {ExperimentPlanner, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: EvidenceScorer, start: {EvidenceScorer, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: KnowledgeIntegrator, start: {KnowledgeIntegrator, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: __MODULE__.Pipeline, start: {__MODULE__.Pipeline, :start_link, [opts]}, restart: :permanent, shutdown: 10_000, type: :worker}
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 5, max_seconds: 30)
  end
end

defmodule Tiannara.Research.ResearchDirector.Pipeline do
  @moduledoc """
  Pipeline orchestrator for the Research Director.
  Advances the scientific investigation pipeline on each trigger.
  """

  use GenServer

  require Logger

  alias Tiannara.Research.{HypothesisRanker, ExperimentPlanner, ResearchQueue, KnowledgeIntegrator, EvidenceScorer}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec ingest([map()]) :: {:ok, non_neg_integer()}
  def ingest(priorities) do
    GenServer.call(__MODULE__, {:ingest, priorities}, 30_000)
  end

  @spec advance() :: :ok
  def advance do
    GenServer.cast(__MODULE__, :advance)
  end

  @impl true
  def init(_opts) do
    Logger.info("[ResearchDirector.Pipeline] Initialized (R0 quarantine active: fabricated experiment execution disabled).")
    {:ok, %{cycles: 0, last_advance_at: nil, total_hypotheses_generated: 0, total_experiments_planned: 0, total_knowledge_integrated: 0, total_quarantined: 0}}
  end

  @impl true
  def handle_call({:ingest, priorities}, _from, state) do
    hypotheses = HypothesisRanker.generate_from_priorities(priorities)
    ranked = HypothesisRanker.rank(hypotheses)

    Enum.each(ranked, fn hypothesis ->
      ResearchQueue.enqueue(:hypothesis, hypothesis)
    end)

    count = length(ranked)

    :telemetry.execute([:tiannara, :research, :hypotheses_generated], %{count: count}, %{sources: Enum.map(priorities, & &1[:domain])})

    {:reply, {:ok, count}, %{state | total_hypotheses_generated: state.total_hypotheses_generated + count}}
  end

  @impl true
  def handle_cast(:advance, state) do
    case ResearchQueue.dequeue() do
      {:ok, :hypothesis, hypothesis} ->
        experiment = ExperimentPlanner.plan(hypothesis)
        ResearchQueue.enqueue(:experiment, experiment)

        :telemetry.execute([:tiannara, :research, :experiment_planned], %{count: 1}, %{hypothesis_id: hypothesis.id})

        {:noreply, %{state | cycles: state.cycles + 1, last_advance_at: DateTime.utc_now(), total_experiments_planned: state.total_experiments_planned + 1}}

      {:ok, :experiment, experiment} ->
        quarantine_experiment(experiment)
        {:noreply, %{state | cycles: state.cycles + 1, last_advance_at: DateTime.utc_now(), total_quarantined: state.total_quarantined + 1}}

      :empty ->
        {:noreply, %{state | cycles: state.cycles + 1, last_advance_at: DateTime.utc_now()}}
    end
  end

  @impl true
  def handle_call(:quarantined_count, _from, state) do
    {:reply, state.total_quarantined, state}
  end

  defp quarantine_experiment(experiment) do
    Logger.warning("[ResearchDirector] R0 quarantine: experiment #{experiment.id} — no fabricated result persisted.")

    :telemetry.execute(
      [:tiannara, :research, :experiment_quarantined],
      %{count: 1},
      %{experiment_id: experiment.id, execution_mode: :quarantined_by_R0, reason: :fabrication_path_disabled}
    )
  end
end
