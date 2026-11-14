defmodule Tiannara.Forecasting.OutcomeRecoveryTest do
  @moduledoc """
  Genuine application-process restart recovery for the verification authority
  (TCP-002.6-R1). Proves that the production resolver performs historical
  recovery when the process-local HMAC key has changed.
  """
  use ExUnit.Case, async: false

  @moduletag timeout: 60_000

  alias Tiannara.Forecasting.Outcome
  alias Tiannara.Forecasting.OutcomeResolution
  alias Tiannara.Forecasting.OutcomeVerifier
  alias Tiannara.Forecasting.Contracts.Forecast
  alias Tiannara.Forecasting.Contracts.Horizon

  setup do
    unless Process.whereis(Tiannara.Forecasting.ForecastRegistry) do
      start_supervised!(Tiannara.Forecasting.ForecastRegistry)
    end

    # Use a test-private authority so the test can stop and restart it without
    # the application supervisor resurrecting it (or shutting down).
    unique_name = :"va_recovery_#{System.unique_integer([:positive])}"
    Application.put_env(:tiannara, :verification_authority_name, unique_name)
    {:ok, _} = Tiannara.Forecasting.VerificationAuthority.start_link(name: unique_name)

    on_exit(fn ->
      Application.delete_env(:tiannara, :verification_authority_name)
    end)

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
      id: "f-recovery",
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

  defp raw, do: Jason.encode!(%{"outcome" => "yes", "source_record" => "rec-1"})

  defp reader(bytes \\ raw()), do: fn _ref -> {:ok, bytes} end

  defp bound_outcome(f) do
    Outcome.new(f.id, "yes",
      observed_at: ~U[2026-09-02 00:00:00Z],
      event_at: ~U[2026-09-02 00:00:00Z],
      published_at: ~U[2026-09-02 00:00:00Z],
      forecast_digest: Forecast.digest(f),
      outcome_definition_digest: f.outcome_definition_digest,
      horizon_digest: f.horizon_digest,
      evidence_ref: "evidence://1",
      evidence_digest: :crypto.hash(:sha256, raw()),
      source_identity: "test-source"
    )
  end

  defp simulation, do: %{evidence_class: :simulated, execution_mode: :simulation}

  test "historical recovery succeeds after a verification-authority restart" do
    f = forecast()
    o = bound_outcome(f)

    {:ok, record} = OutcomeVerifier.verify(f, o, reader())
    assert record.status == :verified_with_limited_source_assurance

    {:ok, verified_outcome} = OutcomeVerifier.apply(record, o)
    assert verified_outcome.verification_status == :verified_with_limited_source_assurance

    authority_name = Tiannara.Forecasting.VerificationAuthority.server()
    GenServer.stop(Process.whereis(authority_name), :normal)
    {:ok, _} = Tiannara.Forecasting.VerificationAuthority.start_link(name: authority_name)

    assert {:error, :verification_record_unauthentic} =
             Tiannara.Forecasting.VerificationAuthority.verify(record)

    assert {:ok, resolution} =
             OutcomeResolution.resolve(f, verified_outcome, simulation(), record, reader())

    assert resolution.verification_re_executed == true
    assert resolution.status == :resolved_not_certified
    assert resolution.model_update == :requires_independent_review
  end

  test "historical recovery is refused without an evidence reader" do
    f = forecast()
    o = bound_outcome(f)
    {:ok, record} = OutcomeVerifier.verify(f, o, reader())
    {:ok, verified_outcome} = OutcomeVerifier.apply(record, o)

    authority_name = Tiannara.Forecasting.VerificationAuthority.server()
    GenServer.stop(Process.whereis(authority_name), :normal)
    {:ok, _} = Tiannara.Forecasting.VerificationAuthority.start_link(name: authority_name)

    assert {:error, :verification_record_unauthentic} =
             OutcomeResolution.resolve(f, verified_outcome, simulation(), record, nil)
  end

  test "historical recovery is refused when the evidence has been altered" do
    f = forecast()
    o = bound_outcome(f)
    {:ok, record} = OutcomeVerifier.verify(f, o, reader())
    {:ok, verified_outcome} = OutcomeVerifier.apply(record, o)

    authority_name = Tiannara.Forecasting.VerificationAuthority.server()
    GenServer.stop(Process.whereis(authority_name), :normal)
    {:ok, _} = Tiannara.Forecasting.VerificationAuthority.start_link(name: authority_name)

    tampered_bytes = Jason.encode!(%{"outcome" => "no"})
    assert {:error, :verification_record_unauthentic} =
             OutcomeResolution.resolve(
               f,
               verified_outcome,
               simulation(),
               record,
               reader(tampered_bytes)
             )
  end

  test "historical recovery is refused when the evidence is missing" do
    f = forecast()
    o = bound_outcome(f)
    {:ok, record} = OutcomeVerifier.verify(f, o, reader())
    {:ok, verified_outcome} = OutcomeVerifier.apply(record, o)

    authority_name = Tiannara.Forecasting.VerificationAuthority.server()
    GenServer.stop(Process.whereis(authority_name), :normal)
    {:ok, _} = Tiannara.Forecasting.VerificationAuthority.start_link(name: authority_name)

    assert {:error, :verification_record_unauthentic} =
             OutcomeResolution.resolve(
               f,
               verified_outcome,
               simulation(),
               record,
               fn _ref -> {:error, :evidence_store_unavailable} end
             )
  end

  test "historical recovery is refused when the verification record is tampered" do
    f = forecast()
    o = bound_outcome(f)
    {:ok, record} = OutcomeVerifier.verify(f, o, reader())
    {:ok, verified_outcome} = OutcomeVerifier.apply(record, o)

    authority_name = Tiannara.Forecasting.VerificationAuthority.server()
    GenServer.stop(Process.whereis(authority_name), :normal)
    {:ok, _} = Tiannara.Forecasting.VerificationAuthority.start_link(name: authority_name)

    tampered = Map.put(record, :status, :verified)

    assert {:error, :verification_status_mismatch} =
             OutcomeResolution.resolve(
               f,
               verified_outcome,
               simulation(),
               tampered,
               reader()
             )
  end

  test "historical recovery is refused when the assurance map is tampered" do
    f = forecast()
    o = bound_outcome(f)
    {:ok, record} = OutcomeVerifier.verify(f, o, reader())
    {:ok, verified_outcome} = OutcomeVerifier.apply(record, o)

    authority_name = Tiannara.Forecasting.VerificationAuthority.server()
    GenServer.stop(Process.whereis(authority_name), :normal)
    {:ok, _} = Tiannara.Forecasting.VerificationAuthority.start_link(name: authority_name)

    tampered = Map.put(record, :assurance, Map.put(record.assurance, :semantic_verification, :failed))

    assert {:error, :verification_record_unauthentic} =
             OutcomeResolution.resolve(
               f,
               verified_outcome,
               simulation(),
               tampered,
               reader()
             )
  end

  test "historical recovery is refused when the forecast binding is tampered" do
    f = forecast()
    o = bound_outcome(f)
    {:ok, record} = OutcomeVerifier.verify(f, o, reader())
    {:ok, verified_outcome} = OutcomeVerifier.apply(record, o)

    authority_name = Tiannara.Forecasting.VerificationAuthority.server()
    GenServer.stop(Process.whereis(authority_name), :normal)
    {:ok, _} = Tiannara.Forecasting.VerificationAuthority.start_link(name: authority_name)

    tampered = Map.put(record, :forecast_digest, :crypto.hash(:sha256, "other"))

    assert {:error, :verification_forecast_digest_mismatch} =
             OutcomeResolution.resolve(
               f,
               verified_outcome,
               simulation(),
               tampered,
               reader()
             )
  end

  test "historical recovery is refused when the observation-content binding is tampered" do
    f = forecast()
    o = bound_outcome(f)
    {:ok, record} = OutcomeVerifier.verify(f, o, reader())
    {:ok, verified_outcome} = OutcomeVerifier.apply(record, o)

    authority_name = Tiannara.Forecasting.VerificationAuthority.server()
    GenServer.stop(Process.whereis(authority_name), :normal)
    {:ok, _} = Tiannara.Forecasting.VerificationAuthority.start_link(name: authority_name)

    tampered = Map.put(record, :observation_digest, :crypto.hash(:sha256, "other"))

    assert {:error, :observation_content_tampered} =
             OutcomeResolution.resolve(
               f,
               verified_outcome,
               simulation(),
               tampered,
               reader()
             )
  end


  test "historical recovery is refused when the outcome-definition digest is tampered" do
    f = forecast()
    o = bound_outcome(f)
    {:ok, record} = OutcomeVerifier.verify(f, o, reader())
    {:ok, verified_outcome} = OutcomeVerifier.apply(record, o)

    authority_name = Tiannara.Forecasting.VerificationAuthority.server()
    GenServer.stop(Process.whereis(authority_name), :normal)
    {:ok, _} = Tiannara.Forecasting.VerificationAuthority.start_link(name: authority_name)

    tampered = Map.put(record, :outcome_definition_digest, :crypto.hash(:sha256, "other"))

    assert {:error, :verification_record_unauthentic} =
             OutcomeResolution.resolve(f, verified_outcome, simulation(), tampered, reader())
  end

  test "historical recovery is refused when the horizon digest is tampered" do
    f = forecast()
    o = bound_outcome(f)
    {:ok, record} = OutcomeVerifier.verify(f, o, reader())
    {:ok, verified_outcome} = OutcomeVerifier.apply(record, o)

    authority_name = Tiannara.Forecasting.VerificationAuthority.server()
    GenServer.stop(Process.whereis(authority_name), :normal)
    {:ok, _} = Tiannara.Forecasting.VerificationAuthority.start_link(name: authority_name)

    tampered = Map.put(record, :horizon_digest, :crypto.hash(:sha256, "other"))

    assert {:error, :verification_record_unauthentic} =
             OutcomeResolution.resolve(f, verified_outcome, simulation(), tampered, reader())
  end

  test "historical recovery is refused when the source identity is tampered" do
    f = forecast()
    o = bound_outcome(f)
    {:ok, record} = OutcomeVerifier.verify(f, o, reader())
    {:ok, verified_outcome} = OutcomeVerifier.apply(record, o)

    authority_name = Tiannara.Forecasting.VerificationAuthority.server()
    GenServer.stop(Process.whereis(authority_name), :normal)
    {:ok, _} = Tiannara.Forecasting.VerificationAuthority.start_link(name: authority_name)

    tampered = Map.put(record, :source_identity, "evil-source")

    assert {:error, :verification_record_unauthentic} =
             OutcomeResolution.resolve(f, verified_outcome, simulation(), tampered, reader())
  end

  test "historical recovery is refused when the evidence digest is tampered" do
    f = forecast()
    o = bound_outcome(f)
    {:ok, record} = OutcomeVerifier.verify(f, o, reader())
    {:ok, verified_outcome} = OutcomeVerifier.apply(record, o)

    authority_name = Tiannara.Forecasting.VerificationAuthority.server()
    GenServer.stop(Process.whereis(authority_name), :normal)
    {:ok, _} = Tiannara.Forecasting.VerificationAuthority.start_link(name: authority_name)

    tampered = Map.put(record, :evidence_digest, :crypto.hash(:sha256, "other"))

    assert {:error, :verification_evidence_mismatch} =
             OutcomeResolution.resolve(f, verified_outcome, simulation(), tampered, reader())
  end

  test "historical recovery is refused when the forecast id is tampered" do
    f = forecast()
    o = bound_outcome(f)
    {:ok, record} = OutcomeVerifier.verify(f, o, reader())
    {:ok, verified_outcome} = OutcomeVerifier.apply(record, o)

    authority_name = Tiannara.Forecasting.VerificationAuthority.server()
    GenServer.stop(Process.whereis(authority_name), :normal)
    {:ok, _} = Tiannara.Forecasting.VerificationAuthority.start_link(name: authority_name)

    tampered = Map.put(record, :forecast_id, "evil-forecast")

    assert {:error, :verification_forecast_mismatch} =
             OutcomeResolution.resolve(f, verified_outcome, simulation(), tampered, reader())
  end

  test "historical recovery is refused when the observation id is tampered" do
    f = forecast()
    o = bound_outcome(f)
    {:ok, record} = OutcomeVerifier.verify(f, o, reader())
    {:ok, verified_outcome} = OutcomeVerifier.apply(record, o)

    authority_name = Tiannara.Forecasting.VerificationAuthority.server()
    GenServer.stop(Process.whereis(authority_name), :normal)
    {:ok, _} = Tiannara.Forecasting.VerificationAuthority.start_link(name: authority_name)

    tampered = Map.put(record, :observation_id, "evil-obs")

    assert {:error, :verification_observation_mismatch} =
             OutcomeResolution.resolve(f, verified_outcome, simulation(), tampered, reader())
  end
end
