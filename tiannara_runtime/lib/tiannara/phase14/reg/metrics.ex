defmodule Tiannara.Phase14.REG.Metrics do
  @moduledoc "Exports REG metrics to Prometheus via :telemetry."
  import Telemetry.Metrics

  @spec metrics() :: [Telemetry.Metrics.t()]
  def metrics do
    [
      last_value("tiannara.phase14.reg.consistency_score",
        description: "Axiomatic consistency metric $\\mathcal{C}(A)$",
        unit: :ratio
      ),
      last_value("tiannara.phase14.reg.drift_magnitude",
        description: "Representational drift $\|\\nabla N_{epi}\|$",
        unit: :ratio
      ),
      counter("tiannara.phase14.reg.generation_cycles_total",
        description: "Total epistemic generation cycles executed"
      ),
      distribution("tiannara.phase14.reg.convergence_delta",
        description: "Distribution of $\|G^{(n+1)} - G^{(n)}\|$",
        unit: :ratio,
        buckets: [0.0001, 0.001, 0.01, 0.1]
      )
    ]
  end
end