defmodule Tiannara.World.Epistemic.IntegrityTest do
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Tiannara.World.ConflictResolutionEngine
  import Tiannara.Test.Phase3Helpers

  describe "Epistemic integrity enforcement" do
    property "confidence ordering is maintained during resolution" do
      check all conf_a <- float(min: 0.5, max: 1.0),
                conf_b <- float(min: 0.0, max: 0.499) do
        a_id = unique_id("conf_a")
        b_id = unique_id("conf_b")

        a = build_entity_spec(:physics, :fact, :measurement, %{value: conf_a}, id: a_id, confidence: conf_a)
        b = build_entity_spec(:physics, :fact, :measurement, %{value: conf_b}, id: b_id, confidence: conf_b)

        {:ok, _} = ConflictResolutionEngine.create_entity(a)
        {:ok, _} = ConflictResolutionEngine.create_entity(b)

        {:ok, result} = ConflictResolutionEngine.resolve(a_id, b_id, strategy: :confidence_weighted)
        assert result.winner_id == a_id
        assert result.winner_confidence >= result.loser_confidence
      end
    end

    property "merge always produces combined confidence >= max of inputs" do
      check all conf_a <- float(min: 0.0, max: 1.0),
                conf_b <- float(min: 0.0, max: 1.0) do
        a_id = unique_id("merge_a")
        b_id = unique_id("merge_b")

        a = build_entity_spec(:biology, :fact, :measurement, %{value: conf_a}, id: a_id, confidence: conf_a)
        b = build_entity_spec(:biology, :fact, :measurement, %{value: conf_b}, id: b_id, confidence: conf_b)

        {:ok, _} = ConflictResolutionEngine.create_entity(a)
        {:ok, _} = ConflictResolutionEngine.create_entity(b)

        {:ok, result} = ConflictResolutionEngine.resolve(a_id, b_id, strategy: :merge)
        {:ok, merged} = ConflictResolutionEngine.get_entity(result.merged_entity_id)

        assert merged.confidence >= max(conf_a, conf_b)
        assert length(Map.get(merged.provenance, :source_entities, [])) >= 2
      end
    end
  end
end
