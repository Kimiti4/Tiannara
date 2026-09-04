defmodule Tiannara.ACE.Supervisor do
  @moduledoc "Supervises all ACE subsystems."
  use Supervisor

  def start_link(opts \\ []), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    children = [
      {Tiannara.ACE.EngineeringRealityGraph, name: :ace_erg},
      {Tiannara.ACE.DesignEvolutionEngine, name: :ace_design_evolution},
      {Tiannara.ACE.CivilizationDigitalTwin, name: :ace_digital_twin},
      {Tiannara.ACE.EngineeringConfidence, name: :ace_confidence},
      {Tiannara.ACE.EngineeringInstitutions, name: :ace_institutions}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
