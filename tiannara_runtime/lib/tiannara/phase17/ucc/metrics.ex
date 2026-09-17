defmodule Tiannara.Phase17.UCC.Metrics do
  @moduledoc "Exports UCC compilation metrics to Prometheus via :telemetry."
  import Telemetry.Metrics

  @spec metrics() :: [Telemetry.Metrics.t()]
  def metrics do
    [
      last_value("tiannara.phase17.ucc.compilation_score",
        description: "UCC compilation metric $\\Xi_{ucc}$",
        unit: :ratio
      ),
      last_value("tiannara.phase17.ucc.resource_utilization",
        description: "Hardware capacity utilization $\\mathcal{R}_{alloc}$",
        unit: :ratio
      ),
      last_value("tiannara.phase17.ucc.equivalence_score",
        description: "Execution equivalence $\| \\text{Exec} - \\text{Ideal} \|$",
        unit: :ratio
      ),
      counter("tiannara.phase17.ucc.compilations_total",
        description: "Total constraint compilations executed"
      ),
      counter("tiannara.phase17.ucc.shardings_total",
        description: "Total distributed surface shardings"
      )
    ]
  end
end