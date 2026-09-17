defmodule Tiannara.Sentinel.Observatories.Types.ObservatorySignal do
  @moduledoc """
  Evidence-only contract for Phase D.1.
  Contains NO execution authority, NO intervention routing, NO decision influence.
  """
  @type observatory_id :: :runtime | :ecological | :semantic | atom()
  @type reliability_state :: :unproven | :provisional | :trusted
  
  @type t :: %__MODULE__{
    id: String.t(),                    # UUID for tracking
    observatory: observatory_id(),
    anomaly_type: atom(),
    recommended_action: atom(),        # Advisory only
    confidence: float(),               # 0.0 - 1.0, observatory's self-assessment
    reasoning: String.t(),             # Human-readable justification
    reliability: reliability_state(),  # System-assessed trustworthiness
    metrics: map(),                    # Observatory-specific diagnostic data
    timestamp: integer(),              # System time in milliseconds
    ttl_seconds: integer()             # Signal expiration for GC
  }

  @enforce_keys [:observatory, :anomaly_type, :recommended_action, :confidence, :reasoning]
  defstruct [
    :id, :observatory, :anomaly_type, :recommended_action, :confidence, 
    :reasoning, :reliability, :metrics, :timestamp, :ttl_seconds
  ]

  @spec new(observatory_id(), atom(), atom(), float(), String.t(), map()) :: t()
  def new(observatory, anomaly_type, action, confidence, reasoning, metrics \\ %{}) do
    %__MODULE__{
      # We skip full UUID generation logic here for simplicity, replacing with a fast random string
      id: "sig_#{:os.system_time(:microsecond)}_#{:rand.uniform(1000)}",
      observatory: observatory,
      anomaly_type: anomaly_type,
      recommended_action: action,
      confidence: Float.round(confidence, 3),
      reasoning: reasoning,
      reliability: :unproven,  # Default: must be earned via ReliabilityTracker
      metrics: metrics,
      timestamp: System.system_time(:millisecond),
      ttl_seconds: 300  # 5-minute TTL for passive signals
    }
  end

  @spec update_reliability(t(), reliability_state()) :: t()
  def update_reliability(signal, new_state) do
    %{signal | reliability: new_state}
  end
end
