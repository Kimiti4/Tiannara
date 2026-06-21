defmodule Tiannara.Sentinel.D2.OperatorGenealogy do
  @moduledoc """
  D.2: Tracks the evolutionary history and ecology of individual Reasoning Operators.
  """
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Records usage of an operator by a civilization."
  def record_usage(operator_id, civ_id, context \\ %{}) do
    GenServer.cast(__MODULE__, {:record_usage, operator_id, civ_id, context})
  end

  @doc "Records the extinction/abandonment of an operator by a civilization."
  def record_abandonment(operator_id, civ_id) do
    GenServer.cast(__MODULE__, {:record_abandonment, operator_id, civ_id})
  end
  
  @doc "Records a synergistic or antagonistic event between operators."
  def record_ecology_interaction(operator_a, operator_b, interaction_type) do
    GenServer.cast(__MODULE__, {:record_ecology, operator_a, operator_b, interaction_type})
  end

  @doc "Retrieves the full operator genealogy state."
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting D.2 OperatorGenealogy")
    {:ok, %{
      operators: %{}, # op_id -> %{adoption_count, extinction_count, ...}
      ecology: %{}    # {op_a, op_b} -> count (positive for synergy, negative for antagonism)
    }}
  end

  @impl true
  def handle_cast({:record_usage, op_id, _civ_id, _context}, state) do
    current = Map.get(state.operators, op_id, %{adoption_count: 0, extinction_count: 0})
    updated = %{current | adoption_count: current.adoption_count + 1}
    {:noreply, %{state | operators: Map.put(state.operators, op_id, updated)}}
  end

  @impl true
  def handle_cast({:record_abandonment, op_id, _civ_id}, state) do
    current = Map.get(state.operators, op_id, %{adoption_count: 0, extinction_count: 0})
    updated = %{current | extinction_count: current.extinction_count + 1}
    {:noreply, %{state | operators: Map.put(state.operators, op_id, updated)}}
  end
  
  @impl true
  def handle_cast({:record_ecology, op_a, op_b, type}, state) do
    key = Enum.sort([op_a, op_b]) |> List.to_tuple()
    current = Map.get(state.ecology, key, 0)
    delta = if type == :synergy, do: 1, else: -1
    {:noreply, %{state | ecology: Map.put(state.ecology, key, current + delta)}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
end
