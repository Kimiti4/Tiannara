defmodule Tiannara.Ocm.OntologyRegistry do
  @moduledoc """
  Central registry for managing ontology versions and metadata across the consensus mesh.
  """

  @telemetry_prefix "tiannara.ocm.ontology_registry"

  use GenServer

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec store(String.t(), map()) :: :ok
  def store(ontology_id, ontology_data) do
    GenServer.call(__MODULE__, {:store, ontology_id, ontology_data})
  end

  @spec get(String.t()) :: {:ok, map()} | {:error, :not_found}
  def get(ontology_id) do
    GenServer.call(__MODULE__, {:get, ontology_id})
  end

  @spec list() :: {:ok, [map()]}
  def list() do
    GenServer.call(__MODULE__, :list)
  end

  @impl true
  def init(_opts) do
    {:ok, %{ontologies: %{}}}
  end

  @impl true
  def handle_call({:store, ontology_id, ontology_data}, _from, state) do
    new_state = Map.put(state.ontologies, ontology_id, ontology_data)
    {:reply, :ok, %{state | ontologies: new_state}}
  end

  @impl true
  def handle_call({:get, ontology_id}, _from, state) do
    case Map.get(state.ontologies, ontology_id) do
      nil -> {:reply, {:error, :not_found}, state}
      data -> {:reply, {:ok, data}, state}
    end
  end

  @impl true
  def handle_call(:list, _from, state) do
    {:reply, {:ok, Map.values(state.ontologies)}, state}
  end
end