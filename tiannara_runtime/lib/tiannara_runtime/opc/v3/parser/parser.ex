defmodule Tiannara.OPC.V3.Parser do
  @moduledoc """
  OPC v3 Parser
  Produces raw syntax trees ONLY - no evaluation logic, no normalization
  """

  alias Tiannara.OPC.V3.Parser.Lexer

  def parse(source) when is_binary(source) do
    tokens = Lexer.tokenize(source)
    case parse_expression(tokens) do
      {:ok, ast, remaining_tokens} -> {:ok, ast, remaining_tokens}
      error -> error
    end
  end

  # Updated parsing functions to handle expressions properly
  defp parse_expression(tokens) do
    parse_binary_op_left_assoc(tokens, 0)
  end

  # Left-associative binary operator parsing
  defp parse_binary_op_left_assoc(tokens, min_precedence) do
    {:ok, left_expr, remaining} = parse_term(tokens)

    continue_parse_binary_op(left_expr, remaining, min_precedence)
  end

  defp continue_parse_binary_op(left_expr, [{:op, op_token} | rest], min_precedence) do
    op_precedence = operator_precedence(op_token)
    
    if op_precedence >= min_precedence do
      {:ok, right_expr, remaining} = parse_term(rest)

      # Handle right associativity for power operator
      if op_token == :^ do
        {:ok, result_expr, final_remaining} = continue_parse_power({:raw_binary, op_token, left_expr, right_expr}, remaining)
        {:ok, result_expr, final_remaining}
      else
        # For left associative operators, continue parsing with the same precedence
        new_expr = {:raw_binary, op_token, left_expr, right_expr}
        
        # Check if there are more operators at the same or higher precedence
        continue_parse_binary_op(new_expr, remaining, op_precedence + 1)
      end
    else
      {:ok, left_expr, [{:op, op_token} | rest]}
    end
  end

  defp continue_parse_binary_op(expr, tokens, _min_precedence) do
    {:ok, expr, tokens}
  end

  defp continue_parse_power(expr, [{:op, :^} | rest]) do
    {:ok, right_expr, remaining} = parse_term(rest)
    new_expr = {:raw_binary, :^, expr, right_expr}
    continue_parse_power(new_expr, remaining)
  end

  defp continue_parse_power(expr, tokens) do
    {:ok, expr, tokens}
  end

  defp parse_term([{:number, value} | rest]), do: {:ok, {:number, value}, rest}
  defp parse_term([{:identifier, name} | rest]), do: {:ok, {:raw_identifier, name}, rest}

  # Handle function calls like sqrt(4)
  defp parse_term([{:identifier, func_name}, {:paren, :open} | rest]) when func_name in [:sqrt, :abs, :sin, :cos, :tan, :exp, :log, :min, :max, :clamp, :lerp, :normalize, :floor, :ceil] do
    case parse_argument_list(rest, []) do
      {:ok, args, [{:paren, :close} | remaining]} ->
        {:ok, {:raw_function, func_name, args}, remaining}
      error ->
        error
    end
  end

  # Handle other identifiers that aren't functions
  defp parse_term([{:identifier, name} | rest]) do
    {:ok, {:raw_identifier, name}, rest}
  end

  # Handle unary minus
  defp parse_term([{:op, :-} | rest]) do
    case parse_factor(rest) do
      {:ok, factor, remaining} ->
        {:ok, {:raw_unary, :-, factor}, remaining}
      error ->
        error
    end
  end

  # Handle parenthesized expressions
  defp parse_term([{:paren, :open} | rest]) do
    case parse_expression(rest) do
      {:ok, expr, [{:paren, :close} | remaining]} ->
        {:ok, expr, remaining}
      error ->
        error
    end
  end

  defp parse_term([]), do: {:error, :unexpected_end_of_input}
  defp parse_term([token | _]), do: {:error, {:unexpected_token, token}}

  # Parse factors (highest precedence)
  defp parse_factor(tokens), do: parse_term(tokens)

  # Parse function arguments
  defp parse_argument_list([{:paren, :close} | rest], args), do: {:ok, Enum.reverse(args), rest}
  defp parse_argument_list([], _args), do: {:error, :missing_closing_paren}
  
  defp parse_argument_list(tokens, args) do
    case parse_expression(tokens) do
      {:ok, arg, [{:comma, _} | rest]} ->
        parse_argument_list(rest, [arg | args])
      {:ok, arg, [{:paren, :close} | rest]} ->
        {:ok, Enum.reverse([arg | args]), rest}
      {:ok, arg, remaining} ->
        {:ok, Enum.reverse([arg | args]), remaining}
      error ->
        error
    end
  end

  defp operator_precedence(:+), do: 1
  defp operator_precedence(:-), do: 1
  defp operator_precedence(:*), do: 2
  defp operator_precedence(:/), do: 2
  defp operator_precedence(:^), do: 3
  defp operator_precedence(_), do: 0
end
