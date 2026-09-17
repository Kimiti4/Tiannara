defmodule Tiannara.Forecasting.PreMortemTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.PreMortem
  alias Tiannara.Forecasting.Contracts.Alternative

  defp alt(attrs) do
    struct!(%Alternative{}, Map.merge(%{id: :x, outcomes: ["a", "b"]}, Map.new(attrs)))
  end

  describe "run/2" do
    test "flags unknown-probability alternatives as high risk" do
      a = alt(probabilities: :unknown, utilities: [1, 2])
      result = PreMortem.run(a)
      assert result.blocked? == true
      assert length(result.failure_modes) >= 1
      assert result.alternative_id == :x
    end

    test "does not block a low-risk deterministic alternative" do
      a = alt(probabilities: [1.0, 0.0], utilities: [10, -100], reversibility: :reversible)
      result = PreMortem.run(a, risk_threshold: 0.8)
      assert result.blocked? == false
    end

    test "blocked? combines the alternative's risk exposure" do
      a = alt(probabilities: [0.5, 0.5], utilities: [10, -100], reversibility: :irreversible)
      result = PreMortem.run(a, risk_threshold: 0.7)
      # irreversible alternative includes an irreversible-commitment failure mode above threshold
      assert result.blocked? == true
    end
  end

  describe "run_all/2" do
    test "returns one result per alternative" do
      as = [alt(id: :a, probabilities: :unknown, utilities: [1, 2]),
            alt(id: :b, probabilities: [0.5, 0.5], utilities: [1, 1], reversibility: :reversible)]
      results = PreMortem.run_all(as)
      assert length(results) == 2
    end
  end

  describe "posture/2" do
    test "proceed when no alternative is blocked" do
      results = [PreMortem.run(alt(probabilities: [1.0, 0.0], utilities: [1, -1], reversibility: :reversible))]
      assert PreMortem.posture(results) == :proceed
    end

    test "block when a high-threshold failure mode exists" do
      results = [PreMortem.run(alt(probabilities: :unknown, utilities: [1, 2]))]
      assert PreMortem.posture(results, 0.8) == :block
    end

    test "require_info when failure modes are below hard threshold" do
      a = alt(probabilities: [0.5, 0.5], utilities: [-1, -2], reversibility: :partially_reversible)
      results = [PreMortem.run(a, risk_threshold: 0.3)]
      assert {:require_info, [_ | _]} = PreMortem.posture(results, 0.9)
    end
  end
end