defmodule Tiannara.Soak.RecoveryGate do
  @moduledoc """
  Mandatory gate: the 72h soak must NOT be treated as production-grade
  evidence until checkpoint recovery testing has passed.

  Until `verdict/1` returns `:gate_open`, any soak report must be labeled
  "recovery-unverified".

  Constitutional basis: "No feature is complete until it is validated." /
  "Capability must never outpace verification."
  """

  @required [
    :resumes_after_abnormal_termination,
    :preserves_elapsed_and_counters,
    :preserves_discovery_state,
    :rejects_corrupt_loads_previous_valid,
    :skips_undecodable_checkpoint,
    :clean_start_on_missing,
    :never_resumes_cross_run,
    :distinguishes_wall_clock_from_validated,
    :refuses_production_checkpoint_path
  ]

  def required_checks, do: @required

  def verdict(passed) when is_list(passed) do
    missing = @required -- passed
    if missing == [], do: :gate_open, else: {:gate_closed, missing}
  end
end
