defmodule Tiannara.LEOC.LatentVault do
  @moduledoc """
  Stores %EigenSeed{} instances representing dormant compressed civilizations.
  """
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def store(seed) do
    GenServer.call(__MODULE__, {:store, seed})
  end

  def get_all() do
    GenServer.call(__MODULE__, :get_all)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}} # id -> seed
  end

  @impl true
  def handle_call({:store, seed}, _from, state) do
    new_state = Map.put(state, seed.id, seed)
    Logger.info("🗄️ [LEOC] Stored EigenSeed #{seed.id} derived from #{seed.source_closure_id}")
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:get_all, _from, state) do
    {:reply, Map.values(state), state}
  end
end
