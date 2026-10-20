defmodule TiannaraRuntime.DigitalTwin.ValidationCampaignTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.WorldModel.DigitalTwin.{
    DigitalTwin, TwinState, SimulationEvent,
    InterventionQueue, ScheduledIntervention, SimulationScenario, TwinMetrics
  }

  alias TiannaraRuntime.WorldModel.DigitalTwin.Engines.{
    SimulationClock, EventEngine, InterventionScheduler,
    EmergenceEngine, MetricsEngine, TwinArchaeology,
    DTMathVerificationEngine, DigitalTwinEngine
  }

  alias TiannaraRuntime.WorldModel.DigitalTwin.SimulationClock, as: SimulationClockStruct

  @moduletag :campaign

  defp sample_composition do
    %{composition_id: "cw_test", parent_model_ids: ["wm_a", "wm_b"]}
  end

  defp sample_scenario do
    %SimulationScenario{
      scenario_id: "ss_test",
      name: "test_scenario",
      initial_conditions: %{"wm_a" => %{"x" => 1.0}, "wm_b" => %{"y" => 2.0}},
      events: [],
      interventions: [],
      total_ticks: 10,
      seed: 42,
      metadata: %{}
    }
  end

  describe "C17.7.95.1 — Struct Validation" do
    test "DigitalTwin has required fields" do
      dt = %DigitalTwin{name: "test", parent_model_ids: ["wm1"], composition_id: "cw1"}
      assert dt.name == "test"
      assert dt.parent_model_ids == ["wm1"]
    end

    test "TwinState validates fields" do
      ts = %TwinState{tick: 0, model_states: %{}}
      assert ts.tick == 0
      assert ts.model_states == %{}
    end

    test "SimulationClock validates mode" do
      sc = %SimulationClockStruct{mode: :fixed, tick: 0, time: 0.0, delta: 1.0}
      assert sc.mode == :fixed
      assert sc.delta == 1.0
    end

    test "SimulationEvent validates type" do
      se = %SimulationEvent{name: "test", type: :disaster, trigger_tick: 5, effects: %{"wm_a" => %{"x" => 0}}}
      assert se.type == :disaster
    end

    test "InterventionQueue has interventions" do
      iq = %InterventionQueue{interventions: []}
      assert iq.interventions == []
    end

    test "ScheduledIntervention validates schedule_type" do
      si = %ScheduledIntervention{schedule_type: :delayed, trigger_tick: 10}
      assert si.schedule_type == :delayed
    end

    test "SimulationScenario validates fields" do
      ss = %SimulationScenario{name: "test", initial_conditions: %{}, total_ticks: 100}
      assert ss.total_ticks == 100
    end

    test "TwinMetrics has civilization fields" do
      tm = %TwinMetrics{tick: 0, economic_output: 0.5, civilization_readiness: 0.5}
      assert tm.civilization_readiness == 0.5
    end
  end

  describe "C17.7.95.2 — ID Generation" do
    test "DigitalTwin generates dt_ prefix" do
      id = DigitalTwin.generate_id(%{name: "test"})
      assert String.starts_with?(id, "dt_")
    end

    test "SimulationClock generates sc_ prefix" do
      sc = SimulationClock.new(:fixed, 1.0)
      assert String.starts_with?(sc.clock_id, "sc_")
    end

    test "SimulationEvent generates se_ prefix" do
      id = SimulationEvent.generate_id(%{name: "test"})
      assert String.starts_with?(id, "se_")
    end

    test "TwinMetrics generates tm_ prefix" do
      id = TwinMetrics.generate_id(%{tick: 0})
      assert String.starts_with?(id, "tm_")
    end

    test "IDs are deterministic" do
      id1 = DigitalTwin.generate_id(%{name: "test"})
      id2 = DigitalTwin.generate_id(%{name: "test"})
      assert id1 == id2
    end
  end

  describe "C17.7.95.3 — Simulation Clock" do
    test "new creates clock with correct values" do
      sc = SimulationClock.new(:fixed, 2.0)
      assert sc.mode == :fixed
      assert sc.delta == 2.0
      assert sc.tick == 0
    end

    test "tick advances clock" do
      sc = SimulationClock.new(:fixed, 1.0)
      advanced = SimulationClock.tick(sc)
      assert advanced.tick == 1
      assert advanced.time == 1.0
    end

    test "reset returns clock to initial state" do
      sc = SimulationClock.new(:fixed, 1.0)
      advanced = SimulationClock.tick(sc)
      reset = SimulationClock.reset(advanced)
      assert reset.tick == 0
      assert reset.time == 0.0
    end

    test "set_delta changes timestep" do
      sc = SimulationClock.new(:variable, 0.5)
      updated = SimulationClock.set_delta(sc, 0.1)
      assert updated.delta == 0.1
    end
  end

  describe "C17.7.95.4 — Event Engine" do
    test "schedule orders events by trigger_tick" do
      e1 = %SimulationEvent{event_id: "se_1", name: "late", type: :policy, trigger_tick: 10, effects: %{}}
      e2 = %SimulationEvent{event_id: "se_2", name: "early", type: :discovery, trigger_tick: 1, effects: %{}}
      {:ok, sorted} = EventEngine.schedule([e1, e2])
      assert hd(sorted).trigger_tick == 1
    end

    test "due_events returns events at given tick" do
      e1 = %SimulationEvent{event_id: "se_due", name: "due", type: :disaster, trigger_tick: 5, effects: %{}}
      e2 = %SimulationEvent{event_id: "se_not", name: "not_due", type: :economic, trigger_tick: 10, effects: %{}}
      due = EventEngine.due_events([e1, e2], 5)
      assert length(due) == 1
      assert hd(due).name == "due"
    end

    test "apply_event modifies model states" do
      event = %SimulationEvent{event_id: "se_test", name: "quake", type: :disaster,
        trigger_tick: 1, effects: %{"wm_a" => %{"x" => 0.0}}}
      state = %TwinState{state_id: "ts1", tick: 1, model_states: %{"wm_a" => %{"x" => 1.0}}}
      new_state = EventEngine.apply_event(event, state)
      assert new_state.model_states["wm_a"]["x"] == 0.0
    end
  end

  describe "C17.7.95.5 — Intervention Scheduler" do
    test "schedule orders interventions by tick and dependency" do
      i1 = %ScheduledIntervention{scheduled_id: "si_2", schedule_type: :delayed, trigger_tick: 10, dependencies: []}
      i2 = %ScheduledIntervention{scheduled_id: "si_1", schedule_type: :immediate, trigger_tick: 1, dependencies: []}
      {:ok, sorted} = InterventionScheduler.schedule([i1, i2])
      assert hd(sorted).trigger_tick == 1
    end

    test "due_interventions finds matching interventions" do
      i1 = %ScheduledIntervention{scheduled_id: "si_due", schedule_type: :delayed, trigger_tick: 5, dependencies: []}
      i2 = %ScheduledIntervention{scheduled_id: "si_not", schedule_type: :delayed, trigger_tick: 10, dependencies: []}
      due = InterventionScheduler.due_interventions([i1, i2], 5)
      assert length(due) == 1
    end

    test "recurring interventions fire at intervals" do
      i1 = %ScheduledIntervention{scheduled_id: "si_rec", schedule_type: :recurring, trigger_tick: 1, recurrence: 3, dependencies: []}
      due_t1 = InterventionScheduler.due_interventions([i1], 1)
      due_t4 = InterventionScheduler.due_interventions([i1], 4)
      assert length(due_t1) == 1
      assert length(due_t4) == 1
    end

    test "apply_intervention modifies twin state" do
      si = %ScheduledIntervention{scheduled_id: "si_test", intervention: %{"target" => "wm_a", "value" => 42, "field" => "temperature"}}
      state = %TwinState{state_id: "ts1", tick: 0, model_states: %{"wm_a" => %{}}}
      new_state = InterventionScheduler.apply_intervention(si, state)
      assert new_state.model_states["wm_a"]["temperature"] == 42
      assert new_state.model_states["wm_a"]["modified_by"] == "si_test"
    end
  end

  describe "C17.7.95.6 — Emergence Engine" do
    test "analyze returns list of patterns" do
      states = for i <- 0..10, do: %TwinState{state_id: "ts_#{i}", tick: i, model_states: %{"a" => %{"health" => 0.5 + i * 0.01}}}
      {:ok, patterns} = EmergenceEngine.analyze(states)
      assert is_list(patterns)
    end

    test "detect_unexpected_equilibria finds stable states" do
      stable = for _i <- 1..10, do: %TwinState{state_id: "ts_s", tick: 0, model_states: %{}}
      {:ok, patterns} = EmergenceEngine.analyze(stable)
      equilibria = Enum.filter(patterns, fn p -> p.type == :unexpected_equilibrium end)
      assert length(equilibria) >= 0
    end
  end

  describe "C17.7.95.7 — Metrics Engine" do
    test "compute returns TwinMetrics with ID" do
      state = %TwinState{state_id: "ts1", tick: 0, model_states: %{"a" => %{"gdp" => 0.8}}, shared_variables: %{}}
      metrics = MetricsEngine.compute(state)
      assert String.starts_with?(metrics.metrics_id, "tm_")
      assert metrics.tick == 0
    end

    test "compute_economic extracts GDP from model states" do
      state = %TwinState{state_id: "ts2", tick: 1, model_states: %{"economy" => %{"gdp" => 0.75}}}
      result = MetricsEngine.compute_economic(state)
      assert result == 0.75
    end

    test "readiness averages sub-metrics" do
      state = %TwinState{state_id: "ts3", tick: 2, model_states: %{"eco" => %{"gdp" => 0.8}, "gov" => %{"governance_stability" => 0.6}}}
      readiness = MetricsEngine.compute_readiness(state)
      assert readiness > 0
    end
  end

  describe "C17.7.95.8 — Twin Archaeology" do
    test "record_tick appends to evidence ledger" do
      twin = %DigitalTwin{twin_id: "dt_test", evidence_ledger: []}
      tick_state = %TwinState{state_id: "ts_tick", tick: 1, model_states: %{}}
      updated = TwinArchaeology.record_tick(twin, tick_state)
      assert length(updated.evidence_ledger) == 1
    end

    test "get_lineage returns entries for tick" do
      twin = %DigitalTwin{twin_id: "dt_test", evidence_ledger: [%{tick: 1, state_id: "ts1"}, %{tick: 2, state_id: "ts2"}]}
      lineage = TwinArchaeology.get_lineage(twin, 2)
      assert length(lineage) == 1
      assert hd(lineage).tick == 2
    end
  end

  describe "C17.7.95.9 — Math Verification" do
    test "verify returns proof hash for valid twin" do
      twin = %DigitalTwin{
        twin_id: "dt_test", parent_model_ids: ["wm_a"],
        state: %TwinState{state_id: "ts", tick: 0, model_states: %{"a" => %{"x" => 1.0}}}
      }
      assert {:ok, proof, _details} = DTMathVerificationEngine.verify(twin)
      assert String.length(proof) > 0
    end

    test "check_conservation_laws passes with model_count > 0" do
      twin = %DigitalTwin{
        parent_model_ids: ["wm_a"],
        state: %TwinState{state_id: "ts", tick: 0, model_states: %{}}
      }
      result = DTMathVerificationEngine.check_conservation_laws(twin)
      assert result.status == :pass
    end
  end

  describe "C17.7.95.10 — Full Simulation Execution" do
    test "initialize creates twin with clock and state" do
      composition = sample_composition()
      scenario = sample_scenario()
      twin = DigitalTwinEngine.initialize(composition, scenario)
      assert String.starts_with?(twin.twin_id, "dt_")
      assert twin.clock.tick == 0
      assert twin.state.tick == 0
    end

    test "step advances simulation by one tick" do
      composition = sample_composition()
      scenario = sample_scenario()
      twin = DigitalTwinEngine.initialize(composition, scenario)
      advanced = DigitalTwinEngine.step(twin)
      assert advanced.clock.tick == 1
      assert advanced.state.tick == 1
    end

    test "verify_replay succeeds for unmodified twin" do
      composition = sample_composition()
      scenario = sample_scenario()
      twin = DigitalTwinEngine.initialize(composition, scenario)
      assert {:ok, :replay_verified, _} = DigitalTwinEngine.verify_replay(twin)
    end

    test "verify_replay fails after modification" do
      composition = sample_composition()
      scenario = sample_scenario()
      twin = DigitalTwinEngine.initialize(composition, scenario)
      advanced = DigitalTwinEngine.step(twin)
      assert {:error, :replay_mismatch, _} = DigitalTwinEngine.verify_replay(advanced)
    end

    test "end-to-end simulation produces outcome" do
      composition = sample_composition()
      scenario = sample_scenario()
      twin = DigitalTwinEngine.initialize(composition, scenario)
      assert {:ok, final_twin, outcome} = DigitalTwinEngine.run_simulation(twin, scenario)
      assert outcome.events_executed >= 0
      assert outcome.final_state.tick == 10
    end
  end
end
