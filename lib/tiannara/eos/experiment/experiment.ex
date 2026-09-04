defmodule Tiannara.EOS.Experiment do
  @moduledoc """
  First-class experiment. Constitutional mandate: "Scientific Method —
  Observation → Hypothesis → Prediction → Simulation → Experiment →
  Validation → Knowledge Integration → Continuous Re-evaluation."
  """

  @enforce_keys [:id, :type, :designed_at]
  defstruct [
    :id,
    :type,
    :purpose,
    :requested_by,
    :theory_ids,
    :prediction_ids,
    :design,
    :budget,
    :status,
    :results,
    :lineage,
    :designed_at,
    :scheduled_at,
    :completed_at
  ]
end

defmodule Tiannara.EOS.ExperimentResults do
  @moduledoc "Immutable experiment outcome. Never modified after completion."

  @enforce_keys [:experiment_id, :completed_at]
  defstruct [
    :experiment_id,
    :outcome_per_theory,
    :resolved_predictions,
    :raw_data_ref,
    :statistical_summary,
    :anomalies,
    :completed_at,
    immutable: false
  ]
end
