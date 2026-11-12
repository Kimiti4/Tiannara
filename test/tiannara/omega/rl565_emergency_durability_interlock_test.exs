defmodule Tiannara.Omega.RL565EmergencyDurabilityInterlockTest do
  use ExUnit.Case, async: false

  alias Tiannara.Council
  alias Tiannara.Council.AuditLog
  alias Tiannara.Council.EmergencyState
  alias Tiannara.Omega.MintRegistry
  alias Tiannara.World.UnifiedWorldModel
  import Tiannara.Test.Phase3Helpers

  setup do
    unless Process.whereis(MintRegistry), do: start_supervised!(MintRegistry)
    unless Process.whereis(AuditLog), do: start_supervised!(AuditLog)
    :ok
  end

  # --------------------------------------------------------------- durability

  test "first boot initializes inactive state and writes state plus marker" do
    with_isolated_base(fn _dir ->
      assert EmergencyState.active?() == false
      assert :ok = EmergencyState.load()

      assert File.exists?(EmergencyState.path())
      assert File.exists?(EmergencyState.marker_path())
      assert EmergencyState.active?() == false
      assert EmergencyState.epoch() == 0
    end)
  end

  test "corrupt authoritative state fails closed" do
    with_isolated_base(fn dir ->
      state_path = EmergencyState.path()
      File.mkdir_p!(dir)
      File.write!(state_path, "this is not an external term")

      assert {:error, :emergency_state_corrupt} = EmergencyState.load()
    end)
  end

  test "invalid snapshot shape fails closed" do
    with_isolated_base(fn _dir ->
      File.mkdir_p!(Path.dirname(EmergencyState.path()))
      File.write!(EmergencyState.path(), :erlang.term_to_binary(%{active: "yes"}))

      assert {:error, :emergency_state_invalid} = EmergencyState.load()
    end)
  end

  test "missing state after initialization fails closed" do
    with_isolated_base(fn dir ->
      File.mkdir_p!(dir)
      File.write!(EmergencyState.marker_path(), "1")

      refute File.exists?(EmergencyState.path())
      assert {:error, :emergency_state_missing} = EmergencyState.load()
    end)
  end

  test "publish failure leaves in-memory state untouched" do
    with_isolated_base(fn dir ->
      assert :ok = EmergencyState.load()
      assert EmergencyState.active?() == false

      blocker = Path.join(dir, "blocker")
      File.write!(blocker, "file, not a directory")
      Application.put_env(:tiannara, :dets_base_path, Path.join(blocker, "nested"))

      assert {:error, {:emergency_persist_failed, {:mkdir, :enoent}}} =
               EmergencyState.publish(%{active: true, invoked_by: :test, reason: "persist fail", epoch: 1})

      assert EmergencyState.active?() == false
      assert EmergencyState.epoch() == 0
    end)
  end

  test "active state and epoch survive a simulated VM restart (disk reload)" do
    with_isolated_base(fn _dir ->
      assert :ok = EmergencyState.load()

      assert :ok =
               EmergencyState.publish(%{
                 active: true,
                 invoked_by: :test,
                 reason: "durable",
                 invoked_at: DateTime.utc_now(),
                 epoch: 7
               })

      assert EmergencyState.active?() == true
      assert EmergencyState.epoch() == 7

      assert :ok = EmergencyState.clear_memory_for_test()
      assert EmergencyState.active?() == false

      assert :ok = EmergencyState.load()
      assert EmergencyState.active?() == true
      assert EmergencyState.epoch() == 7
      assert EmergencyState.snapshot().reason == "durable"
    end)
  end

  test "Council.init refuses to start on corrupt authoritative state" do
    with_isolated_base(fn _dir ->
      File.mkdir_p!(Path.dirname(EmergencyState.path()))
      File.write!(EmergencyState.path(), "corrupt")

      assert_raise RuntimeError, ~r/emergency_state_corrupt/, fn ->
        Council.init([])
      end
    end)
  end

  test "Council.init refuses to start when initialized state is missing" do
    with_isolated_base(fn dir ->
      File.mkdir_p!(dir)
      File.write!(EmergencyState.marker_path(), "1")

      assert_raise RuntimeError, ~r/emergency_state_missing/, fn ->
        Council.init([])
      end
    end)
  end

  # ----------------------------------------------------------------- interlock

  test "emergency activation waits for an in-flight protected effect" do
    entity_id = create_entity("interlock_boundary")
    bound = mint_delete_authorization(entity_id)
    test_pid = self()

    attach_boundary_handler(test_pid)

    delete = Task.async(fn -> UnifiedWorldModel.delete_entity(entity_id, bound) end)
    assert_receive {:effect_boundary, %{effect_id: effect_id}}, 5_000
    assert effect_id == bound.effect_id

    activation = Task.async(fn -> Council.invoke_emergency(:cp1922, "boundary race") end)
    on_exit(fn -> Council.lift_emergency(:cp1922) end)

    # Activation must not win the race while the mutation holds the interlock.
    assert Task.yield(activation, 300) == nil

    # Release the mutation; it finishes before activation is published.
    send(UnifiedWorldModel, :continue)

    assert {:ok, _result} = Task.await(delete, 5_000)
    assert :ok = Task.await(activation, 5_000)

    refute_entity_exists(entity_id)
    assert Council.emergency_state().active == true
  end

  test "protected effect waits for a held interlock" do
    entity_id = create_entity("interlock_hold")
    bound = mint_delete_authorization(entity_id)
    parent = self()

    holder =
      spawn(fn ->
        EmergencyState.with_interlock(fn ->
          send(parent, :interlock_held)

          receive do
            :release_interlock -> :ok
          end
        end)
      end)

    assert_receive :interlock_held, 5_000

    delete = Task.async(fn -> UnifiedWorldModel.delete_entity(entity_id, bound) end)
    assert Task.yield(delete, 300) == nil
    # Read the backing graph directly: the UWM GenServer is blocked on the
    # interlock, so a GenServer.call to it would deadlock the test.
    assert {:ok, _entity} = Tiannara.World.UnifiedRealityGraph.get_entity(entity_id)

    send(holder, :release_interlock)
    assert {:ok, _result} = Task.await(delete, 5_000)
    refute_entity_exists(entity_id)
  end

  test "pre-active emergency refuses the effect without consuming the grant" do
    entity_id = create_entity("interlock_preactive")
    bound = mint_delete_authorization(entity_id)

    assert :ok = Council.invoke_emergency(:cp1922, "pre-active")
    on_exit(fn -> Council.lift_emergency(:cp1922) end)

    assert {:error, :council_emergency_active} =
             UnifiedWorldModel.delete_entity(entity_id, bound)

    assert_entity_exists(entity_id)
    # The refusal happens before consumption, so the grant remains usable.
    assert MintRegistry.status(bound.authorization_id) == :granted

    assert :ok = Council.lift_emergency(:cp1922)
    assert {:ok, _result} = UnifiedWorldModel.delete_entity(entity_id, bound)
    refute_entity_exists(entity_id)
  end

  # ------------------------------------------------------------------ helpers

  defp attach_boundary_handler(test_pid) do
    handler_id = "cp1922-boundary-#{System.unique_integer([:positive])}"

    :telemetry.attach(
      handler_id,
      [:tiannara, :unified_world_model, :effect_boundary],
      fn _event, _measurements, metadata, pid ->
        send(pid, {:effect_boundary, metadata})

        receive do
          :continue -> :ok
        after
          5_000 -> :ok
        end
      end,
      test_pid
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)
    :ok
  end

  defp create_entity(tag) do
    spec = build_entity_spec(:knowledge, :fact, :cp1922, %{tag: tag}, id: unique_id("cp1922"))
    {:ok, id} = UnifiedWorldModel.create_entity(spec)
    id
  end

  defp with_isolated_base(fun) do
    original = Application.get_env(:tiannara, :dets_base_path)

    dir =
      Path.join(
        System.tmp_dir!(),
        "tiannara_emergency_#{System.unique_integer([:positive])}"
      )

    File.rm_rf!(dir)
    File.mkdir_p!(dir)
    Application.put_env(:tiannara, :dets_base_path, dir)

    try do
      fun.(dir)
    after
      Application.put_env(:tiannara, :dets_base_path, original)
      _ = EmergencyState.clear_memory_for_test()
      _ = EmergencyState.load()
      File.rm_rf(dir)
    end
  end
end
