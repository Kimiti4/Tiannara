defmodule Tiannara.Forecasting.DecisionTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.Decision
  alias Tiannara.Forecasting.Contracts.Alternative

  defp alt(attrs) do
    struct!(%Alternative{}, Map.merge(%{id: :a}, Map.new(attrs)))
  end

  describe "new/1" do
    test "builds a decision with version 1 and a generated id" do
      a = alt(outcomes: ["x", "y"], probabilities: [0.5, 0.5], utilities: [1, 1])
      d = Decision.new(question: "Q", alternatives: [a])
      assert d.question == "Q"
      assert d.decision_version == 1
      assert d.lineage == []
      assert d.id != nil
    end

    test "accepts a DecisionRequest struct as input" do
      a = alt(id: :go, outcomes: ["s", "f"], probabilities: [0.8, 0.2], utilities: [5, -1])
      req = %Tiannara.Forecasting.Contracts.DecisionRequest{question: "Go?", alternatives: [a]}
      d = Decision.new(req)
      assert d.question == "Go?"
      assert [alt] = d.alternatives
      assert alt.id == :go
    end

    test "keeps raw alternative data decision-time (no recomputation of EV)" do
      a = alt(outcomes: ["x"], probabilities: [1.0], utilities: [42])
      d = Decision.new(question: "Q", alternatives: [a])
      assert d.expected_values == nil
      assert d.recommended_alternative_id == nil
    end
  end

  describe "validate/1" do
    test "accepts a well-formed decision" do
      a = alt(outcomes: ["x", "y"], probabilities: [0.5, 0.5], utilities: [1, 1])
      assert {:ok, _} = Decision.validate(Decision.new(question: "Q", alternatives: [a]))
    end

    test "rejects missing question" do
      a = alt(outcomes: ["x"], probabilities: [1.0], utilities: [1.0])
      assert {:error, :missing_question} = Decision.validate(Decision.new(alternatives: [a]))
    end

    test "rejects empty alternatives" do
      assert {:error, :missing_alternatives} = Decision.validate(Decision.new(question: "Q", alternatives: []))
    end

    test "rejects malformed alternatives (probability/outcome mismatch)" do
      a = alt(outcomes: ["x", "y"], probabilities: [0.5], utilities: [1, 1])
      assert {:error, :invalid_alternative} = Decision.validate(Decision.new(question: "Q", alternatives: [a]))
    end

    test "unknown probabilities are valid for validation" do
      a = alt(outcomes: ["x", "y"], probabilities: :unknown, utilities: [1, 1])
      assert {:ok, _} = Decision.validate(Decision.new(question: "Q", alternatives: [a]))
    end
  end

  describe "version/2" do
    test "produces a new version referencing its ancestor" do
      a = alt(id: :a, outcomes: ["x", "y"], probabilities: [0.5, 0.5], utilities: [1, 1])
      d1 = Decision.new(question: "Q", alternatives: [a])
      d2 = Decision.version(d1, context: %{note: "revised"})
      assert d2.decision_version == 2
      assert d2.lineage == [d1.id]
      assert d2.id != d1.id
      assert d2.context == %{note: "revised"}
    end
  end

  describe "do_nothing/0" do
    test "provides the default no-action alternative" do
      dn = Decision.do_nothing()
      assert dn.id == :do_nothing
      assert dn.label == "do_nothing"
    end
  end
end