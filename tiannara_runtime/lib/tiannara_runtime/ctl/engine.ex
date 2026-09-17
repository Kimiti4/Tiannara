defmodule TiannaraRuntime.CTL.Engine do
  @moduledoc """
  Phase 5F.6 — CTL Engine

  Maintains the causal tensegrity graph, computes branch stress, and
  triggers resolution when causal tension exceeds the configured elasticity.
  """

  use GenServer
  require Logger
  alias TiannaraRuntime.CTL.{Event, Reconciler}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok,
     %{
       causal_graph: %{},
       stress_map: %{},
       sync_elasticity: 10_000,
       stress_threshold: 0.9
     }}
  end

  @doc "Register a causal event into the CTL graph."
  def register_event(event) when is_map(event) do
    GenServer.cast(__MODULE__, {:register_event, Event.normalize(event)})
  end

  @impl true
  def handle_cast({:register_event, event}, state) do
    updated_graph = add_event(state.causal_graph, event)
    stress_map = compute_stress(updated_graph, state.sync_elasticity)

    if max_stress(stress_map) > state.stress_threshold do
      Logger.warning("[CTL] causal instability detected → initiating resolution")
      Task.start(fn -> Reconciler.resolve(updated_graph, stress_map) end)
    end

    {:noreply, %{state | causal_graph: updated_graph, stress_map: stress_map}}
  end

  defp add_event(graph, %Event{id: id} = event) do
    Map.put(graph, id, event)
  end

  defp compute_stress(graph, sync_elasticity) do
    graph
    |> Enum.map(fn {_id, event} ->
      stress =
        Enum.reduce(event.causal_links, 0.0, fn link, acc ->
          neighbor_timestamp = neighbor_timestamp(graph, link.id)
          drift = abs(event.timestamp - neighbor_timestamp) / max(sync_elasticity, 1)

          acc + drift * max(link.weight || 1.0, 1.0)
        end)

      {event.id, stress}
    end)
    |> Enum.into(%{})
  end

  defp neighbor_timestamp(graph, id) do
    case Map.get(graph, id) do
      %Event{timestamp: timestamp} -> timestamp
      _ -> System.system_time(:millisecond)
    end
  end

  defp max_stress(stress_map) do
    stress_map
    |> Map.values()
    |> Enum.max(fn -> 0.0 end)
  end
end
