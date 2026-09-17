defmodule ObservatoryApiWeb.Hub.COBStreamBridge do
  @moduledoc """
  Bridges COB constitutional events into the LiveStream Engine.

  Subscribes to all COB events via SubscriptionRegistry and forwards
  them to LiveStreamEngine by domain → topic mapping, enabling
  real-time WebSocket delivery to Observatory UI rooms.
  """
  use GenServer

  @topic_pattern "constitution.*:*.*:*"

  @domain_map %{
    "runtime" => :runtime,
    "scientific" => :science,
    "discovery" => :discovery,
    "engineering" => :engineering,
    "knowledge" => :knowledge,
    "planetary" => :planetary,
    "civilization" => :civilization,
    "evolution" => :evolution,
    "certification" => :certification,
    "replay" => :replay,
    "mission" => :mission,
    "experiment" => :experiments,
    "governance" => :alerts,
    "security" => :alerts,
    "alert" => :alerts
  }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    ObservationBus.SubscriptionRegistry.subscribe(self(), @topic_pattern)
    {:ok, %{forwarded: 0}}
  end

  @impl true
  def handle_info({:constitutional_event, %ObservationBus.Event{} = event, _topic}, state) do
    event
    |> domain_to_topic()
    |> case do
      nil -> :ok
      topic -> ObservatoryApiWeb.Hub.LiveStreamEngine.stream(topic, event_to_payload(event))
    end

    {:noreply, %{state | forwarded: state.forwarded + 1}}
  end

  defp domain_to_topic(%ObservationBus.Event{domain: domain}) do
    base = domain |> String.split("/") |> List.first() |> String.split("-") |> List.first()
    Map.get(@domain_map, base)
  end

  defp event_to_payload(%ObservationBus.Event{id: id, domain: domain, payload: payload, timestamp: ts}) do
    %{
      id: id,
      domain: domain,
      payload: payload,
      timestamp: ts
    }
  end
end
