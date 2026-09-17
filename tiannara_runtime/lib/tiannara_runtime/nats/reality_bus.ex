defmodule Tiannara.Meta.Mesh.RealityBus do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def publish(subject, payload) when is_binary(subject) and is_map(payload) do
    encoded = Jason.encode!(payload)
    TiannaraRuntime.NATS.Bus.publish(subject, encoded)
    :ok
  end

  def subscribe(subject) when is_binary(subject) do
    TiannaraRuntime.NATS.Bus.subscribe(subject)
    {:ok, subject}
  end

  def unsubscribe(subscription_id) do
    TiannaraRuntime.NATS.Bus.unsubscribe(subscription_id)
    :ok
  end

  def publish_causal(subject, payload, causal_context \\ %{}) do
    enriched_payload = Map.merge(payload, %{
      _causal_metadata: %{
        trace_id: Map.get(causal_context, :trace_id, UUID.uuid4()),
        timestamp: System.system_time(:millisecond),
        causal_depth: Map.get(causal_context, :causal_depth, 0),
        source_node: Node.self()
      }
    })
    publish(subject, enriched_payload)
  end

  def publish_partitioned(event_type, payload, entropy_zone) do
    subject = case entropy_zone do
      :high -> "tiannara.entropy.high.#{event_type}"
      :medium -> "tiannara.entropy.medium.#{event_type}"
      :low -> "tiannara.entropy.low.#{event_type}"
      _ -> "tiannara.entropy.unknown.#{event_type}"
    end
    publish(subject, payload)
  end

  @impl true
  def init(_opts) do
    state = %{
      subscriptions: %{},
      published_count: 0,
      received_count: 0
    }
    {:ok, state}
  end

  @impl true
  def handle_info({:nats_message, subject, body}, state) do
    try do
      decoded = Jason.decode!(body)
      handle_event(subject, decoded)
    rescue
      e ->
        Logger.error("RealityBus failed to decode message: #{inspect(e)}")
    end
    {:noreply, %{state | received_count: state.received_count + 1}}
  end

  defp handle_event(subject, payload) do
    cond do
      String.starts_with?(subject, "tiannara.observer.") ->
        handle_observer_event(subject, payload)
      String.starts_with?(subject, "tiannara.opc.") ->
        handle_opc_event(subject, payload)
      String.starts_with?(subject, "tiannara.chronogram.") ->
        handle_chronogram_event(subject, payload)
      String.starts_with?(subject, "tiannara.mscl.") ->
        handle_mscl_event(subject, payload)
      String.starts_with?(subject, "tiannara.olef.") ->
        handle_olef_event(subject, payload)
      String.starts_with?(subject, "tiannara.mesh.") ->
        handle_mesh_event(subject, payload)
      true ->
        Logger.warning("RealityBus unhandled subject: #{subject}")
    end
  end

  defp handle_observer_event(subject, payload) do
    Logger.info("RealityBus observer event: #{subject}")
  end

  defp handle_opc_event(subject, payload) do
    Logger.debug("RealityBus OPC event: #{subject}")
  end

  defp handle_chronogram_event(subject, payload) do
    Logger.debug("RealityBus chronogram event: #{subject}")
  end

  defp handle_mscl_event(subject, payload) do
    Logger.warning("RealityBus MSCL stability event: #{subject}")
  end

  defp handle_olef_event(subject, payload) do
    Logger.debug("RealityBus OLEF pressure event: #{subject}")
  end

  defp handle_mesh_event(subject, payload) do
    Logger.info("RealityBus mesh sync event: #{subject}")
  end
end
