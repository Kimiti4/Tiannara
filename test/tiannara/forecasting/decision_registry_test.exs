defmodule Tiannara.Forecasting.DecisionRegistryTest do
  use ExUnit.Case, async: false

  alias Tiannara.Forecasting.{Decision, DecisionEngine, DecisionRegistry}
  alias Tiannara.Forecasting.Contracts.Alternative

  setup do
    start_supervised!(DecisionRegistry)
    :ets.delete_all_objects(:efdi_decision_registry)
    :ok
  end

  defp alternative(id, probs) do
    struct!(%Alternative{},
      id: id, label: Atom.to_string(id),
      outcomes: ["hi", "lo"], probabilities: probs, utilities: [10, 0])
  end

  defp decision(question \\ "Q") do
    Decision.new(question: question, alternatives: [alternative(:go, [0.8, 0.2])])
  end

  describe "register/1" do
    test "registers and retrieves a decision by id" do
      d = decision()
      assert {:ok, stored} = DecisionRegistry.register(d)
      assert stored.id == d.id
      assert {:ok, fetched} = DecisionRegistry.get(d.id)
      assert fetched.question == "Q"
    end

    test "registering the same id is a no-op (immutable)" do
      d = decision()
      assert {:ok, _} = DecisionRegistry.register(d)
      assert {:ok, _} = DecisionRegistry.register(%{d | question: "different"})
      assert {:ok, fetched} = DecisionRegistry.get(d.id)
      assert fetched.question == "Q"
    end

    test "count/all_ids reflect registrations" do
      assert DecisionRegistry.count() == 0
      {:ok, d1} = DecisionRegistry.register(decision("q1"))
      {:ok, d2} = DecisionRegistry.register(decision("q2"))
      assert DecisionRegistry.count() == 2
      assert Enum.sort(DecisionRegistry.all_ids()) == Enum.sort([d1.id, d2.id])
    end

    test "rejects invalid decisions" do
      bad = Decision.new(question: "Q", alternatives: [])
      assert {:error, :missing_alternatives} = DecisionRegistry.register(bad)

      bad2 = Decision.new(alternatives: [Decision.do_nothing()])
      assert {:error, :missing_question} = DecisionRegistry.register(bad2)
    end
  end

  describe "get/1" do
    test ":error for unknown id" do
      assert :error = DecisionRegistry.get("nope")
    end
  end

  describe "engine-decide then register (integration shape)" do
    test "a decision produced by the engine is registered and retrievable" do
      a = alternative(:invest, [0.6, 0.4])
      assert {:ok, d} = DecisionEngine.decide(question: "invest?", alternatives: [a])
      assert {:ok, stored} = DecisionRegistry.register(d)
      assert stored.recommended_alternative_id == :invest
      assert {:ok, fetched} = DecisionRegistry.get(stored.id)
      assert fetched.expected_values[:invest] |> is_number()
    end
  end

  describe "health/0" do
    test "reports registry health" do
      h = DecisionRegistry.health()
      assert h.ets_available == true
      assert h.eventstore_degraded in [true, false]
    end
  end
end