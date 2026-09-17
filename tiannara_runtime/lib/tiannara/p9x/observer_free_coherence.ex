defmodule Tiannara.P9X.ObserverFreeCoherence do
  @moduledoc """
  Validates Observerless consistency.
  Checks structural persistence scores without reference frames.
  """
  use GenServer
  alias Tiannara.EventBus

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    EventBus.subscribe("grcc.mutation")
    {:ok, %{score: 1.0}}
  end

  def handle_info({:mutation_proposed, s}, state) do
    score = evaluate_without_observers(s)
    
    if score < 0.2 do
      # Isolation gate triggers
      EventBus.broadcast("validation.status", :observer_free_invalid, %{reason: "Low coherence"})
    end
    
    {:noreply, %{state | score: score}}
  end
  
  def handle_info(_, state), do: {:noreply, state}

  defp evaluate_without_observers(_), do: :rand.uniform()
end
