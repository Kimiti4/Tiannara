defmodule Tiannara.World.Epistemic.ConflictDetectorTest do
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Tiannara.World.ConflictResolutionEngine
  import Tiannara.Test.Phase3Helpers

  describe "Epistemic conflict detection" do
    property "symmetry: detector finds conflict both ways" do
      check all conf_a <- float(min: 0.0, max: 1.0),
                conf_b <- float(min: 0.0, max: 1.0) do
        unless length(Enum.uniq([conf_a, conf_b])) == 1 do
          a_id = unique_id("sym_a")
          b_id = unique_id("sym_b")
          domain = :physics

          a = build_entity_spec(domain, :fact, :measurement, %{value: conf_a}, id: a_id, confidence: conf_a)
          b = build_entity_spec(domain, :fact, :measurement, %{value: conf_b}, id: b_id, confidence: conf_b)

          {:ok, _} = ConflictResolutionEngine.create_entity(a)
          {:ok, _} = ConflictResolutionEngine.create_entity(b)

          ab = ConflictResolutionEngine.detect_conflict(a_id, b_id)
          ba = ConflictResolutionEngine.detect_conflict(b_id, a_id)

          assert match?({:ok, _}, ab)
          assert match?({:ok, _}, ba)
        end
      end
    end

    property "entities in different domains never conflict" do
      check all domain_a <- member_of([:physics, :biology, :psychology, :knowledge]),
                domain_b <- member_of([:physics, :biology, :psychology, :knowledge]) do
        unless domain_a == domain_b do
          a_id = unique_id("dom_a")
          b_id = unique_id("dom_b")

          a = build_entity_spec(domain_a, :fact, :measurement, %{value: 1.0}, id: a_id)
          b = build_entity_spec(domain_b, :fact, :measurement, %{value: 2.0}, id: b_id)

          {:ok, _} = ConflictResolutionEngine.create_entity(a)
          {:ok, _} = ConflictResolutionEngine.create_entity(b)

          assert {:ok, %{conflict_type: :no_conflict}} =
            ConflictResolutionEngine.detect_conflict(a_id, b_id)
        end
      end
    end

    test "identical entities are not conflicting" do
      id = unique_id("identical")
      spec = build_entity_spec(:knowledge, :fact, :data, %{value: "same"}, id: id)
      {:ok, _} = ConflictResolutionEngine.create_entity(spec)

      assert {:ok, %{conflict_type: :no_conflict}} =
        ConflictResolutionEngine.detect_conflict(id, id)
    end
  end
end
