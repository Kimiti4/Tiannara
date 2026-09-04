defmodule Tiannara.ASC.InstitutionEngine do
  @moduledoc """
  Converts successful discoveries and capabilities into persistent institutions.
  Institutions steward knowledge, manage capabilities, and provide civilizational continuity.
  """
  use GenServer
  alias Tiannara.ASC.Models.Institution

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)

  def propose_institution(pid, attrs), do: GenServer.call(pid, {:propose, attrs})
  def evaluate_institution(pid, inst_id), do: GenServer.call(pid, {:evaluate, inst_id})

  @impl true
  def init(_), do: {:ok, %{institutions: %{}}}

  @impl true
  def handle_call({:propose, attrs}, _from, state) do
    inst = %Institution{
      id: UUID.uuid4(),
      name: attrs.name,
      civilization_id: attrs.civilization_id,
      purpose: attrs.purpose,
      capabilities_managed: Map.get(attrs, :capabilities, []),
      knowledge_stewarded: Map.get(attrs, :knowledge, []),
      founding_discovery_id: attrs.founding_discovery_id,
      stability: 0.5,
      status: :proposed
    }
    state = put_in(state, [:institutions, inst.id], inst)
    {:reply, {:ok, inst}, state}
  end

  @impl true
  def handle_call({:evaluate, inst_id}, _from, state) do
    case Map.get(state.institutions, inst_id) do
      nil -> {:reply, {:error, :not_found}, state}
      inst ->
        evaluated = %{inst |
          stability: calculate_stability(inst),
          status: :active
        }
        state = put_in(state, [:institutions, inst_id], evaluated)
        {:reply, {:ok, evaluated}, state}
    end
  end

  defp calculate_stability(inst) do
    knowledge_depth = length(inst.knowledge_stewarded) * 0.1
    capability_depth = length(inst.capabilities_managed) * 0.15
    min(1.0, 0.3 + knowledge_depth + capability_depth)
  end
end
