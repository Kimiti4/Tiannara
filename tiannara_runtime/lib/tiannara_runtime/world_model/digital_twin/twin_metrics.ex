defmodule TiannaraRuntime.WorldModel.DigitalTwin.TwinMetrics do
  @moduledoc """
  Phase 17.7.1 — TwinMetrics struct.
  Reproducible civilization metrics computed from the twin state.
  """
  defstruct [
    :metrics_id, :tick, :economic_output, :scientific_productivity,
    :infrastructure_health, :governance_stability, :ecological_resilience,
    :energy_efficiency, :logistics_performance, :medical_outcomes,
    :knowledge_growth, :civilization_readiness, :metadata
  ]

  @type t :: %__MODULE__{
          metrics_id: String.t() | nil,
          tick: non_neg_integer() | nil,
          economic_output: float() | nil,
          scientific_productivity: float() | nil,
          infrastructure_health: float() | nil,
          governance_stability: float() | nil,
          ecological_resilience: float() | nil,
          energy_efficiency: float() | nil,
          logistics_performance: float() | nil,
          medical_outcomes: float() | nil,
          knowledge_growth: float() | nil,
          civilization_readiness: float() | nil,
          metadata: map() | nil
        }

  def generate_id(canonical) when is_map(canonical) do
    hash = :crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower)
    "tm_" <> hash
  end
end
