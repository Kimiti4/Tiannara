defmodule Tiannara.Phase11.CRCA.Metrics do
  @moduledoc """
  Exports CRCA arbitration metrics to Prometheus via :telemetry.
  """
  import Telemetry.Metrics

  @spec metrics() :: [Telemetry.Metrics.t()]
  def metrics do
    [
      last_value("tiannara.phase11.crca.arbitration_score",
        description: "CRCA equilibrium metric $\\mathcal{A}_{crca}$",
        unit: :ratio
      ),
      last_value("tiannara.phase11.crca.temporal_coherence",
        description: "Temporal alignment coherence $\\mathcal{T}_{coh}$",
        unit: :ratio
      ),
      counter("tiannara.phase11.crca.paradoxes_resolved_total",
        description: "Total causal paradoxes detected & resolved"
      ),
      distribution("tiannara.phase11.crca.sync_latency_ms",
        description: "Distribution of temporal sync latency",
        unit: :millisecond,
        buckets: [10, 50, 100, 200, 500]
      )
    ]
  end
end