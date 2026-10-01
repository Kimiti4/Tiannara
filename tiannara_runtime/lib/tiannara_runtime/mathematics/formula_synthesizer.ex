defmodule TiannaraRuntime.Mathematics.FormulaSynthesizer do
  @moduledoc """
  Bounded mathematical candidate synthesis.

  Candidate generation is deliberately separated from verification. The
  synthesizer proposes expressions satisfying syntactic/type constraints; it
  never labels a candidate true, optimal, useful, or novel.
  """

  alias TiannaraRuntime.Mathematics.{FormalAST, TypeChecker, DerivationGraph}

  def generate(variable, constants \ [], opts \ []) do
    budget = min(Keyword.get(opts, :budget, 16), 64)
    templates = [
      fn -> FormalAST.add(variable, hd_or_zero(constants)) end,
      fn -> FormalAST.multiply(variable, hd_or_one(constants)) end,
      fn -> FormalAST.power(variable, FormalAST.constant(2, :integer)) end,
      fn -> FormalAST.add(FormalAST.power(variable, FormalAST.constant(2, :integer)), variable) end
    ]

    candidates =
      templates
      |> Enum.take(budget)
      |> Enum.map(fn build ->
        expression = build.()
        case TypeChecker.check(expression) do
          {:ok, typing} ->
            {:ok, %{expression: expression, typing: typing, status: :candidate}}
          {:error, reason} ->
            {:rejected, reason}
        end
      end)
      |> Enum.filter(&match?({:ok, _}, &1))
      |> Enum.map(fn {:ok, candidate} ->
        graph = DerivationGraph.new(variable)
        %{candidate | derivation_graph: graph}
      end)

    {:ok, %{candidates: candidates, status: :candidate, certification_eligible: false}}
  end

  defp hd_or_zero([x | _]), do: x
  defp hd_or_zero([]), do: FormalAST.constant(0, :integer)
  defp hd_or_one([x | _]), do: x
  defp hd_or_one([]), do: FormalAST.constant(1, :integer)
end
