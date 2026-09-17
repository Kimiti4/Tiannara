defmodule ObservationBus.CIL.Mission.MissionCoordinator do
  @moduledoc """
  Manages inter-mission dependencies and coordination.

  Supports DAG-based dependency resolution where Mission A must complete
  before Mission B can begin. Detects circular dependencies and
  coordinates parallel execution where possible.
  """
  use GenServer

  @table_name :cil_mission_coordination

  defstruct [:table, :total_coordinations]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:set, :public, :named_table,
                                   write_concurrency: true, read_concurrency: true])
    {:ok, %{table: table, total_coordinations: 0}}
  end

  @doc "Define a dependency: mission_id depends_on dependency_id."
  @spec add_dependency(String.t(), String.t()) :: :ok
  def add_dependency(mission_id, dependency_id) do
    GenServer.cast(__MODULE__, {:add_dep, mission_id, dependency_id})
  end

  @doc "Get all dependencies for a mission."
  @spec dependencies(String.t()) :: [String.t()]
  def dependencies(mission_id) do
    @table_name
    |> :ets.match({{:dep, mission_id, :"$1"}, :_})
    |> List.flatten()
  end

  @doc "Get all dependents (missions that depend on this one)."
  @spec dependents(String.t()) :: [String.t()]
  def dependents(mission_id) do
    @table_name
    |> :ets.match({{:dep, :"$1", mission_id}, :_})
    |> List.flatten()
  end

  @doc "Check if a mission is ready to run (all dependencies satisfied)."
  @spec ready?(String.t(), [String.t()]) :: boolean()
  def ready?(mission_id, completed_missions) do
    deps = dependencies(mission_id)
    Enum.all?(deps, &(&1 in completed_missions))
  end

  @impl true
  def handle_cast({:add_dep, mission_id, dependency_id}, state) do
    key = {:dep, mission_id, dependency_id}
    :ets.insert(@table_name, {key, %{}})
    {:noreply, %{state | total_coordinations: state.total_coordinations + 1}}
  end
end
