defmodule Tiannara.Forecasting.Observation do
  @moduledoc """
  Acquisition-side construction of an observation bound to a registered forecast.

  This module **acquires**; it does not verify. It records what was retrieved
  and from where. Whether that evidence satisfies the forecast's outcome
  definition is decided by `Tiannara.Forecasting.OutcomeVerifier`, which
  inspects the stored evidence independently.

  The binding values are taken from the registered forecast, never from the
  caller. A caller cannot choose the forecast digest, the outcome-definition
  digest or the horizon digest.
  """
  alias Tiannara.Forecasting.Contracts.Forecast
  alias Tiannara.Forecasting.Outcome

  @doc """
  Binds an acquired observation to a registered forecast.

  Returns `{:ok, outcome}` or `{:error, reason}` with an exact reason. The
  registered forecast is retrieved from the canonical registry; if it is not
  registered, the observation cannot be bound.
  """
  @spec bind(Forecast.t(), map()) :: {:ok, Outcome.outcome()} | {:error, atom()}
  def bind(%Forecast{} = forecast, observation) when is_map(observation) do
    observation = Map.new(observation)

    with {:ok, registered} <- require_registered(forecast),
         :ok <- require_match(forecast, registered),
         :ok <- require_unverified(observation),
         {:ok, evidence_ref, evidence_digest} <- require_evidence(observation),
         {:ok, source_identity} <- require_source(observation) do
      bound =
        Outcome.new(registered.id, Map.get(observation, :observed_outcome),
          observation_id:
            Map.get(observation, :observation_id) || Tiannara.Executive.Types.new_id(),
          forecast_digest: Forecast.digest(registered),
          outcome_definition_digest: registered.outcome_definition_digest,
          horizon_digest: registered.horizon_digest,
          source_identity: source_identity,
          source_type: Map.get(observation, :source_type),
          source_record_id: Map.get(observation, :source_record_id),
          evidence_ref: evidence_ref,
          evidence_digest: evidence_digest,
          evidence_schema_version: Map.get(observation, :evidence_schema_version),
          observed_at: Map.get(observation, :event_at) || Map.get(observation, :observed_at),
          event_at: Map.get(observation, :event_at),
          published_at: Map.get(observation, :published_at),
          acquired_at: Map.get(observation, :acquired_at) || DateTime.utc_now(),
          source: Map.get(observation, :source, "acquisition")
        )

      Tiannara.Forecasting.Lifecycle.record_observation(bound)

      {:ok, bound}
    end
  end

  def bind(%Forecast{} = forecast, observation) when is_list(observation) do
    bind(forecast, Map.new(observation))
  end

  def bind(_forecast, _observation), do: {:error, :invalid_observation}

  defp require_registered(%Forecast{id: nil}), do: {:error, :forecast_id_missing}

  # The registered record is the authority. It is returned, not merely
  # checked, so that the binding below is populated from it rather than from
  # the caller's copy of the forecast.
  defp require_registered(%Forecast{} = forecast) do
    case Tiannara.Forecasting.ForecastRegistry.get(forecast.id) do
      {:ok, registered} -> {:ok, registered}
      :error -> {:error, :forecast_not_registered}
    end
  catch
    :exit, _reason -> {:error, :forecast_registry_unavailable}
  end

  # The caller's forecast must be the registered one. A forecast that shares
  # an id but carries a different horizon, version or outcome definition is
  # refused rather than quietly bound.
  defp require_match(%Forecast{} = forecast, %Forecast{} = registered) do
    if Forecast.digest(forecast) == Forecast.digest(registered) do
      :ok
    else
      {:error, :forecast_does_not_match_registered}
    end
  end

  # An observation is bound *before* it is verified. A caller that arrives
  # with a verification status has skipped the verifier, so the binding is
  # refused rather than silently downgraded.
  defp require_unverified(observation) do
    case Map.get(observation, :verification_status) do
      nil ->
        :ok

      :unverified ->
        :ok

      _claimed ->
        {:error, :verification_status_not_acceptable_at_binding}
    end
  end

  defp require_evidence(observation) do
    ref = Map.get(observation, :evidence_ref)
    digest = Map.get(observation, :evidence_digest)

    cond do
      not is_binary(ref) -> {:error, :evidence_reference_missing}
      not is_binary(digest) -> {:error, :evidence_digest_missing}
      true -> {:ok, ref, digest}
    end
  end

  defp require_source(observation) do
    case Map.get(observation, :source_identity) do
      identity when is_binary(identity) and identity != "" -> {:ok, identity}
      _ -> {:error, :source_identity_missing}
    end
  end
end
