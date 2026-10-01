defmodule TiannaraRuntime.Mathematics.FormalProblemTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.Mathematics.FormalProblem

  test "formal problem requires an explicit target" do
    assert {:error, :formal_target_required} =
             FormalProblem.new(%{variables: [], assumptions: [], definitions: [], targets: []})
  end

  test "formal problem preserves unresolved status" do
    {:ok, problem} = FormalProblem.new(%{
      variables: [%{name: "x", domain: :real}],
      assumptions: [%{status: :unresolved, statement: "x is bounded"}],
      definitions: [],
      targets: [%{formal: "f(x) = 0"}]
    })

    assert problem.formalization_status == :unresolved
    assert String.starts_with?(problem.problem_id, "problem_")
  end

  test "complete formal problem is content addressed" do
    attrs = %{
      variables: [%{name: "n", domain: :natural}],
      assumptions: [],
      definitions: [],
      targets: [%{formal: "n + 1 > n"}]
    }

    {:ok, a} = FormalProblem.new(attrs)
    {:ok, b} = FormalProblem.new(attrs)
    assert a.problem_id == b.problem_id
    assert a.formalization_status == :complete
  end
end
