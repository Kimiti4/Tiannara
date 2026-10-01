defmodule TiannaraRuntime.Mathematics.EquivalenceEngine do
  @moduledoc """
  Conservative structural equivalence checker.

  It reports only equivalences justified by implemented rules. Unknown
  equivalence is distinct from inequality or falsehood.
  """

  alias TiannaraRuntime.Mathematics.FormalAST

  def check(a, b) do
    with :ok <- FormalAST.validate(a),
         :ok <- FormalAST.validate(b) do
      cond do
        a == b -> {:ok, :equivalent, %{method: :structural_identity}}
        commutative_pair?(a, b) -> {:ok, :equivalent, %{method: :commutativity}}
        true -> {:ok, :unknown, %{reason: :no_implemented_equivalence_rule}}
      end
    end
  end

  defp commutative_pair?({:op, :add, [a, b]}, {:op, :add, [b, a]}), do: true
  defp commutative_pair?({:op, :multiply, [a, b]}, {:op, :multiply, [b, a]}), do: true
  defp commutative_pair?(_, _), do: false
end
