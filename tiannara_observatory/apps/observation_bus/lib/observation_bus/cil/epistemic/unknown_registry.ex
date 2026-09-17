defmodule ObservationBus.CIL.Epistemic.UnknownRegistry do
  @moduledoc """
  Unknowns are first-class citizens in the Constitutional Epistemic Observatory.

  Tracks types: known_unknown, unknown_unknown, unverified, unobservable,
  currently_impossible, waiting_for_technology.
  """
  use GenServer

  @table_name :cil_unknown_registry
  @unknown_types ~w(known_unknown unknown_unknown unverified unobservable currently_impossible waiting_for_technology)a

  defstruct [:table, :total_unknowns]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:set, :public, :named_table,
                                   write_concurrency: true, read_concurrency: true])
    {:ok, %{table: table, total_unknowns: 0}}
  end

  @doc "Register an unknown."
  @spec register(atom(), String.t(), map()) :: {:ok, String.t()}
  def register(type, description, metadata \\ %{}) when type in @unknown_types do
    GenServer.call(__MODULE__, {:register, type, description, metadata})
  end

  @doc "List unknowns, optionally filtered by type."
  @spec list(atom()) :: [map()]
  def list(type \\ nil) do
    @table_name
    |> :ets.tab2list()
    |> Enum.map(fn {_id, u} -> u end)
    |> Enum.filter(fn u -> is_nil(type) or u.type == type end)
    |> Enum.sort_by(& &1.registered_at, {:desc, DateTime})
  end

  @doc "Resolve an unknown with evidence."
  @spec resolve(String.t(), String.t()) :: :ok
  def resolve(id, resolution) do
    GenServer.cast(__MODULE__, {:resolve, id, resolution})
  end

  @doc "Get unknown count by type."
  @spec counts() :: map()
  def counts do
    GenServer.call(__MODULE__, :counts)
  end

  @impl true
  def handle_call({:register, type, description, metadata}, _from, state) do
    id = uuid_v4()
    entry = %{
      id: id, type: type, description: description, metadata: metadata,
      resolved: false, resolution: nil,
      registered_at: DateTime.utc_now()
    }
    :ets.insert(@table_name, {id, entry})
    {:reply, {:ok, id}, %{state | total_unknowns: state.total_unknowns + 1}}
  end

  def handle_call(:counts, _from, state) do
    all = :ets.tab2list(@table_name) |> Enum.map(fn {_, u} -> u end)
    counts = Enum.group_by(all, & &1.type) |> Enum.map(fn {k, v} -> {k, length(v)} end) |> Map.new()
    {:reply, %{total: length(all), by_type: counts}, state}
  end

  @impl true
  def handle_cast({:resolve, id, resolution}, state) do
    case :ets.lookup(@table_name, id) do
      [{^id, entry}] ->
        updated = %{entry | resolved: true, resolution: resolution}
        :ets.insert(@table_name, {id, updated})
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
