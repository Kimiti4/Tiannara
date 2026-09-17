defmodule TiannaraRuntime.Mathematics.MathematicalID do
  @moduledoc "Phase 16.X.1 — Content-addressed identifier for all mathematical objects."
  @type t :: String.t()

  @spec from_canonical_map(map()) :: t()
  def from_canonical_map(map) when is_map(map) do
    map |> canonicalize() |> Jason.encode!() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
  end

  @spec from_bytes(binary()) :: t()
  def from_bytes(bytes) when is_binary(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  defp canonicalize(term) when is_map(term) do
    term |> Enum.map(fn {k, v} -> {to_string(k), canonicalize(v)} end) |> Enum.sort_by(fn {k, _v} -> k end) |> Enum.into(%{})
  end

  defp canonicalize(term) when is_list(term), do: Enum.map(term, &canonicalize/1)
  defp canonicalize(term), do: term
end
