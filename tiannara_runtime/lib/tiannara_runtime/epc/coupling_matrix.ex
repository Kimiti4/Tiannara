defmodule Tiannara.EPC.CouplingMatrix do
  @moduledoc """
  Evolution Pressure Control: Coupling Matrix.
  Safe Jacobian estimator based on state differentials.
  """
  
  def estimate(s) do
    %{
      ose: s.n - s.d,
      cis: s.c - s.phi,
      grcc: s.h - s.d,
      olef: s.phi - s.l
    }
  end
end
