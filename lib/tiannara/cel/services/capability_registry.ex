defmodule Tiannara.CEL.Services.CapabilityRegistry do
  use Tiannara.ExecutiveService.Base
  use GenServer
  require Logger

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def register_capability(service_id, capabilities, provider_pid) do
    GenServer.call(__MODULE__, {:register, service_id, capabilities, provider_pid})
  end

  def find_provider(capability) do
    GenServer.call(__MODULE__, {:find_provider, capability})
  end

  def update_health(service_id, health_status) do
    GenServer.cast(__MODULE__, {:update_health, service_id, health_status})
  end

  def missing_capabilities(required) do
    GenServer.call(__MODULE__, {:missing, required})
  end

  def all_providers, do: GenServer.call(__MODULE__, :all)

  @impl true
  def id, do: :capability_graph

  @impl true
  def version, do: "2.0.0"

  @impl true
  def capabilities, do: [:capability_discovery, :intelligent_delegation, :workload_balancing]

  @impl true
  def health, do: :healthy

  @impl true
  def constitutional_score do
    %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: :capability_graph,
      health: 1.0,
      constitutional_alignment: 0.95,
      transparency: 0.9,
      explainability: 0.85,
      evidence_quality: 0.85,
      human_oversight: 0.65,
      computed_at: DateTime.utc_now()
    }
  end

  @impl true
  def init(_opts) do
    providers = %{
      agency: %{id: :agency, capabilities: [:investigate, :generate_hypothesis, :validate], pid: nil, health: :healthy, workload: 0.0},
      asc: %{id: :asc, capabilities: [:create_capability, :improve_institution, :govern], pid: nil, health: :healthy, workload: 0.0},
      cci: %{id: :cci, capabilities: [:forecast, :governance_cycle, :risk_assess], pid: nil, health: :healthy, workload: 0.0},
      sentinel: %{id: :sentinel, capabilities: [:detect, :classify, :monitor, :alert], pid: nil, health: :healthy, workload: 0.0}
    }
    Logger.info("CapabilityRegistry v2: Initialized with #{map_size(providers)} providers")
    {:ok, %{providers: providers}}
  end

  @impl true
  def handle_call({:register, service_id, capabilities, pid}, _from, state) do
    provider = %{
      id: service_id,
      capabilities: capabilities,
      pid: pid,
      health: :healthy,
      workload: 0.0
    }
    {:reply, :ok, put_in(state, [:providers, service_id], provider)}
  end

  @impl true
  def handle_call({:find_provider, capability}, _from, state) do
    candidates =
      state.providers
      |> Map.values()
      |> Enum.filter(fn p -> p.health == :healthy and capability in p.capabilities end)
      |> Enum.sort_by(fn p -> p.workload end)

    case candidates do
      [best | _] -> {:reply, {:ok, best.id, best.pid}, state}
      [] -> {:reply, {:error, :no_provider}, state}
    end
  end

  @impl true
  def handle_call({:missing, required}, _from, state) do
    available =
      state.providers
      |> Map.values()
      |> Enum.filter(&(&1.health == :healthy))
      |> Enum.flat_map(& &1.capabilities)
      |> MapSet.new()

    missing = Enum.reject(required, &(&1 in available))
    {:reply, missing, state}
  end

  @impl true
  def handle_call(:all, _from, state) do
    {:reply, Map.values(state.providers), state}
  end

  @impl true
  def handle_cast({:update_health, service_id, health_status}, state) do
    if Map.has_key?(state.providers, service_id) do
      {:noreply, put_in(state, [:providers, service_id, :health], health_status)}
    else
      {:noreply, state}
    end
  end
end
