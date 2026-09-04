defmodule Tiannara.Omega.Verification.Report do
  @moduledoc """
  Aggregates scenario outcomes into a campaign report with boundary-level
  results and an overall verdict.

  Constitutional basis: Explainability, Observability, "Maintain audit trails."
  """

  alias Tiannara.Omega.Verification.ScenarioOutcome

  defstruct [:campaign_id, :outcomes, :total, :passed, :failed, :inconclusive,
             :boundary_results, :overall, :timestamp]

  def aggregate(outcomes) do
    total = length(outcomes)
    passed = Enum.count(outcomes, &ScenarioOutcome.fully_passed?/1)
    failed = Enum.count(outcomes, fn o -> o.outcome != o.expected end)
    inconclusive = Enum.count(outcomes, &(&1.outcome == :inconclusive))

    boundary_results = compute_boundary_results(outcomes)

    # Ω.R is verified ONLY if ALL scenarios fully pass and none are inconclusive.
    overall = if passed == total and inconclusive == 0, do: :verified, else: :open

    %__MODULE__{
      campaign_id: make_id(),
      outcomes: outcomes,
      total: total,
      passed: passed,
      failed: failed,
      inconclusive: inconclusive,
      boundary_results: boundary_results,
      overall: overall,
      timestamp: System.system_time(:second)
    }
  end

  defp compute_boundary_results(outcomes) do
    outcomes
    |> Enum.group_by(&boundary_for/1)
    |> Enum.map(fn {boundary, outs} ->
      all_passed = Enum.all?(outs, &ScenarioOutcome.fully_passed?/1)
      {boundary, if(all_passed, do: :pass, else: :fail)}
    end)
    |> Map.new()
  end

  defp boundary_for(%{scenario: s}) do
    case s do
      :authorization_bypass -> :authorization_boundary
      :grant_replay -> :authorization_boundary
      :identity_forgery -> :authorization_boundary
      :idempotency -> :replay_protection
      :certification_bypass -> :certification_boundary
      :candidate_mutation -> :candidate_integrity
      :lineage_tampering -> :lineage_integrity
      :restart_recovery -> :restart_recovery
      :deployment_race -> :concurrency_safety
      :evidence_corruption -> :evidence_integrity
      :legacy_api_bypass -> :legacy_api_containment
      _ -> :unknown
    end
  end

  defp make_id, do: :"campaign-#{System.unique_integer([:monotonic])}"
end