defmodule ObservationBus.CIL.Mission.MissionRegistry do
  @moduledoc """
  Central registry for all constitutional missions.

  Tracks mission id, name, status, priority, resource allocation,
  domains, goals, and inter-mission dependencies.
  """
  use GenServer

  @table_name :cil_mission_registry

  defstruct [:table, :total_missions]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:set, :public, :named_table,
                                   write_concurrency: true, read_concurrency: true])
    {:ok, %{table: table, total_missions: 0}}
  end

  @doc "Register a new mission."
  @spec register(String.t(), String.t(), keyword()) :: {:ok, String.t()}
  def register(name, description, opts \\ []) do
    GenServer.call(__MODULE__, {:register, name, description, opts})
  end

  @doc "Update mission status."
  @spec set_status(String.t(), atom()) :: :ok
  def set_status(id, status) do
    GenServer.cast(__MODULE__, {:set_status, id, status})
  end

  @doc "List missions, optionally filtered by status."
  @spec list(atom()) :: [map()]
  def list(status \\ nil) do
    @table_name
    |> :ets.tab2list()
    |> Enum.map(fn {_id, m} -> m end)
    |> Enum.filter(fn m -> is_nil(status) or m.status == status end)
  end

  @doc "Get a single mission."
  @spec get(String.t()) :: map() | nil
  def get(id) do
    case :ets.lookup(@table_name, id) do
      [{^id, m}] -> m
      [] -> nil
    end
  end

  @impl true
  def handle_call({:register, name, description, opts}, _from, state) do
    id = uuid_v4()
    mission = %{
      id: id, name: name, description: description,
      status: :pending,
      priority: Keyword.get(opts, :priority, 50),
      domains: Keyword.get(opts, :domains, []),
      goals: Keyword.get(opts, :goals, []),
      dependencies: Keyword.get(opts, :dependencies, []),
      resources: Keyword.get(opts, :resources, %{}),
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
    :ets.insert(@table_name, {id, mission})
    {:reply, {:ok, id}, %{state | total_missions: state.total_missions + 1}}
  end

  @impl true
  def handle_cast({:set_status, id, status}, state) do
    case :ets.lookup(@table_name, id) do
      [{^id, m}] ->
        :ets.insert(@table_name, {id, %{m | status: status, updated_at: DateTime.utc_now()}})
      _ -> :ok
    end
    {:noreply, state}
  end

  defp uuid_v4 do
    <<a::64, b::64>> = :crypto.strong_rand_bytes(16)
    <<u1::48, _::4, u2::12, _::2, u3::62>> = <<a::64, b::64>>
    <<u1::48, 4::4, u2::12, 2::2, u3::62>>
    |> Base.encode16(case: :lower)
    |> then(fn s ->
      "#{String.slice(s, 0, 8)}-#{String.slice(s, 8, 4)}-#{String.slice(s, 12, 4)}-#{String.slice(s, 16, 4)}-#{String.slice(s, 20, 12)}"
    end)
  end
end
