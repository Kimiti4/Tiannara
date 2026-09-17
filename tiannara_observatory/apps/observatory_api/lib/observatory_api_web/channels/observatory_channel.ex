defmodule ObservatoryApiWeb.ObservatoryChannel do
  use Phoenix.Channel

  @topic_map %{
    "obs:runtime" => :runtime,
    "obs:science" => :science,
    "obs:engineering" => :engineering,
    "obs:knowledge" => :knowledge,
    "obs:planet" => :planetary,
    "obs:civilization" => :civilization,
    "obs:evolution" => :evolution,
    "obs:certification" => :certification,
    "obs:alerts" => :alerts,
    "obs:replay" => :replay,
    "obs:mission" => :mission,
    "obs:experiments" => :experiments,
    "obs:theories" => :theories,
    "obs:discovery" => :discovery
  }

  def join(topic, _payload, socket) do
    stream_topic = Map.get(@topic_map, topic)

    if stream_topic do
      ObservatoryApiWeb.Hub.LiveStreamEngine.subscribe(stream_topic, self())
      {:ok, assign(socket, :stream_topic, stream_topic)}
    else
      {:error, %{reason: :unknown_topic}}
    end
  end

  def handle_info({:stream_batch, batch}, socket) do
    push(socket, "stream", batch)
    {:noreply, socket}
  end

  def handle_info({:observatory_event, event, _priority, _topic}, socket) do
    push(socket, "event", event)
    {:noreply, socket}
  end

  def terminate(_reason, socket) do
    if stream_topic = socket.assigns[:stream_topic] do
      ObservatoryApiWeb.Hub.LiveStreamEngine.unsubscribe(stream_topic, self())
    end

    :ok
  end
end
