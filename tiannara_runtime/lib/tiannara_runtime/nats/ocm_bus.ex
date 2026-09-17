defmodule TiannaraRuntime.NATS.OCMBus do
  require Logger
  alias TiannaraRuntime.NATS.Publisher

  @reconcile_topic   "tiannara.ocm.reconcile"
  @drift_alert_topic "tiannara.ocm.drift.alert"
  @quarantine_topic  "tiannara.ocm.quarantine"
  @request_topic     "tiannara.ocm.consensus.request"
  @result_topic      "tiannara.ocm.consensus.result"

  def publish_reconcile(payload) when is_map(payload) do
    msg = %{
      type: :reconcile,
      payload: payload,
      timestamp: System.system_time(:millisecond),
      trace_id: generate_trace_id()
    }
    Publisher.publish(@reconcile_topic, Jason.encode!(msg))
  end

  def publish_drift_alert(node_a, node_b, drift, category) when category in [:warning, :critical] do
    msg = %{
      type: :drift_alert,
      node_a: node_a,
      node_b: node_b,
      drift: drift,
      category: category,
      severity: severity(category),
      timestamp: System.system_time(:millisecond)
    }
    Publisher.publish(@drift_alert_topic, Jason.encode!(msg))
  end

  def publish_quarantine(node_a, node_b, drift) do
    msg = %{
      type: :quarantine_notice,
      node_a: node_a,
      node_b: node_b,
      drift: drift,
      reason: "drift #{Float.round(drift, 4)} >= 0.60 - critical semantic divergence",
      timestamp: System.system_time(:millisecond)
    }
    Publisher.publish(@quarantine_topic, Jason.encode!(msg))
  end

  def publish_consensus_result(result) when is_map(result) do
    msg = %{
      type: :consensus_result,
      result: result,
      timestamp: System.system_time(:millisecond)
    }
    Publisher.publish(@result_topic, Jason.encode!(msg))
  end

  def subscribe_consensus_requests(callback) when is_function(callback, 1) do
    TiannaraRuntime.NATS.Bus.subscribe(@request_topic)
    {:ok, :subscribed}
  end

  def subscribe_consensus_results(callback) when is_function(callback, 1) do
    TiannaraRuntime.NATS.Bus.subscribe(@result_topic)
    {:ok, :subscribed}
  end

  def subscribe_drift_alerts(user_callback) when is_function(user_callback, 1) do
    TiannaraRuntime.NATS.Bus.subscribe(@drift_alert_topic)
    {:ok, :subscribed}
  end

  defp severity(:warning),  do: :medium
  defp severity(:critical), do: :high
  defp severity(_),         do: :low

  defp generate_trace_id, do: UUID.uuid4()
end
