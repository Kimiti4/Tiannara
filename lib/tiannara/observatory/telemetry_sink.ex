defmodule Tiannara.Observatory.TelemetrySink do
  @moduledoc """
  Strictly passive telemetry ingestion.
  Listens to :telemetry events and writes to ETS.
  Performs zero scientific computation.
  """

  def attach_handlers do
    :telemetry.attach_many(
      "tiannara-observatory-sink",
      [
        [:tiannara, :foundations, :math, :operation],
        [:tiannara, :reasoning, :belief, :update],
        [:tiannara, :meta_science, :bottleneck],
        [:tiannara, :executive, :scheduler, :task_complete]
      ],
      &handle_event/4,
      nil
    )
  end

  defp handle_event(event, measurements, metadata, _config) do
    record = %{
      timestamp: System.monotonic_time(:millisecond),
      event: event,
      measurements: measurements,
      metadata: metadata
    }

    :ets.insert(:tiannara_telemetry_log, {record.timestamp, record})
  end
end
