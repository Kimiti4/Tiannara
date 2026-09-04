defmodule Tiannara.ASC.Reality.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      Tiannara.ASC.Reality.Director,
      Tiannara.ASC.Reality.RiskAssessmentEngine,
      Tiannara.ASC.Reality.SafetyVerificationEngine,
      Tiannara.ASC.Reality.ComplianceEngine,
      Tiannara.ASC.Reality.RollbackEngine,
      Tiannara.ASC.Reality.StagedRolloutManager,
      Tiannara.ASC.Reality.IncidentResponseEngine,
      Tiannara.ASC.Reality.DigitalDeploymentManager,
      Tiannara.ASC.Reality.Adapters.SimulatedAdapter,
      Tiannara.ASC.Reality.PhysicalDeploymentManager,
      Tiannara.ASC.Reality.ResourceOptimizationEngine,
      Tiannara.ASC.Reality.InfrastructurePlanner,
      Tiannara.ASC.Reality.EnvironmentalImpactEngine,
      Tiannara.ASC.Reality.DeploymentAuditEngine
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end
end
