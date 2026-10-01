defmodule TiannaraRuntime.Mathematics.CounterexampleLearnerTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.CounterexampleLearner

  test "counterexample becomes a candidate constraint, not a fact" do
    candidate = %{expression: :x}
    {:ok, learned} = CounterexampleLearner.learn({:falsified, %{x: 2}}, candidate)
    assert learned.status == :constraint_candidate
    assert learned.certification_eligible == false
  end

  test "constraint requires independent validation" do
    {:ok, result} =
      CounterexampleLearner.validate_constraint(:candidate_constraint, fn _ ->
        {:supported, %{tests: 3}}
      end)
    assert result.status == :supported
  end
end
