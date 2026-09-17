defmodule TiannaraOS.CivilizationKernelTest do
  use ExUnit.Case, async: false
  require Logger

  alias TiannaraOS.CivilizationKernel
  alias TiannaraOS.WorldManager
  alias TiannaraOS.State
  alias TiannaraOS.World
  alias Tiannara.REA.Epistemic.Institution

  setup do
    # Reset state to clean State before each test
    clean_state = %State{
      worlds: %{},
      theories: %{},
      institutions: %{},
      tools: %{},
      discoveries: %{},
      memory: %{global_ledger: []},
      economy: %{},
      security: %{},
      governance: %{
        active_mode: :balanced,
        constitutional_events: [],
        overrides: [],
        audit_log: []
      }
    }

    # Reset via human override to ensure a clean starting point
    {:ok, _} = CivilizationKernel.human_override(clean_state)
    :ok
  end

  test "Kernel boots and returns initial state" do
    state = CivilizationKernel.get_state()
    assert %State{} = state
    assert state.worlds == %{}
    assert state.theories == %{}
    assert state.institutions == %{}
  end

  test "Dynamic world spawning and verification for :cybersecurity" do
    assert {:ok, %World{} = world} = WorldManager.spawn_world(:cybersecurity, tenant_id: "default_tenant")
    
    # Verify properties
    assert world.template_id == :cybersecurity
    assert world.tenant_id == "default_tenant"
    assert length(world.labs) > 0
    assert length(world.institutions) > 0
    assert length(world.theories) > 0

    # Retrieve state and verify maps
    state = CivilizationKernel.get_state()
    assert Map.has_key?(state.worlds, world.id)

    # Verify institutions exist in state
    for inst_id <- world.institutions do
      assert Map.has_key?(state.institutions, inst_id)
      inst = Map.get(state.institutions, inst_id)
      assert inst.id == inst_id
    end

    # Verify theories exist in state
    for theory_id <- world.theories do
      assert Map.has_key?(state.theories, theory_id)
      theory = Map.get(state.theories, theory_id)
      assert theory.world_id == world.id
    end
  end

  test "Dynamic world spawning and verification for :robotics and :mathematics" do
    assert {:ok, %World{} = world_rob} = WorldManager.spawn_world(:robotics, tenant_id: "default_tenant")
    assert world_rob.template_id == :robotics

    assert {:ok, %World{} = world_math} = WorldManager.spawn_world(:mathematics, tenant_id: "default_tenant")
    assert world_math.template_id == :mathematics
  end

  test "Tenant isolation violation is blocked" do
    # Spawning a world with mismatched tenant_id must return {:error, :tenant_isolation_violation}
    # since default_tenant is the kernel's active tenant
    assert {:error, :tenant_isolation_violation} = WorldManager.spawn_world(:cybersecurity, tenant_id: "foreign_tenant")
  end

  test "Resource ceiling: compute_ceiling_exceeded" do
    # Default compute ceiling is 10,000.0. Let's create an institution with compute_share exceeding this limit.
    large_compute_inst = %Institution{
      id: :inst_overlimit,
      name: "Overlimit Executor",
      compute_share: 15_000.0
    }

    result = CivilizationKernel.update_state(fn state ->
      %{state | institutions: Map.put(state.institutions, :inst_overlimit, large_compute_inst)}
    end)

    assert {:error, :compute_ceiling_exceeded} = result
    
    # State should not have been updated
    state = CivilizationKernel.get_state()
    refute Map.has_key?(state.institutions, :inst_overlimit)
  end

  test "Resource ceiling: memory_objects_ceiling_exceeded" do
    # Default memory objects ceiling is 50,000. Let's create a map of tools exceeding this limit.
    large_tools = Map.new(1..50_005, fn i -> {String.to_atom("tool_#{i}"), %{}} end)

    result = CivilizationKernel.update_state(fn state ->
      %{state | tools: large_tools}
    end)

    assert {:error, :memory_objects_ceiling_exceeded} = result
  end

  test "Infallible state rollback preserves civilization memory audits (ARC1 rule)" do
    # Step 1: Set some memory
    {:ok, state_with_memory} = CivilizationKernel.update_state(fn state ->
      %{state | memory: %{global_ledger: ["event1", "event2"]}}
    end)

    # Step 2: Spawn a world
    assert {:ok, world} = WorldManager.spawn_world(:cybersecurity)
    state_after_spawn = CivilizationKernel.get_state()
    assert Map.has_key?(state_after_spawn.worlds, world.id)

    # Step 3: Trigger rollback to state_with_memory
    {:ok, state_after_rollback} = CivilizationKernel.rollback(state_with_memory)

    # Step 4: Verify world is gone (restored state), but memory is preserved!
    refute Map.has_key?(state_after_rollback.worlds, world.id)
    assert state_after_rollback.memory == %{global_ledger: ["event1", "event2"]}

    # Verify audit log in governance has rollback logged
    assert Enum.any?(state_after_rollback.governance.audit_log, fn event -> event.type == :rollback end)
  end

  test "Human veto override bypasses normal checks" do
    # Step 1: Construct an invalid state (e.g. cross-tenant world and compute ceiling exceeded)
    invalid_state = %State{
      worlds: %{
        invalid_world: %World{id: :invalid_world, tenant_id: "mismatched_tenant"}
      },
      institutions: %{
        overlimit_inst: %Institution{id: :overlimit_inst, compute_share: 20_000.0}
      },
      governance: %{
        active_mode: :balanced,
        constitutional_events: [],
        overrides: [],
        audit_log: []
      }
    }

    # Verify standard update fails on this state
    result = CivilizationKernel.update_state(fn _ -> invalid_state end)
    assert {:error, _} = result

    # Verify human override succeeds
    assert {:ok, updated_state} = CivilizationKernel.human_override(invalid_state)
    assert Map.has_key?(updated_state.worlds, :invalid_world)
    assert Map.has_key?(updated_state.institutions, :overlimit_inst)

    # Verify override and audit event logging
    assert Enum.any?(updated_state.governance.overrides, fn event -> event.type == :human_override end)
    assert Enum.any?(updated_state.governance.audit_log, fn event -> event.type == :human_override end)
  end

  test "World retirement (destroy_world/1) cleanup" do
    # Step 1: Spawn cybersecurity world
    assert {:ok, world} = WorldManager.spawn_world(:cybersecurity)
    state = CivilizationKernel.get_state()
    assert Map.has_key?(state.worlds, world.id)
    assert length(world.institutions) > 0
    assert length(world.theories) > 0

    # Step 2: Destroy world
    assert {:ok, destroyed_world_id} = WorldManager.destroy_world(world.id)
    assert destroyed_world_id == world.id

    # Step 3: Verify world, associated institutions and theories are cleaned up from State
    state_after_destruction = CivilizationKernel.get_state()
    refute Map.has_key?(state_after_destruction.worlds, world.id)

    for inst_id <- world.institutions do
      refute Map.has_key?(state_after_destruction.institutions, inst_id)
    end

    for theory_id <- world.theories do
      refute Map.has_key?(state_after_destruction.theories, theory_id)
    end
  end
end
