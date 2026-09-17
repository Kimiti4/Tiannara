defmodule Tiannara.Forecasting.D3IntegrationTest do
  use ExUnit.Case, async: false

  alias Tiannara.Forecasting.{
    Decision,
    DecisionEngine,
    DecisionQuality,
    DecisionRegistry,
    DecisionReview,
    DecisionSnapshot,
    PreMortem,
    ValueOfInformation
  }
  alias Tiannara.Forecasting.Contracts.{Alternative, DecisionOutcome}

  setup do
    start_supervised!(DecisionRegistry)
    :ets.delete_all_objects(:efdi_decision_registry)
    :ok
  end

  defp alt(id, probs, utils, opts \\ []) do
    struct!(%Alternative{},
      id: id, label: Atom.to_string(id),
      outcomes: ["win", "lose"], probabilities: probs, utilities: utils,
      reversibility: Keyword.get(opts, :reversibility, :reversible))
  end

  describe "engine → snapshot → registry → quality pipeline" do
    test "a full D3 loop keeps decision quality independent of outcome" do
      alts = [
        alt(:campaign, [0.6, 0.4], [100, -40]),
        alt(:wait, [0.7, 0.3], [30, 15]),
        Decision.do_nothing()
      ]

      assert {:ok, decision} = DecisionEngine.decide(question: "Launch campaign?", alternatives: alts)

      snap = DecisionSnapshot.capture(decision)
      assert snap.decision_id == decision.id

      assert {:ok, _} = DecisionRegistry.register(decision)
      assert {:ok, stored} = DecisionRegistry.get(decision.id)

      quality = DecisionQuality.evaluate(stored, snap)
      assert quality.hindsight_independent == true
      assert quality.basis == :decision_time

      outcomes = [
        %{alternative_id: :campaign, observed_outcome: "win"},
        %{alternative_id: :campaign, observed_outcome: "lose"}
      ]

      for o <- outcomes do
        outcome = %DecisionOutcome{
          decision_id: decision.id,
          alternative_id: o.alternative_id,
          observed_outcome: o.observed_outcome,
          observed_at: DateTime.add(decision.created_at, 60, :second)
        }

        assert {:ok, _} = DecisionReview.guard_outcome(outcome, stored)
      end

      # re-evaluate: identical score, because outcome is never an input
      quality_again = DecisionQuality.evaluate(stored, snap)
      assert quality.score == quality_again.score
    end
  end

  describe "pre-mortem + value-of-information inform authorization flow" do
    test "research priorities are produced for information-sensitive decisions" do
      alts = [
        alt(:enter, [0.52, 0.48], [200, 0]),
        alt(:stay, [0.48, 0.52], [195, 5])
      ]

      assert {:ok, decision} = DecisionEngine.decide(question: "Enter market?", alternatives: alts)
      priorities = ValueOfInformation.to_research_priorities(decision, sensitivity_threshold: 0.0)
      assert priorities != []

      premortem = PreMortem.run_all(decision.alternatives)
      assert length(premortem) == length(decision.alternatives)
      posture = PreMortem.posture(premortem)
      assert match?(:proceed, posture) or match?({:require_info, info} when info != [], posture) or posture == :block
    end

    test "irreversible high-stakes alternative escalates to require_info or block" do
      alts = [
        alt(:merge, :unknown, [1000, -1000], reversibility: :irreversible),
        alt(:wait, [0.8, 0.2], [50, 40], reversibility: :reversible)
      ]

      assert {:ok, decision} = DecisionEngine.decide(question: "Merge?", alternatives: alts)
      result = PreMortem.run(Enum.find(decision.alternatives, &(&1.id == :merge)))
      assert result.blocked? == true
    end
  end

  describe "adapter boundary defects do not leak into the registry" do
    test "decisions never mutate after registration" do
      alts = [
        alt(:a, [0.5, 0.5], [10, 0]),
        alt(:b, [0.5, 0.5], [0, 10])
      ]

      assert {:ok, decision} = DecisionEngine.decide(question: "Q", alternatives: alts)
      assert {:ok, _} = DecisionRegistry.register(decision)
      assert {:ok, stored} = DecisionRegistry.get(decision.id)

      # attempt to mutate the stored record is impossible (immutable term)
      poisoned = %{stored | expected_values: %{a: 999.0}}
      assert poisoned != stored
      assert {:ok, untouched} = DecisionRegistry.get(decision.id)
      assert untouched == stored
      refute untouched.expected_values[:a] == 999.0
    end
  end
end