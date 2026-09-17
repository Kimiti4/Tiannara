defmodule Tiannara.EPC.ControlLaw do
  @moduledoc """
  Evolution Pressure Control: Control Law.
  Computes damped bounds-safe control pressure vectors.
  """
  
  def compute(s, _j, _a, stability) do
    %{
      ose: 0.3*(target_entropy() - s.h) + 0.1*s.n - 0.2*s.d,
      cis: 0.4*s.c - 0.3*s.d - 0.2*s.phi,
      grcc: 0.5*s.h - 0.4*s.d + 0.2*s.n,
      olef: 0.4*s.phi - 0.3*s.l
    }
    |> damp(stability)
  end

  defp damp(u, stability) do
    factor = if stability.risk > 0.7, do: 0.3, else: 1.0

    Map.new(u, fn {k, v} -> {k, v * factor} end)
  end

  defp target_entropy, do: 0.65
end
