defmodule Tiannara.OMCS.OMCS1IntegrationTest do
  use ExUnit.Case, async: false
  require Logger

  alias Tiannara.OMCS
  alias Tiannara.OMCS.Engine
  alias Tiannara.OMCS.Milestone
  alias Tiannara.ROS.ShardManager
  alias Tiannara.ROS.CivilizationSpawner
  alias Tiannara.Core.WorldModel.BeliefSystem

  setup_all do
    # Application is already started by mix test, including OMCS.Supervisor
    start_supervised!({Tiannara.Core.WorldModel.Supervisor, [shard_id: :world_0]})
    :ok
  end

  @tag timeout: 60000
  test "Alpha Transformation Test: Continuity across massive evolution" do
    Logger.info("🧪 Beginning Alpha Transformation Test")

    assert {:ok, :shard_alpha_trans} = ShardManager.spawn_shard(:shard_alpha_trans)
    Process.sleep(50)

    # 1. Spawn Alpha
    assert {:ok, civ_id} = CivilizationSpawner.spawn_civilization(:shard_alpha_trans, "Alpha-Trans", ["exploration"])
    Engine.register_civilization(civ_id)

    # Inject the initial thematic belief so it becomes the baseline fingerprint
    belief_sys = Tiannara.ROS.Registry.via(BeliefSystem, :shard_alpha_trans)
    GenServer.call(belief_sys, {:add_belief, %{
      id: "initial_belief_1",
      statement: "exploration",
      confidence: 1.0,
      source: "founding",
      evidence: [],
      created_at: DateTime.utc_now(),
      last_verified: DateTime.utc_now()
    }})

    # 2. Capture Initial Identity
    initial_seed = OMCS.capture_identity(:shard_alpha_trans, civ_id)

    # 3. Fast-forward evolution (5,000 ticks simulated)
    simulate_evolution(:shard_alpha_trans, civ_id, 5000)

    # 4. Capture Transformed Identity
    evolved_seed = OMCS.capture_identity(:shard_alpha_trans, civ_id)

    # 5. Measure Continuity
    continuity = OMCS.ContinuityScorer.score(initial_seed, evolved_seed)

    Logger.info("Transformation Continuity: #{inspect(continuity)}")

    # We expect some ontology drift, but lineage and narrative should remain high
    assert continuity.lineage_continuity >= 0.95
    assert continuity.narrative_continuity >= 0.85
    assert continuity.overall_continuity >= 0.80
  end

  @tag timeout: 60000
  test "Alpha Death Test: Continuity across death and restoration" do
    Logger.info("🧪 Beginning Alpha Death Test")

    assert {:ok, :shard_alpha_death} = ShardManager.spawn_shard(:shard_alpha_death)
    Process.sleep(50)

    # 1. Spawn Alpha
    assert {:ok, civ_id} = CivilizationSpawner.spawn_civilization(:shard_alpha_death, "Alpha-Death", ["preservation"])
    Engine.register_civilization(civ_id)

    # Inject the initial thematic belief so it becomes the baseline fingerprint
    belief_sys = Tiannara.ROS.Registry.via(BeliefSystem, :shard_alpha_death)
    GenServer.call(belief_sys, {:add_belief, %{
      id: "initial_belief_death",
      statement: "preservation",
      confidence: 1.0,
      source: "founding",
      evidence: [],
      created_at: DateTime.utc_now(),
      last_verified: DateTime.utc_now()
    }})

    # 2. Fast-forward evolution (10,000 ticks simulated)
    simulate_evolution(:shard_alpha_death, civ_id, 10000)

    # 3. Kill Alpha (Capture Identity for OMCS / LEOC)
    identity_seed = OMCS.capture_identity(:shard_alpha_death, civ_id)
    
    # 4. Restore Alpha into a new Shard
    assert {:ok, :shard_alpha_restored} = ShardManager.spawn_shard(:shard_alpha_restored)
    Process.sleep(50)
    
    {:ok, continuity} = OMCS.restore_identity(:shard_alpha_restored, identity_seed)

    Logger.info("Restoration Continuity: #{inspect(continuity)}")

    # The graduation gate criteria
    assert continuity.lineage_continuity >= 0.95
    assert continuity.ontology_continuity >= 0.90
    assert continuity.causal_continuity >= 0.90
    assert continuity.narrative_continuity >= 0.90
    assert continuity.overall_continuity >= 0.90
  end

  # --- Helper to simulate time passage, milestone accumulation, and belief shifts ---
  defp simulate_evolution(shard_id, civ_id, ticks) do
    # Simulate a series of milestones
    num_events = div(ticks, 1000)
    
    Enum.each(1..num_events, fn i ->
      type = Enum.random([:major_discovery, :war, :merger, :paradigm_shift])
      milestone = Milestone.new(type, "Event #{i} after #{i * 1000} ticks")
      Engine.record_milestone(civ_id, milestone)
      
      # Simulate causal links
      Engine.record_causal_link(civ_id, "Decision_#{i}", "Effect_#{i}")
    end)

    # Simulate Ontology mutation
    belief_sys = Tiannara.ROS.Registry.via(BeliefSystem, shard_id)
    
    # Add new evolved beliefs
    GenServer.call(belief_sys, {:add_belief, %{
      id: "evolved_belief_1",
      statement: "We must adapt to survive",
      confidence: 0.8,
      source: "evolution",
      evidence: [],
      created_at: DateTime.utc_now(),
      last_verified: DateTime.utc_now()
    }})
  end
end
