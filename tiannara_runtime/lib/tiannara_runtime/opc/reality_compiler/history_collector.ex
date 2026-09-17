defmodule Tiannara.OPC.RealityCompiler.HistoryCollector do
  require Logger

  def collect(event) do
    normalized = %{
      id: event.id,
      type: event.type,
      payload: event.payload,
      timestamp: event.timestamp
    }

    GenServer.cast(Tiannara.OPC.RealityCompiler.HistorySupervisor, {:ingest_event, normalized})
  end
end
