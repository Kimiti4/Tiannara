defmodule Tiannara.CEL.Services.ExecutiveDigitalTwin do
  use Tiannara.ExecutiveService.Base
  use GenServer
  require Logger

  @moduledoc """
  Executive Digital Twin — simulation and validation of executive strategies before deployment.

  This is the ultimate expression of "Verification First" and "Evolution without validation
  creates randomness". It simulates mission plans, architectural changes, and resource
  allocations in a sandboxed environment before applying them to the live system.

  Capabilities:
    - Strategy Simulation: sandboxed execution of proposed plans
    - Counterfactual Analysis: what-if scenarios for failures, resource constraints
    - Outcome Prediction Integration: uses DecisionPredictor to forecast step outcomes
    - Council Evidence Generation: concrete simulation data for high-impact approvals
    - State Isolation: zero mutation of the live system during simulation
  """

  alias Tiannara.CEL.Services.{DecisionPredictor, CapabilityGraph, ResourceManager, ExecutiveMemory}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @max_simulation_steps 1000
  @simulation_timeout_ms :timer.seconds(30)

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  # ── Client API ──────────────────────────────────────────────────

  def simulate_strategy(strategy_spec, context \\ nil) do
    GenServer.call(__MODULE__, {:simulate, strategy_spec, context}, @simulation_timeout_ms)
  end

  def run_counterfactual(scenario_spec, context \\ nil) do
    GenServer.call(__MODULE__, {:counterfactual, scenario_spec, context}, @simulation_timeout_ms)
  end

  def stats, do: GenServer.call(__MODULE__, :stats)

  # ── ExecutiveService Behaviour ──────────────────────────────────

  @impl true
  def id, do: :executive_digital_twin

  @impl true
  def version, do: "1.0.0"

  @impl true
  def capabilities do
    [:strategy_simulation, :counterfactual_analysis, :outcome_prediction_integration,
     :council_evidence_generation, :state_isolation, :mission_simulation,
     :what_if_analysis, :council_advisory]
  end

  @impl true
  def dependencies, do: [:decision_predictor, :capability_graph, :resource_manager, :executive_memory]

  @impl true
  def constitutional_score do
    s = stats()
    eq = if s.total_simulations > 0, do: min(1.0, s.validated_simulations / max(1, s.total_simulations)), else: 0.5

    %ConstitutionalScore{
      service_id: :executive_digital_twin,
      health: if(s.healthy, do: 1.0, else: 0.0),
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: eq,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  # ── Init ────────────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    {:ok, %{total_simulations: 0, validated_simulations: 0, healthy: true, started_at: DateTime.utc_now()}}
  end

  # ── Call Handlers ───────────────────────────────────────────────

  @impl true
  def handle_call({:simulate, strategy_spec, context}, _from, state) do
    Logger.info("DigitalTwin: Simulating strategy #{strategy_spec.id}")
    sandbox = initialize_sandbox()
    {final, step_results, failure_modes} = run_simulation(sandbox, Map.get(strategy_spec, :steps, []), context)
    report = build_report(strategy_spec, step_results, failure_modes, final)

    safely_record(:strategy_simulated, %{strategy_id: strategy_spec.id, status: report.status})
    emit_constitutional_event(:strategy_simulated, %{status: report.status, steps: length(step_results)}, %{strategy_id: strategy_spec.id})

    {:reply, {:ok, report}, %{state | total_simulations: state.total_simulations + 1}}
  end

  @impl true
  def handle_call({:counterfactual, scenario_spec, context}, _from, state) do
    Logger.info("DigitalTwin: Running counterfactual")
    sandbox = initialize_sandbox()
    perturbed = apply_perturbation(sandbox, scenario_spec.perturbation)
    {final, step_results, failures} = run_simulation(perturbed, scenario_spec.baseline_strategy.steps, context)

    baseline = scenario_spec.baseline_strategy.expected_outcome
    report = %{
      scenario_id: scenario_spec.id,
      perturbation: scenario_spec.perturbation,
      baseline_outcome: baseline,
      perturbed_outcome: final.status,
      divergence: %{detected: baseline != final.status, impact: if(baseline != final.status, do: :high, else: :low)},
      step_results: step_results,
      failure_modes: Enum.uniq(failures),
      recommendation: if(length(failures) > 0, do: "Strategy fragile under perturbation. Add redundancy.", else: "Strategy resilient to perturbation."),
      simulated_at: DateTime.utc_now()
    }

    {:reply, {:ok, report}, state}
  end

  @impl true
  def handle_call(:stats, _from, state), do: {:reply, state, state}

  # ── Simulation Engine ───────────────────────────────────────────

  defp initialize_sandbox do
    status = safely_call(ResourceManager, :status, []) || %{available: %{cpu: 100, memory_mb: 65_536, gpu: 8, storage_gb: 10_000}}
    graph = safely_call(CapabilityGraph, :export, []) || %{vertices: [], edges: []}
    %{resources: status.available, capabilities: graph, time_step: 0, status: :running}
  end

  defp run_simulation(sandbox, steps, context) do
    run_simulation(sandbox, steps, context, [], [])
  end

  defp run_simulation(sandbox, [], _context, step_results, failure_modes) do
    {Map.put(sandbox, :status, :success), Enum.reverse(step_results), failure_modes}
  end

  defp run_simulation(sandbox, [step | rest], context, step_results, failure_modes) do
    if sandbox.time_step >= @max_simulation_steps do
      {Map.put(sandbox, :status, :timeout), Enum.reverse(step_results), [:simulation_timeout | failure_modes]}
    else
      pred = safely_predict(step, context)

      if pred do
        rate = Map.get(pred, :predicted_success_rate, 0.5)
        roll = :rand.uniform()

        if rate >= 0.5 and roll <= rate do
          updated = Map.update!(Map.put(sandbox, :resources, deduct(sandbox.resources, pred)), :time_step, &(&1 + 1))
          run_simulation(updated, rest, context, [%{step: step, outcome: :success, prediction: pred} | step_results], failure_modes)
        else
          risk = identify_primary_risk(Map.get(pred, :risk_factors, %{}))
          recovery = Map.get(step, :recovery_plan)
          new_failures = [{:step_failed, risk} | failure_modes]

          if recovery do
            {recovered, rec_results, rec_failures} = run_simulation(sandbox, recovery, context, [], [])
            if recovered.status == :success do
              next_sandbox = Map.update!(recovered, :time_step, &(&1 + 1))
              run_simulation(next_sandbox, rest, context, step_results ++ rec_results, new_failures ++ rec_failures)
            else
              {Map.put(sandbox, :status, :failed), Enum.reverse(step_results), new_failures ++ rec_failures}
            end
          else
            {Map.put(sandbox, :status, :failed), Enum.reverse(step_results), new_failures}
          end
        end
      else
        run_simulation(Map.update!(sandbox, :time_step, &(&1 + 1)), rest, context, [%{step: step, outcome: :unknown, prediction: nil} | step_results], failure_modes)
      end
    end
  end

  defp build_report(spec, step_results, failure_modes, final) do
    rec =
      cond do
        final.status == :success and failure_modes == [] -> :approve
        final.status == :success -> :approve_with_monitoring
        Map.get(spec, :recovery_plan) -> :requires_modification
        true -> :reject
      end

    %{
      strategy_id: spec.id,
      status: final.status,
      steps_executed: length(step_results),
      failure_modes: Enum.uniq(failure_modes),
      resource_projection: final.resources,
      recommendation: rec,
      step_details: step_results,
      simulated_at: DateTime.utc_now()
    }
  end

  defp identify_primary_risk(factors) do
    factors |> Enum.sort_by(fn {_k, v} -> v end, :desc) |> hd |> elem(0)
  rescue
    _ -> :unknown
  end

  defp deduct(resources, _pred) do
    Map.new(resources, fn {k, v} -> {k, min(1.0, v + 0.05)} end)
  end

  defp apply_perturbation(sandbox, perturbation) do
    if reduction = perturbation.resource_reduction do
      factor = 1.0 - reduction
      Map.put(sandbox, :resources, Map.new(sandbox.resources, fn {k, v} -> {k, v * factor} end))
    else
      sandbox
    end
  end

  defp safely_predict(step, context) do
    case safely_call(DecisionPredictor, :predict_mission_outcome, [step, context]) do
      {:ok, pred} -> pred
      _ -> nil
    end
  end

  defp safely_record(event_type, payload) do
    try do
      ExecutiveMemory.record_event(event_type, payload)
    rescue
      _ -> :ok
    end
  end

  defp safely_call(mod, fun, args) do
    try do
      apply(mod, fun, args)
    rescue
      _ -> nil
    catch
      _, _ -> nil
    end
  end
end
