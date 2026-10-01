defmodule TiannaraRuntime.Mathematics.ConstraintEngine do
  @moduledoc """
  Constraint layer for mathematical synthesis.

  Constraints are filters, not proofs. Passing them only means a candidate
  survives the encoded constraints.
  """

  def filter(candidates, constraints) when is_list(candidates) and is_list(constraints) do
    Enum.map(candidates, fn candidate ->
      results = Enum.map(constraints, &evaluate(&1, candidate))
      %{
        candidate: candidate,
        constraint_results: results,
        status: if(Enum.all?(results, &(&1.status == :satisfied)), do: :survives_constraints, else: :rejected)
      }
    end)
  end

  def evaluate({:requires_type, expected}, %{typing: %{type: actual}}),
    do: %{constraint: {:requires_type, expected}, status: if(actual == expected, do: :satisfied, else: :rejected)}
  def evaluate({:requires_no_side_conditions}, %{typing: %{side_conditions: []}}),
    do: %{constraint: :requires_no_side_conditions, status: :satisfied}
  def evaluate({:requires_no_side_conditions}, _),
    do: %{constraint: :requires_no_side_conditions, status: :rejected}
  def evaluate({:predicate, fun}, candidate) when is_function(fun, 1) do
    result = fun.(candidate)
    %{constraint: :predicate, status: if(result == true, do: :satisfied, else: :rejected)}
  end
  def evaluate(unknown, _), do: %{constraint: unknown, status: :unresolved}
end
