defmodule Tiannara.CCI.Supervisor do
  @moduledoc "Supervises all CCI subsystems with one_for_one strategy."
  use Supervisor

  def start_link(opts \\ []), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    children = [
      {Tiannara.CCI.CivilizationSelfModel, name: :cci_csm},
      {Tiannara.CCI.ConstitutionalGovernanceEngine, name: :cci_cge},
      {Tiannara.CCI.CivilizationForecastingEngine, name: :cci_cfe},
      {Tiannara.CCI.InstitutionalEvolutionSystem, name: :cci_ies},
      {Tiannara.CCI.CivilizationalMemoryEngine, name: :cci_cme},
      {Tiannara.CCI.CivilizationExperimentRuntime, name: :cci_cxr},
      {Tiannara.CCI.PriorityResearchEngine, name: :cci_pre},
      {Tiannara.CCI.CivilizationRiskIntelligence, name: :cci_cri}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
