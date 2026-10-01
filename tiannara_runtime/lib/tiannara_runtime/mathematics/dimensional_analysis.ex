defmodule TiannaraRuntime.Mathematics.DimensionalAnalysis do
  @moduledoc """
  Minimal dimensional-analysis substrate.

  Units are treated as metadata attached to quantities. Arithmetic combines
  dimensions conservatively and rejects incompatible addition/comparison.
  """

  def quantity(value, dimensions), do: {:quantity, value, normalize(dimensions)}

  def add({:quantity, _, da}, {:quantity, _, db}) when da == db, do: {:ok, da}
  def add({:quantity, _, _}, {:quantity, _, _}), do: {:error, :incompatible_dimensions}

  def multiply({:quantity, _, da}, {:quantity, _, db}),
    do: {:ok, combine(da, db, 1)}
  def divide({:quantity, _, da}, {:quantity, _, db}),
    do: {:ok, combine(da, db, -1)}

  defp normalize(dimensions), do: dimensions |> Map.new() |> Enum.reject(fn {_, v} -> v == 0 end) |> Map.new()
  defp combine(a, b, sign) do
    Map.merge(a, b, fn _k, x, y -> x + sign * y end)
    |> Enum.reject(fn {_, v} -> v == 0 end)
    |> Map.new()
  end
end
