defmodule Tiannara.UCC.ConstitutionGenome do
  @moduledoc """
  The Canonical ConstitutionGenome representation.
  Tracks the fundamental laws of the world that govern adaptation, separated from state.
  """
  
  @derive Jason.Encoder
  defstruct [
    :id,
    :epoch,
    # Thermodynamic Laws
    :gamma_persistence,
    :rho_signal,
    :alpha_trust,
    :tau_explore,
    # Spatial / Communication Laws
    :radius,
    :movement_budget,
    :signal_horizon,
    :trust_horizon
  ]
end
