defmodule Tiannara.World.VersionImmutabilityPropertiesTest do
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Tiannara.World.VersionManager
  import Tiannara.Test.Phase3Helpers

  setup_all do
    case start_supervised({VersionManager, :test}) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
    %{}
  end

  setup do
    %{entity_id: unique_id("version_prop")}
  end

  describe "Version immutability" do
    property "every created version has monotonically increasing version", %{entity_id: entity_id} do
      check all updates <- list_of(integer(1..100), min_length: 1, max_length: 5) do
        Enum.each(updates, fn val ->
          VersionManager.create_version(%{
            entity_id: entity_id, content: %{value: val, updated_at: DateTime.utc_now()},
            change_type: :updated, parent_version_id: nil, branch_id: :main, provenance: fresh_provenance()
          })
        end)

        {:ok, history} = VersionManager.version_history(entity_id)
        numbers = Enum.map(history, & &1.version)
        assert numbers == Enum.sort(numbers)
        assert numbers == Enum.uniq(numbers)
      end
    end

    property "retrieved version snapshot matches what was stored", %{entity_id: entity_id} do
      check all payload <- map_of(
                    one_of([constant(:a), constant(:b), constant(:c), constant(:d), constant(:e)]),
                    integer(0..1000), min_length: 1, max_length: 3
                  ) do
        {:ok, vnum} = VersionManager.create_version(%{
          entity_id: entity_id, content: payload, change_type: :updated,
          parent_version_id: nil, branch_id: :main, provenance: fresh_provenance()
        })

        {:ok, retrieved} = VersionManager.get_version(entity_id, vnum)
        assert Map.get(retrieved.snapshot, :content) == payload
        assert retrieved.entity_id == entity_id
      end
    end

    property "tagging a version is idempotent per (entity, tag_name)", %{entity_id: entity_id} do
      check all tag_name <- string(:alphanumeric, min_length: 3, max_length: 10) do
        {:ok, vnum} = VersionManager.create_version(%{
          entity_id: entity_id, content: %{tag_test: true}, change_type: :updated,
          parent_version_id: nil, branch_id: :main, provenance: fresh_provenance()
        })

        :ok = VersionManager.tag_version(entity_id, vnum, tag_name, %{first: true})
        :ok = VersionManager.tag_version(entity_id, vnum, tag_name, %{second: true})

        tags = VersionManager.get_tags(entity_id)
        matching = Enum.filter(tags, &(&1.tag == tag_name))
        assert length(matching) == 1
      end
    end
  end
end
