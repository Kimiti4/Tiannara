defmodule Tiannara.Telemetry.EventAggregator do
  @moduledoc """
  Semantic Runtime Memory.
  Subscribes to major ecological events on the EventBus and aggregates them
  to track lineage mutation events, ontology collapse warnings, and closure
  instability traces over time.
  """
  use GenServer

  alias Tiannara.EventBus

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    EventBus.subscribe("constraint.updated")
    EventBus.subscribe("field.pressure_changed")
    EventBus.subscribe("immune.response")
    EventBus.subscribe("validation.status")
    EventBus.subscribe("grcc.mutation")

    {:ok, %{events: []}}
  end

  def handle_info({event_name, payload}, state) do
    # Add timestamp and store
    event = %{
      name: event_name,
      payload: payload,
      timestamp: System.os_time(:millisecond)
    }
    
    # Keep last 1000 events to prevent unbounded memory growth
    new_events = [event | state.events] |> Enum.take(1000)
    
    {:noreply, %{state | events: new_events}}
  end
  
  def get_events do
    GenServer.call(__MODULE__, :get_events)
  end
  
  def handle_call(:get_events, _from, state) do
    {:reply, state.events, state}
  end
end
