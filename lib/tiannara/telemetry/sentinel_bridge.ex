defmodule Tiannara.Telemetry.SentinelBridge do
  @moduledoc """
  Bridges live telemetry into the Ω.1 Sentinel heartbeat. Produces the
  `observer` and `analyzer` functions the Heartbeat.Server consumes, so the
  Sentinel observes REAL runtime state and emits epistemic events on anomalies.

  This is the wiring that converts the dry-run Sentinel into a live observer:
      Runtime telemetry → Observation → AnomalyDetector → EpistemicEvent → Ω-loop

  Constitutional basis: "Detect anomalies", Observability, augmentation clause
  (observes and reports; does not act).
  """

  alias Tiannara.Telemetry.{Observation, AnomalyDetector, RuntimeAdapter}
  alias Tiannara.Sentinel.EpistemicEvent

  @doc """
  Builds `observer`/`analyzer` heartbeat options backed by a telemetry adapter
  and a rolling observation window.
  """
  def build_heartbeat_opts(opts \\ []) do
    adapter = Keyword.get(opts, :adapter, RuntimeAdapter)
    window_size = Keyword.get(opts, :window_size, 5)

    {:ok, window_agent} = Agent.start_link(fn -> [] end)

    observer = fn ->
      obs = adapter.collect([])

      Agent.update(window_agent, fn w ->
        [obs | w] |> Enum.take(window_size) |> Enum.reverse()
      end)

      Agent.get(window_agent, & &1)
    end

    analyzer = fn window, _cycle ->
      window
      |> AnomalyDetector.detect(opts)
      |> to_epistemic_events()
    end

    [observer: observer, analyzer: analyzer]
  end

  @doc "Convert detected anomalies into `:anomaly_detected` epistemic events."
  def to_epistemic_events(anomalies) when is_list(anomalies) do
    Enum.map(anomalies, fn anomaly ->
      %EpistemicEvent{
        type: :anomaly_detected,
        severity: anomaly.severity,
        payload: anomaly,
        confidence: 0.7,
        evidence: Map.get(anomaly, :evidence, [])
      }
    end)
  end
end