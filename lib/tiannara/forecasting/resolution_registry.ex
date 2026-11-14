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
  append-only framed log on disk. On start the registry replays that log and
  rebuilds the index, so resolution history survives a process restart.

  When the event store cannot be reached, the registry reports itself degraded
  and non-durable. It does not silently present an in-memory resolution as a
  durably recorded one.

  ## Idempotency

  An exact retry of an already committed resolution returns the original
  persisted record without appending another event. A conflicting resolution
  for an already-resolved forecast is rejected with `:resolution_conflict`.

  ## Instance isolation

  The ETS tables are named after the registered instance, so an isolated
  registry can be started without colliding with the application-wide one.
  """
  use GenServer

  require Logger

  alias Tiannara.Forecasting.OutcomeResolution

  @event_type "efdi.forecast.resolved"

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

  @doc "The ETS table backing this registry instance."
  @spec table() :: atom()
  def table, do: :"#{server()}_resolutions"

  @doc "The durable event log this registry writes its lineage to."
  @spec event_store() :: module()
  def event_store, do: Tiannara.Executive.EventStore

  @doc """
  Commits a resolution durably.

  Returns `{:ok, resolution}` for a newly committed or already-existing
  identical resolution, `{:error, :resolution_conflict}` when a different
  resolution already exists for the forecast, and `{:error, reason}` on
  failure.
  """
  @spec commit(map()) :: {:ok, map()} | {:error, term()}
  def commit(resolution) when is_map(resolution) do
    GenServer.call(server(), {:commit, resolution})
  end

  @doc "Retrieves a resolution by forecast id."
  @spec get(String.t()) :: {:ok, map()} | :error
  def get(forecast_id) when is_binary(forecast_id) do
    GenServer.call(server(), {:get, forecast_id})
  end

  @doc "Returns all resolution ids."
  @spec all_ids() :: [String.t()]
  def all_ids, do: GenServer.call(server(), :all_ids)

  @doc "Returns the number of committed resolutions."
  @spec count() :: non_neg_integer()
  def count, do: GenServer.call(server(), :count)

  @doc "Health of the resolution registry."
  @spec health() :: map()
  def health, do: GenServer.call(server(), :health)

  @doc "Replays the durable lineage and rebuilds the in-memory index."
  @spec recover() :: {:ok, non_neg_integer()} | {:error, :eventstore_unavailable}
  def recover, do: GenServer.call(server(), :recover)

  # ------------------------------------------------------------------
  # Server callbacks
  # ------------------------------------------------------------------

  @impl true
  def init(opts) do
    name = Keyword.get(opts, :name, server())
    table = :"#{name}_resolutions"

    if :ets.info(table) == :undefined do
      :ets.new(table, [:set, :public, :named_table, read_concurrency: true])
    end

    {recovered, degraded, failures} = rehydrate(table)

    {:ok,
     %{
       table: table,
       count: 0,
       eventstore_degraded: degraded,
       recovered_count: recovered,
       recovery_failures: failures
     }}
  end

  @impl true
  def handle_call({:commit, resolution}, _from, state) do
    forecast_id = Map.get(resolution, :forecast_id)

    case get_by_forecast(state.table, forecast_id) do
      {:ok, existing} ->
        # Idempotency: exact retry returns the original.
        if resolution_identity(existing) == resolution_identity(resolution) do
          {:reply, {:ok, existing}, state}
        else
          {:reply, {:error, :resolution_conflict}, state}
        end

      :error ->
        :ets.insert(state.table, {forecast_id, resolution})
        state = maybe_append_event(resolution, state)
        {:reply, {:ok, resolution}, %{state | count: state.count + 1}}
    end
  end

  def handle_call({:get, forecast_id}, _from, state) do
    {:reply, get_by_forecast(state.table, forecast_id), state}
  end

  def handle_call(:all_ids, _from, state) do
    {:reply, all_ids_from_ets(state.table), state}
  end

  def handle_call(:count, _from, state) do
    {:reply, :ets.info(state.table, :size), state}
  end

  def handle_call(:recover, _from, state) do
    {recovered, degraded, failures} = rehydrate(state.table)
    state = %{state | recovered_count: recovered, eventstore_degraded: degraded, recovery_failures: failures}
    {:reply, {:ok, recovered}, state}
  end

  def handle_call(:health, _from, state) do
    {:reply,
     %{
       ets_available: :ets.info(state.table) != :undefined,
       eventstore_degraded: state.eventstore_degraded,
       durable: not state.eventstore_degraded,
       resolution_count: :ets.info(state.table, :size),
       recovered_count: state.recovered_count,
       recovery_failures: state.recovery_failures
     }, state}
  end

  # ------------------------------------------------------------------
  # Persistence helpers
  # ------------------------------------------------------------------

  defp get_by_forecast(table, forecast_id) do
    case :ets.lookup(table, forecast_id) do
      [{_, r}] -> {:ok, r}
      [] -> :error
    end
  end

  defp all_ids_from_ets(table) do
    :ets.foldl(fn
      {id, _r}, acc when is_binary(id) -> [id | acc]
      _, acc -> acc
    end, [], table)
  end

  defp resolution_identity(resolution) do
    :crypto.hash(
      :sha256,
      :erlang.term_to_binary(
        {:tiannara_resolution_identity_v1, Map.get(resolution, :forecast_id),
         Map.get(resolution, :forecast_version), Map.get(resolution, :forecast_digest),
         Map.get(resolution, :outcome_definition_digest), Map.get(resolution, :horizon_digest),
         Map.get(resolution, :observation_id), Map.get(resolution, :evidence_digest),
         Map.get(resolution, :observed_outcome), Map.get(resolution, :verification_record_digest)}
      )
    )
  end

  defp maybe_append_event(resolution, state) do
    event = Tiannara.Executive.Event.new(@event_type, %{resolution: resolution})

    try do
      event_store().append(event)
      state
    catch
      :exit, _reason ->
        Logger.error("[EFDI.ResolutionRegistry] durable lineage unavailable")
        %{state | eventstore_degraded: true}

      :error, _reason ->
        Logger.error("[EFDI.ResolutionRegistry] durable lineage failed")
        %{state | eventstore_degraded: true}
    rescue
      _error ->
        Logger.error("[EFDI.ResolutionRegistry] durable lineage raised")
        %{state | eventstore_degraded: true}
    end
  end

  defp rehydrate(table) do
    case safe_stream() do
      {:ok, events, unreadable, truncated} ->
        {recovered, failures} =
          Enum.reduce(events, {0, 0}, fn event, {acc, failed} ->
            case resolution_from_event(event) do
              {:ok, resolution} ->
                :ets.insert(table, {Map.get(resolution, :forecast_id), resolution})
                {acc + 1, failed}

              :error ->
                {acc, failed + 1}
            end
          end)

        total_failures = failures + unreadable
        {recovered, total_failures > 0 or truncated, total_failures}

      :error ->
        {0, true, :unreadable}
    end
  end

  defp safe_stream do
    case event_store().stream_verified(0) do
      {:ok,
       %{
         records: records,
         unreadable: unreadable,
         truncated: truncated,
         integrity_failures: failures,
         sequence_gaps: gaps,
         unverified_legacy: legacy
       }} ->
        events = Enum.map(records, & &1.event)
        {:ok, events, unreadable + failures + gaps + legacy, truncated}

      _ ->
        :error
    end
  catch
    :exit, _reason -> :error
  rescue
    _error -> :error
  end

  defp resolution_from_event(%{type: @event_type, data: %{resolution: resolution}})
       when is_map(resolution) do
    {:ok, resolution}
  end

  defp resolution_from_event(_event), do: :error
end
