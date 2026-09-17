defmodule Tiannara.World.BeliefStatePropertiesTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Tiannara.World.BeliefState

  describe "BeliefState invariants" do
    property "confidence + uncertainty always sums to 1.0 (within float tolerance)" do
      check all prior <- float(min: 0.0, max: 1.0),
                evidence_strength <- float(min: 0.0, max: 1.0),
                evidence_quality <- float(min: 0.0, max: 1.0) do
        state = BeliefState.new(prior, evidence_strength, evidence_quality)
        assert_in_delta state.confidence + state.uncertainty, 1.0, 1.0e-9
      end
    end

    property "update preserves confidence + uncertainty = 1.0" do
      check all prior <- float(min: 0.0, max: 1.0),
                strength <- float(min: 0.0, max: 1.0),
                quality <- float(min: 0.0, max: 1.0),
                new_strength <- float(min: 0.0, max: 1.0),
                new_quality <- float(min: 0.0, max: 1.0) do
        state = BeliefState.new(prior, strength, quality)
        updated = BeliefState.update(state, new_strength, new_quality)
        assert_in_delta updated.confidence + updated.uncertainty, 1.0, 1.0e-9
      end
    end

    property "decay never produces negative confidence" do
      check all prior <- float(min: 0.0, max: 1.0),
                strength <- float(min: 0.0, max: 1.0),
                quality <- float(min: 0.0, max: 1.0),
                days <- integer(0..10_000) do
        state = BeliefState.new(prior, strength, quality)
        decayed = BeliefState.decay(state, days)
        assert decayed.confidence >= 0.0
        assert decayed.confidence <= 1.0
        assert decayed.uncertainty >= 0.0
        assert decayed.uncertainty <= 1.0
      end
    end

    property "evidence_count monotonically increases with updates" do
      check all prior <- float(min: 0.0, max: 1.0),
                updates <- list_of(
                  tuple({float(min: 0.0, max: 1.0), float(min: 0.0, max: 1.0)}),
                  min_length: 1,
                  max_length: 50
                ) do
        state = BeliefState.new(prior, 0.5, 0.5)
        final = Enum.reduce(updates, state, fn {s, q}, acc -> BeliefState.update(acc, s, q) end)
        assert final.evidence_count == 1 + length(updates)
      end
    end

    property "revision_history records every update" do
      check all prior <- float(min: 0.0, max: 1.0),
                updates <- list_of(
                  tuple({float(min: 0.0, max: 1.0), float(min: 0.0, max: 1.0)}),
                  max_length: 20
                ) do
        state = BeliefState.new(prior, 0.5, 0.5)
        final = Enum.reduce(updates, state, fn {s, q}, acc -> BeliefState.update(acc, s, q) end)
        assert length(final.revision_history) == 1 + length(updates)
      end
    end

    property "promotion_ready respects thresholds" do
      check all prior <- float(min: 0.0, max: 1.0),
                strength <- float(min: 0.0, max: 1.0),
                quality <- float(min: 0.0, max: 1.0),
                min_conf <- float(min: 0.0, max: 1.0),
                min_ev <- integer(0..20) do
        state = BeliefState.new(prior, strength, quality)
        ready = BeliefState.promotion_ready?(state, min_conf, min_ev)
        expected = state.confidence >= min_conf and state.evidence_count >= min_ev and state.evidence_quality >= 0.7
        assert ready == expected
      end
    end
  end
end
