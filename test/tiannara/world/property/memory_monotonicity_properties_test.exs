defmodule Tiannara.World.MemoryMonotonicityPropertiesTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Tiannara.World.CanonicalWorldState

  describe "Memory stage progression" do
    property "next_stage is strictly forward in the memory chain" do
      check all stage <- member_of(CanonicalWorldState.memory_stages()) do
        stages = CanonicalWorldState.memory_stages()
        current_idx = Enum.find_index(stages, &(&1 == stage))

        case CanonicalWorldState.next_stage(stage) do
          nil -> assert current_idx == length(stages) - 1
          next ->
            next_idx = Enum.find_index(stages, &(&1 == next))
            assert next_idx == current_idx + 1
        end
      end
    end

    property "successive next_stage calls eventually reach nil" do
      check all start_stage <- member_of(CanonicalWorldState.memory_stages()) do
        stages = CanonicalWorldState.memory_stages()
        max_iterations = length(stages) + 1

        final =
          Enum.reduce_while(1..max_iterations, start_stage, fn _, current ->
            case CanonicalWorldState.next_stage(current) do
              nil -> {:halt, :reached_end}
              next -> {:cont, next}
            end
          end)

        assert final == :reached_end
      end
    end

    property "memory stages are a fixed, ordered chain" do
      stages = CanonicalWorldState.memory_stages()
      assert is_list(stages)
      assert length(stages) > 0
      assert stages == Enum.uniq(stages)
      assert hd(stages) == :data
      assert List.last(stages) == :scientific_discovery
    end
  end
end
