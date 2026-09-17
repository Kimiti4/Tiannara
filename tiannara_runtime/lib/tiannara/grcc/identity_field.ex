defmodule Tiannara.GRCC.IdentityField do
  @moduledoc """
  Tracks spawned identities and their coherence over time.
  """
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{identities: %{}}}
  end

  def handle_cast({:spawn_identity, id}, state) do
    new_identities = Map.put(state.identities, id, %{coherence: 1.0})
    {:noreply, %{state | identities: new_identities}}
  end
end
