defmodule Tiannara.OPC.Validator.SymbolicValidator do
  @moduledoc """
  Phase 5F.6 — OPC Symbolic Stability Validator
  
  Validates AST for mathematical stability and safety before compilation.
  Detects division by zero, unbounded growth, and recursive instability.
  """
  
  use GenServer
  require Logger

  @max_recursion_depth 16
  @max_value 1.0e308
  @min_value -1.0e308

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc """
  Validate an AST for symbolic stability.
  
  Returns {:ok, :stable} or {:error, reason}
  """
  def validate(ast) do
    validate_node(ast, 0)
  end

  defp validate_node(_, depth) when depth > @max_recursion_depth do
    Logger.warning("OPC Validator: Recursive instability detected at depth #{depth}")
    {:error, :recursive_instability}
  end

  defp validate_node({:number, n}, _depth) do
    if n > @max_value or n < @min_value do
      {:error, {:value_out_of_bounds, n}}
    else
      {:ok, :stable}
    end
  end

  defp validate_node({:identifier, _id}, _depth), do: {:ok, :stable}

  defp validate_node({:binary_op, :/, _, {:number, 0.0}}, _depth) do
    Logger.warning("OPC Validator: Division by zero detected")
    {:error, :division_by_zero}
  end

  defp validate_node({:binary_op, :/, left, right}, depth) do
    with {:ok, _} <- validate_node(left, depth + 1),
         {:ok, _} <- validate_node(right, depth + 1),
         :ok <- check_divisor_safety(right) do
      {:ok, :stable}
    end
  end

  defp validate_node({:binary_op, :^, base, exp}, depth) do
    with {:ok, _} <- validate_node(base, depth + 1),
         {:ok, _} <- validate_node(exp, depth + 1),
         :ok <- check_exponent_safety(base, exp) do
      {:ok, :stable}
    end
  end

  defp validate_node({:binary_op, op, left, right}, depth) when op in [:+, :-, :*, :mod] do
    with {:ok, _} <- validate_node(left, depth + 1),
         {:ok, _} <- validate_node(right, depth + 1) do
      {:ok, :stable}
    end
  end

  defp validate_node({:unary_op, :-, operand}, depth) do
    validate_node(operand, depth + 1)
  end

  defp validate_node({:unary_op, :sqrt, operand}, depth) do
    with {:ok, _} <- validate_node(operand, depth + 1),
         :ok <- check_sqrt_domain(operand) do
      {:ok, :stable}
    end
  end

  defp validate_node({:unary_op, op, operand}, depth) when op in [:abs, :sin, :cos, :tan, :exp, :log, :floor, :ceil] do
    validate_node(operand, depth + 1)
  end

  defp validate_node({:function, _name, args}, depth) do
    result = Enum.reduce_while(args, {:ok, :stable}, fn arg, _acc ->
      case validate_node(arg, depth + 1) do
        {:ok, _} -> {:cont, {:ok, :stable}}
        error -> {:halt, error}
      end
    end)
    
    case result do
      {:ok, _} -> {:ok, :stable}
      error -> error
    end
  end

  defp validate_node({:tensor, elements}, depth) do
    result = Enum.reduce_while(elements, {:ok, :stable}, fn elem, _acc ->
      case validate_node(elem, depth + 1) do
        {:ok, _} -> {:cont, {:ok, :stable}}
        error -> {:halt, error}
      end
    end)
    
    case result do
      {:ok, _} -> {:ok, :stable}
      error -> error
    end
  end

  defp validate_node({:conditional, condition, true_branch, false_branch}, depth) do
    with {:ok, _} <- validate_node(condition, depth + 1),
         {:ok, _} <- validate_node(true_branch, depth + 1),
         {:ok, _} <- validate_node(false_branch, depth + 1) do
      {:ok, :stable}
    end
  end

  defp check_divisor_safety({:number, n}) do
    if abs(n) < 1.0e-10 do
      Logger.warning("OPC Validator: Near-zero divisor detected (#{n})")
      {:error, :near_zero_divisor}
    else
      :ok
    end
  end

  defp check_divisor_safety(_), do: :ok

  defp check_exponent_safety({:number, base}, {:number, exp}) do
    cond do
      base < 0 and exp != floor(exp) ->
        {:error, :complex_result_from_negative_base}
      abs(base) > 100 and abs(exp) > 10 ->
        Logger.warning("OPC Validator: Potential exponential blowup (#{base}^#{exp})")
        {:error, :exponential_blowup_risk}
      true ->
        :ok
    end
  end

  defp check_exponent_safety(_, _), do: :ok

  defp check_sqrt_domain({:number, n}) do
    if n < 0 do
      {:error, :sqrt_negative_domain}
    else
      :ok
    end
  end

  defp check_sqrt_domain(_), do: :ok

  @impl true
  def init(state), do: {:ok, state}
end
