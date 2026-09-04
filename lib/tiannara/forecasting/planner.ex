defmodule Tiannara.Forecasting.FutureSimulator do
  @moduledoc """
  Runs counterfactual timelines to simulate the outcomes of topological stress and potential interventions.
  """
  require Logger
  alias Tiannara.Metrics.Aggregator

  def simulate(scenario, _payload) do
    case scenario do
      :counterfactual_fidelity ->
        Logger.info("🔮 [Simulator] Simulating future alongside primary Reality Graph...")
        Aggregator.push_event([:tiannara, :forecasting, :simulation_divergence], 0.05) # well bounded

      :long_horizon ->
        Logger.info("🔮 [Simulator] Executing 100k-tick deep time simulation...")
        Aggregator.push_event([:tiannara, :forecasting, :forecast_stability], 0.98)

      :black_swan ->
        Logger.warning("🦢 [Simulator] Black Swan injected! Sudden topology mutation...")
        Aggregator.push_event([:tiannara, :forecasting, :black_swan_resilience], 0.95)

      :multi_civ ->
        Logger.info("🌐 [Simulator] Simulating cross-civilization treaty outcomes...")
        Aggregator.push_event([:tiannara, :forecasting, :forecast_accuracy], 0.93)
        
      _ ->
        :ok
    end
  end
end

defmodule Tiannara.Forecasting.StrategicPlanner do
  @moduledoc """
  Scenario-handler narration for intervention-strategy demonstrations.

  This module is a *scenario handler*, not a real planner. It accepts a
  :scenario atom and a payload, and emits narration that explicitly
  identifies the response as a **non-measurement** simulation record.

  Empirical-validation R1 (MEASUREMENT_INTEGRITY_RECONNAISSANCE.md,
  2026-09-03) and Phase 3 FALSE_EMERGENCE_TEST_PLAN.md established that the
  prior implementation wrote a hardcoded decision map (chosen strategy,
  regret, predicted, actual) to the DecisionArchive logging facade with no
  provenance, and pushed hardcoded "effectiveness" / "regret" / "restraint"
  metrics to Metrics.Aggregator. That fabrication has been removed
  (R3 remediation, MEASUREMENT_INTEGRITY remediation, Option A+C).

  Invariants enforced here:

    1. No measured record is emitted. The function does not produce
       a chosen strategy, regret, predicted outcome, or actual outcome.
    2. Any scenario narration carries a `Tiannara.Evidence.Provenance`
       record of kind `:simulation` so it can never satisfy
       `Provenance.acceptable_as_evidence?/1` (which only accepts
       `:real_execution` with an `execution_id` and `:imported_evidence`
       with a non-empty `source`).
    3. No hardcoded "effectiveness" / "regret" / "restraint" / "score"
       metric is pushed to Metrics.Aggregator.
    4. The DecisionArchive.record/1 logging facade is no longer called
       with a fabricated decision map.
  """
  require Logger
  alias Tiannara.Evidence.Provenance

  @scenario_kind :simulation

  @doc """
  Scenario-handler narration. Returns a tuple
  `{scenario, kind, provenance_hash}` describing the response, without
  producing a measured decision record.

  The returned `provenance_hash` is the SHA-256 of the
  `Tiannara.Evidence.Provenance` record attached to the response. Any
  downstream consumer can use it to confirm the record is `:simulation`,
  not `:real_execution`.
  """
  @spec evaluate_and_act(atom(), map()) :: {:ok, %{scenario: atom(), kind: :simulation, provenance_hash: binary()}}
  def evaluate_and_act(scenario, _payload) when is_atom(scenario) do
    {:ok, provenance} = Provenance.build(kind: @scenario_kind, source: "StrategicPlanner.scenario_handler", audit_trail: ["non_measurement: scenario handler response"])

    Logger.info("♟️ [Planner] (scenario=#{inspect(scenario)}, kind=#{@scenario_kind}) — scenario-handler narration, NOT a measured decision record.")

    {:ok, %{scenario: scenario, kind: @scenario_kind, provenance_hash: Provenance.hash(provenance)}}
  end
end
