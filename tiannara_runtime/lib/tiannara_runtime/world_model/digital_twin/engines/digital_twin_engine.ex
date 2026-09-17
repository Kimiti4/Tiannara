defmodule TiannaraRuntime.WorldModel.DigitalTwin.Engines.DigitalTwinEngine do
  @moduledoc """
  Phase 17.7.9 — DigitalTwinEngine (Constitutional Runtime).
  Orchestrates the full simulation lifecycle: initialization, time stepping,
  event processing, intervention execution, emergence detection, metrics,
  archaeology, replay, and certification.
  """

  alias TiannaraRuntime.WorldModel.DigitalTwin.DigitalTwin
  alias TiannaraRuntime.WorldModel.DigitalTwin.TwinState
  alias TiannaraRuntime.WorldModel.DigitalTwin.SimulationScenario
  alias TiannaraRuntime.WorldModel.DigitalTwin.SimulationOutcome
  alias TiannaraRuntime.WorldModel.DigitalTwin.Engines.SimulationClock
  alias TiannaraRuntime.WorldModel.DigitalTwin.Engines.EventEngine
  alias TiannaraRuntime.WorldModel.DigitalTwin.Engines.InterventionScheduler
  alias TiannaraRuntime.WorldModel.DigitalTwin.Engines.EmergenceEngine
  alias TiannaraRuntime.WorldModel.DigitalTwin.Engines.MetricsEngine
  alias TiannaraRuntime.WorldModel.DigitalTwin.Engines.TwinArchaeology
  alias TiannaraRuntime.WorldModel.DigitalTwin.Engines.DTMathVerificationEngine

  @doc """
  Initializes a DigitalTwin from a composed world model and scenario.
  """
  def initialize(composition, scenario) do
    clock = SimulationClock.new(:fixed, 1.0, seed: scenario.seed || :erlang.system_time())

    initial_state = %TwinState{
      state_id: nil,
      tick: 0,
      model_states: scenario.initial_conditions || %{},
      shared_variables: %{}
    }

    state_canonical = %{tick: 0, model_states: initial_state.model_states}
    state_hash = :crypto.hash(:sha256, Jason.encode!(state_canonical)) |> Base.encode16(case: :lower)
    initial_state = %{initial_state | state_id: "ts_" <> state_hash}

    twin = %DigitalTwin{
      twin_id: nil,
      name: scenario.name || "digital_twin",
      parent_model_ids: composition.parent_model_ids,
      composition_id: composition.composition_id,
      clock: clock,
      state: initial_state,
      intervention_queue: nil,
      scenario_registry: [scenario],
      event_timeline: [],
      metrics: [],
      evidence_ledger: [],
      archaeology_root: initial_state.state_id,
      replay_fingerprint: nil,
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    twin = compute_twin_id(twin)
    fp = compute_fingerprint(twin)
    %{twin | replay_fingerprint: fp}
  end

  @doc """
  Runs a full simulation scenario on the twin.
  Returns {:ok, DigitalTwin.t(), SimulationOutcome.t()} or {:error, reason}.
  """
  def run_simulation(twin, scenario) do
    with {:ok, events} <- EventEngine.schedule(scenario.events || []),
         {:ok, interventions} <- InterventionScheduler.schedule(scenario.interventions || []),
         {:ok, final_twin, outcome} <- execute_steps(twin, events, interventions, scenario) do
      {:ok, final_twin, outcome}
    end
  end

  @doc """
  Advances the twin by one simulation tick.
  """
  def step(twin) do
    clock = SimulationClock.tick(twin.clock)
    tick = clock.tick
    events = EventEngine.due_events(twin.event_timeline || [], tick)
    interventions = InterventionScheduler.due_interventions(
      (twin.intervention_queue && twin.intervention_queue.interventions) || [], tick
    )

    state = twin.state

    state_after_events = Enum.reduce(events, state, fn e, s -> EventEngine.apply_event(e, s) end)
    state_after_interventions = Enum.reduce(interventions, state_after_events, fn si, s ->
      InterventionScheduler.apply_intervention(si, s)
    end)

    tick_state = %{state_after_interventions | tick: tick}
    state_canonical = %{tick: tick, model_states: tick_state.model_states}
    state_hash = :crypto.hash(:sha256, Jason.encode!(state_canonical)) |> Base.encode16(case: :lower)
    tick_state = %{tick_state | state_id: "ts_" <> state_hash}

    twin = %{twin | clock: clock, state: tick_state}
    twin = TwinArchaeology.record_tick(twin, tick_state)

    compute_twin_id(twin)
  end

  @doc """
  Verifies replay of a digital twin.
  """
  def verify_replay(twin) do
    computed = compute_fingerprint(twin)
    stored = twin.replay_fingerprint

    if computed == stored do
      {:ok, :replay_verified, twin}
    else
      {:error, :replay_mismatch, %{expected: stored, computed: computed}}
    end
  end

  defp execute_steps(twin, events, interventions, scenario) do
    total_ticks = scenario.total_ticks || 1000

    final_twin =
      Enum.reduce(1..total_ticks, twin, fn _tick, acc ->
        step(acc)
      end)

    outcome = build_outcome(final_twin, scenario)
    certified_twin = certify_twin(final_twin)

    {:ok, certified_twin, outcome}
  end

  defp build_outcome(twin, scenario) do
    metrics = [MetricsEngine.compute(twin.state)]

    %SimulationOutcome{
      outcome_id: "so_" <> (:crypto.hash(:sha256, twin.twin_id <> "outcome") |> Base.encode16(case: :lower)),
      scenario_id: scenario.scenario_id,
      final_state: twin.state,
      metrics: metrics,
      events_executed: length(twin.event_timeline || []),
      interventions_executed: length((twin.intervention_queue && twin.intervention_queue.interventions) || []),
      metadata: %{twin_id: twin.twin_id}
    }
  end

  defp certify_twin(twin) do
    fp = compute_fingerprint(twin)
    %{twin | replay_fingerprint: fp}
  end

  defp compute_fingerprint(twin) do
    excluded = [:twin_id, :archaeology_root, :created_at, :metadata,
                :replay_fingerprint, :certificate, :evidence_ledger]

    canonical =
      twin
      |> Map.from_struct()
      |> Map.drop(excluded)
      |> deep_struct_to_map()

    "fp_" <> (:crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower))
  end

  defp compute_twin_id(twin) do
    excluded = [:twin_id, :archaeology_root, :created_at, :metadata,
                :replay_fingerprint, :certificate, :evidence_ledger]

    canonical =
      twin
      |> Map.from_struct()
      |> Map.drop(excluded)
      |> deep_struct_to_map()

    hash = :crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower)
    %{twin | twin_id: "dt_" <> hash}
  end

  defp deep_struct_to_map(value) when is_struct(value) do
    value
    |> Map.from_struct()
    |> Enum.map(fn {k, v} -> {k, deep_struct_to_map(v)} end)
    |> Map.new()
  end

  defp deep_struct_to_map(value) when is_map(value) do
    Enum.map(value, fn {k, v} -> {k, deep_struct_to_map(v)} end) |> Map.new()
  end

  defp deep_struct_to_map(value) when is_list(value) do
    Enum.map(value, &deep_struct_to_map/1)
  end

  defp deep_struct_to_map(value), do: value
end
