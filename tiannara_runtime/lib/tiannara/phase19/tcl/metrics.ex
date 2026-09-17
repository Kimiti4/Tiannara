defmodule Tiannara.Phase19.TCL.Metrics do
  @moduledoc "Exports TCL consensus metrics to Prometheus via :telemetry."
  import Telemetry.Metrics

  @spec metrics() :: [Telemetry.Metrics.t()]
  def metrics do
    [
      last_value("tiannara.phase19.tcl.consensus_score",
        description: "TCL consensus metric $\\mathcal{C}_{tcl}$",
        unit: :ratio
      ),
      last_value("tiannara.phase19.tcl.divergence_magnitude",
        description: "Cross-instance rule divergence $\\mathcal{D}_{divergence}$",
        unit: :ratio
      ),
      counter("tiannara.phase19.tcl.sync_cycles_total",
        description: "Total lattice synchronization cycles executed"
      ),
      counter("tiannara.phase19.tcl.rollbacks_total",
        description: "Total baseline rollbacks triggered"
      ),
      distribution("tiannara.phase19.tcl.convergence_delta",
        description: "Distribution of $\|\\theta^{(n+1)} - \\theta^{(n)}\|$",
        unit: :ratio,
        buckets: [0.0001, 0.001, 0.01, 0.1]
      )
    ]
  end
end