defmodule Tiannara.Runtime.OED.Lattice.ELF do
  @moduledoc """
  Phase 5F.8 — Epistemic Lattice Field (ELF)

  Models the network of phase-offset Procedural Decoy Ontologies (sandboxes).
  """

  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, %{pdos: %{}}}
  end

  @doc """
  Registers a decoy ontology (PDO) manifold under OED.
  """
  def register_pdo(observer_id, params) do
    GenServer.call(__MODULE__, {:register_pdo, observer_id, params})
  end

  @doc """
  Injects phase-offset resonance interference between two sandboxes.
  """
  def inject_interference(observer_a, observer_b) do
    GenServer.call(__MODULE__, {:inject_interference, observer_a, observer_b})
  end

  @doc """
  Retrieves a registered PDO manifold.
  """
  def get_pdo(observer_id) do
    GenServer.call(__MODULE__, {:get_pdo, observer_id})
  end

  # --- GenServer Callbacks ---

  @impl true
  def handle_call({:register_pdo, observer_id, params}, _from, state) do
    pdo = %{
      reality_state: :semi_real_counterfactual,
      function: :entropic_load_balancer,
      branch_id: "branch_#{observer_id}",
      pressure: Map.get(params, :pressure, 0.0),
      trap_type: Map.get(params, :trap_type)
    }

    new_pdos = Map.put(state.pdos, observer_id, pdo)
    {:reply, {:ok, pdo}, %{state | pdos: new_pdos}}
  end

  @impl true
  def handle_call({:inject_interference, observer_a, observer_b}, _from, state) do
    edge = %{
      source: observer_a,
      target: observer_b,
      interference_mode: :phase_offset_resonance_dampening
    }

    {:reply, {:ok, edge}, state}
  end

  @impl true
  def handle_call({:get_pdo, observer_id}, _from, state) do
    pdo =
      case Map.get(state.pdos, observer_id) do
        nil ->
          %{
            reality_state: :semi_real_counterfactual,
            function: :entropic_load_balancer,
            branch_id: "branch_#{observer_id}"
          }

        registered ->
          registered
      end

    {:reply, {:ok, pdo}, state}
  end
end
