defmodule Tiannara.Forecasting.OutcomeResolutionTest do
  use ExUnit.Case, async: false

  alias Tiannara.Forecasting.Outcome
  alias Tiannara.Forecasting.OutcomeResolution
  alias Tiannara.Forecasting.OutcomeVerifier
  alias Tiannara.Forecasting.Contracts.Forecast
  alias Tiannara.Forecasting.Contracts.Horizon

  setup do
    unless Process.whereis(Tiannara.Forecasting.ForecastRegistry) do
      start_supervised!(Tiannara.Forecasting.ForecastRegistry)
    end

    unless Process.whereis(Tiannara.Forecasting.VerificationAuthority) do
      start_supervised!(Tiannara.Forecasting.VerificationAuthority)
    end

    :ok
  end

  defp horizon do
    {:ok, h} =
      Horizon.from_iso(%{
        start_at: "2026-09-01T00:00:00Z",
        end_at: "2026-09-03T00:00:00Z",
        policy: :closed
      })

    h
  end

  defp forecast do
    h = horizon()

    f = %Forecast{
      id: "f-1",
      question: "Will event occur?",
      outcomes: ["yes", "no"],
      probabilities: [0.7, 0.3],
      forecast_version: "v1",
      created_at: ~U[2026-09-01 00:00:00Z],
      typed_horizon: h,
      outcome_definition_digest: :crypto.hash(:sha256, "definition-1"),
      horizon_digest: Horizon.digest(h)
    }

    {:ok, _} = Tiannara.Forecasting.ForecastRegistry.register(f)
    f
  end

  # The stored evidence. Its digest is what the verifier recomputes.
  defp raw, do: Jason.encode!(%{"outcome" => "yes", "source_record" => "rec-1"})

  defp reader(bytes \\ raw()), do: fn _ref -> {:ok, bytes} end

  # A bound outcome: the digests come from the registered forecast and the
  # evidence reference is present. It is *not* verified.
  defp bound_outcome(f, overrides \\ []) do
    Outcome.new(
      f.id,
      "yes",
      [
        observed_at: ~U[2026-09-02 00:00:00Z],
        event_at: ~U[2026-09-02 00:00:00Z],
        published_at: ~U[2026-09-02 00:00:00Z],
        forecast_digest: Forecast.digest(f),
        outcome_definition_digest: f.outcome_definition_digest,
        horizon_digest: f.horizon_digest,
        evidence_ref: "evidence://1",
        evidence_digest: :crypto.hash(:sha256, raw()),
        source_identity: "test-source"
      ] ++ overrides
    )
  end

  # A bound outcome that the verifier has actually verified, plus the
  # verification record it produced.
  defp verified(f, overrides \\ []) do
    outcome = bound_outcome(f, overrides)
    {:ok, result} = OutcomeVerifier.verify(f, outcome, reader())
    {:ok, verified_outcome} = OutcomeVerifier.apply(result, outcome)
    {verified_outcome, result}
  end

  defp simulation, do: %{evidence_class: :simulated, execution_mode: :simulation}

  test "resolves with explicit simulation evidence without certifying" do
    f = forecast()
    {o, record} = verified(f)

    assert {:ok, r} = OutcomeResolution.resolve(f, o, simulation(), record, reader())

    assert r.status == :resolved_not_certified
    assert r.evidence_status == :simulated_observation
    assert r.model_update == :requires_independent_review
    assert_in_delta r.scores.brier, 0.09, 1.0e-12
  end

  test "the resolution preserves the exact forecast and evidence provenance" do
    f = forecast()
    {o, record} = verified(f)

    assert {:ok, r} = OutcomeResolution.resolve(f, o, simulation(), record, reader())

    assert r.forecast_digest == Forecast.digest(f)
    assert r.outcome_definition_digest == f.outcome_definition_digest
    assert r.horizon_digest == f.horizon_digest
    assert r.observation_id == o.observation_id
    assert r.evidence_digest == o.evidence_digest
    assert r.verification_status == :verified_with_limited_source_assurance
    assert r.verification_record_digest == record.record_digest
  end

  test "rejects forecast id mismatch" do
    f = forecast()
    o = Outcome.new("other", "yes", observed_at: ~U[2026-09-02 00:00:00Z])

    assert {:error, :forecast_id_mismatch} = OutcomeResolution.resolve(f, o)
  end

  test "rejects hindsight contamination" do
    f = forecast()
    o = Outcome.new(f.id, "yes", observed_at: ~U[2026-08-31 23:59:59Z])

    assert {:error, :hindsight_contamination} = OutcomeResolution.resolve(f, o)
  end

  test "real evidence requires real execution" do
    f = forecast()
    {o, record} = verified(f)

    assert {:error, :real_evidence_requires_real_execution} =
             OutcomeResolution.resolve(
               f,
               o,
               %{evidence_class: :real, execution_mode: :simulation},
               record,
               reader()
             )
  end

  test "a legacy outcome without provenance is not eligible for resolution" do
    f = forecast()
    o = Outcome.new(f.id, "yes", observed_at: ~U[2026-09-02 00:00:00Z])

    assert {:error, :legacy_outcome_not_eligible} =
             OutcomeResolution.resolve(f, o, simulation())
  end

  test "rejects a substituted forecast digest" do
    f = forecast()
    o = bound_outcome(f, forecast_digest: :crypto.hash(:sha256, "other"))

    assert {:error, :forecast_digest_mismatch} =
             OutcomeResolution.resolve(f, o, simulation())
  end

  test "rejects a substituted outcome-definition digest" do
    f = forecast()
    o = bound_outcome(f, outcome_definition_digest: :crypto.hash(:sha256, "other"))

    assert {:error, :outcome_definition_digest_mismatch} =
             OutcomeResolution.resolve(f, o, simulation())
  end

  test "rejects a substituted horizon digest" do
    f = forecast()
    o = bound_outcome(f, horizon_digest: :crypto.hash(:sha256, "other"))

    assert {:error, :horizon_digest_mismatch} =
             OutcomeResolution.resolve(f, o, simulation())
  end

  test "rejects an event outside the registered horizon" do
    f = forecast()

    o =
      bound_outcome(f, event_at: ~U[2026-09-05 00:00:00Z], observed_at: ~U[2026-09-05 00:00:00Z])

    assert {:error, :event_outside_horizon} =
             OutcomeResolution.resolve(f, o, simulation())
  end

  test "rejects a missing event timestamp" do
    f = forecast()
    o = bound_outcome(f)
    # The event time is what the horizon is evaluated against; the legacy
    # observed_at alone is not sufficient.
    o = %{o | event_at: nil}

    assert {:error, :event_timestamp_missing} =
             OutcomeResolution.resolve(f, o, simulation())
  end

  test "rejects publication outside the closed policy" do
    f = forecast()
    o = bound_outcome(f, published_at: ~U[2026-09-04 00:00:00Z])

    assert {:error, :publication_outside_policy} =
             OutcomeResolution.resolve(f, o, simulation())
  end

  test "rejects a forecast without a typed horizon" do
    # The outcome stays bound so that the horizon check, not the binding
    # check, is the reason it is refused.
    f = %Forecast{
      id: "f-no-horizon",
      question: "Will event occur?",
      outcomes: ["yes", "no"],
      probabilities: [0.7, 0.3],
      forecast_version: "v1",
      created_at: ~U[2026-09-01 00:00:00Z],
      typed_horizon: nil,
      outcome_definition_digest: :crypto.hash(:sha256, "definition-1"),
      horizon_digest: :crypto.hash(:sha256, "horizon")
    }

    {:ok, _} = Tiannara.Forecasting.ForecastRegistry.register(f)

    o = bound_outcome(f)

    assert {:error, :typed_horizon_missing} =
             OutcomeResolution.resolve(f, o, simulation(), nil, reader())
  end

  test "an event exactly at the horizon start resolves" do
    f = forecast()

    {o, record} =
      verified(f, event_at: ~U[2026-09-01 00:00:00Z], observed_at: ~U[2026-09-01 00:00:00Z])

    assert {:ok, _r} = OutcomeResolution.resolve(f, o, simulation(), record, reader())
  end

  test "an event exactly at the horizon end resolves" do
    o_at = [event_at: ~U[2026-09-03 00:00:00Z], observed_at: ~U[2026-09-03 00:00:00Z]]
    f = forecast()
    {o, record} = verified(f, o_at)

    assert {:ok, _r} = OutcomeResolution.resolve(f, o, simulation(), record, reader())
  end

  test "an event one second after the horizon end is refused" do
    o_at = [event_at: ~U[2026-09-03 00:00:01Z], observed_at: ~U[2026-09-03 00:00:01Z]]
    f = forecast()
    {o, record} = verified(f, o_at)

    assert {:error, :event_outside_horizon} =
             OutcomeResolution.resolve(f, o, simulation(), record, reader())
  end

  test "publication exactly at the horizon end is eligible under the closed policy" do
    f = forecast()
    {o, record} = verified(f, published_at: ~U[2026-09-03 00:00:00Z])

    assert {:ok, _r} = OutcomeResolution.resolve(f, o, simulation(), record, reader())
  end

  test "publication one second after the horizon end is refused" do
    f = forecast()
    {o, record} = verified(f, published_at: ~U[2026-09-03 00:00:01Z])

    assert {:error, :publication_outside_policy} =
             OutcomeResolution.resolve(f, o, simulation(), record, reader())
  end

  # ---------------------------------------------------------------
  # The verification record is required
  # ---------------------------------------------------------------

  test "refuses a resolution with no verification record" do
    f = forecast()
    # An adapter that asserts its own verification, without a record.
    o = bound_outcome(f, verification_status: :verified_with_limited_source_assurance)

    assert {:error, :verification_record_missing} =
             OutcomeResolution.resolve(f, o, simulation())
  end

  test "refuses a verification record bound to another observation" do
    f = forecast()
    {_o, record} = verified(f)
    other = bound_outcome(f, observation_id: "obs-other")

    assert {:error, :verification_observation_mismatch} =
             OutcomeResolution.resolve(f, other, simulation(), record, reader())
  end

  test "refuses a tampered verification record" do
    f = forecast()
    {o, record} = verified(f)
    tampered = Map.put(record, :status, :verified)

    assert {:error, :verification_record_unauthentic} =
             OutcomeResolution.resolve(f, o, simulation(), tampered, reader())
  end

  test "refuses a verification record whose evidence digest does not match" do

    f = forecast()
    {_o, record} = verified(f)
    o = bound_outcome(f, evidence_digest: :crypto.hash(:sha256, "other"))

    assert {:error, :verification_evidence_mismatch} =
             OutcomeResolution.resolve(f, o, simulation(), record, reader())
  end

  test "refuses a verification record whose forecast digest does not match" do
    f = forecast()
    o = bound_outcome(f)

    # The record was produced against a different forecast. The record's own
    # digest is intact; it is the forecast it was verified against that does
    # not match the forecast being resolved.
    other = %{f | outcome_definition_digest: :crypto.hash(:sha256, "other")}
    {:ok, record} = OutcomeVerifier.verify(other, o, reader())

    assert {:error, :verification_forecast_digest_mismatch} =
             OutcomeResolution.resolve(f, o, simulation(), record, reader())
  end

  test "refuses a verification record reporting a status the outcome does not carry" do
    f = forecast()
    # The outcome was never taken through the verification transition, so it
    # still carries :unverified.
    o = bound_outcome(f)
    {_verified, record} = verified(f)

    assert {:error, :verification_status_mismatch} =
             OutcomeResolution.resolve(f, o, simulation(), record, reader())
  end

  test "refuses an observation mutated after it was verified" do
    f = forecast()
    {o, record} = verified(f)

    # The observed value is changed after verification. The record binds the
    # observation's content, so the change is detected.
    mutated = Map.put(o, :observed_outcome, "no")

    assert {:error, :observation_content_tampered} =
             OutcomeResolution.resolve(f, mutated, simulation(), record, reader())
  end

  test "refuses a verification whose verdict is not sufficient" do
    f = forecast()
    # The source identity is missing, so the verifier cannot establish it and
    # the verdict is :unverified.
    o = bound_outcome(f, source_identity: nil)

    {:ok, record} = OutcomeVerifier.verify(f, o, reader())
    assert record.status == :unverified
    assert record.reason == :source_identity_missing

    {:ok, applied} = OutcomeVerifier.apply(record, o)
    assert applied.verification_status == :unverified

    assert {:error, :verification_not_sufficient} =
             OutcomeResolution.resolve(f, applied, simulation(), record, reader())
  end

  test "an event outside the horizon is refused at the horizon boundary" do
    f = forecast()

    o =
      bound_outcome(f, event_at: ~U[2026-09-05 00:00:00Z], observed_at: ~U[2026-09-05 00:00:00Z])

    # The verifier also rejects this evidence, but the resolver refuses it
    # at the forecast's own horizon first, and says so.
    {:ok, record} = OutcomeVerifier.verify(f, o, reader())
    assert record.status == :rejected
    assert record.reason == :event_outside_horizon

    {:ok, applied} = OutcomeVerifier.apply(record, o)

    assert {:error, :event_outside_horizon} =
             OutcomeResolution.resolve(f, applied, simulation(), record, reader())
  end
end
