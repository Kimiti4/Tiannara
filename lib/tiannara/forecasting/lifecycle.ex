defmodule Tiannara.Forecasting.Lifecycle do
  @moduledoc """
  Truthful lifecycle and assurance observability for the forecast lifecycle.

  This module answers one question: **where has the lifecycle actually
  reached, and what has actually been established?** It exists because the
  difference between "no observation", "an observation that was acquired but
  not verified", "an observation verified with limited source assurance" and
  "an outcome that was resolved" is exactly the difference a status flag
  collapses.

  ## Rules it follows

    * It never reports `operational`, `healthy` or a zero failure count as a
      default. A count is zero because nothing happened, and it says so.
    * It never collapses materially different conditions. The lifecycle state
      and the per-stage counts are reported separately.
    * It never reports a state that was not reached.
    * When the ledger itself is unavailable, it reports that fact and
      **presents no counts at all**, rather than presenting zeros that would
      read as "nothing happened".

  ## Scope

  The ledger is **process-scoped**. It does not survive a restart. Durable
  resolution persistence is not implemented and is registered as `TCP-B-064`;
  the snapshot says so rather than implying durability it does not have.

  ## It is instrumentation, not a gate

  The lifecycle paths record into this ledger on a best-effort basis. A
  ledger that is down must not stop a forecast from being registered,
  bound, verified or resolved, so a recording failure is never propagated
  into the business path.
  """
  use Agent

  alias Tiannara.Forecasting.ForecastRegistry

  @doc "The registered name of the lifecycle ledger."
  @spec server() :: atom()
  def server, do: Application.get_env(:tiannara, :forecast_lifecycle_name) || __MODULE__

  @spec start_link(keyword()) :: Agent.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, server())
    Agent.start_link(fn -> initial() end, name: name)
  end

  # ------------------------------------------------------------------
  # Recording
  # ------------------------------------------------------------------

  @doc "Records an outcome that was constructed."
  @spec record_outcome(map(), atom()) :: :ok | {:error, atom()}
  def record_outcome(outcome, name \\ server()) when is_map(outcome) do
    update(name, fn state ->
      %{state | outcomes: Map.put(state.outcomes, Map.get(outcome, :id), outcome)}
    end)
  end

  @doc "Records an observation that was bound to a registered forecast."
  @spec record_observation(map(), atom()) :: :ok | {:error, atom()}
  def record_observation(outcome, name \\ server()) when is_map(outcome) do
    update(name, fn state ->
      %{
        state
        | observations: Map.put(state.observations, Map.get(outcome, :observation_id), outcome)
      }
    end)
  end

  @doc "Records a completed verification, whatever its verdict."
  @spec record_verification(map(), atom()) :: :ok | {:error, atom()}
  def record_verification(verification, name \\ server()) when is_map(verification) do
    update(name, fn state ->
      failures =
        if Map.get(verification, :status) == :rejected and
             Map.get(verification, :reason) == :evidence_integrity_failure do
          state.evidence_integrity_failures + 1
        else
          state.evidence_integrity_failures
        end

      %{
        state
        | verifications:
            Map.put(state.verifications, Map.get(verification, :observation_id), verification),
          evidence_integrity_failures: failures
      }
    end)
  end

  @doc "Records a resolution that the canonical resolver produced."
  @spec record_resolution(map(), atom()) :: :ok | {:error, atom()}
  def record_resolution(resolution, name \\ server()) when is_map(resolution) do
    update(name, fn state ->
      %{
        state
        | resolutions: Map.put(state.resolutions, Map.get(resolution, :resolution_id), resolution)
      }
    end)
  end

  @doc "Records a score that was computed for a resolved forecast."
  @spec record_score(map(), atom()) :: :ok | {:error, atom()}
  def record_score(score, name \\ server()) when is_map(score) do
    update(name, fn state -> %{state | scores: state.scores ++ [score]} end)
  end

  @doc """
  Records a source-acquisition attempt.

  `status` is `:acquired`, `:unavailable` or `:failed`. This is how the
  difference between "no source was tried" and "a source was tried and was
  not reachable" becomes visible.
  """
  @spec record_acquisition(map(), atom()) :: :ok | {:error, atom()}
  def record_acquisition(attempt, name \\ server()) when is_map(attempt) do
    update(name, fn state ->
      acquisition = %{
        status: Map.get(attempt, :status, :unavailable),
        attempts: state.acquisition.attempts + 1,
        successes: state.acquisition.successes + acquisition_delta(attempt, :success),
        failures: state.acquisition.failures + acquisition_delta(attempt, :failure),
        source_identity: Map.get(attempt, :source_identity) || state.acquisition.source_identity,
        last_failure: Map.get(attempt, :reason) || state.acquisition.last_failure
      }

      %{state | acquisition: acquisition}
    end)
  end

  @doc "Records a failure to recover a resolution after a restart."
  @spec record_resolution_recovery_failure(atom(), atom()) :: :ok | {:error, atom()}
  def record_resolution_recovery_failure(reason, name \\ server()) when is_atom(reason) do
    update(name, fn state ->
      %{state | resolution_recovery_failures: state.resolution_recovery_failures + 1}
    end)
  end

  # ------------------------------------------------------------------
  # Reading
  # ------------------------------------------------------------------

  @doc """
  The current lifecycle and assurance state.

  When the ledger is unavailable this returns `available: false` and **no
  counts**, because zeros would read as "nothing happened" rather than
  "nothing could be seen".
  """
  @spec snapshot(atom()) :: map()
  def snapshot(name \\ server()) do
    Agent.get(name, &build/1)
  rescue
    _error -> unavailable()
  catch
    :exit, _reason -> unavailable()
  end

  @doc "Whether the lifecycle ledger itself is reachable."
  @spec available?(atom()) :: boolean()
  def available?(name \\ server()) do
    Process.whereis(name) != nil
  end

  defp unavailable do
    %{
      available: false,
      reason: :lifecycle_ledger_unavailable,
      note: "No lifecycle counts are reported because the ledger could not be reached."
    }
  end

  defp initial do
    %{
      outcomes: %{},
      observations: %{},
      verifications: %{},
      resolutions: %{},
      scores: [],
      acquisition: %{
        status: :no_attempt,
        attempts: 0,
        successes: 0,
        failures: 0,
        source_identity: nil,
        last_failure: nil
      },
      evidence_integrity_failures: 0,
      resolution_recovery_failures: 0
    }
  end

  defp update(name, fun) do
    Agent.update(name, fun)
  rescue
    _error -> {:error, :lifecycle_ledger_unavailable}
  catch
    :exit, _reason -> {:error, :lifecycle_ledger_unavailable}
  end

  defp acquisition_delta(attempt, kind) do
    case Map.get(attempt, :status) do
      :acquired when kind == :success -> 1
      :failed when kind == :failure -> 1
      :unavailable when kind == :failure -> 1
      _ -> 0
    end
  end

  # ------------------------------------------------------------------
  # The snapshot
  # ------------------------------------------------------------------

  defp build(state) do
    by_status = Enum.group_by(state.verifications, fn {_id, v} -> Map.get(v, :status) end)

    awaiting =
      state.observations
      |> Map.keys()
      |> Enum.reject(&Map.has_key?(state.verifications, &1))
      |> length()

    resolved = map_size(state.resolutions)

    %{
      available: true,
      generated_at: DateTime.utc_now(),
      scope: :process_scoped,
      durable: false,
      durability_limitation:
        "The lifecycle ledger is process-scoped and does not survive a restart. " <>
          "Durable resolution persistence is not implemented (TCP-B-064).",
      forecasts: forecast_counts(),
      observations: %{
        constructed: map_size(state.outcomes),
        acquired: map_size(state.observations),
        awaiting_verification: awaiting,
        verified: count(by_status, :verified),
        verified_with_limited_source_assurance:
          count(by_status, :verified_with_limited_source_assurance),
        requires_review: count(by_status, :requires_review),
        rejected: count(by_status, :rejected),
        unverified: count(by_status, :unverified),
        unavailable: count(by_status, :unavailable),
        evidence_integrity_failures: state.evidence_integrity_failures
      },
      outcomes: %{
        unresolved: map_size(state.observations) - resolved,
        resolved: resolved,
        resolution_recovery_failures: state.resolution_recovery_failures
      },
      scores: %{
        real_forecast_scores: length(state.scores),
        calibration_readiness: :not_established,
        calibration_limitation: "A single score is not calibration."
      },
      acquisition: state.acquisition,
      verification: %{
        policy_available: true,
        policy_version: Tiannara.Forecasting.OutcomeVerifier.policy_version(),
        publisher_authenticity: :not_established,
        publisher_authenticity_limitation:
          "No publisher signature is verified, so :verified is unreachable."
      },
      assurance: assurance_summary(by_status),
      lifecycle_state: lifecycle_state(state),
      transitions_proven: transitions_proven(state)
    }
  end

  defp count(by_status, status), do: length(Map.get(by_status, status, []))

  defp forecast_counts do
    forecasts =
      ForecastRegistry.all_ids()
      |> Enum.map(fn id ->
        case ForecastRegistry.get(id) do
          {:ok, forecast} -> forecast
          _error -> nil
        end
      end)

    with_horizon =
      Enum.count(forecasts, fn f -> not is_nil(f) and not is_nil(Map.get(f, :typed_horizon)) end)

    %{
      registered: length(forecasts),
      with_typed_horizon: with_horizon,
      without_typed_horizon: length(forecasts) - with_horizon,
      registry_available: true
    }
  rescue
    _error -> registry_unavailable()
  catch
    :exit, _reason -> registry_unavailable()
  end

  defp registry_unavailable do
    %{
      registered: :unavailable,
      with_typed_horizon: :unavailable,
      without_typed_horizon: :unavailable,
      registry_available: false
    }
  end

  # The assurance actually established, aggregated across the verifications
  # that completed. A dimension that was never established is reported as
  # `:not_established`, not as `:established`.
  defp assurance_summary(by_status) do
    completed =
      Enum.flat_map(by_status, fn {_status, entries} ->
        Enum.map(entries, fn {_id, verification} -> verification end)
      end)

    %{
      binding: aggregate(completed, :binding),
      evidence_integrity: aggregate(completed, :evidence_integrity),
      source_identity: aggregate(completed, :source_identity),
      transport_protection: aggregate(completed, :transport_protection),
      publisher_authenticity: :not_established,
      semantic_verification: aggregate(completed, :semantic_verification),
      temporal_eligibility: aggregate(completed, :temporal_eligibility),
      corroboration: :not_required_and_not_available
    }
  end

  defp aggregate([], _dimension), do: :not_established

  defp aggregate(completed, dimension) do
    values = Enum.map(completed, fn v -> Map.get(Map.get(v, :assurance, %{}), dimension) end)

    cond do
      Enum.all?(values, &(&1 == :established)) -> :established
      Enum.any?(values, &(&1 == :failed)) -> :failed
      Enum.any?(values, &(&1 == :established)) -> :partially_established
      true -> :not_established
    end
  end

  defp lifecycle_state(state) do
    cond do
      state.scores != [] ->
        :forecast_scored

      map_size(state.resolutions) > 0 ->
        :outcome_resolved

      verified_any?(state) ->
        :outcome_verified

      map_size(state.observations) > 0 ->
        :observation_acquired

      true ->
        :forecast_registered
    end
  end

  defp transitions_proven(state) do
    []
    |> maybe_push(:observation_acquired, map_size(state.observations) > 0)
    |> maybe_push(:outcome_verified, verified_any?(state))
    |> maybe_push(:outcome_resolved, map_size(state.resolutions) > 0)
    |> maybe_push(:forecast_scored, state.scores != [])
  end

  defp maybe_push(list, _stage, false), do: list
  defp maybe_push(list, stage, true), do: list ++ [stage]

  defp verified_any?(state) do
    Enum.any?(state.verifications, fn {_id, v} ->
      Map.get(v, :status) in [:verified, :verified_with_limited_source_assurance]
    end)
  end
end
