defmodule Tiannara.ASC.CapabilityEvolution do
  @moduledoc """
  Evolves technological capabilities through competition and selection.
  Fitness = Innovation * Efficiency * Scalability * CivilizationalValue / Cost
  """
  use GenServer
  alias Tiannara.ASC.Models.Capability

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)

  def propose_capability(pid, attrs), do: GenServer.call(pid, {:propose, attrs})
  def select_capabilities(pid, domain), do: GenServer.call(pid, {:select, domain})
  def get_lineage(pid, cap_id), do: GenServer.call(pid, {:lineage, cap_id})

  @impl true
  def init(_), do: {:ok, %{capabilities: %{}, lineage: %{}}}

  @impl true
  def handle_call({:propose, attrs}, _from, state) do
    cap = %Capability{
      id: UUID.uuid4(),
      name: attrs.name,
      domain: attrs.domain,
      lineage_id: Map.get(attrs, :parent_id, UUID.uuid4()),
      dependencies: Map.get(attrs, :dependencies, []),
      fitness: calculate_fitness(attrs),
      efficiency: Map.get(attrs, :efficiency, 0.5),
      cost: Map.get(attrs, :cost, 0.5),
      scalability: Map.get(attrs, :scalability, 0.5),
      civilizational_value: Map.get(attrs, :civilizational_value, 0.5),
      status: :emerging
    }
    state = put_in(state, [:capabilities, cap.id], cap)
    state = update_in(state, [:lineage, cap.lineage_id], fn list -> [cap.id | list || []] end)
    {:reply, {:ok, cap}, state}
  end

  @impl true
  def handle_call({:select, domain}, _from, state) do
    selected = state.capabilities
    |> Map.values()
    |> Enum.filter(&(&1.domain == domain))
    |> Enum.sort_by(& &1.fitness, :desc)
    |> Enum.take(3)
    |> Enum.map(&promote/1)

    state = Enum.reduce(selected, state, fn cap, acc ->
      put_in(acc, [:capabilities, cap.id], cap)
    end)
    {:reply, selected, state}
  end

  @impl true
  def handle_call({:lineage, cap_id}, _from, state) do
    case Map.get(state.capabilities, cap_id) do
      nil -> {:reply, {:error, :not_found}, state}
      cap -> {:reply, Map.get(state.lineage, cap.lineage_id, []), state}
    end
  end

  defp calculate_fitness(attrs) do
    innovation = Map.get(attrs, :innovation, 0.5)
    eff = Map.get(attrs, :efficiency, 0.5)
    scale = Map.get(attrs, :scalability, 0.5)
    civ_val = Map.get(attrs, :civilizational_value, 0.5)
    cost = max(0.1, Map.get(attrs, :cost, 0.5))
    (innovation * eff * scale * civ_val) / cost
  end

  defp promote(cap) do
    %{cap | status: :promoted, adoption: min(1.0, cap.adoption + 0.2)}
  end
end
