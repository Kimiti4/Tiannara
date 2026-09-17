defmodule Tiannara.OPC.Parser.Lexer do
  @moduledoc """
  Phase 5F.6 — OPC Lexer
  
  Tokenizes observer physics expressions into structured tokens.
  Supports mathematical operators, identifiers, numbers, and function calls.
  """
  
  use GenServer

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc """
  Tokenize a physics expression string.
  
  ## Example
  
      iex> Lexer.tokenize("gravity * 9.81 + velocity ^ 2")
      [{:identifier, :gravity}, {:operator, :*}, {:number, 9.81}, 
       {:operator, :+}, {:identifier, :velocity}, {:operator, :^}, {:number, 2}]
  """
  def tokenize(expression) when is_binary(expression) do
    ~r/\d+\.\d+|\d+|[a-zA-Z_][a-zA-Z0-9_]*|[\+\-\*\/\^\,\(\)]|\S+/
    |> Regex.scan(expression)
    |> List.flatten()
    |> Enum.map(&tokenize_token/1)
    |> Enum.filter(& &1)
  end

  defp tokenize_token(""), do: nil
  defp tokenize_token("+"), do: {:operator, :+}
  defp tokenize_token("-"), do: {:operator, :-}
  defp tokenize_token("*"), do: {:operator, :*}
  defp tokenize_token("/"), do: {:operator, :/}
  defp tokenize_token("^"), do: {:operator, :^}
  defp tokenize_token("("), do: {:paren, :open}
  defp tokenize_token(")"), do: {:paren, :close}
  defp tokenize_token(","), do: {:separator, :comma}
  
  defp tokenize_token(token) do
    cond do
      # Numbers (integers and floats)
      Regex.match?(~r/^\d+(\.\d+)?$/, token) ->
        val = if String.contains?(token, "."), do: String.to_float(token), else: String.to_integer(token) * 1.0
        {:number, val}
      
      # Identifiers (variable names, functions)
      Regex.match?(~r/^[a-zA-Z_][a-zA-Z0-9_]*$/, token) ->
        {:identifier, String.to_atom(token)}
      
      # Invalid token
      true ->
        {:error, {:invalid_token, token}}
    end
  end

  @impl true
  def init(state), do: {:ok, state}
end
