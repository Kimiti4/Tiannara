defmodule Tiannara.LEOC.AnchorRegistry do
  @moduledoc """
  Versioned baseline anchors for LEOC.

  Anchors are content-addressed so every seed can prove which baseline it used.
  """
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def put(world_id, %Nx.Tensor{} = tensor) do
    hash = hash_tensor(tensor)
    GenServer.call(__MODULE__, {:put, world_id, hash, tensor})
  end

  def get(world_id, hash), do: GenServer.call(__MODULE__, {:get, world_id, hash})
  def current(world_id), do: GenServer.call(__MODULE__, {:current, world_id})

  def hash_tensor(%Nx.Tensor{} = tensor) do
    :crypto.hash(:sha256, Nx.to_binary(Nx.as_type(tensor, {:f, 32})))
  end

  @impl true
  def init(_opts), do: {:ok, %{anchors: %{}, current: %{}}}

  @impl true
  def handle_call({:put, world_id, hash, tensor}, _from, state) do
    key = {world_id, hash}
    record = %{tensor: tensor, hash: hash, version: map_size(state.anchors) + 1}
    {:reply, {:ok, hash},
     %{state | anchors: Map.put(state.anchors, key, record), current: Map.put(state.current, world_id, hash)}}
  end

  @impl true
  def handle_call({:get, world_id, hash}, _from, state) do
    {:reply, Map.fetch(state.anchors, {world_id, hash}), state}
  end

  @impl true
  def handle_call({:current, world_id}, _from, state) do
    case Map.fetch(state.current, world_id) do
      {:ok, hash} -> {:reply, Map.fetch(state.anchors, {world_id, hash}), state}
      :error -> {:reply, :error, state}
    end
  end
end
