defmodule Tiannara.OSE.Battlefield do
  @moduledoc """
  Ontological Selection Ecology: Battlefield.
  
  Defines the arena where universes interact. State includes:
  - ontology_gradient
  - causal_pressure
  - thermodynamic_budget
  - interoperability_zone
  - observer_stress
  - novelty_flux
  """
  
  defstruct [
    ontology_gradient: 0.0,
    causal_pressure: 0.0,
    thermodynamic_budget: 1000.0,
    interoperability_zone: %{},
    observer_stress: 0.0,
    novelty_flux: 0.0,
    active_universes: []
  ]
end
