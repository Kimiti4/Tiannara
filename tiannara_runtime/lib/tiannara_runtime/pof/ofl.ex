defmodule Tiannara.POF.OFL do
  @moduledoc """
  Observer-Free Limit (OFL).
  
  The asymptotic limit where no reference frame remains.
  Never fully instantiated. Defines the absolute minimum epsilon (ε)
  of observer density and distinction tendency to prevent irreversible loop termination.
  """
  
  @epsilon 1.0e-9

  @doc """
  The irreducible residual asymmetry required for Genesis regeneration.
  """
  def epsilon(), do: @epsilon

  def current_state(observer_density) do
    if observer_density <= @epsilon do
      :undecidable_reference
    else
      :resolvable
    end
  end
end
