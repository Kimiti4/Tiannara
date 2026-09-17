defmodule Tiannara.NATS.PressureStream do
  require Logger

  @pressure_topic "tiannara.olef.pressure"
  @alert_topic "tiannara.mscl.alerts"
  @redistribution_topic "tiannara.olef.redistribution"

  def publish_pressure(node_id, pressure_value, metadata \\ %{}) do
    payload = Jason.encode!(%{
      node: node_id,
      pressure: pressure_value,
      timestamp: System.system_time(),
      metadata: metadata
    })
    TiannaraRuntime.NATS.Bus.publish(@pressure_topic, payload)
    :ok
  end

  def publish_alert(alert_type, severity, details) do
    payload = Jason.encode!(%{
      alert_type: alert_type,
      severity: severity,
      details: details,
      timestamp: System.system_time()
    })
    TiannaraRuntime.NATS.Bus.publish(@alert_topic, payload)
    :ok
  end

  def publish_redistribution(event_type, source_node, target_nodes, amount) do
    payload = Jason.encode!(%{
      event_type: event_type,
      source: source_node,
      targets: target_nodes,
      amount: amount,
      timestamp: System.system_time()
    })
    TiannaraRuntime.NATS.Bus.publish(@redistribution_topic, payload)
    :ok
  end

  def subscribe_to_pressure(handler_pid) do
    TiannaraRuntime.NATS.Bus.subscribe(@pressure_topic)
    {:ok, make_ref()}
  end

  def subscribe_to_alerts(handler_pid) do
    TiannaraRuntime.NATS.Bus.subscribe(@alert_topic)
    {:ok, make_ref()}
  end

  defp publish_to_nats(topic, payload) do
    TiannaraRuntime.NATS.Bus.publish(topic, payload)
    :ok
  end

  defp subscribe_to_topic(topic, handler_pid) do
    TiannaraRuntime.NATS.Bus.subscribe(topic)
    subscription_ref = make_ref()
    spawn_link(fn ->
      receive_loop(handler_pid, subscription_ref)
    end)
    {:ok, subscription_ref}
  end

  defp receive_loop(handler_pid, ref) do
    receive do
      {:nats_message, _subject, payload} ->
        case Jason.decode(payload) do
          {:ok, decoded} ->
            send(handler_pid, {:nats_message, decoded})
          {:error, _} ->
            Logger.warning("Invalid JSON in NATS message")
        end
        receive_loop(handler_pid, ref)
      _msg ->
        receive_loop(handler_pid, ref)
    end
  end
end
