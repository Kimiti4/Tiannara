defmodule Tiannara.Discovery.EpistemicSeederTest do
  use ExUnit.Case, async: false

  setup do
    Application.ensure_all_started(:tiannara)
    :ok
  end

  test "seed_battery creates four provenance-tagged entities and returns a manifest" do
    before = Tiannara.World.UnifiedWorldModel.stats().entity_count

    manifest = Tiannara.Discovery.EpistemicSeeder.seed_battery()

    assert manifest.domain == :sensor_fusion
    assert manifest.entities_created == 4
    assert length(manifest.entity_ids) == 4
    assert manifest.entity_failures == []
    assert length(manifest.gaps_from_seed) >= 1
    assert length(manifest.contradictions_from_seed) >= 1
    assert manifest.note =~ "INPUTS"

    after_count = Tiannara.World.UnifiedWorldModel.stats().entity_count
    assert after_count == before + 4
  end

  test "seeded entities carry origin: :epistemic_seed provenance" do
    manifest = Tiannara.Discovery.EpistemicSeeder.seed_battery()

    Enum.each(manifest.entity_ids, fn id ->
      assert {:ok, entity} = Tiannara.World.UnifiedRealityGraph.get_entity(id)
      assert entity.provenance.origin == :epistemic_seed
    end)
  end

  test "seeded entities are canonical: top-level status present and findable by status filter" do
    manifest = Tiannara.Discovery.EpistemicSeeder.seed_battery()

    Enum.each(manifest.entity_ids, fn id ->
      assert {:ok, entity} = Tiannara.World.UnifiedRealityGraph.get_entity(id)
      assert entity.status == :active
      assert is_number(entity.confidence)
      assert is_number(entity.uncertainty)
      assert Map.has_key?(entity, :domain)
    end)

    {:ok, result} = Tiannara.World.WorldQueryEngine.find(status: :active, limit: 100)
    found = Enum.map(result.results, & &1.id)
    Enum.each(manifest.entity_ids, fn id -> assert id in found end)
  end

  test "last_manifest reads back the persisted manifest" do
    _ = Tiannara.Discovery.EpistemicSeeder.seed_battery()

    stored = Tiannara.Discovery.EpistemicSeeder.last_manifest()

    assert is_map(stored)
    assert stored["entities_created"] == 4
    assert length(stored["entity_ids"]) == 4
    assert stored["domain"] == "sensor_fusion"
  end
end
