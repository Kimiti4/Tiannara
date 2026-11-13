defmodule Tiannara.Forecasting.OutcomeIntegrityTest do
  @moduledoc """
  Adversarial verification of the observation binding and the independent
  evidence verifier (TCP-002.6 Stages 3 and 4).

  Three properties are pinned:

    * an observation is bound to the **registered** forecast, and the
      authoritative digests are derived from that record rather than supplied
      by the caller;
    * the acquisition layer cannot advance the lifecycle by itself. The
      verifier re-reads the stored evidence, re-digests it, parses it
      independently, and reports the assurance it actually established —
      including the fact that publisher authenticity is **not** established;
    * a verification result is bound to the observation's **content**, so an
      observation cannot be verified and then altered before resolution.
  """
  use ExUnit.Case, async: false

  alias Tiannara.Forecasting.Contracts.Forecast
  alias Tiannara.Forecasting.Contracts.Horizon
  alias Tiannara.Forecasting.Forecast, as: ForecastBuilder
  alias Tiannara.Forecasting.Outcome
  alias Tiannara.Forecasting.OutcomeResolution
  alias Tiannara.Forecasting.{ForecastRegistry, Observation, OutcomeVerifier}

  @raw Jason.encode!(%{"outcome" => "yes", "source_record" => "rec-1"})

  setup do
    unless Process.whereis(ForecastRegistry), do: start_supervised!(ForecastRegistry)
    unless Process.whereis(Tiannara.Forecasting.VerificationAuthority), do: start_supervised!(Tiannara.Forecasting.VerificationAuthority)

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

    {:ok, _} = ForecastRegistry.register(forecast)

    {:ok, forecast: forecast, horizon: horizon}
  end

  defp observation(overrides \\ []) do
    Keyword.merge(
      [
        observation_id: "obs-1",
        observed_outcome: "yes",
        event_at: ~U[2026-09-02 00:00:00Z],
        published_at: ~U[2026-09-02 00:01:00Z],
        acquired_at: ~U[2026-09-02 00:05:00Z],
        source_identity: "test-source",
        source_type: "test",
        source_record_id: "rec-1",
        evidence_ref: "evidence://1",
        evidence_digest: :crypto.hash(:sha256, @raw),
        evidence_schema_version: "v1"
      ],
      overrides
    )
  end

  defp reader(bytes \\ @raw), do: fn _ref -> {:ok, bytes} end

  describe "observation binding" do
    test "an observation is bound to the registered forecast", ctx do
      assert {:ok, outcome} = Observation.bind(ctx.forecast, observation())

      assert outcome.forecast_id == ctx.forecast.id
      assert outcome.forecast_digest == Forecast.digest(ctx.forecast)
      assert outcome.outcome_definition_digest == ctx.forecast.outcome_definition_digest
      assert outcome.horizon_digest == ctx.forecast.horizon_digest
      assert outcome.evidence_digest == :crypto.hash(:sha256, @raw)
      assert outcome.source_identity == "test-source"
      assert outcome.event_at == ~U[2026-09-02 00:00:00Z]
      assert outcome.published_at == ~U[2026-09-02 00:01:00Z]
      assert outcome.acquired_at == ~U[2026-09-02 00:05:00Z]
    end

    test "an unregistered forecast cannot be bound", ctx do
      unregistered = %{ctx.forecast | id: "not-registered"}

      assert {:error, :forecast_not_registered} = Observation.bind(unregistered, observation())
    end

    test "a forecast that shares an id but differs from the registered one is refused", ctx do
      # Same id, substituted typed horizon. The registered record is the
      # authority, so the caller's copy is refused rather than bound.
      {:ok, other_horizon} =
        Horizon.from_iso(%{
          start_at: "2026-09-01T00:00:00Z",
          end_at: "2026-09-05T00:00:00Z",
          policy: :closed
        })

      substituted = %{
        ctx.forecast
        | typed_horizon: other_horizon,
          horizon_digest: Horizon.digest(other_horizon)
      }

      assert {:error, :forecast_does_not_match_registered} =
               Observation.bind(substituted, observation())
    end

    test "the binding uses the registered record's digests, not the caller's", ctx do
      assert {:ok, outcome} = Observation.bind(ctx.forecast, observation())

      registered = ForecastRegistry.get(ctx.forecast.id)

      assert {:ok, registered} = registered
      assert outcome.forecast_digest == Forecast.digest(registered)
      assert outcome.outcome_definition_digest == registered.outcome_definition_digest
      assert outcome.horizon_digest == registered.horizon_digest
    end

    test "evidence without a reference is refused", ctx do
      obs = observation(evidence_ref: nil)

      assert {:error, :evidence_reference_missing} = Observation.bind(ctx.forecast, obs)
    end

    test "evidence without a digest is refused", ctx do
      obs = observation(evidence_digest: nil)

      assert {:error, :evidence_digest_missing} = Observation.bind(ctx.forecast, obs)
    end

    test "an observation without a source identity is refused", ctx do
      obs = observation(source_identity: nil)

      assert {:error, :source_identity_missing} = Observation.bind(ctx.forecast, obs)
    end

    test "the acquisition timestamps are not collapsed into one another", ctx do
      assert {:ok, outcome} = Observation.bind(ctx.forecast, observation())

      refute outcome.event_at == outcome.published_at
      refute outcome.published_at == outcome.acquired_at
    end

    test "a missing source timestamp stays missing", ctx do
      obs = observation(published_at: nil)

      assert {:ok, outcome} = Observation.bind(ctx.forecast, obs)
      assert outcome.published_at == nil
      refute outcome.published_at == outcome.acquired_at
    end

    test "conflicting observations are preserved rather than overwritten", ctx do
      {:ok, first} =
        Observation.bind(
          ctx.forecast,
          observation(observation_id: "obs-a", observed_outcome: "yes")
        )

      first_digest = Outcome.content_digest(first)

      {:ok, second} =
        Observation.bind(
          ctx.forecast,
          observation(observation_id: "obs-b", observed_outcome: "no")
        )

      # The first observation is untouched, and the second is a separate
      # record. Neither overwrites the other, and neither is silently
      # reconciled with the other.
      assert Outcome.content_digest(first) == first_digest
      assert first.observation_id == "obs-a"
      assert second.observation_id == "obs-b"
      assert first.observed_outcome == "yes"
      assert second.observed_outcome == "no"
    end

    test "an adapter cannot assert its own verification status at binding", ctx do
      obs = observation(verification_status: :verified)

      assert {:error, :verification_status_not_acceptable_at_binding} =
               Observation.bind(ctx.forecast, obs)
    end

    test "a bound observation carries no verification status of its own", ctx do
      assert {:ok, outcome} = Observation.bind(ctx.forecast, observation())

      assert outcome.verification_status == :unverified
      refute Outcome.eligible_for_resolution?(outcome)
    end
  end

  describe "independent verification" do
    test "a bound observation verifies against the stored evidence", ctx do
      {:ok, outcome} = Observation.bind(ctx.forecast, observation())

      assert {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader())

      # The evidence is intact, the source is identified, the semantics match
      # and the event is inside the horizon — but the publisher's
      # cryptographic authenticity was not established.
      assert result.status == :verified_with_limited_source_assurance
      assert result.assurance.evidence_integrity == :established
      assert result.assurance.source_identity == :declared
      assert result.assurance.semantic_verification == :established
      assert result.assurance.temporal_eligibility == :established
      assert result.assurance.publisher_authenticity == :not_established
      assert result.reason == :publisher_authenticity_not_established
      assert result.verification_policy_version == OutcomeVerifier.policy_version()
    end

    test "the verification result is bound to the forecast, the observation and the evidence",
         ctx do
      {:ok, outcome} = Observation.bind(ctx.forecast, observation())

      assert {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader())

      assert result.forecast_id == ctx.forecast.id
      assert result.forecast_digest == Forecast.digest(ctx.forecast)
      assert result.observation_id == outcome.observation_id
      assert result.evidence_digest == outcome.evidence_digest
      assert result.observation_digest == Outcome.content_digest(outcome)
    end

    test "evidence altered after acquisition is rejected on integrity", ctx do
      {:ok, outcome} = Observation.bind(ctx.forecast, observation())

      tampered = Jason.encode!(%{"outcome" => "no"})

      assert {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader(tampered))
      assert result.status == :rejected
      assert result.reason == :evidence_integrity_failure
    end

    test "the verifier reads the evidence itself, not the adapter's parsed value", ctx do
      # The adapter's `observed_outcome` says "yes"; the stored evidence says
      # "no". The verifier must follow the evidence.
      {:ok, outcome} = Observation.bind(ctx.forecast, observation(observed_outcome: "yes"))

      stored = Jason.encode!(%{"outcome" => "no"})
      outcome = %{outcome | evidence_digest: :crypto.hash(:sha256, stored)}

      assert {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader(stored))
      assert result.status == :rejected
      assert result.reason == :observation_disagrees_with_evidence
    end

    test "the verifier refuses when the evidence disagrees with the bound observation", ctx do
      stored = Jason.encode!(%{"outcome" => "no"})

      {:ok, outcome} = Observation.bind(ctx.forecast, observation(observed_outcome: "yes"))
      outcome = %{outcome | evidence_digest: :crypto.hash(:sha256, stored)}

      assert {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader(stored))
      assert result.status == :rejected
      assert result.reason == :observation_disagrees_with_evidence
    end

    test "an observation whose value is outside the declared outcome space is rejected", ctx do
      stored = Jason.encode!(%{"outcome" => "maybe"})

      {:ok, outcome} = Observation.bind(ctx.forecast, observation(observed_outcome: "maybe"))
      outcome = %{outcome | evidence_digest: :crypto.hash(:sha256, stored)}

      assert {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader(stored))
      assert result.status == :rejected
      assert result.reason == :observation_outside_outcome_definition
    end

    test "missing evidence cannot be read", ctx do
      {:ok, outcome} = Observation.bind(ctx.forecast, observation())

      assert {:ok, result} =
               OutcomeVerifier.verify(ctx.forecast, outcome, fn _ref -> {:ok, :not_bytes} end)

      assert result.status == :unavailable
      assert result.reason == :evidence_read_failed
    end

    test "a missing source identity is unverified", ctx do
      {:ok, outcome} = Observation.bind(ctx.forecast, observation())
      outcome = %{outcome | source_identity: nil}

      assert {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader())
      assert result.status == :unverified
      assert result.reason == :source_identity_missing
    end

    test "a missing event timestamp is unverified", ctx do
      {:ok, outcome} = Observation.bind(ctx.forecast, observation())
      outcome = %{outcome | event_at: nil}

      assert {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader())
      assert result.status == :unverified
      assert result.reason == :event_timestamp_missing
    end

    test "an event outside the registered horizon is rejected", ctx do
      {:ok, outcome} =
        Observation.bind(ctx.forecast, observation(event_at: ~U[2026-09-09 00:00:00Z]))

      assert {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader())
      assert result.status == :rejected
      assert result.reason == :event_outside_horizon
    end

    test "an event exactly at the horizon start is inside it", ctx do
      {:ok, outcome} =
        Observation.bind(ctx.forecast, observation(event_at: ~U[2026-09-01 00:00:00Z]))

      assert {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader())
      assert result.status == :verified_with_limited_source_assurance
    end

    test "an event exactly at the horizon end is inside it", ctx do
      {:ok, outcome} =
        Observation.bind(ctx.forecast, observation(event_at: ~U[2026-09-03 00:00:00Z]))

      assert {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader())
      assert result.status == :verified_with_limited_source_assurance
    end

    test "an event one second after the horizon end is outside it", ctx do
      {:ok, outcome} =
        Observation.bind(ctx.forecast, observation(event_at: ~U[2026-09-03 00:00:01Z]))

      assert {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader())
      assert result.status == :rejected
      assert result.reason == :event_outside_horizon
    end

    test "publication outside the closed policy is rejected", ctx do
      {:ok, outcome} =
        Observation.bind(ctx.forecast, observation(published_at: ~U[2026-09-09 00:00:00Z]))

      assert {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader())
      assert result.status == :rejected
      assert result.reason == :publication_outside_policy
    end

    test "an unparsable evidence payload is rejected", ctx do
      raw = "this is not json"

      {:ok, outcome} =
        Observation.bind(ctx.forecast, observation(evidence_digest: :crypto.hash(:sha256, raw)))

      assert {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader(raw))
      assert result.status == :rejected
      assert result.reason == :evidence_parse_failed
    end

    test "the legacy observed_at is not substituted for the event time", ctx do
      obs = observation() |> Keyword.delete(:event_at)

      {:ok, outcome} = Observation.bind(ctx.forecast, obs)

      # The legacy field is carried, but it is not an event time.
      assert outcome.event_at == nil

      {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader())
      assert result.status == :unverified
      assert result.reason == :event_timestamp_missing
    end

    test "the acquisition time is not substituted for the event time", ctx do
      obs =
        observation()
        |> Keyword.delete(:event_at)
        |> Keyword.put(:acquired_at, ~U[2026-09-02 00:05:00Z])

      {:ok, outcome} = Observation.bind(ctx.forecast, obs)

      assert outcome.event_at == nil
      assert outcome.acquired_at == ~U[2026-09-02 00:05:00Z]

      {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader())
      assert result.status == :unverified
      assert result.reason == :event_timestamp_missing
    end

    test "a forecast registered after the relevant information was available is refused", ctx do
      # The registered forecast was created after its target period elapsed,
      # so the event cannot be a prospective outcome of it.
      assert DateTime.compare(ctx.forecast.created_at, ctx.horizon.end_at) == :gt

      {:ok, outcome} = Observation.bind(ctx.forecast, observation())
      {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader())
      {:ok, applied} = OutcomeVerifier.apply(result, outcome)

      # It is refused as hindsight contamination, not resolved and presented
      # as a prospective prediction.
      assert {:error, :hindsight_contamination} =
               OutcomeResolution.resolve(
                 ctx.forecast,
                 applied,
                 %{evidence_class: :simulated, execution_mode: :simulation},
                 result,
                 reader()
               )
    end

    test "an adapter cannot certify its own observation", ctx do
      # The adapter sets every self-asserted field it controls. The binding
      # refuses the claim outright rather than silently downgrading it.
      assert {:error, :verification_status_not_acceptable_at_binding} =
               Observation.bind(
                 ctx.forecast,
                 observation(
                   verification_status: :verified,
                   verified_at: ~U[2026-09-02 00:06:00Z]
                 )
               )

      # And with no claim present, the verdict is the verifier's own.
      {:ok, outcome} = Observation.bind(ctx.forecast, observation())

      assert {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader())
      assert result.status == :verified_with_limited_source_assurance
      assert result.assurance.publisher_authenticity == :not_established
    end
  end

  describe "the verification transition" do
    test "a verification result applies to the observation it belongs to", ctx do
      {:ok, outcome} = Observation.bind(ctx.forecast, observation())
      {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader())

      assert {:ok, applied} = OutcomeVerifier.apply(result, outcome)
      assert applied.verification_status == :verified_with_limited_source_assurance
      assert applied.verified_at == result.verified_at
      assert applied.verification_policy_version == OutcomeVerifier.policy_version()
      assert Outcome.eligible_for_resolution?(applied)
    end

    test "a verification result for another observation is refused", ctx do
      {:ok, outcome} = Observation.bind(ctx.forecast, observation())
      {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader())

      other = %{outcome | observation_id: "obs-other"}

      assert {:error, :verification_observation_mismatch} =
               OutcomeVerifier.apply(result, other)
    end

    test "a tampered verification record is refused", ctx do
      {:ok, outcome} = Observation.bind(ctx.forecast, observation())
      {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader())

      tampered = Map.put(result, :status, :verified)

      assert {:error, :verification_record_tampered} =
               OutcomeVerifier.apply(tampered, outcome)
    end

    test "an unsupported verification policy is refused", ctx do
      {:ok, outcome} = Observation.bind(ctx.forecast, observation())
      {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader())

      tampered = Map.put(result, :verification_policy_version, "efdi-verification-v0")

      assert {:error, :verification_policy_unsupported} =
               OutcomeVerifier.apply(tampered, outcome)
    end

    test "an observation altered after verification is refused", ctx do
      {:ok, outcome} = Observation.bind(ctx.forecast, observation())
      {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader())

      # The observed value is changed after the evidence was verified.
      mutated = %{outcome | observed_outcome: "no"}

      assert {:error, :observation_content_tampered} =
               OutcomeVerifier.apply(result, mutated)
    end

    test "a negative verdict is applied and leaves the observation ineligible", ctx do
      {:ok, outcome} = Observation.bind(ctx.forecast, observation())
      outcome = %{outcome | source_identity: nil}

      {:ok, result} = OutcomeVerifier.verify(ctx.forecast, outcome, reader())
      assert result.status == :unverified

      assert {:ok, applied} = OutcomeVerifier.apply(result, outcome)
      assert applied.verification_status == :unverified
      refute Outcome.eligible_for_resolution?(applied)
    end
  end

  describe "legacy outcomes" do
    test "a legacy outcome is classified unverified and is not eligible", ctx do
      later = DateTime.add(ctx.forecast.created_at, 3600, :second)
      legacy = Outcome.new(ctx.forecast.id, "yes", observed_at: later)

      assert Outcome.classification(legacy) == :legacy_unverified
      refute Outcome.bound?(legacy)
      refute Outcome.eligible_for_resolution?(legacy)
    end

    test "a legacy outcome cannot be resolved", ctx do
      later = DateTime.add(ctx.forecast.created_at, 3600, :second)
      legacy = Outcome.new(ctx.forecast.id, "yes", observed_at: later)

      assert {:error, :legacy_outcome_not_eligible} =
               Tiannara.Forecasting.OutcomeResolution.resolve(ctx.forecast, legacy, %{
                 evidence_class: :simulated,
                 execution_mode: :simulation
               })
    end
  end
end
