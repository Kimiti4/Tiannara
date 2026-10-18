defmodule TiannaraOS.Stage5GovernanceRegistry do
  @moduledoc """
  Authoritative rollout-tier records for Stage 5 Tier C (OQ-2).

  `Stage5CivilizationAdaptation.verify_rollout_tier/3` consults this module
  to verify, per supporting input, that `:piloted` and `:governance_reviewed`
  claims are backed by authoritative governance records — never inferred from
  self-reported labels, synthetic acceptance, stage-cursor position, or an
  earlier gate passing (`certification/audit/STAGE5_OUTCOME_VOCABULARY.md` §4,
  §7 OQ-2).

  ## Production behaviour (fail-closed)

  No authoritative pilot/governance store exists in this repository: the
  production-readiness scan established that no pilot has ever run (Stage 4
  defers every proposal to `:awaiting_pilot_evidence`) and that Stage 4
  appends `:governance_reviewed` unconditionally with no review performed.
  `fetch_rollout_authorizations/1` therefore always returns
  `{:error, :authoritative_records_unavailable}`, so `:rollout_authorized`
  is unreachable in production until a genuine store is implemented
  (explicitly out of S5-2 scope — missing or unverifiable evidence must
  block rollout, never guess a tier or relax a gate).

  ## Record contract (fixed now, implemented by the future store)

      fetch_rollout_authorizations(institution_ids)
        :: {:ok, %{institution_id => record}} | {:error, atom()}

      record :: %{
        stages: [atom()],                  # must include :piloted AND :governance_reviewed
        evidence_source: :evidence_backed, # synthetic never authorizes rollout
        verified_at: DateTime.t()          # freshness anchor; stale records fail closed
      }

  Every requested `institution_id` must have a complete record or
  verification fails closed.
  """

  @type record :: %{
          stages: [atom()],
          evidence_source: :evidence_backed,
          verified_at: DateTime.t()
        }

  @type fetch_error :: :authoritative_records_unavailable

  @doc """
  Fetch authoritative rollout-tier records for the given institution ids.

  Always fails closed while no authoritative store exists
  (see moduledoc). Returns `{:error, :authoritative_records_unavailable}`.
  """
  @spec fetch_rollout_authorizations([atom()]) ::
          {:ok, %{optional(atom()) => record()}} | {:error, fetch_error()}
  def fetch_rollout_authorizations(institution_ids) do
    _ = institution_ids
    {:error, :authoritative_records_unavailable}
  end
end
