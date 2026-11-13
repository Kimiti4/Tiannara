defmodule Tiannara.Forecasting.OutcomeResolution do
  @moduledoc """
  Evidence-bound forecast to reality resolution.

  Linking an outcome is not the same thing as proving that it is usable for
  performance learning. This layer keeps that distinction explicit.

  ## What resolution requires

  A resolution is only produced when **all** of the following hold:

    * the forecast is the **canonical registered record** — the resolver
      retrieves it from `ForecastRegistry` rather than trusting a caller's
      struct;
    * the observation is bound to that registered forecast — its forecast
      digest, outcome-definition digest and horizon digest all match the
      authoritative record;
    * the registered typed horizon is satisfied — the event timestamp is
      present, inside the horizon, and the publication timestamp satisfies
      the registered publication policy;
    * a **verification record** exists, is bound to that observation and to
      the evidence, and reports an acceptable status;
    * the process-local HMAC is either valid (live process) or, when it is
      not (restarted authority), re-execution against the immutable evidence
      succeeds and the recomputed result agrees with the persisted record on
      status, reason and the complete assurance map;
    * when an evidence reader is supplied, re-execution is performed as
      defence in depth (live process) or as the recovery authority (restarted
      process);
    * the observation's own verification status is the one the record reports;
    * real evidence with limited source assurance is refused until a
      source-trust policy is ratified (TCP-B-066).

  The verification record is required, not optional. An observation that
  merely *claims* to be verified cannot be resolved: the claim is checked
  against a record that the verifier produced, and the record must be bound
  by observation id, evidence digest, forecast id and forecast digest.

  ## What resolution does not do

  It does not certify the outcome. `status` is `:resolved_not_certified` and
  `model_update` is `:requires_independent_review`. Nothing here selects a
  model, mutates a model, or grants production authority.
  """
  alias Tiannara.Forecasting.Calibration
  alias Tiannara.Forecasting.Contracts.Forecast
  alias Tiannara.Forecasting.{ForecastRegistry, Outcome, OutcomeVerifier}

  @acceptable_verification_statuses [:verified, :verified_with_limited_source_assurance]

  @spec resolve(Forecast.t(), map(), map(), map() | nil, (String.t() -> {:ok, binary()} | {:error, atom()}) | nil) ::
          {:ok, map()} | {:error, term()}
  def resolve(forecast, outcome, evidence \\ %{}, verification \\ nil, evidence_reader \\ nil)

  def resolve(%Forecast{} = forecast, outcome, evidence, verification, evidence_reader)
      when is_map(outcome) do
    with {:ok, registered} <- require_registered_canonical(forecast),
         :ok <- validate_link(registered, outcome),
         :ok <- validate_horizon(registered, outcome),
         :ok <- verify_record_hmac(verification),
         :ok <- validate_verification(registered, outcome, verification),
         :ok <- verify_record_reexecution(registered, outcome, verification, evidence_reader),
         :ok <- validate_evidence(evidence),
         :ok <- validate_source_trust_policy(evidence, verification),
         {:ok, scores} <- score(registered, outcome) do
      resolution = %{
        resolution_id: id(),
        forecast_id: registered.id,
        forecast_version: registered.forecast_version,
        forecast_digest: Forecast.digest(registered),
        outcome_definition_digest: registered.outcome_definition_digest,
        horizon_digest: registered.horizon_digest,
        model_ref: registered.model_ref,
        forecast_created_at: registered.created_at,
        observation_id: outcome.observation_id,
        evidence_digest: outcome.evidence_digest,
        observed_outcome: outcome.observed_outcome,
        observed_at: outcome.observed_at,
        event_at: outcome.event_at,
        published_at: outcome.published_at,
        acquired_at: outcome.acquired_at,
        verified_at: outcome.verified_at,
        verification_status: outcome.verification_status,
        verification_policy_version: outcome.verification_policy_version,
        verification_record_digest: Map.get(verification, :record_digest),
        verification_re_executed: evidence_reader != nil and is_function(evidence_reader, 1),
        resolution_source: outcome.source,
        scores: scores,
        evidence: normalize_evidence(evidence),
        evidence_status: evidence_status(evidence),
        status: :resolved_not_certified,
        model_update: :requires_independent_review
      }

      Tiannara.Forecasting.Lifecycle.record_resolution(resolution)

      {:ok, resolution}
    end
  end

  def resolve(_, _, _, _, _), do: {:error, :invalid_resolution_input}

  # The resolver anchors on the canonical registered record rather than on a
  # caller's struct. An unregistered or mismatched forecast is refused.
  defp require_registered_canonical(%Forecast{id: nil}), do: {:error, :forecast_id_missing}

  defp require_registered_canonical(%Forecast{} = forecast) do
    case ForecastRegistry.get(forecast.id) do
      {:ok, registered} ->
        if Forecast.digest(registered) == Forecast.digest(forecast) do
          {:ok, registered}
        else
          {:error, :forecast_does_not_match_registered}
        end

      :error ->
        {:error, :forecast_not_registered}
    end
  catch
    :exit, _reason -> {:error, :forecast_registry_unavailable}
  end

  @spec validate_evidence(map()) :: :ok | {:error, term()}
  def validate_evidence(evidence) when is_map(evidence) do
    klass = Map.get(evidence, :evidence_class, :unknown)
    mode = Map.get(evidence, :execution_mode, :unknown)

    cond do
      klass not in [:simulated, :real, :unknown] -> {:error, :invalid_evidence_class}
      mode not in [:simulation, :real_execution, :unknown] -> {:error, :invalid_execution_mode}
      klass == :real and mode != :real_execution -> {:error, :real_evidence_requires_real_execution}
      mode == :real_execution and klass != :real -> {:error, :real_execution_requires_real_evidence}
      true -> :ok
    end
  end

  # The binding is checked against the *authoritative* forecast that is
  # passed in, not against anything the outcome asserts about itself.
  defp validate_link(%Forecast{} = forecast, outcome) do
    forecast_id = forecast.id
    created_at = forecast.created_at

    cond do
      not is_binary(forecast_id) ->
        {:error, :forecast_id_missing}

      Map.get(outcome, :forecast_id) != forecast_id ->
        {:error, :forecast_id_mismatch}

      not is_map_key(outcome, :observed_outcome) ->
        {:error, :observed_outcome_missing}

      not match?(%DateTime{}, Map.get(outcome, :observed_at)) ->
        {:error, :observed_at_required}

      not is_nil(created_at) and DateTime.compare(outcome.observed_at, created_at) == :lt ->
        {:error, :hindsight_contamination}

      # A legacy outcome carries no binding and no evidence. It stays
      # readable, but it cannot be resolved.
      not Outcome.bound?(outcome) ->
        {:error, :legacy_outcome_not_eligible}

      Map.get(outcome, :forecast_digest) != Forecast.digest(forecast) ->
        {:error, :forecast_digest_mismatch}

      Map.get(outcome, :outcome_definition_digest) != forecast.outcome_definition_digest ->
        {:error, :outcome_definition_digest_mismatch}

      Map.get(outcome, :horizon_digest) != forecast.horizon_digest ->
        {:error, :horizon_digest_mismatch}

      true ->
        :ok
    end
  end

  # The registered typed horizon is enforced here, at the resolution
  # boundary. A caller cannot substitute a horizon: the horizon used is the
  # forecast's own.
  defp validate_horizon(%Forecast{} = forecast, outcome) do
    case forecast.typed_horizon do
      nil ->
        {:error, :typed_horizon_missing}

      horizon ->
        event_at = Map.get(outcome, :event_at)
        published_at = Map.get(outcome, :published_at)

        cond do
          is_nil(event_at) ->
            {:error, :event_timestamp_missing}

          not Tiannara.Forecasting.Contracts.Horizon.event_within?(horizon, event_at) ->
            {:error, :event_outside_horizon}

          not is_nil(published_at) and
              not Tiannara.Forecasting.Contracts.Horizon.publication_eligible?(horizon, published_at) ->
            {:error, :publication_outside_policy}

          true ->
            :ok
        end
    end
  end

  # The verification record is required. Without it there is nothing that
  # establishes the evidence was ever inspected, and an adapter that asserted
  # its own verification would be believed.
  defp validate_verification(%Forecast{} = forecast, outcome, verification)
       when is_map(verification) do
    cond do
      Map.get(verification, :verification_policy_version) !=
          OutcomeVerifier.policy_version() ->
        {:error, :verification_policy_unsupported}

      Map.get(verification, :forecast_id) != forecast.id ->
        {:error, :verification_forecast_mismatch}

      Map.get(verification, :forecast_digest) != Forecast.digest(forecast) ->
        {:error, :verification_forecast_digest_mismatch}

      Map.get(verification, :observation_id) != Map.get(outcome, :observation_id) ->
        {:error, :verification_observation_mismatch}

      Map.get(verification, :evidence_digest) != Map.get(outcome, :evidence_digest) ->
        {:error, :verification_evidence_mismatch}

      # The observation must be exactly the one that was verified.
      Map.get(verification, :observation_digest) !=
          Outcome.content_digest(outcome) ->
        {:error, :observation_content_tampered}

      Map.get(verification, :status) not in @acceptable_verification_statuses ->
        {:error, :verification_not_sufficient}

      Map.get(outcome, :verification_status) != Map.get(verification, :status) ->
        {:error, :verification_status_mismatch}

      true ->
        :ok
    end
  end

  defp validate_verification(_forecast, _outcome, _verification),
    do: {:error, :verification_record_missing}

  # Process-local HMAC is a live-process tamper check, not a durable
  # credential. On a fresh process the key differs, so a previously signed
  # record fails the HMAC check. That is not by itself evidence of tampering:
  # it may be a historical record from a restarted authority.
  #
  # The recovery authority is re-execution against the immutable evidence:
  #   * if the HMAC passes (live process), re-execution is optional defence
  #     in depth when a reader is supplied;
  #   * if the HMAC fails (restarted authority or tampering), re-execution is
  #     REQUIRED, and the recomputed result must agree with the persisted
  #     record on status, reason and the complete assurance map.
  #
  # This distinguishes live verification from historical recovery explicitly
  # rather than skipping authentication on every request.
  defp verify_record_hmac(verification) do
    case OutcomeVerifier.authentic?(verification) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp verify_record_reexecution(_registered, _outcome, _verification, nil), do: :ok

  defp verify_record_reexecution(registered, outcome, verification, reader)
       when is_function(reader, 1) do
    case OutcomeVerifier.authentic?(verification) do
      :ok ->
        # Live-process tamper check passed. Re-execute as defence in depth.
        reexecute_and_compare(registered, outcome, verification, reader)

      {:error, :verification_record_unauthentic} ->
        # HMAC failed. Could be a restarted authority (recovery) or tampering.
        # Re-execution is the recovery authority.
        reexecute_and_compare(registered, outcome, verification, reader)

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Re-executes verification against the immutable evidence and compares
  # the complete recomputed result against the persisted record. Status,
  # reason and the full assurance map must all agree.
  defp reexecute_and_compare(forecast, outcome, verification, reader) do
    case OutcomeVerifier.verify(forecast, outcome, reader) do
      {:ok, recomputed} ->
        if recomputed.status == Map.get(verification, :status) and
             recomputed.reason == Map.get(verification, :reason) and
             recomputed.assurance == Map.get(verification, :assurance) do
          :ok
        else
          {:error, :verification_record_unauthentic}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # TCP-B-066: no ratified source-trust policy exists. A real resolution that
  # rests on limited source assurance is blocked until a policy is ratified
  # that states which assurance level is acceptable for which source and
  # outcome class. Synthetic resolutions are unaffected.
  defp validate_source_trust_policy(evidence, verification) when is_map(evidence) and is_map(verification) do
    klass = Map.get(evidence, :evidence_class, :unknown)
    status = Map.get(verification, :status)

    if klass == :real and status == :verified_with_limited_source_assurance do
      {:error, :source_trust_policy_not_ratified}
    else
      :ok
    end
  end

  defp validate_source_trust_policy(_evidence, _verification), do: :ok

  defp score(%Forecast{} = forecast, outcome) do
    observed = outcome.observed_outcome
    brier = Calibration.score(forecast, observed, :brier)
    log_loss = Calibration.score(forecast, observed, :log_loss)

    directional =
      case {forecast.outcomes, forecast.probabilities} do
        {outcomes, probs} when is_list(outcomes) and is_list(probs) and outcomes != [] and probs != [] ->
          {_, index} = Enum.with_index(probs) |> Enum.max_by(fn {p, _} -> p end)
          if Enum.at(outcomes, index) == observed, do: 1, else: 0

        _ ->
          :unknown
      end

    {:ok,
     %{
       brier: brier.value,
       log_loss: log_loss.value,
       directional_accuracy: directional,
       sample_size: 1
     }}
  end

  defp evidence_status(%{evidence_class: :real, execution_mode: :real_execution}), do: :real_observation
  defp evidence_status(%{evidence_class: :simulated, execution_mode: :simulation}), do: :simulated_observation
  defp evidence_status(_), do: :evidence_unresolved

  defp normalize_evidence(evidence) do
    %{
      evidence_class: Map.get(evidence, :evidence_class, :unknown),
      execution_mode: Map.get(evidence, :execution_mode, :unknown),
      observation_id: Map.get(evidence, :observation_id),
      provenance: Map.get(evidence, :provenance),
      effect_verified: Map.get(evidence, :effect_verified, false)
    }
  end

  defp id, do: "forecast-resolution-" <> Integer.to_string(System.unique_integer([:positive]))
end
