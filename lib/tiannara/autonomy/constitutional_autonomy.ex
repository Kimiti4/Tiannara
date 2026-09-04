defmodule Tiannara.Autonomy.ConstitutionalAutonomy do
  @moduledoc """
  Constitutional Autonomy — TIA-OMEGA-4

  The safe self-improvement engine for Tiannara. Enables the system to
  identify, propose, simulate, validate, deploy, and monitor improvements
  to its own runtime, architecture, and knowledge — always within
  constitutional constraints.
  """

  use Supervisor
  require Logger

  alias Tiannara.Autonomy.{ImprovementEngine, ProposalGenerator, SimulationManager, DeploymentPipeline, ConstitutionalValidator, RollbackEngine}

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec status() :: map()
  def status do
    %{improvements: ImprovementEngine.status(), proposals: ProposalGenerator.status(), simulations: SimulationManager.status(), deployments: DeploymentPipeline.status(), validation: ConstitutionalValidator.status(), rollbacks: RollbackEngine.status()}
  end

  @spec health() :: map()
  def health do
    %{status: :healthy, active_proposals: ProposalGenerator.active_count(), running_simulations: SimulationManager.running_count(), active_deployments: DeploymentPipeline.active_count(), total_improvements_deployed: DeploymentPipeline.total_deployed(), total_rollbacks: RollbackEngine.total_rollbacks(), constitutional_violations: ConstitutionalValidator.total_violations()}
  end

  @spec run_cycle() :: {:ok, map()} | {:error, term()}
  def run_cycle do
    GenServer.call(__MODULE__.Orchestrator, :run_cycle, 120_000)
  end

  @spec submit_proposal(map()) :: {:ok, binary()} | {:error, term()}
  def submit_proposal(proposal) do
    ProposalGenerator.submit_manual(proposal)
  end

  @spec approve(binary(), atom()) :: :ok | {:error, term()}
  def approve(proposal_id, approver) do
    DeploymentPipeline.approve(proposal_id, approver)
  end

  @spec reject(binary(), atom(), String.t()) :: :ok | {:error, term()}
  def reject(proposal_id, rejector, reason) do
    DeploymentPipeline.reject(proposal_id, rejector, reason)
  end

  @spec rollback(binary(), String.t()) :: :ok | {:error, term()}
  def rollback(deployment_id, reason) do
    RollbackEngine.rollback(deployment_id, reason)
  end

  @impl true
  def init(opts) do
    Logger.info("[ConstitutionalAutonomy] Starting Constitutional Autonomy...")

    children = [
      %{id: RollbackEngine, start: {RollbackEngine, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: ConstitutionalValidator, start: {ConstitutionalValidator, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: ImprovementEngine, start: {ImprovementEngine, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: ProposalGenerator, start: {ProposalGenerator, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: SimulationManager, start: {SimulationManager, :start_link, [[]]}, restart: :permanent, shutdown: 10_000, type: :worker},
      %{id: DeploymentPipeline, start: {DeploymentPipeline, :start_link, [opts]}, restart: :permanent, shutdown: 15_000, type: :worker},
      %{id: __MODULE__.Orchestrator, start: {__MODULE__.Orchestrator, :start_link, [opts]}, restart: :permanent, shutdown: 10_000, type: :worker}
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 3, max_seconds: 60)
  end
end

defmodule Tiannara.Autonomy.ConstitutionalAutonomy.Orchestrator do
  @moduledoc """
  Orchestrates the full improvement cycle.
  """

  use GenServer
  require Logger

  alias Tiannara.Autonomy.{ImprovementEngine, ProposalGenerator, SimulationManager, DeploymentPipeline, ConstitutionalValidator, RollbackEngine}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec run_cycle() :: {:ok, map()} | {:error, term()}
  def run_cycle do
    GenServer.call(__MODULE__, :run_cycle, 120_000)
  end

  @impl true
  def init(_opts) do
    {:ok, %{cycles: 0, last_cycle_at: nil, total_improvements: 0, total_rejected: 0, total_rolled_back: 0}}
  end

  @impl true
  def handle_call(:run_cycle, _from, state) do
    Logger.info("[Autonomy.Orchestrator] Running improvement cycle #{state.cycles + 1}...")
    result = execute_cycle()
    {:reply, result, %{state | cycles: state.cycles + 1, last_cycle_at: DateTime.utc_now()}}
  end

  defp execute_cycle do
    opportunities = ImprovementEngine.identify()

    if length(opportunities) == 0 do
      {:ok, %{stage: :identification, result: :no_opportunities, improvements: 0}}
    else
      if autonomous_execution_enabled?() and real_simulation_provider?() do
        full_cycle(opportunities)
      else
        # Truthful: the autonomous cycle must NOT simulate or deploy without a
        # real execution provider. No fabricated improvement ratios or
        # deployment successes are reported.
        {:ok, %{
          stage: :simulation,
          result: :not_available,
          reason: if(autonomous_execution_enabled?(), do: :no_real_simulation_provider, else: :autonomous_execution_not_enabled),
          improvements: length(opportunities)
        }}
      end
    end
  end

  defp full_cycle(opportunities) do
    proposals = ProposalGenerator.generate(opportunities)

    validated = Enum.filter(proposals, fn proposal ->
      case ConstitutionalValidator.validate(proposal) do
        {:approved, _} -> true
        {:rejected, reason} -> Logger.info("[Autonomy] Proposal rejected: #{reason}"); false
      end
    end)

    if length(validated) == 0 do
      {:ok, %{stage: :validation, result: :all_rejected, proposals: length(proposals)}}
    else
      simulated = Enum.map(validated, fn proposal -> SimulationManager.simulate(proposal) end)
      viable = Enum.filter(simulated, fn sim -> sim[:improvement_ratio] != nil and sim[:improvement_ratio] > 1.0 end)

      if length(viable) == 0 do
        {:ok, %{stage: :simulation, result: :no_improvement, simulated: length(simulated)}}
      else
        deployments = Enum.map(viable, fn sim -> DeploymentPipeline.deploy(sim) end)

        :telemetry.execute([:tiannara, :autonomy, :cycle_completed], %{deployments: length(deployments)}, %{opportunities: length(opportunities), proposals: length(proposals)})

        {:ok, %{stage: :deployment, opportunities: length(opportunities), proposals: length(proposals), validated: length(validated), simulated: length(simulated), deployed: length(deployments)}}
      end
    end
  end

  defp autonomous_execution_enabled?,
    do: Application.get_env(:tiannara, :real_execution_enabled, false) == true

  defp real_simulation_provider?,
    do: false
end
