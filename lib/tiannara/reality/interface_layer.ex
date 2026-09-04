defmodule Tiannara.Reality.InterfaceLayer do
  @moduledoc """
  The standardized adapter layer connecting the external world to the Unified Reality Graph.
  Translates external noise (Jira tickets, Slack messages, Datadog alerts) 
  into ontological Graph Nodes.
  """
  alias Tiannara.Graph.UnifiedRealityGraph
  require Logger

  @adapters [:github, :jira, :datadog, :stripe, :slack]

  def run_ingestion_cycle do
    Logger.info("🌍 [InterfaceLayer] Polling external reality...")
    
    Enum.each(@adapters, fn adapter ->
      Logger.info("   📡 Polling adapter: #{adapter}...")
      events = fetch_mock_delta(adapter)
      translate_and_ingest(adapter, events)
    end)
  end

  defp fetch_mock_delta(:datadog), do: [%{id: "dd_alert_1", type: "apm_trace", message: "Hydration bottleneck detected"}]
  defp fetch_mock_delta(:github), do: [%{id: "pr_991", type: "pull_request", message: "BatchGraphHydrator patch"}]
  defp fetch_mock_delta(_), do: []

  defp translate_and_ingest(adapter, events) do
    Enum.each(events, fn event ->
      # Convert external noise into a Tiannara Graph Node
      node_id = "#{adapter}_#{event.id}"
      UnifiedRealityGraph.ingest_node(node_id, :reality_event, event)
      Logger.info("   🔗 [InterfaceLayer] Ingested external event into Reality Graph: #{node_id}")
    end)
  end
end
