defmodule Tiannara.Sentinel.Contracts.Intervention do
  @moduledoc """
  Represents a proposed intervention or regulation inside the Sentinel framework.
  Phase B1.5 restricts these to recommendations and tracks their empirical outcomes.
  """
  @enforce_keys [
    :id,
    :target_system,
    :action,
    :status
  ]

  defstruct [
    :id,
    :target_system,
    :action,
    :rationale,
    :confidence,
    :expected_impact,
    :source_anomaly,
    :created_at,
    :evaluation_tick,
    :success_score,
    :shadow_result,
    status: :proposed
  ]

  @type action_type ::
          :observe
          | :investigate
          | :rebalance
          | :isolate
          | :reconcile
          | :quarantine

  @type status_type ::
          :proposed
          | :reviewed
          | :observed
          | :successful
          | :failed

  @type t :: %__MODULE__{
          id: String.t(),
          target_system: atom() | String.t(),
          action: action_type(),
          rationale: String.t(),
          confidence: float(),
          expected_impact: map(),
          source_anomaly: String.t(),
          created_at: integer(),
          evaluation_tick: integer() | nil,
          success_score: float() | nil,
          shadow_result: Tiannara.Sentinel.Contracts.ShadowResult.t() | nil,
          status: status_type()
        }
end
