defmodule Tiannara.CEL.CapabilityRegistry do
  use GenServer
  require Logger

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def register_subsystem(subsystem_spec) do
    GenServer.call(__MODULE__, {:register, subsystem_spec})
  end

  def update_workload(subsystem_id, workload_pct) do
    GenServer.cast(__MODULE__, {:update_workload, subsystem_id, workload_pct})
  end

  def get_delegation_target(event_type) do
    GenServer.call(__MODULE__, {:find_target, event_type})
  end

  def healthy?, do: GenServer.call(__MODULE__, :healthy)

  def constitutional_score, do: GenServer.call(__MODULE__, :constitutional_score)

  @impl true
  def init(_opts) do
    initial_capabilities = %{
      agency: %{
        id: :agency, purpose: "Autonomous scientific investigation",
        capabilities: [:investigate, :generate_hypothesis, :validate],
        delegation_endpoint: Tiannara.Agency.Orchestrator,
        health: :healthy, workload: 0.0
      },
      asc: %{
        id: :asc, purpose: "Civilizational capability and governance",
        capabilities: [:create_capability, :improve_institution, :govern],
        delegation_endpoint: Tiannara.ASC.Orchestrator,
        health: :healthy, workload: 0.0
      },
      cci: %{
        id: :cci, purpose: "Civilization reasoning and forecasting",
        capabilities: [:forecast, :governance_cycle, :risk_assess],
        delegation_endpoint: Tiannara.CCI.Orchestrator,
        health: :healthy, workload: 0.0
      },
      sentinel: %{
        id: :sentinel, purpose: "Observation, detection, and security",
        capabilities: [:detect, :classify, :monitor, :alert],
        delegation_endpoint: Tiannara.Sentinel.Activation.Engine,
        health: :healthy, workload: 0.0
      }
    }
    {:ok, %{subsystems: initial_capabilities}}
  end

  @impl true
  def handle_call({:register, spec}, _from, state) do
    new_state = put_in(state, [:subsystems, spec.id], spec)
    Logger.info("CapabilityRegistry: Registered subsystem #{spec.id}")
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:find_target, event_type}, _from, state) do
    candidates =
      state.subsystems
      |> Enum.filter(fn {_id, sub} ->
        sub.health == :healthy and event_type in sub.capabilities
      end)
      |> Enum.sort_by(fn {_id, sub} -> sub.workload end)

    case candidates do
      [{best_id, _sub} | _] -> {:reply, {:ok, best_id}, state}
      [] -> {:reply, {:error, :no_capable_subsystem}, state}
    end
  end

  @impl true
  def handle_call(:healthy, _from, state), do: {:reply, true, state}

  @impl true
  def handle_call(:constitutional_score, _from, state) do
    score = %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: :capability_graph,
      health: 1.0,
      constitutional_alignment: 0.95,
      transparency: 0.9,
      explainability: 0.85,
      evidence_quality: 0.85,
      human_oversight: 0.6,
      computed_at: DateTime.utc_now()
    }
    {:reply, score, state}
  end

  @impl true
  def handle_cast({:update_workload, id, workload}, state) do
    if Map.has_key?(state.subsystems, id) do
      {:noreply, put_in(state, [:subsystems, id, :workload], workload)}
    else
      {:noreply, state}
    end
  end
end
