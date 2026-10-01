defmodule TiannaraRuntime.Mathematics.SymbolicAlgebra do
  @moduledoc """
  Conservative symbolic algebra normalizer for a small explicit AST.

  Normalization is syntactic/mathematical transformation; it does not by
  itself establish a theorem about an external system.
  """

  def normalize({:add, {:constant, 0}, x}), do: normalize(x)
  def normalize({:add, x, {:constant, 0}}), do: normalize(x)
  def normalize({:mul, {:constant, 0}, _}), do: {:constant, 0}
  def normalize({:mul, _, {:constant, 0}}), do: {:constant, 0}
  def normalize({:mul, {:constant, 1}, x}), do: normalize(x)
  def normalize({:mul, x, {:constant, 1}}), do: normalize(x)
  def normalize({:neg, {:neg, x}}), do: normalize(x)
  def normalize({:add, x, y}), do: {:add, normalize(x), normalize(y)}
  def normalize({:mul, x, y}), do: {:mul, normalize(x), normalize(y)}
  def normalize({:neg, x}), do: {:neg, normalize(x)}
  def normalize({:pow, x, n}), do: {:pow, normalize(x), n}
  def normalize(expression), do: expression

  def equivalent?(left, right) do
    normalize(left) == normalize(right)
  end
end
