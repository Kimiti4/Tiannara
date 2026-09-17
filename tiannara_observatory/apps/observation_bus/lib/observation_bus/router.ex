defmodule ObservationBus.Router do
  @moduledoc """
  Constitutional Event Router — the heart of the observation bus.

  Responsibilities:
    * Receive events from any source (telemetry, NATS, GenServers, etc.)
    * Canonicalize into `ObservationBus.Event`
    * Assign ordering sequences
    * Route to all matching subscribers
    * Record lineage
    * Emit telemetry for observability

  This is not topic routing. It is semantic routing based on
  the event's domain, priority, and constitutional properties.
  """

  alias ObservationBus.Event

  @doc """
  Publishes an event onto the bus.

  The event flows through:
    1. Buffer (backpressure-aware)
    2. Priority Engine (reorder by priority)
    3. Ordering Engine (assign sequences)
    4. Router (fan-out to subscribers)
    5. Lineage Engine (record relationships)
    6. Telemetry (emit metrics)
  """
  @spec publish(Event.t() | keyword(), keyword()) :: {:ok, Event.t()} | {:error, term()}
  def publish(event_or_kw, _opts \\ []) do
    event = normalize(event_or_kw)
    routed = route(event)
    {:ok, routed}
  end

  @doc """
  Routes a single event to all matching subscribers synchronously.
  Returns the event with telemetry attached.
  """
  def route(%Event{} = event) do
    event
    |> advance(:validated)
    |> advance(:canonicalized)
    |> ObservationBus.OrderingEngine.order()
    |> advance(:ordered)
    |> do_route()
    |> record_lineage()
    |> emit_telemetry()
  end

  defp normalize(%Event{} = event), do: event
  defp normalize(kw) when is_list(kw), do: Event.new(kw)

  defp advance(event, stage), do: Event.advance(event, stage)

  defp do_route(%Event{domain: domain} = event) do
    topic = Event.topic(event)

    subscribers = ObservationBus.SubscriptionRegistry.subscribers_for(topic)

    if subscribers != [] do
      Enum.each(subscribers, fn pid ->
        send(pid, {:constitutional_event, event, topic})
      end)
    end

    broadcast_topic = "constitution.broadcast.#{domain}"
    broadcast_subs = ObservationBus.SubscriptionRegistry.subscribers_for(broadcast_topic)

    if broadcast_subs != [] do
      Enum.each(broadcast_subs, fn pid ->
        send(pid, {:constitutional_event, event, broadcast_topic})
      end)
    end

    advance(event, :routed)
  end

  defp record_lineage(%Event{} = event) do
    ObservationBus.LineageEngine.record(event)
    advance(event, :observed)
  end

  defp emit_telemetry(%Event{} = event) do
    :telemetry.execute([:observation_bus, :event, :routed], %{count: 1}, %{
      domain: event.domain,
      priority: event.priority,
      global_sequence: event.global_sequence
    })

    advance(event, :stored)
  end
end
