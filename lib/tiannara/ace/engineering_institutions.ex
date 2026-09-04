defmodule Tiannara.ACE.EngineeringInstitutions do
  @moduledoc """
  Manages specialized engineering institutions that:
  - Steward capabilities
  - Produce designs
  - Compete and cooperate
  - Share knowledge
  - Evolve engineering expertise

  Examples: Aerospace Institute, Materials Institute, Energy Systems Institute
  """
  use GenServer
  alias Tiannara.ACE.Models.EngineeringInstitution

  @default_institutions [
    %{name: "Aerospace Engineering Institute", domain: :aerospace, specialization: :propulsion},
    %{name: "Materials Science Institute", domain: :materials, specialization: :advanced_materials},
    %{name: "Energy Systems Institute", domain: :energy, specialization: :renewable},
    %{name: "Robotics Institute", domain: :robotics, specialization: :autonomous_systems},
    %{name: "Manufacturing Institute", domain: :manufacturing, specialization: :automation}
  ]

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)

  def establish_institution(pid, attrs), do: GenServer.call(pid, {:establish, attrs})
  def get_institution(pid, domain), do: GenServer.call(pid, {:get, domain})
  def record_design(pid, domain, design), do: GenServer.cast(pid, {:record_design, domain, design})
  def list_institutions(pid), do: GenServer.call(pid, :list)

  @impl true
  def init(_) do
    initial = Enum.reduce(@default_institutions, %{}, fn attrs, acc ->
      inst = %EngineeringInstitution{
        id: UUID.uuid4(),
        name: attrs.name,
        domain: attrs.domain,
        specialization: attrs.specialization,
        capabilities_stewarded: [],
        designs_produced: [],
        knowledge_base: [],
        collaboration_partners: [],
        performance_metrics: %{designs_completed: 0, success_rate: 0.0},
        status: :active
      }
      Map.put(acc, attrs.domain, inst)
    end)
    {:ok, %{institutions: initial}}
  end

  @impl true
  def handle_call({:establish, attrs}, _from, state) do
    inst = %EngineeringInstitution{
      id: UUID.uuid4(),
      name: attrs.name,
      domain: attrs.domain,
      specialization: attrs.specialization,
      status: :active
    }
    state = put_in(state, [:institutions, attrs.domain], inst)
    {:reply, {:ok, inst}, state}
  end

  @impl true
  def handle_call({:get, domain}, _from, state), do: {:reply, Map.get(state.institutions, domain), state}

  @impl true
  def handle_call(:list, _from, state), do: {:reply, Map.values(state.institutions), state}

  @impl true
  def handle_cast({:record_design, domain, design}, state) do
    case Map.get(state.institutions, domain) do
      nil -> {:noreply, state}
      inst ->
        updated = %{inst |
          designs_produced: [design.id | inst.designs_produced],
          performance_metrics: %{inst.performance_metrics |
            designs_completed: inst.performance_metrics.designs_completed + 1
          }
        }
        {:noreply, put_in(state, [:institutions, domain], updated)}
    end
  end
end
