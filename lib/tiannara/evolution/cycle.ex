defmodule Tiannara.Evolution.Cycle do
  @moduledoc """
  A single evolutionary cycle record. Preserves lineage, state, metrics, and
  the exact reasons for acceptance or rejection.

  Constitutional basis: "Every architectural decision should remain traceable",
  "Preserve lineage", "Maintain audit trails".
  """

  @enforce_keys [:cycle_id, :decision]
  defstruct [
    :cycle_id,
    :parent_cycle_id,
    :system_version,
    :constitutional_version,
    :experiment_id,
    :hypothesis_id,
    :proposal_id,
    :patch_id,
    :evidence_ids,
    :test_results,
    :certification_result,
    :decision,
    :metrics_before,
    :metrics_after,
    :drift_metrics,
    :rejection_reasons,
    :rejected_alternatives,
    :rollback_state,
    :timestamp
  ]

  @type t :: %__MODULE__{}
end