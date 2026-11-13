defmodule Tiannara.Forecasting.LifecycleObservabilityTest do
  @moduledoc """
  The lifecycle and assurance observability (TCP-002.6 Stage 12).

  The point of these tests is that the observability must not lie. A count
  must be zero because nothing happened, a state must be one that was
  actually reached, and the difference between "no observation", "acquired
  but unverified", "verified with limited assurance" and "resolved" must
  survive into the snapshot.
  """
  use ExUnit.Case, async: false

  alias Tiannara.Forecasting.Contracts.Forecast
  alias Tiannara.Forecasting.Contracts.Horizon
  alias Tiannara.Forecasting.Forecast, as: ForecastBuilder
  alias Tiannara.Forecasting.Lifecycle
  alias Tiannara.Forecasting.{ForecastRegistry, Observation, OutcomeResolution, OutcomeVerifier}

  @raw Jason.encode!(%{"outcome" => "yes"})

  setup do
    unless Process.whereis(ForecastRegistry), do: start_supervised!(ForecastRegistry)
    unless Process.whereis(Tiannara.Forecasting.VerificationAuthority), do: start_supervised!(Tiannara.Forecasting.VerificationAuthority)

    ledger = :"lifecycle_test_#{System.unique_integer([:positive])}"
    start_supervised!({Lifecycle, name: ledger})

    {:ok, ledger: ledger}
  end

  defp observation do
    [
      observation_id: "obs-1",
      observed_outcome: "yes",
      event_at: ~U[2026-09-02 00:00:00Z],
      published_at: ~U[2026-09-02 00:01:00Z],
      acquired_at: ~U[2026-09-02 00:05:00Z],
      source_identity: "test-source",
      evidence_ref: "evidence://1",
      evidence_digest: :crypto.hash(:sha256, @raw)
    ]
  end

  defp verification(status, reason) do
    %{
      observation_id: "obs-1",
      status: status,
      reason: reason,
      assurance: %{evidence_integrity: :established, source_identity: :declared}
    }
  end

  describe "the snapshot does not lie" do
    test "an empty ledger reports the registered state and no observations", ctx do
      snapshot = Lifecycle.snapshot(ctx.ledger)

      assert snapshot.available == true
      assert snapshot.lifecycle_state == :forecast_registered
      assert snapshot.transitions_proven == []
      assert snapshot.observations.acquired == 0
      assert snapshot.observations.awaiting_verification == 0
      assert snapshot.outcomes.resolved == 0
      assert snapshot.outcomes.unresolved == 0
      assert snapshot.scores.real_forecast_scores == 0
    end

    test "the snapshot never claims durability", ctx do
      snapshot = Lifecycle.snapshot(ctx.ledger)

      assert snapshot.durable == false
      assert snapshot.scope == :process_scoped
      assert snapshot.durability_limitation =~ "TCP-B-064"
    end

    test "publisher authenticity is reported as not established", ctx do
      snapshot = Lifecycle.snapshot(ctx.ledger)

      assert snapshot.verification.publisher_authenticity == :not_established
      assert snapshot.assurance.publisher_authenticity == :not_established
      assert snapshot.verification.publisher_authenticity_limitation =~ ":verified is unreachable"
    end

    test "calibration readiness is reported as not established", ctx do
      snapshot = Lifecycle.snapshot(ctx.ledger)

      assert snapshot.scores.calibration_readiness == :not_established
      assert snapshot.scores.calibration_limitation =~ "not calibration"
    end

    test "an assurance dimension that was never established says so", ctx do
      snapshot = Lifecycle.snapshot(ctx.ledger)

      assert snapshot.assurance.evidence_integrity == :not_established
      assert snapshot.assurance.semantic_verification == :not_established
      assert snapshot.assurance.temporal_eligibility == :not_established
      assert snapshot.assurance.corroboration == :not_required_and_not_available
    end

    test "the acquisition status distinguishes no attempt from a failed attempt", ctx do
      assert Lifecycle.snapshot(ctx.ledger).acquisition.status == :no_attempt

      Lifecycle.record_acquisition(
        %{status: :unavailable, reason: :connection_refused},
        ctx.ledger
      )

      acquisition = Lifecycle.snapshot(ctx.ledger).acquisition
      assert acquisition.status == :unavailable
      assert acquisition.attempts == 1
      assert acquisition.failures == 1
      assert acquisition.successes == 0
      assert acquisition.last_failure == :connection_refused
    end
  end

  describe "the lifecycle conditions are not collapsed" do
    test "no observation, acquired but unverified, verified and resolved are distinct", ctx do
      ledger = ctx.ledger

      # No observation at all.
      assert Lifecycle.snapshot(ledger).observations.acquired == 0
      assert Lifecycle.snapshot(ledger).observations.awaiting_verification == 0

      Lifecycle.record_observation(%{id: "o1", observation_id: "obs-1"}, ledger)
      snapshot = Lifecycle.snapshot(ledger)
      assert snapshot.observations.acquired == 1
      assert snapshot.observations.awaiting_verification == 1
      assert snapshot.observations.verified == 0
      assert snapshot.observations.verified_with_limited_source_assurance == 0
      assert snapshot.lifecycle_state == :observation_acquired

      Lifecycle.record_verification(
        verification(
          :verified_with_limited_source_assurance,
          :publisher_authenticity_not_established
        ),
        ledger
      )

      snapshot = Lifecycle.snapshot(ledger)
      assert snapshot.observations.awaiting_verification == 0
      assert snapshot.observations.verified_with_limited_source_assurance == 1
      assert snapshot.observations.verified == 0
      assert snapshot.lifecycle_state == :outcome_verified

      Lifecycle.record_resolution(%{resolution_id: "r1", forecast_id: "f-1"}, ledger)

      snapshot = Lifecycle.snapshot(ledger)
      assert snapshot.outcomes.resolved == 1
      assert snapshot.outcomes.unresolved == 0
      assert snapshot.lifecycle_state == :outcome_resolved
    end

    test "a negative verdict is counted as negative, not as verified", ctx do
      Lifecycle.record_observation(%{id: "o1", observation_id: "obs-1"}, ctx.ledger)

      Lifecycle.record_verification(
        verification(:rejected, :evidence_integrity_failure),
        ctx.ledger
      )

      snapshot = Lifecycle.snapshot(ctx.ledger)
      assert snapshot.observations.rejected == 1
      assert snapshot.observations.verified == 0
      assert snapshot.observations.verified_with_limited_source_assurance == 0
      assert snapshot.observations.evidence_integrity_failures == 1
      assert snapshot.lifecycle_state == :observation_acquired
    end

    test "an observation awaiting review is not counted as verified", ctx do
      Lifecycle.record_observation(%{id: "o1", observation_id: "obs-1"}, ctx.ledger)

      Lifecycle.record_verification(
        verification(:requires_review, :evidence_requires_review),
        ctx.ledger
      )

      snapshot = Lifecycle.snapshot(ctx.ledger)
      assert snapshot.observations.requires_review == 1
      assert snapshot.observations.verified == 0
      assert snapshot.lifecycle_state == :observation_acquired
    end
  end

  describe "availability" do
    test "an unreachable ledger reports no counts at all", ctx do
      snapshot = Lifecycle.snapshot(:no_such_ledger)

      assert snapshot.available == false
      assert snapshot.reason == :lifecycle_ledger_unavailable
      refute Map.has_key?(snapshot, :observations)
      refute Map.has_key?(snapshot, :lifecycle_state)
    end

    test "the ledger is supervised and reachable by default" do
      assert Lifecycle.available?()
      assert Lifecycle.snapshot().available == true
    end
  end

  describe "the observability is wired to the real path" do
    test "the canonical resolver records its resolution" do
      before = Lifecycle.snapshot().outcomes.resolved

      {:ok, horizon} =
        Horizon.from_iso(%{
          start_at: "2026-09-01T00:00:00Z",
          end_at: "2026-09-03T00:00:00Z",
          policy: :closed
        })

      forecast =
        ForecastBuilder.new(
          question: "Will event occur?",
          event: "event",
          outcomes: ["yes", "no"],
          probabilities: [0.7, 0.3],
          horizon: "48h",
          typed_horizon: horizon
        )
        |> Map.put(:created_at, ~U[2026-09-01 00:00:00Z])

      {:ok, _} = ForecastRegistry.register(forecast)

      {:ok, bound} = Observation.bind(forecast, observation())
      {:ok, record} = OutcomeVerifier.verify(forecast, bound, fn _ref -> {:ok, @raw} end)
      {:ok, verified} = OutcomeVerifier.apply(record, bound)

      assert {:ok, resolution} =
               OutcomeResolution.resolve(
                 forecast,
                 verified,
                 %{
                   evidence_class: :simulated,
                   execution_mode: :simulation
                 },
                 record,
                 fn _ref -> {:ok, @raw} end
               )

      after_resolution = Lifecycle.snapshot()

      assert after_resolution.outcomes.resolved == before + 1
      assert after_resolution.lifecycle_state == :outcome_resolved
      assert resolution.forecast_digest == Forecast.digest(forecast)
      assert resolution.verification_record_digest == record.record_digest
    end
  end
end
