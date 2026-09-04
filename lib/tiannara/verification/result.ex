defmodule Tiannara.Verification.Result do
  @moduledoc """
  Immutable verification evidence record.

  Constitutional mandate: "Verification First. No feature is complete
  until it is validated."

  Once created, a Verification.Result cannot be modified. It is attached
  to a Proposal and serves as the gatekeeper for human review.
  """
  @enforce_keys [:proposal_id, :verified_at]
  defstruct [
    :proposal_id,
    :reproduction,
    :regression_tests,
    :simulation,
    :constitutional_compliance,
    :verified_at,
    immutable: false
  ]

  def passed?(%__MODULE__{} = r) do
    is_map(r.reproduction) and is_map(r.regression_tests) and is_map(r.constitutional_compliance) and
      r.reproduction.reproduced and
      r.regression_tests.all_passing and
      r.constitutional_compliance.compliant
  end
end
