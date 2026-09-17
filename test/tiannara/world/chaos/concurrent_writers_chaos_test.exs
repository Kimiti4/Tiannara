defmodule Tiannara.World.Chaos.ConcurrentWritersTest do
  use ExUnit.Case, async: false

  alias Tiannara.World.VersionManager
  import Tiannara.Test.Phase3Helpers

  @moduletag :chaos
  @moduletag timeout: 120_000

  describe "Concurrent version writing" do
    test "50 concurrent writers all succeed without conflict" do
      entity_id = unique_id("concurrent_writer")

      VersionManager.create_version(%{
        entity_id: entity_id, content: %{initial: true}, change_type: :created,
        parent_version_id: nil, branch_id: :main, provenance: fresh_provenance()
      })

      tasks =
        Enum.map(1..50, fn i ->
          Task.async(fn ->
            VersionManager.create_version(%{
              entity_id: entity_id, content: %{writer: i, timestamp: System.system_time(:millisecond)},
              change_type: :updated, parent_version_id: nil, branch_id: :main, provenance: fresh_provenance()
            })
          end)
        end)

      results = Task.await_many(tasks, 30_000)
      successes = Enum.count(results, &match?({:ok, _}, &1))
      assert successes == 50
    end

    test "1000 sequential version creates all succeed" do
      entity_id = unique_id("seq_writer")

      results =
        Enum.map(1..1000, fn i ->
          VersionManager.create_version(%{
            entity_id: entity_id, content: %{iteration: i}, change_type: :updated,
            parent_version_id: nil, branch_id: :main, provenance: fresh_provenance()
          })
        end)

      successes = Enum.count(results, &match?({:ok, _}, &1))
      assert successes == 1000
    end
  end
end
