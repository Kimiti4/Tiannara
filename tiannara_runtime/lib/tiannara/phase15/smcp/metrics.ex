defmodule Tiannara.Phase15.SMCP.Metrics do
  @moduledoc "Exports SMCP adaptation metrics to Prometheus via :telemetry."
  import Telemetry.Metrics

  @spec metrics() :: [Telemetry.Metrics.t()]
  def metrics do
    [
      last_value("tiannara.phase15.smcp.consensus_stability",
        description: "Federation consensus stability metric $\\mathcal{S}_{cons}$",
        unit: :ratio
      ),
      counter("tiannara.phase15.smcp.adaptations_total",
        description: "Total consensus parameter adaptations executed"
      ),
      counter("tiannara.phase15.smcp.rollbacks_total",
        description: "Total baseline rollbacks triggered"
      ),
      distribution("tiannara.phase15.smcp.adoption_latency_ms",
        description: "Distribution of time to full parameter adoption",
        unit: :millisecond,
        buckets: [1000, 5000, 10000, 25000]
      )
    ]
  end
end