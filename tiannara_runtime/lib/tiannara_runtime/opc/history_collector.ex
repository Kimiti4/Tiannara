defmodule Tiannara.OPC.HistoryCollector do
  @moduledoc """
  Phase 5F.9 — History Collector for OPC.
  Normalizes incoming event traces and forwards them into the compiler pipeline.
  """

  def collect(event) when is_map(event) do
    normalized = %{
      id: Map.get(event, :id, Map.get(event, "id", UUID.uuid4())),
      type: Map.get(event, :type, Map.get(event, "type", "unknown")),
      payload: Map.get(event, :payload, Map.get(event, "payload", %{})),
      timestamp: Map.get(event, :timestamp, System.system_time(:microsecond))
    }

    Tiannara.OPC.RealityCompiler.ingest_event(normalized)
  end
end
