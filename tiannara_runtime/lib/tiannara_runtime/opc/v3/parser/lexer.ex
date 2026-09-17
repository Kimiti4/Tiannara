defmodule Tiannara.OPC.V3.Parser.Lexer do
  @moduledoc """
  OPC v3 Lexer
  Tokenizes source strings into raw tokens for the parser
  """

  def tokenize(input) do
    input
    |> String.graphemes()
    |> tokenize([], "")
  end

  defp tokenize([], tokens, ""), do: Enum.reverse(tokens)
  defp tokenize([], tokens, buffer), do: Enum.reverse([tokenize_buffer(buffer) | tokens])

  defp tokenize([char | rest], tokens, buffer) do
    case char do
      "(" -> process_char(char, :paren, :open, rest, tokens, buffer)
      ")" -> process_char(char, :paren, :close, rest, tokens, buffer)
      "+" -> process_operator(char, :+, rest, tokens, buffer)
      "-" -> process_operator(char, :-, rest, tokens, buffer)
      "*" -> process_operator(char, :*, rest, tokens, buffer)
      "/" -> process_operator(char, :/, rest, tokens, buffer)
      "^" -> process_operator(char, :^, rest, tokens, buffer)
      "," -> process_operator(char, :comma, rest, tokens, buffer)
      " " -> process_whitespace(rest, tokens, buffer)
      "\t" -> process_whitespace(rest, tokens, buffer)
      "\n" -> process_whitespace(rest, tokens, buffer)
      "." -> tokenize_number(char, rest, tokens, buffer)
      digit when digit >= "0" and digit <= "9" -> tokenize_number(char, rest, tokens, buffer)
      letter when letter >= "a" and letter <= "z" -> tokenize_identifier(char, rest, tokens, buffer)
      letter when letter >= "A" and letter <= "Z" -> tokenize_identifier(char, rest, tokens, buffer)
      "_" -> tokenize_identifier(char, rest, tokens, buffer)
      _ -> process_char(char, :unknown, char, rest, tokens, buffer)
    end
  end

  defp process_char(_char, token_type, value, rest, tokens, "") do
    new_tokens = [{token_type, value} | tokens]
    tokenize(rest, new_tokens, "")
  end

  defp process_char(_char, token_type, value, rest, tokens, buffer) do
    new_tokens = [tokenize_buffer(buffer), {token_type, value} | tokens]
    tokenize(rest, new_tokens, "")
  end

  defp process_operator(_char, op_atom, rest, tokens, "") do
    new_tokens = [{:op, op_atom} | tokens]
    tokenize(rest, new_tokens, "")
  end

  defp process_operator(_char, op_atom, rest, tokens, buffer) do
    new_tokens = [tokenize_buffer(buffer), {:op, op_atom} | tokens]
    tokenize(rest, new_tokens, "")
  end

  defp process_whitespace(rest, tokens, "") do
    tokenize(rest, tokens, "")
  end

  defp process_whitespace(rest, tokens, buffer) do
    new_tokens = [tokenize_buffer(buffer) | tokens]
    tokenize(rest, new_tokens, "")
  end

  defp tokenize_number(char, rest, tokens, buffer) do
    tokenize(rest, tokens, buffer <> char)
  end

  defp tokenize_identifier(char, rest, tokens, buffer) do
    tokenize(rest, tokens, buffer <> char)
  end

  defp tokenize_buffer(buffer) when buffer == "", do: []

  defp tokenize_buffer(buffer) do
    case Float.parse(buffer) do
      {number, ""} -> {:number, number}
      _ ->
        case Integer.parse(buffer) do
          {integer, ""} -> {:number, integer}
          _ -> {:identifier, String.to_atom(buffer)}
        end
    end
  end
end
