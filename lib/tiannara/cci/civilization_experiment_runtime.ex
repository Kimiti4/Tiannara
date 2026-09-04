defmodule Tiannara.CCI.CivilizationExperimentRuntime do
  @moduledoc """
  Civilization Experiment Runtime (CXR): enables safe experiments on governance models,
  research structures, knowledge systems, resource allocation, capability development.
  Process: Hypothesis → Simulation → Small-scale Trial → Evaluation → Promotion/Rejection.
  """
  use GenServer
  alias Tiannara.CCI.Models.CivilizationExperiment

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)

  def propose_experiment(pid, hypothesis, experiment_type), do: GenServer.call(pid, {:propose, hypothesis, experiment_type})
  def run_simulation(pid, experiment_id), do: GenServer.call(pid, {:simulate, experiment_id})
  def run_trial(pid, experiment_id), do: GenServer.call(pid, {:trial, experiment_id})
  def evaluate(pid, experiment_id), do: GenServer.call(pid, {:evaluate, experiment_id})

  @impl true
  def init(_), do: {:ok, %{experiments: %{}}}

  @impl true
  def handle_call({:propose, hypothesis, experiment_type}, _from, state) do
    experiment = %CivilizationExperiment{
      id: UUID.uuid4(),
      hypothesis: hypothesis,
      timestamp: DateTime.utc_now(),
      experiment_type: experiment_type,
      scope: determine_scope(experiment_type),
      simulation_phase: :pending,
      trial_phase: :pending,
      evaluation_metrics: define_metrics(experiment_type),
      success_criteria: define_success_criteria(experiment_type),
      failure_conditions: define_failure_conditions(experiment_type),
      rollback_plan: define_rollback(experiment_type),
      status: :proposed,
      results: nil,
      human_approval: :pending,
      constitutional_check: :pending
    }
    state = put_in(state, [:experiments, experiment.id], experiment)
    {:reply, {:ok, experiment}, state}
  end

  @impl true
  def handle_call({:simulate, experiment_id}, _from, state) do
    case Map.get(state.experiments, experiment_id) do
      nil -> {:reply, {:error, :not_found}, state}
      experiment ->
        sim_results = run_simulation_phase(experiment)
        updated = %{experiment | simulation_phase: :completed, results: sim_results, status: :simulated}
        state = put_in(state, [:experiments, experiment_id], updated)
        {:reply, {:ok, updated}, state}
    end
  end

  @impl true
  def handle_call({:trial, experiment_id}, _from, state) do
    case Map.get(state.experiments, experiment_id) do
      nil -> {:reply, {:error, :not_found}, state}
      experiment when experiment.simulation_phase != :completed ->
        {:reply, {:error, :simulation_required}, state}
      experiment ->
        trial_results = run_trial_phase(experiment)
        updated = %{experiment | trial_phase: :completed, results: trial_results, status: :trialed}
        state = put_in(state, [:experiments, experiment_id], updated)
        {:reply, {:ok, updated}, state}
    end
  end

  @impl true
  def handle_call({:evaluate, experiment_id}, _from, state) do
    case Map.get(state.experiments, experiment_id) do
      nil -> {:reply, {:error, :not_found}, state}
      experiment when experiment.trial_phase != :completed ->
        {:reply, {:error, :trial_required}, state}
      experiment ->
        evaluation = evaluate_experiment(experiment)
        decision = if evaluation.success, do: :promote, else: :reject
        updated = %{experiment | status: decision, results: evaluation}
        state = put_in(state, [:experiments, experiment_id], updated)
        {:reply, {:ok, updated}, state}
    end
  end

  defp determine_scope(type) do
    case type do
      :governance_model -> :civilization_wide
      :research_structure -> :multi_domain
      :knowledge_system -> :cross_domain
      :resource_allocation -> :resource_layer
      :capability_development -> :capability_ecology
    end
  end

  defp define_metrics(type) do
    case type do
      :governance_model -> [:decision_quality, :constitutional_compliance, :human_oversight_preservation]
      :research_structure -> [:discovery_rate, :knowledge_compounding, :diversity]
      :knowledge_system -> [:retrieval_accuracy, :knowledge_reuse, :preservation_rate]
      :resource_allocation -> [:efficiency, :equity, :capability_growth]
      :capability_development -> [:innovation_rate, :capability_fitness, :adoption]
    end
  end

  defp define_success_criteria(_type), do: %{improvement_threshold: 0.15, no_regression: true, constitutional_compliance: true}
  defp define_failure_conditions(_type), do: [:constitutional_violation, :knowledge_loss, :human_oversight_reduction]
  defp define_rollback(_type), do: "Revert to pre-experiment state; preserve all observations as civilizational memory."

  defp run_simulation_phase(experiment) do
    %{
      phase: :simulation,
      metrics: Enum.map(experiment.evaluation_metrics, fn m -> {m, :rand.uniform() * 0.4 + 0.5} end) |> Map.new(),
      confidence: 0.7,
      unexpected_behaviors: []
    }
  end

  defp run_trial_phase(experiment) do
    %{
      phase: :trial,
      metrics: Enum.map(experiment.evaluation_metrics, fn m -> {m, :rand.uniform() * 0.3 + 0.6} end) |> Map.new(),
      confidence: 0.8,
      observations: []
    }
  end

  defp evaluate_experiment(experiment) do
    trial_metrics = experiment.results.metrics
    meets_criteria = Enum.all?(trial_metrics, fn {_m, v} -> v >= experiment.success_criteria.improvement_threshold end)
    no_failures = not Enum.any?(Map.keys(trial_metrics), fn m -> m in experiment.failure_conditions end)

    %{
      success: meets_criteria and no_failures,
      metrics: trial_metrics,
      recommendation: if(meets_criteria and no_failures, do: :promote, else: :reject),
      lessons_learned: extract_lessons(experiment, trial_metrics)
    }
  end

  defp extract_lessons(experiment, metrics) do
    ["Experiment #{experiment.id} (#{experiment.experiment_type}): hypothesis #{if Enum.all?(metrics, fn {_, v} -> v > 0.7 end), do: "supported", else: "not fully supported"}."]
  end
end
