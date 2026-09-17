defmodule Tiannara.EPC.Objective do
  @moduledoc """
  Evolution Pressure Control: Objective Function.
  Lyapunov-candidate core tracking evolutionary potential.
  """
  
  def compute(s) do
    α = 0.25
    β = 0.20
    γ = 0.20
    δ = 0.15
    λ = 0.10
    μ = 0.05
    ν = 0.05

    α*s.h +
    β*s.n +
    γ*s.o +
    δ*s.c -
    λ*s.d -
    μ*s.phi -
    ν*s.l
  end
end
