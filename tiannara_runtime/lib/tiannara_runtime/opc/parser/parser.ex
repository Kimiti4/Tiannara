defmodule Tiannara.OPC.Parser.Parser do
  @moduledoc """
  Phase 5F.6 — OPC Parser
  
  Converts tokenized expressions into Abstract Syntax Trees (AST).
  Implements recursive descent parsing with bounded depth.
  
  ## Safety Features
  
  - Maximum AST depth enforcement (default: 16)
  - Operator precedence handling
  - Function call validation
  - Tensor construction support
  """
  
  use GenServer
  alias Tiannara.OPC.Parser.AST
  alias Tiannara.OPC.Parser.Lexer

  @max_ast_depth 16

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc """
  Parse a physics expression string into an AST.
  
  ## Example
  
      iex> Parser.parse("gravity * 9.81")
      {:ok, {:binary_op, :*, {:identifier, :gravity}, {:number, 9.81}}}
  """
  def parse(expression) when is_binary(expression) do
    tokens = Lexer.tokenize(expression)
    
    case build_ast(tokens, 0) do
      {:ok, ast, _remaining} ->
        if AST.depth(ast) > @max_ast_depth do
          {:error, {:ast_too_deep, AST.depth(ast), @max_ast_depth}}
        else
          case AST.validate_operations(ast) do
            :ok -> {:ok, ast}
            error -> error
          end
        end
      
      error ->
        error
    end
  end

  # Recursive descent parser
  defp build_ast([], depth), do: {:error, {:unexpected_eof, depth}}
  
  # Parse binary operations (lowest precedence: +, -)
  defp build_ast(tokens, depth) when depth < @max_ast_depth do
    parse_addition(tokens, depth)
  end

  defp parse_addition(tokens, depth) do
    case parse_multiplication(tokens, depth) do
      {:ok, left, remaining} ->
        parse_addition_rest(left, remaining, depth)
      error ->
        error
    end
  end

  defp parse_addition_rest(left, [{:operator, op} | rest], depth) when op in [:+, :-] do
    case parse_multiplication(rest, depth + 1) do
      {:ok, right, remaining} ->
        parse_addition_rest({:binary_op, op, left, right}, remaining, depth)
      error ->
        error
    end
  end

  defp parse_addition_rest(left, remaining, _depth), do: {:ok, left, remaining}

  # Parse multiplication/division (higher precedence: *, /)
  defp parse_multiplication(tokens, depth) do
    case parse_exponent(tokens, depth) do
      {:ok, left, remaining} ->
        parse_multiplication_rest(left, remaining, depth)
      error ->
        error
    end
  end

  defp parse_multiplication_rest(left, [{:operator, op} | rest], depth) when op in [:*, :/] do
    case parse_exponent(rest, depth + 1) do
      {:ok, right, remaining} ->
        parse_multiplication_rest({:binary_op, op, left, right}, remaining, depth)
      error ->
        error
    end
  end

  defp parse_multiplication_rest(left, remaining, _depth), do: {:ok, left, remaining}

  # Parse exponentiation (right-associative)
  defp parse_exponent(tokens, depth) do
    case parse_unary(tokens, depth) do
      {:ok, base, [{:operator, :^} | rest]} ->
        case parse_exponent(rest, depth + 1) do
          {:ok, exp, remaining} ->
            {:ok, {:binary_op, :^, base, exp}, remaining}
          error ->
            error
        end
      result ->
        result
    end
  end

  # Parse unary operators (-, sqrt, etc.)
  defp parse_unary([{:operator, :-} | rest], depth) do
    case parse_primary(rest, depth + 1) do
      {:ok, operand, remaining} ->
        {:ok, {:unary_op, :-, operand}, remaining}
      error ->
        error
    end
  end

  defp parse_unary([{:identifier, func}, {:paren, :open} | rest], depth) when func in [:sqrt, :abs, :sin, :cos, :tan, :exp, :log] do
    case parse_function_args(rest, depth + 1) do
      {:ok, args, [{:paren, :close} | remaining]} ->
        {:ok, {:function, func, args}, remaining}
      {:ok, args, remaining} ->
        {:ok, {:function, func, args}, remaining}
      error ->
        error
    end
  end

  defp parse_unary(tokens, depth), do: parse_primary(tokens, depth)

  # Parse primary expressions (numbers, identifiers, parenthesized expressions)
  defp parse_primary([{:number, n} | rest], _depth), do: {:ok, {:number, n}, rest}
  
  defp parse_primary([{:identifier, id} | rest], _depth), do: {:ok, {:identifier, id}, rest}
  
  defp parse_primary([{:paren, :open} | rest], depth) do
    case parse_addition(rest, depth + 1) do
      {:ok, expr, [{:paren, :close} | remaining]} ->
        {:ok, expr, remaining}
      error ->
        error
    end
  end

  defp parse_primary([], depth), do: {:error, {:unexpected_eof, depth}}
  defp parse_primary([token | _], depth), do: {:error, {:unexpected_token, token, depth}}

  # Parse function arguments
  defp parse_function_args(tokens, depth) do
    parse_function_args_acc(tokens, depth, [])
  end

  defp parse_function_args_acc([{:paren, :close} | rest], _depth, acc), do: {:ok, Enum.reverse(acc), rest}
  
  defp parse_function_args_acc(tokens, depth, acc) do
    case parse_addition(tokens, depth) do
      {:ok, arg, [{:separator, :comma} | rest]} ->
        parse_function_args_acc(rest, depth, [arg | acc])
      {:ok, arg, [{:paren, :close} | rest]} ->
        {:ok, Enum.reverse([arg | acc]), rest}
      error ->
        error
    end
  end

  defp parse_function_args_acc([], _depth, acc), do: {:ok, Enum.reverse(acc), []}

  @impl true
  def init(state), do: {:ok, state}
end
