defmodule Tiarnara.Phase18.RRM.Metrics do
  @moduledoc "Exports RRM metamorphosis metrics to Prometheus via :telemetry."
  import Telemetry.Metrics

  @spec metrics() :: [Telemetry.Metrics.t()]
  def metrics do
    [
      last_value("tiarnara.phase18.rrm.metamorphosis_score",
        description: "RRM adaptation metric $\\mathcal{M}_{rrm}$",
        unit: :ratio
      ),
      last_value("tiarnara.phase18.rrm.drift_magnitude",
        description: "Rule evolution drift $\|\\Delta \\theta\|$",
        unit: :ratio
      ),
      counter("tiarnara.phase18.rrm.evolutions_total",
        description: "Total runtime rule evolutions executed"
      ),
      counter("tiarnara.phase18.rrm.rollbacks_total",
        description: "Total baseline rollbacks triggered"
      ),
      distribution("tiarnara.phase18.rrm.jit_compilation_latency_ms",
        description: "Distribution of JIT compilation latency",
        unit: :millisecond,
        buckets: [5, 20, 50, 100, 250]
      )
    ]
  end
end