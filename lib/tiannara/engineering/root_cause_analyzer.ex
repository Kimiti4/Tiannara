defmodule Tiannara.Engineering.RootCauseAnalyzer do
  @moduledoc """
  L4 Root Cause Analyzer.

  Constitutional mandate: Distinguish clearly between facts, evidence,
  assumptions, and hypotheses. Evidence Before Confidence.

  Consumes observed failures and produces ROOT_CAUSE_HYPOTHESIS artifacts
  — never facts. Each hypothesis carries a confidence interval and a
  reproducibility predicate.

  The analyzer never mutates runtime state. It emits hypotheses as
  Proposal-ready data.
  """
  use GenServer
  require Logger

  alias Tiannara.Executive.Types
  alias Tiannara.Engineering.Proposal

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Analyze an observed failure and emit a root-cause hypothesis.

  `failure` is a map like:
    %{exception: %KeyError{key: :uncertainty_level}, stacktrace: [...], phase: :load_spike, timestamp: DateTime, soak_run_id: "soak-..."}
  """
  def analyze(failure) do
    GenServer.call(__MODULE__, {:analyze, failure})
  end

  @impl true
  def init(_opts) do
    {:ok, %{hypothesis_count: 0, known_patterns: load_known_patterns()}}
  end

  @impl true
  def handle_call({:analyze, failure}, _from, state) do
    Logger.info("[RootCauseAnalyzer] Analyzing failure: #{inspect(failure.exception)}")

    {hypothesis, confidence, contract_violation} =
      case classify_failure(failure, state.known_patterns) do
        {:known_pattern, pattern, confidence, violation} ->
          {build_hypothesis(pattern, failure), confidence, violation}

        {:novel, reason} ->
          {
            %{
              statement: "Novel failure pattern",
              explanation: "Unrecognized exception in phase #{inspect(failure.phase)}: #{Exception.message(reason)}",
              evidence: [failure],
              confidence: 0.1
            },
            0.1,
            %{producer: :unknown, consumer: :unknown, field: :unknown, policy: :quarantine}
          }
      end

    proposal =
      Proposal.new(
        failure,
         extract_module(contract_violation),
        root_cause_hypothesis: hypothesis,
        contract_violation: contract_violation,
        confidence: confidence,
        soak_run_id: failure[:soak_run_id]
      )

    {:reply, {:ok, proposal, hypothesis}, %{state | hypothesis_count: state.hypothesis_count + 1}}
  end

  defp classify_failure(failure, patterns) do
    Enum.find_value(patterns, {:novel, failure.exception}, fn pattern ->
      if apply(pattern.matcher, [failure]) do
        {:known_pattern, pattern, pattern.confidence, pattern.contract_violation}
      end
    end)
  end

  defp extract_module(%{consumer: mod} = _contract_violation) when is_atom(mod) do
    mod
  end

  defp extract_module(_), do: :unknown

  defp build_hypothesis(pattern, failure) do
    %{
      statement: pattern.statement,
      explanation: pattern.explanation,
      evidence: [failure],
      confidence: pattern.confidence,
      pattern_id: pattern.id,
      suggested_repair_template: pattern.suggested_repair
    }
  end

  defp load_known_patterns do
    [
      %{
        id: :missing_uncertainty_key,
        statement: "Artifact payloads missing :uncertainty_level field cause KeyError in RiskAssessmentEngine",
        explanation: "Consumer reads artifact.uncertainty_level directly instead of via boundary normalization. Load-spike stubs carry only %{name, version, payload: %{data}}.",
        confidence: 0.9,
        matcher: fn failure ->
          match?(%KeyError{key: :uncertainty_level}, failure.exception) or
            (match?(%KeyError{}, failure.exception) and
               (Exception.message(failure.exception) =~ "uncertainty_level"))
        end,
        contract_violation: %{
          producer: :load_spike_harness,
          consumer: :risk_assessment_engine,
          field: :uncertainty_level,
          policy: :normalize_with_default
        },
        suggested_repair: "Map.get(artifact, :uncertainty_level, 0.5)"
      },
      %{
        id: :infinity_timeout_amplification,
        statement: "GenServer.call with :infinity timeout amplifies single-task failures into orchestrator hangs",
        explanation: "Director.deploy uses :infinity timeout; a crashed Task pins the caller indefinitely. Should be bounded.",
        confidence: 0.85,
        matcher: fn failure ->
          failure.phase == :t_plus_48h_load_spike and
            (Exception.message(failure.exception) =~ "Infinity" or
             match?(%FunctionClauseError{}, failure.exception))
        end,
        contract_violation: %{
          producer: :reality_director,
          consumer: :task_supervisor,
          field: :timeout,
          policy: :bounded_wait
        },
        suggested_repair: "GenServer.call(..., 60_000) with Task.yield/shutdown fallback"
      },
      %{
        id: :case_clause_on_error_shape,
        statement: "run_pipeline errors return {:error, reason} (2-tuple) but handle_call only matches {:error, reason, pipeline} (3-tuple)",
        explanation: "CaseClauseError at Director.handle_call when a pipeline stage returns a bare error tuple.",
        confidence: 0.8,
        matcher: fn failure ->
          match?(%CaseClauseError{}, failure.exception) and
            Exception.message(failure.exception) =~ "no case clause matching: {:error"
        end,
        contract_violation: %{
          producer: :pipeline,
          consumer: :director_handle_call,
          field: :error_return_shape,
          policy: :normalize_error_shape
        },
        suggested_repair: "Add {:error, reason} -> match arm in handle_call case block"
      }
    ]
  end
end
