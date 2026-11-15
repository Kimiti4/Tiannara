defmodule Tiannara.Forecasting.ResolutionRegistry do
  @moduledoc """
  Durable persistence and replay for forecast outcome resolutions.

  This is the **storage** authority for resolutions. It is not a resolution
  authority: `Tiannara.Forecasting.OutcomeResolution` remains the sole authority
  that decides whether a resolution may be produced. This module only appends,
  retrieves, replays and deduplicates the records that authority produces.

  ## Durability

  The ETS table is an **index**, not the record of truth. The durable record is
  the `efdi.forecast.resolved` event in `Tiannara.Executive.EventStore`, an
  append-only framed log on disk.

  ## Transactional recovery

  Recovery is a three-stage transaction:

    1. **Read** — obtain the complete history and all storage diagnostics;
    2. **Build** — construct a candidate index in memory, validating every
       resolution event, its identity and forecast-id uniqueness;
    3. **Publish** — replace the single published index object atomically,
       and only if stages 1 and 2 succeeded.

  A failure in any stage leaves no partial candidate authoritative. The
  previously published index is invalidated and normal lookups refuse to
  claim verified durability until a later recovery succeeds.

  ## Trust rules

  `get/1`, `all_ids/0`, `count/0` and `commit/1` are **trusted** operations:
  they succeed only while the registry is published, its index was built from
  a complete verified history, and the EventStore still reports a verified,
  appendable history. Otherwise they return `{:error, :registry_not_verified}`
  or `{:error, :registry_degraded}`.

  `durable: true` in `health/0` is therefore not derived from "the process is
  alive" or "degraded is false". It requires a verified EventStore history, a
  published index built from that history, and a live EventStore health check
  that still agrees.

  ## Idempotency and conflict

  An exact retry of an already committed resolution returns the original
  persisted record without appending another event. A conflicting resolution
  for an already-resolved forecast is rejected with `:resolution_conflict`.

  ## Duplicate history

  Two durable resolution events for the same forecast are a history-consistency
  finding, never a second canonical resolution:

    * identical resolution identity — `:duplicate_identical_resolution_event`;
    * different identity — `:conflicting_forecast_resolutions`.

  In both cases recovery fails closed. The duplicate is not counted as a
  resolution and no index is published.

  ## Instance isolation

  The ETS table is named after the registered instance, and the EventStore
  instance can be supplied explicitly via `:event_store_name`, so an isolated
  registry can be started without colliding with the application-wide one.
  """
  use GenServer

  require Logger

  alias Tiannara.Executive.EventStore

  @event_type "efdi.forecast.resolved"
  @index_key :__resolution_index__
  @trusted_integrities [:verified, :empty_verified]

  @required_resolution_fields [
    :resolution_id,
    :forecast_id,
    :forecast_version,
    :forecast_digest,
    :outcome_definition_digest,
    :horizon_digest,
    :model_ref,
    :forecast_created_at,
    :observation_id,
    :evidence_digest,
    :observed_outcome,
    :observed_at,
    :event_at,
    :published_at,
    :acquired_at,
    :verified_at,
    :verification_status,
    :verification_policy_version,
    :verification_record_digest,
    :resolution_source,
    :scores,
    :status
  ]

  # ------------------------------------------------------------------
  # Client API
  # ------------------------------------------------------------------

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, server())
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "The registered name of the resolution registry."
  @spec server() :: atom()
  def server, do: Application.get_env(:tiannara, :resolution_registry_name) || __MODULE__

  @doc "The ETS table backing a registry instance."
  @spec table(atom()) :: atom()
  def table(name \\ server()), do: :"#{name}_resolutions"

  @doc """
  Commits a resolution durably.

  Returns `{:ok, resolution}` for a newly committed or already-existing
  identical resolution, `{:error, :resolution_conflict}` when a different
  resolution already exists for the forecast, and a typed error otherwise.
  """
  @spec commit(map(), atom()) :: {:ok, map()} | {:error, term()}
  def commit(resolution, name \\ server()) when is_map(resolution) do
    GenServer.call(name, {:commit, resolution})
  end

  @doc """
  Retrieves a resolution by forecast id from the verified index.

  Returns `{:error, :registry_not_verified}` when the index is not
  authoritative for the complete durable history.
  """
  @spec get(String.t(), atom()) :: {:ok, map()} | :error | {:error, term()}
  def get(forecast_id, name \\ server()) when is_binary(forecast_id) do
    GenServer.call(name, {:get, forecast_id})
  end

  @doc "Returns all verified resolution ids."
  @spec all_ids(atom()) :: [String.t()] | {:error, term()}
  def all_ids(name \\ server()), do: GenServer.call(name, :all_ids)

  @doc "Returns the number of verified committed resolutions."
  @spec count(atom()) :: non_neg_integer() | {:error, term()}
  def count(name \\ server()), do: GenServer.call(name, :count)

  @doc "Health of the resolution registry."
  @spec health(atom()) :: map()
  def health(name \\ server()), do: GenServer.call(name, :health)

  @doc """
  Replays the durable lineage and transactionally republishes the index.

  Returns `{:ok, count}` only when the complete EventStore history is
  verified and every resolution event passes semantic validation.
  """
  @spec recover(atom()) :: {:ok, non_neg_integer()} | {:error, term()}
  def recover(name \\ server()), do: GenServer.call(name, :recover)

  # ------------------------------------------------------------------
  # Server callbacks
  # ------------------------------------------------------------------

  @impl true
  def init(opts) do
    name = Keyword.get(opts, :name, server())
    table = :"#{name}_resolutions"
    event_store_name = Keyword.get(opts, :event_store_name, EventStore.server())

    if :ets.info(table) == :undefined do
      :ets.new(table, [:set, :protected, :named_table, read_concurrency: true])
    end

    state = %{
      table: table,
      event_store_name: event_store_name,
      integrity: :not_recovered,
      published: false,
      count: 0,
      recovered_count: 0,
      recovery_error: nil,
      recovery_generation: 0,
      eventstore_health: nil
    }

    case transactional_recover(state) do
      {:ok, index, recovery} ->
        case safe_publish(table, index) do
          :ok ->
            {:ok,
             %{
               state
               | integrity: recovery.integrity,
                 published: true,
                 count: map_size(index),
                 recovered_count: map_size(index),
                 recovery_error: nil,
                 recovery_generation: 1,
                 eventstore_health: recovery.eventstore_health
             }}

          {:error, :publication_failure} ->
            invalidate(table)

            {:ok,
             %{
               state
               | integrity: :degraded,
                 published: false,
                 count: 0,
                 recovered_count: 0,
                 recovery_error: :publication_failure,
                 recovery_generation: 1,
                 eventstore_health: recovery.eventstore_health
             }}
        end

      {:error, reason, recovery} ->
        invalidate(table)

        {:ok,
         %{
           state
           | integrity: :degraded,
             published: false,
             count: 0,
             recovered_count: 0,
             recovery_error: reason,
             recovery_generation: 1,
             eventstore_health: recovery.eventstore_health
         }}
    end
  end

  @impl true
  def handle_call({:commit, resolution}, _from, state) do
    with {:ok, state} <- ensure_trusted(state),
         :ok <- validate_commit_payload(resolution) do
      forecast_id = Map.fetch!(resolution, :forecast_id)

      case lookup(state.table, forecast_id) do
        {:ok, existing} ->
          # Idempotency: exact retry returns the original. This is only
          # reachable while the index is verified.
          if resolution_identity(existing) == resolution_identity(resolution) do
            {:reply, {:ok, existing}, state}
          else
            {:reply, {:error, :resolution_conflict}, state}
          end

        :error ->
          case append_event(resolution, state) do
            {:ok, new_state} ->
              put_entry(new_state.table, forecast_id, resolution)
              count = new_state.count + 1

              {:reply, {:ok, resolution}, %{new_state | count: count, recovered_count: count}}

            {:error, reason, new_state} ->
              {:reply, {:error, reason}, new_state}
          end
      end
    else
      {:error, reason, state} -> {:reply, {:error, reason}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:get, forecast_id}, _from, state) do
    case ensure_trusted(state) do
      {:ok, state} ->
        case lookup(state.table, forecast_id) do
          {:ok, resolution} -> {:reply, {:ok, resolution}, state}
          :error -> {:reply, :error, state}
        end

      {:error, reason, state} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:all_ids, _from, state) do
    case ensure_trusted(state) do
      {:ok, state} ->
        ids =
          state.table
          |> index()
          |> Map.keys()
          |> Enum.sort()

        {:reply, ids, state}

      {:error, reason, state} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:count, _from, state) do
    case ensure_trusted(state) do
      {:ok, state} -> {:reply, map_size(index(state.table)), state}
      {:error, reason, state} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:recover, _from, state) do
    case transactional_recover(state) do
      {:ok, index, recovery} ->
        generation = state.recovery_generation + 1

        case safe_publish(state.table, index) do
          :ok ->
            count = map_size(index)

            {:reply, {:ok, count},
             %{
               state
               | integrity: recovery.integrity,
                 published: true,
                 count: count,
                 recovered_count: count,
                 recovery_error: nil,
                 recovery_generation: generation,
                 eventstore_health: recovery.eventstore_health
             }}

          {:error, :publication_failure} ->
            invalidate(state.table)

            {:reply, {:error, :publication_failure},
             %{
               state
               | integrity: :degraded,
                 published: false,
                 count: 0,
                 recovered_count: 0,
                 recovery_error: :publication_failure,
                 recovery_generation: generation,
                 eventstore_health: recovery.eventstore_health
             }}
        end

      {:error, reason, recovery} ->
        invalidate(state.table)
        generation = state.recovery_generation + 1

        {:reply, {:error, reason},
         %{
           state
           | integrity: :degraded,
             published: false,
             count: 0,
             recovered_count: 0,
             recovery_error: reason,
             recovery_generation: generation,
             eventstore_health: recovery.eventstore_health
         }}
    end
  end

  def handle_call(:health, _from, state) do
    live =
      case fetch_health(state) do
        {:ok, health} -> health
        {:error, _reason} -> nil
      end

    trusted_live = trusted_health?(live)

    durable =
      state.published and state.integrity in @trusted_integrities and trusted_live

    {:reply,
     %{
       ets_available: :ets.info(state.table) != :undefined,
       integrity: state.integrity,
       published: state.published,
       index_verified: state.published,
       durable: durable,
       resolution_count: if(state.published, do: state.count, else: 0),
       recovered_count: if(state.published, do: state.recovered_count, else: 0),
       recovery_error: state.recovery_error,
       recovery_generation: state.recovery_generation,
       eventstore_available: live != nil,
       eventstore_degraded: not trusted_live,
       eventstore_integrity: live && live[:integrity],
       eventstore: live
     }, state}
  end

  # ------------------------------------------------------------------
  # Transactional recovery
  # ------------------------------------------------------------------

  defp transactional_recover(state) do
    try do
      with {:ok, health} <- fetch_health(state),
           {:ok, %{records: records, diagnostics: diagnostics}} <- fetch_records(state),
           :ok <- require_clean_diagnostics(diagnostics, records),
           :ok <- require_trusted_health(health),
           {:ok, index} <- build_candidate(records) do
        integrity = if map_size(index) == 0, do: :empty_verified, else: :verified

        {:ok, index, %{integrity: integrity, eventstore_health: health}}
      else
        {:error, reason} ->
          {:error, reason, %{eventstore_health: nil}}
      end
    rescue
      error ->
        Logger.error(
          "[EFDI.ResolutionRegistry] candidate index construction failed: #{inspect(error)}"
        )

        {:error, :candidate_index_construction_failure, %{eventstore_health: nil}}
    catch
      :exit, _reason ->
        {:error, :eventstore_unavailable, %{eventstore_health: nil}}
    end
  end

  defp fetch_health(state) do
    try do
      case EventStore.health(state.event_store_name) do
        %{} = health -> {:ok, health}
        other -> {:error, {:unexpected_health_response, other}}
      end
    rescue
      _error -> {:error, :eventstore_unavailable}
    catch
      :exit, _reason -> {:error, :eventstore_unavailable}
    end
  end

  defp fetch_records(state) do
    try do
      case EventStore.read_records(state.event_store_name) do
        {:ok, %{records: records, diagnostics: diagnostics}} ->
          {:ok, %{records: records, diagnostics: diagnostics}}

        {:error, {:read_failed, reason}} ->
          {:error, {:file_read_failure, reason}}

        {:error, reason} ->
          {:error, {:read_failure, reason}}

        other ->
          {:error, {:unexpected_read_response, other}}
      end
    rescue
      _error -> {:error, :eventstore_unavailable}
    catch
      :exit, _reason -> {:error, :eventstore_unavailable}
    end
  end

  defp require_clean_diagnostics(diagnostics, records) do
    cond do
      diagnostics.truncated ->
        {:error, :truncated_history}

      diagnostics.unreadable > 0 ->
        {:error, :unreadable_record}

      diagnostics.integrity_failures > 0 ->
        {:error, EventStore.failure_detail(records)}

      diagnostics.sequence_gaps > 0 ->
        {:error, :sequence_gap}

      diagnostics.unverified_legacy > 0 ->
        {:error, :unverified_legacy_record}

      true ->
        :ok
    end
  end

  defp require_trusted_health(%{poisoned: true}), do: {:error, :eventstore_poisoned}

  defp require_trusted_health(%{integrity: integrity}) when integrity in @trusted_integrities,
    do: :ok

  defp require_trusted_health(%{integrity: :unavailable}), do: {:error, :eventstore_unavailable}
  defp require_trusted_health(%{integrity: :truncated}), do: {:error, :truncated_history}

  defp require_trusted_health(%{integrity: :integrity_failure}),
    do: {:error, :storage_integrity_failure}

  defp require_trusted_health(%{integrity: :sequence_gap}), do: {:error, :sequence_gap}

  defp require_trusted_health(%{integrity: :legacy_unverified}),
    do: {:error, :unverified_legacy_record}

  defp require_trusted_health(%{integrity: :recovery_required}),
    do: {:error, :recovery_required}

  defp require_trusted_health(_health), do: {:error, :eventstore_integrity_unverified}

  defp build_candidate(records) do
    Enum.reduce_while(records, {:ok, %{}}, fn record, {:ok, index} ->
      case record.integrity do
        :verified ->
          case candidate_entry(record.event) do
            :skip -> {:cont, {:ok, index}}
            {:ok, resolution} -> merge_entry(index, resolution)
            {:error, reason} -> {:halt, {:error, reason}}
          end

        _other ->
          {:halt, {:error, :storage_integrity_failure}}
      end
    end)
  end

  defp merge_entry(index, resolution) do
    forecast_id = Map.fetch!(resolution, :forecast_id)

    case Map.fetch(index, forecast_id) do
      :error ->
        {:cont, {:ok, Map.put(index, forecast_id, resolution)}}

      {:ok, existing} ->
        # Duplicate durable records are a history-consistency finding. They are
        # never silently merged, and they never inflate the canonical count.
        if resolution_identity(existing) == resolution_identity(resolution) do
          {:halt, {:error, :duplicate_identical_resolution_event}}
        else
          {:halt, {:error, :conflicting_forecast_resolutions}}
        end
    end
  end

  defp candidate_entry(%{type: @event_type, data: %{resolution: resolution}})
       when is_map(resolution) do
    validate_resolution(resolution)
  end

  defp candidate_entry(%{type: @event_type}), do: {:error, :malformed_resolution_event}
  defp candidate_entry(%{type: _other}), do: :skip
  defp candidate_entry(_other), do: {:error, :malformed_resolution_event}

  defp validate_resolution(resolution) do
    forecast_id = Map.get(resolution, :forecast_id)

    cond do
      not is_binary(forecast_id) or forecast_id == "" ->
        {:error, :missing_forecast_identity}

      not Enum.all?(@required_resolution_fields, &Map.has_key?(resolution, &1)) ->
        {:error, :malformed_resolution_event}

      not is_map(Map.get(resolution, :scores)) ->
        {:error, :malformed_resolution_event}

      true ->
        {:ok, resolution}
    end
  end

  # ------------------------------------------------------------------
  # Trust and persistence helpers
  # ------------------------------------------------------------------

  defp ensure_trusted(state) do
    cond do
      not state.published ->
        {:error, :registry_not_verified, state}

      state.integrity not in @trusted_integrities ->
        {:error, :registry_not_verified, state}

      true ->
        case fetch_health(state) do
          {:ok, health} ->
            if trusted_health?(health) do
              {:ok, %{state | eventstore_health: health}}
            else
              {:error, :registry_degraded, degrade(state, health)}
            end

          {:error, _reason} ->
            {:error, :eventstore_unavailable, degrade(state, nil)}
        end
    end
  end

  defp trusted_health?(nil), do: false

  defp trusted_health?(%{integrity: integrity} = health) do
    integrity in @trusted_integrities and
      Map.get(health, :poisoned) != true and
      Map.get(health, :append_permitted) == true and
      Map.get(health, :degraded) == false
  end

  defp degrade(state, health) do
    %{
      state
      | integrity: :degraded,
        published: false,
        eventstore_health: health
    }
  end

  defp append_event(resolution, state) do
    event = Tiannara.Executive.Event.new(@event_type, %{resolution: resolution})

    try do
      case EventStore.append(event, state.event_store_name) do
        :ok ->
          {:ok, state}

        {:error, reason} ->
          Logger.error("[EFDI.ResolutionRegistry] durable append failed: #{inspect(reason)}")
          {:error, append_error(reason), degrade(state, nil)}
      end
    rescue
      _error ->
        Logger.error("[EFDI.ResolutionRegistry] durable lineage raised")
        {:error, :eventstore_failed, degrade(state, nil)}
    catch
      :exit, _reason ->
        Logger.error("[EFDI.ResolutionRegistry] durable lineage unavailable")
        {:error, :eventstore_unavailable, degrade(state, nil)}
    end
  end

  defp append_error(:store_poisoned), do: :eventstore_poisoned
  defp append_error(:store_not_appendable), do: :eventstore_degraded
  defp append_error(reason), do: {:eventstore_append_failed, reason}

  defp validate_commit_payload(resolution) do
    case validate_resolution(resolution) do
      {:ok, _resolution} -> :ok
      {:error, _reason} -> {:error, :invalid_resolution_payload}
    end
  end

  defp resolution_identity(resolution) do
    :crypto.hash(
      :sha256,
      :erlang.term_to_binary(
        {:tiannara_resolution_identity_v2, Map.get(resolution, :forecast_id),
         Map.get(resolution, :forecast_version), Map.get(resolution, :forecast_digest),
         Map.get(resolution, :outcome_definition_digest), Map.get(resolution, :horizon_digest),
         Map.get(resolution, :model_ref), Map.get(resolution, :observation_id),
         Map.get(resolution, :observation_digest), Map.get(resolution, :evidence_digest),
         Map.get(resolution, :evidence_status), Map.get(resolution, :observed_outcome),
         Map.get(resolution, :observed_at), Map.get(resolution, :event_at),
         Map.get(resolution, :published_at), Map.get(resolution, :acquired_at),
         Map.get(resolution, :verified_at), Map.get(resolution, :verification_status),
         Map.get(resolution, :verification_policy_version),
         Map.get(resolution, :verification_record_digest),
         Map.get(resolution, :resolution_source), Map.get(resolution, :scores),
         Map.get(resolution, :status)}
      )
    )
  end

  # The published index is a single ETS object. Replacing it is atomic, so a
  # reader never observes an empty or half-built table during recovery.
  defp index(table) do
    case :ets.lookup(table, @index_key) do
      [{@index_key, index}] -> index
      [] -> %{}
    end
  end

  defp lookup(table, forecast_id), do: Map.fetch(index(table), forecast_id)

  defp put_entry(table, forecast_id, resolution) do
    :ets.insert(table, {@index_key, Map.put(index(table), forecast_id, resolution)})
  end

  defp safe_publish(table, index) do
    :ets.insert(table, {@index_key, index})
    :ok
  rescue
    _error -> {:error, :publication_failure}
  end

  defp invalidate(table) do
    :ets.delete_all_objects(table)
  rescue
    _error -> false
  end
end
