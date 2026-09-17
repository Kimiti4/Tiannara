defmodule TiannaraRuntime.OCM.Registry do
  @moduledoc """
  Phase 5F.7 — OCM Ontology Registry

  Stores semantic embeddings for runtime nodes and exposes a simple
  registration API for distributed ontology convergence.
  """

  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{ontologies: %{}}}
  end

  @doc "Register or update a node's ontology vector."
  def register(node_id, ontology_vector) when is_list(ontology_vector) do
    GenServer.cast(__MODULE__, {:register, node_id, ontology_vector})
  end

  @doc "Fetch all registered ontologies." 
  def list do
    GenServer.call(__MODULE__, :list)
  end

  @impl true
  def handle_cast({:register, node_id, ontology_vector}, state) do
    Logger.debug("[OCM] registering ontology for #{inspect(node_id)}")

    ontologies = Map.put(state.ontologies, node_id, ontology_vector)
    {:noreply, %{state | ontologies: ontologies}}
  end

  @impl true
  def handle_call(:list, _from, state) do
    {:reply, state.ontologies, state}
  end
end
