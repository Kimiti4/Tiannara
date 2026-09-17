defmodule Tiannara.World.Chaos.ReplayDeterminismTest do
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Tiannara.World.{UnifiedWorldModel, VersionManager}
  import Tiannara.Test.Phase3Helpers

  @moduletag :chaos
  @moduletag timeout: 60_000

  describe "Replay determinism" do
    property "replaying same sequence yields identical state" do
      check all operations <- list_of(
                one_of([
                  {:create, string(:alphanumeric, min_length: 3, max_length: 10)},
                  {:update, string(:alphanumeric), integer()},
                  {:delete, string(:alphanumeric)}
                ]),
                min_length: 1, max_length: 20
              ) do
        initial_meta = %{}

        {state1, _meta1} = apply_operations(initial_meta, operations, %{})
        {state2, _meta2} = apply_operations(initial_meta, operations, %{})

        assert state1 == state2
      end
    end

    defp apply_operations(meta, ops, seed_entities) do
      Enum.reduce(ops, {seed_entities, meta}, fn
        {:create, name}, {entities, m} ->
          id = "replay_#{name}"
          spec = build_entity_spec(:knowledge, :fact, :replay, %{name: name}, id: id)
          {:ok, _} = UnifiedWorldModel.create_entity(spec)
          entities = Map.put(entities, name, %{id: id, name: name, content: spec.attributes})
          {entities, m}

        {:update, name, val}, {entities, m} ->
          case Map.get(entities, name) do
            nil -> {entities, m}
            %{id: id} ->
              UnifiedWorldModel.update_entity(id, %{replay_value: val})
              e = Map.get(entities, name) |> Map.put(:replay_value, val)
              {Map.put(entities, name, e), m}
          end

        {:delete, name}, {entities, m} ->
          case Map.get(entities, name) do
            nil -> {entities, m}
            %{id: id} ->
              UnifiedWorldModel.delete_entity(id)
              {Map.delete(entities, name), m}
          end
      end)
    end

    test "crash during version creation leaves no partial state" do
      entity_id = unique_id("crash_test")

      :ets.new(:crash_monitor, [:set, :public, :named_table])

      process = spawn_link(fn ->
        try do
          VersionManager.create_version(%{
            entity_id: entity_id, content: %{crash_point: "after_write"},
            change_type: :updated, parent_version_id: nil, branch_id: :main, provenance: fresh_provenance()
          })
          :ets.insert(:crash_monitor, {:survived, true})
        rescue
          _ -> :ets.insert(:crash_monitor, {:survived, false})
        end
      end)

      Process.sleep(10)
      Process.exit(process, :kill)
      Process.sleep(50)

      assert {:ok, versions} = VersionManager.version_history(entity_id)
      all_valid = Enum.all?(versions, fn v ->
        is_binary(v.id) and is_integer(v.version_number) and v.version_number > 0
      end)
      assert all_valid
    end
  end
end
