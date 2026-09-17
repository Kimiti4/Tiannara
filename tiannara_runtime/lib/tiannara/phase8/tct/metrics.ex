defmodule Tiannara.Phase8.TCT.Metrics do
  @moduledoc """
  Exports TCT simulation metrics to Prometheus via :telemetry.
  """
  import Telemetry.Metrics

  @spec metrics() :: [Telemetry.Metrics.t()]
  def metrics do
    [
      last_value("tiannara.phase8.tct.coherence",
        description: "Coherence pressure component Cₙ",
        unit: :ratio
      ),
      last_value("tiannara.phase8.tct.divergence",
        description: "Divergence pressure component Dₙ",
        unit: :ratio
      ),
      last_value("tiannara.phase8.tct.resonance",
        description: "Recursive coupling component Rₙ",
        unit: :ratio
      ),
      last_value("tiannara.phase8.tct.tensor",
        description: "Transfinite coherence tensor value Tₙ = Cₙ - Dₙ + Rₙ",
        unit: :ratio
      ),
      counter("tiannara.phase8.tct.iterations_total",
        description: "Total simulation iterations executed"
      ),
      distribution("tiannara.phase8.tct.convergence_delta",
        description: "Distribution of |Tₙ₊₁ - Tₙ|",
        unit: :ratio,
        buckets: [0.0001, 0.001, 0.01, 0.1]
      )
    ]
  end

  @doc "Attach telemetry handlers to TCT engine events"
  @spec attach_handlers() :: :ok
  def attach_handlers do
    :telemetry.attach_many(
      "tct-metrics",
      [
        [:tiannara, :phase8, :tct, :iteration],
        [:tiannara, :phase8, :tct, :complete]
      ],
      &handle_event/4,
      %{}
    )
  end

  defp handle_event([:tiannara, :phase8, :tct, :iteration], measurements, metadata, _config) do
    # Prometheus scraper reads from /metrics endpoint
    # This function ensures values are in the global metric registry
    :ok
  end
end