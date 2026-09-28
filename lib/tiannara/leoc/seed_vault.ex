defmodule Tiannara.LEOC.SeedVault do
  @moduledoc "Runtime vault for compact LEOC reconstruction seeds."
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def store(%Tiannara.LEOC.Seed{} = seed), do: GenServer.call(__MODULE__, {:store, seed})
  def get(world_id, epoch), do: GenServer.call(__MODULE__, {:get, world_id, epoch})
  def get_by_id(id), do: GenServer.call(__MODULE__, {:get_by_id, id})

  @impl true
  def init(_opts), do: {:ok, %{by_key: %{}, by_id: %{}}}

  @impl true
  def handle_call({:store, seed}, _from, state) do
    key = {seed.world_id, seed.epoch}
    {:reply, :ok,
     %{state |
       by_key: Map.put(state.by_key, key, seed),
       by_id: Map.put(state.by_id, seed.id, seed)}}
  end

  @impl true
  def handle_call({:get, world_id, epoch}, _from, state) do
    {:reply, Map.fetch(state.by_key, {world_id, epoch}), state}
  end

  @impl true
  def handle_call({:get_by_id, id}, _from, state) do
    {:reply, Map.fetch(state.by_id, id), state}
  end
end
