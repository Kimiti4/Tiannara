defmodule Tiannara.Research.ExperimentPlanner do
  @moduledoc """
  Experiment Planner — designs experiments to test hypotheses.

  For each hypothesis, generates a structured experiment plan including:
    - Objective
    - Variables (independent, dependent, controlled)
    - Methodology
    - Success criteria
    - Resource requirements
    - Estimated duration
    - Risk assessment

  ## Constitutional Alignment

    - Scientific Method: Experiments follow Prediction → Simulation → Experiment.
    - Verification First: Every experiment includes validation criteria.
    - Safety: Risk assessment is mandatory; capability never outpaces verification.
    - Explainability: Every plan carries explicit rationale and methodology.
    - Reproducibility: Plans are deterministic given the same hypothesis.
    - Testability: Experiments include adversarial and stress components.
  """

  use GenServer

  require Logger

  alias Tiannara.Executive.Types

  @type experiment() :: %{
    id: binary(), hypothesis: map(), objective: String.t(), methodology: String.t(),
    variables: %{independent: [atom()], dependent: [atom()], controlled: [atom()]},
    success_criteria: [String.t()], failure_criteria: [String.t()], resources: [atom()],
    estimated_duration_ms: non_neg_integer(), risk_level: :low | :medium | :high,
    status: :planned | :running | :completed | :failed | :cancelled,
    created_at: DateTime.t(), started_at: DateTime.t() | nil, completed_at: DateTime.t() | nil
  }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec plan(map()) :: experiment()
  def plan(hypothesis) do
    GenServer.call(__MODULE__, {:plan, hypothesis})
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(_opts) do
    {:ok, %{total_planned: 0, last_plan_at: nil}}
  end

  @impl true
  def handle_call({:plan, hypothesis}, _from, state) do
    experiment = build_experiment(hypothesis)

    :telemetry.execute([:tiannara, :research, :experiment_planned], %{count: 1}, %{domain: hypothesis.domain, risk: experiment.risk_level})

    {:reply, experiment, %{state | total_planned: state.total_planned + 1, last_plan_at: DateTime.utc_now()}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{total_planned: state.total_planned, last_plan_at: state.last_plan_at}, state}
  end

  defp build_experiment(hypothesis) do
    %{
      id: Types.new_id(), hypothesis: hypothesis,
      objective: "Test whether: #{hypothesis.statement} Falsification: #{hypothesis.falsification_criteria}",
      methodology: select_methodology(hypothesis),
      variables: select_variables(hypothesis),
      success_criteria: [
        "Observation confirms predicted effect with confidence >= 0.7",
        "Results are reproducible across 3 independent runs",
        "No confounding variables identified"
      ],
      failure_criteria: [
        "No statistically significant effect observed",
        "Results are inconsistent across runs",
        "Confounding variables cannot be controlled"
      ],
      resources: select_resources(hypothesis),
      estimated_duration_ms: estimate_duration(hypothesis),
      risk_level: assess_risk(hypothesis),
      status: :planned, created_at: DateTime.utc_now(), started_at: nil, completed_at: nil
    }
  end

  defp select_methodology(%{domain: :memory}), do: "Controlled memory profiling: isolate suspect allocation paths, measure memory delta under varied load, compare against baseline."
  defp select_methodology(%{domain: :performance}), do: "Benchmark-driven investigation: establish baseline throughput/latency, introduce controlled perturbation, measure deviation, identify causal chain."
  defp select_methodology(%{domain: :process}), do: "Process lifecycle audit: enumerate all processes, track creation/destruction rates, identify leaks or unbounded growth patterns."
  defp select_methodology(_), do: "General scientific investigation: observe, hypothesize, predict, test, validate."

  defp select_variables(%{domain: :memory}), do: %{independent: [:allocation_rate, :gc_frequency, :process_count], dependent: [:total_memory, :heap_size, :binary_memory], controlled: [:load_profile, :runtime_version, :configuration]}
  defp select_variables(%{domain: :performance}), do: %{independent: [:concurrency_level, :message_size, :scheduler_count], dependent: [:latency_p99, :throughput, :reductions_per_sec], controlled: [:hardware, :runtime_version, :data_volume]}
  defp select_variables(_), do: %{independent: [:suspected_factor], dependent: [:observed_signal], controlled: [:environment, :configuration]}

  defp select_resources(%{domain: :memory}), do: [:cpu, :memory_profiler, :benchmark_runner]
  defp select_resources(%{domain: :performance}), do: [:cpu, :benchmark_runner, :profiler]
  defp select_resources(_), do: [:cpu, :observation_tools]

  defp estimate_duration(%{domain: :memory}), do: :timer.minutes(5)
  defp estimate_duration(%{domain: :performance}), do: :timer.minutes(10)
  defp estimate_duration(_), do: :timer.minutes(3)

  defp assess_risk(%{confidence: confidence}) when confidence > 0.8, do: :low
  defp assess_risk(%{confidence: confidence}) when confidence > 0.5, do: :medium
  defp assess_risk(_), do: :high
end
