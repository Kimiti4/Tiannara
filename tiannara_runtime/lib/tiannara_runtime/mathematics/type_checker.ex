defmodule TiannaraRuntime.Mathematics.TypeChecker do
  @moduledoc """
  Static type/domain checker for the formal mathematical AST.

  It rejects invalid arithmetic combinations and produces explicit side
  conditions for partial operations such as division.
  """

  alias TiannaraRuntime.Mathematics.FormalAST

  def check(ast) do
    with :ok <- FormalAST.validate(ast),
         {:ok, type, conditions} <- infer(ast) do
      {:ok, %{type: type, side_conditions: conditions}}
    end
  end

  defp infer({:var, _name, domain}), do: {:ok, domain, []}
  defp infer({:const, _value, domain}), do: {:ok, domain, []}

  defp infer({:op, op, [a, b]}) do
    with {:ok, ta, ca} <- infer(a),
         {:ok, tb, cb} <- infer(b),
         {:ok, result} <- arithmetic_type(op, ta, tb) do
      conditions = ca ++ cb ++ division_condition(op, a)
      {:ok, result, Enum.uniq(conditions)}
    end
  end

  defp infer({:rel, rel, a, b}) when rel in [:equal, :not_equal, :less_than, :less_equal, :greater_than, :greater_equal] do
    with {:ok, ta, ca} <- infer(a),
         {:ok, tb, cb} <- infer(b),
         :ok <- comparable?(ta, tb, rel) do
      {:ok, :boolean, ca ++ cb}
    end
  end

  defp infer({:logic, op, children}) when op in [:and, :or, :implies, :iff] do
    with :ok <- all_boolean(children) do
      {:ok, :boolean, Enum.flat_map(children, fn child -> {:ok, _, c} = infer(child); c end)}
    end
  end

  defp infer({:logic, :not, [child]}) do
    with {:ok, :boolean, conditions} <- infer(child), do: {:ok, :boolean, conditions}
  end

  defp infer({:quantifier, _q, {:var, _name, domain}, proposition}) do
    with {:ok, :boolean, conditions} <- infer(proposition) do
      {:ok, :boolean, [{:domain, domain} | conditions]}
    end
  end

  defp arithmetic_type(:add, a, b), do: numeric_join(a, b)
  defp arithmetic_type(:subtract, a, b), do: numeric_join(a, b)
  defp arithmetic_type(:multiply, a, b), do: numeric_join(a, b)
  defp arithmetic_type(:divide, a, b), do: numeric_join(a, b)
  defp arithmetic_type(:power, a, _b) when a in [:real, :integer, :natural, :rational, :complex], do: {:ok, a}
  defp arithmetic_type(_, _, _), do: {:error, :incompatible_operand_types}

  defp numeric_join(a, b) when a in [:real, :integer, :natural, :rational, :complex] and b in [:real, :integer, :natural, :rational, :complex] do
    {:ok, if(:complex in [a, b], do: :complex, else: if(:real in [a, b], do: :real, else: if(:rational in [a, b], do: :rational, else: :integer)))}
  end
  defp numeric_join(_, _), do: {:error, :non_numeric_operands}

  defp comparable?(a, b, _rel) when a == b, do: :ok
  defp comparable?(a, b, _rel) when a in [:natural, :integer, :rational, :real] and b in [:natural, :integer, :rational, :real], do: :ok
  defp comparable?(_, _, :equal), do: :ok
  defp comparable?(_, _, _), do: {:error, :incomparable_domains}

  defp all_boolean(children) do
    if Enum.all?(children, fn child -> match?({:ok, :boolean, _}, infer(child)) end), do: :ok, else: {:error, :logical_operand_must_be_boolean}
  end

  defp division_condition(:divide, denominator), do: [{:not_equal, denominator, {:const, 0, :integer}}]
  defp division_condition(_, _), do: []
end
