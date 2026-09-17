defmodule Tiannara.Phase16.REA.Metrics do
  @moduledoc "Exports REA harmonization metrics to Prometheus via :telemetry."
  import Telemetry.Metrics

  @spec metrics() :: [Telemetry.Metrics.t()]
  def metrics do
    [
      last_value("tiannara.phase16.rea.harmonization_score",
        description: "Cross-domain harmonization metric $\\mathcal{H}_{rea}$",
        unit: :ratio
      ),
      last_value("tiannara.phase16.rea.constraint_conflict_density",
        description: "Unified constraint conflict density $\\mathcal{D}_{conflict}$",
        unit: :ratio
      ),
      counter("tiannara.phase16.rea.arbitration_cycles_total",
        description: "Total epistemic arbitration cycles executed"
      ),
      distribution("tiannara.phase16.rea.convergence_delta",
        description: "Distribution of $\|\\mathcal{A}^{(n+1)} - \\mathcal{A}^{(n)}\|$",
        unit: :ratio,
        buckets: [0.0001, 0.001, 0.01, 0.1]
      )
    ]
  end
end