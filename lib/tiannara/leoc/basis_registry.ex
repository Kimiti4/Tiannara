defmodule Tiannara.LEOC.BasisRegistry do
  @moduledoc "Content-addressed decoder basis registry for LEOC."
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def put(%Nx.Tensor{} = basis, %Nx.Tensor{} = mean) do
    basis32 = Nx.as_type(basis, {:f, 32})
    hash = :crypto.hash(:sha256, Nx.to_binary(basis32))
    GenServer.call(__MODULE__, {:put, hash, basis, mean})
    {:ok, hash}
  end

  def get(hash), do: GenServer.call(__MODULE__, {:get, hash})

  @impl true
  def init(_opts), do: {:ok, %{}}

  @impl true
  def handle_call({:put, hash, basis, mean}, _from, state) do
    {:reply, :ok, Map.put(state, hash, %{basis: basis, mean: mean, hash: hash, version: 1})}
  end

  @impl true
  def handle_call({:get, hash}, _from, state), do: {:reply, Map.fetch(state, hash), state}
end
