defmodule Tiannara.UCC.MacroStateRegistry do
  @moduledoc """
  Stores current active Institutional states (InstitutionGenomes).
  """
  use GenServer

  alias Tiannara.UCC.InstitutionGenome

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def register_institution(id, %InstitutionGenome{} = genome) do
    GenServer.cast(__MODULE__, {:register, id, genome})
  end

  def get_institution(id) do
    GenServer.call(__MODULE__, {:get, id})
  end

  def list_institutions() do
    GenServer.call(__MODULE__, :list)
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:register, id, genome}, state) do
    {:noreply, Map.put(state, id, genome)}
  end

  @impl true
  def handle_call({:get, id}, _from, state) do
    {:reply, Map.get(state, id), state}
  end

  @impl true
  def handle_call(:list, _from, state) do
    {:reply, Map.values(state), state}
  end
end
