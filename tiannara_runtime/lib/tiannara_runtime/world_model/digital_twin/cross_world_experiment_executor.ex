defmodule TiannaraRuntime.WorldModel.DigitalTwin.CrossWorldExperimentExecutor do
  @moduledoc """
  Real DigitalTwin executor adapter for Sentinel cross-world experiments.

  This adapter deliberately has no simulation fallback. It converts an explicit
  Sentinel scenario map into the canonical DigitalTwin SimulationScenario,
  initializes the supplied composition, executes it through DigitalTwinEngine,
  verifies replay determinism, and returns observed simulation data.

  It does not certify the theory. Sentinel remains responsible for evidence
  lineage and ACL/OAVL validation.
  """

  alias TiannaraRuntime.WorldModel.DigitalTwin.SimulationScenario
  alias TiannaraRuntime.WorldModel.DigitalTwin.Engines.DigitalTwinEngine

  @spec execute(map(), map()) :: {:ok, map()} | {:error, term()}
  def execute(scenario, composition) when is_map(scenario) and is_map(composition) do
    with {:ok, twin_scenario} <- build_scenario(scenario),
         {:ok, twin, outcome} <- run(composition, twin_scenario),
         {:ok, :replay_verified, _} <- DigitalTwinEngine.verify_replay(twin) do
      {:ok, normalize_outcome(scenario, twin, outcome)}
    end
  end

  def execute(_, _), do: {:error, :invalid_cross_world_execution_input}

  defp run(composition, scenario) do
    twin = DigitalTwinEngine.initialize(composition, scenario)
    DigitalTwinEngine.run_simulation(twin, scenario)
  rescue
    exception -> {:error, {:digital_twin_execution_failed, exception}}
  end

  defp build_scenario(scenario) do
    required = [:scenario_id, :name, :initial_conditions, :events, :interventions, :total_ticks, :seed]

    if Enum.all?(required, &Map.has_key?(scenario, &1)) do
      {:ok, %SimulationScenario{
        scenario_id: scenario.scenario_id,
        name: scenario.name,
        initial_conditions: scenario.initial_conditions,
        events: scenario.events,
        interventions: scenario.interventions,
        total_ticks: scenario.total_ticks,
        metrics_config: Map.get(scenario, :metrics_config, []),
        seed: scenario.seed,
        metadata: Map.get(scenario, :metadata, %{})
      }}
    else
      {:error, {:missing_scenario_fields, Enum.reject(required, &Map.has_key?(scenario, &1))}}
    end
  end

  defp normalize_outcome(source, twin, outcome) do
    %{
      outcome: classify(outcome),
      observations: %{
        final_state: outcome.final_state,
        metrics: outcome.metrics,
        events_executed: outcome.events_executed,
        interventions_executed: outcome.interventions_executed,
        twin_id: twin.twin_id,
        replay_fingerprint: twin.replay_fingerprint
      },
      counterevidence: Map.get(source, :counterevidence, []),
      assumptions_held: Map.get(source, :assumptions_held, []),
      assumptions_changed: Map.get(source, :assumptions_changed, []),
      execution_mode: :simulation,
      evidence_class: :simulated,
      simulation_fingerprint: twin.replay_fingerprint
    }
  end

  defp classify(outcome) do
    case Map.get(outcome.metadata || %{}, :classification) do
      value when value in [:supported, :refuted, :inconclusive, :mixed] -> value
      _ -> :inconclusive
    end
  end
end
