defmodule Tiannara.GRCC.LineageManager do
  @moduledoc """
  Tracks mutation frequencies per lineage.
  """
  use GenServer
  alias Tiannara.EventBus

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    EventBus.subscribe("validation.status")
    {:ok, %{lineages: %{}, blocked: false}}
  end

  def handle_info({:observer_free_invalid, _}, state) do
    # Pause evolution safely
    {:noreply, %{state | blocked: true}}
  end

  def handle_info({:mutate, lineage}, state) do
    if state.blocked do
      {:noreply, state}
    else
      updated = Map.update(state.lineages, lineage, 1, &(&1 + 1))
      EventBus.broadcast("grcc.mutation", :mutation_proposed, %{lineage: lineage})
      {:noreply, %{state | lineages: updated}}
    end
  end
  
  def handle_info(_, state), do: {:noreply, state}
end
