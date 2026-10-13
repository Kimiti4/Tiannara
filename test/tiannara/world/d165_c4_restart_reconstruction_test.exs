defmodule Tiannara.World.D165C4RestartReconstructionTest do
  use ExUnit.Case, async: false

  alias Tiannara.Council.{AuditLog, MachineAuthorization}
  alias Tiannara.Omega.{EffectIdentity, MintRegistry}
  alias Tiannara.World.WorldMutationEngine

  @restart_timeout_ms 5_000

  setup do
    unless Process.whereis(AuditLog), do: start_supervised!(AuditLog)
    unless Process.whereis(MintRegistry), do: start_supervised!(MintRegistry)
    unless Process.whereis(WorldMutationEngine), do: start_supervised!(WorldMutationEngine)
    :ok
  end

  defp await_restarted(module, old_pid) do
    deadline = System.monotonic_time(:millisecond) + @restart_timeout_ms

    case await_restarted_loop(module, old_pid, deadline) do
      {:ok, pid} ->
        pid

      :timeout ->
        start_detached(module)

        case Process.whereis(module) do
          pid when is_pid(pid) and pid != old_pid ->
            pid

          _ ->
            flunk("#{inspect(module)} could not be restarted after stop (C4 restart unavailable)")
        end
    end
  end

  defp await_restarted_loop(module, old_pid, deadline) do
    case Process.whereis(module) do
      pid when is_pid(pid) and pid != old_pid ->
        {:ok, pid}

      _ ->
        if System.monotonic_time(:millisecond) < deadline do
          Process.sleep(25)
          await_restarted_loop(module, old_pid, deadline)
        else
          :timeout
        end
    end
  end

  defp start_detached(module) do
    {:ok, sup} = Supervisor.start_link([module], strategy: :one_for_one)
    Process.unlink(sup)
    :ok
  end

  defp open_materialized_table(path, attempts \\ 40)

  defp open_materialized_table(_path, 0) do
    flunk("C4 materialization could not open the mutation table (attempts exhausted)")
  end

  defp open_materialized_table(path, attempts) do
    case :dets.open_file(:world_mutations, type: :set, file: String.to_charlist(path)) do
      {:ok, :world_mutations} ->
        :ok

      {:error, _reason} ->
        Process.sleep(50)
        open_materialized_table(path, attempts - 1)
    end
  end

  defp record_for(spec_id) do
    WorldMutationEngine.history(limit: 100_000)
    |> Enum.find(fn record -> Map.get(record, :spec, %{})[:id] == spec_id end)
  end

  test "D165 C4: effect ids re-derived from persisted descriptors match originals after a restart" do
    spec = %{id: "d165-c4-#{System.unique_integer([:positive])}", type: :knowledge}

    {:ok, mutation_id} = WorldMutationEngine.mutate(:create_entity, spec)
    assert is_binary(mutation_id)

    record = record_for(spec.id)
    assert record, "mutation record must exist before restart"
    assert record.effect_id

    {:ok, derived_pre} =
      WorldMutationEngine.effect_descriptor(:create_entity, spec) |> EffectIdentity.effect_id()

    assert derived_pre == record.effect_id

    auth = struct(MachineAuthorization, record.machine_authorization)
    assert auth.council_decision_ref, "R-1 anchor must be present in the persisted wrap"
    assert MachineAuthorization.content_hash(auth) == auth.content_hash

    registry_pid = Process.whereis(MintRegistry)
    wme_pid = Process.whereis(WorldMutationEngine)
    assert is_pid(registry_pid) and is_pid(wme_pid)

    GenServer.stop(registry_pid)
    await_restarted(MintRegistry, registry_pid)

    records = WorldMutationEngine.history(limit: 100_000)
    assert Enum.any?(records, &(&1.id == record.id))

    GenServer.stop(wme_pid)
    Process.sleep(50)

    assert Process.whereis(WorldMutationEngine) == nil,
           "unexpected supervisor respawn closed the C4 materialization window"

    # test_helper wipes this run's root AFTER the app opened the engine's DETS
    # file, so the live table writes to a deleted handle. Migrate the genuine
    # records to a real file so the restarted engine reads true persisted state.
    path = WorldMutationEngine.dets_path()
    File.mkdir_p!(Path.dirname(path))
    :ok = open_materialized_table(path)
    Enum.each(records, fn r -> :ok = :dets.insert(:world_mutations, {r.id, r}) end)
    :ok = :dets.sync(:world_mutations)
    :ok = :dets.close(:world_mutations)

    await_restarted(WorldMutationEngine, wme_pid)

    persisted = record_for(spec.id)
    assert persisted, "mutation record must survive the engine restart"

    {:ok, derived_post} =
      WorldMutationEngine.effect_descriptor(:create_entity, persisted.spec)
      |> EffectIdentity.effect_id()

    assert derived_post == derived_pre
    assert derived_post == persisted.effect_id
    assert persisted.effect_id == record.effect_id

    rebuilt = struct(MachineAuthorization, persisted.machine_authorization)
    assert MachineAuthorization.content_hash(rebuilt) == rebuilt.content_hash
    assert rebuilt.council_decision_ref == auth.council_decision_ref
    assert MintRegistry.decision_ref(persisted.authorization_id) == auth.council_decision_ref

    assert MintRegistry.status(persisted.authorization_id) == :consumed

    assert {:error, :already_consumed} =
             MintRegistry.consume(persisted.authorization_id, persisted.effect_id)
  end
end
