defmodule Tiannara.CTL.ParadoxResolver do
  @moduledoc """
  Decommissioned in MC-002-M (L2 theatrical decommission).

  Historical behavior: read two boolean flags (`:contradicts_base`,
  `:broken_downstream`) and return an unconditional success tuple while
  pushing fabricated structural/collapse metrics — no logical analysis was
  performed (exact prior literals are archived in the M3 decommission ledger).
  Per "Truth > apparent capability", that theatrical behavior is replaced here
  by an explicit
  `{:error, :paradox_resolver_unavailable}` so unverified merge paths are
  never silently sold as "resolved". The truthful merge path lives in
  `Tiannara.CTL.BranchReconciliation` (real stress evaluation +
  `HistoryIsolation.isolate/1` quarantine on failure).

  Unavailable: no truthful paradox-resolution implementation exists in this
  runtime.
  """
  def resolve(_branch_h, _base_h) do
    {:error, :paradox_resolver_unavailable}
  end
end