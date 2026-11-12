defmodule Tiannara.Forecasting.ForecastRegistry do
  @moduledoc """
  D2 forecast registry: immutable storage + lineage for `Contracts.Forecast`.

  A GenServer backed by an ETS named table (`:efdi_forecast_registry`) and
  an append-only EventStore lineage.

  Constitutional rules:
    - Forecasts are immutable: registering never overwrites; same id → no-op.
    - Each forecast id maps to exactly one record.
    - Lineage (`lineage` list) enables "what did Tiannara believe at time T".
    - Corrections are new versions, never rewrites.

  ## Durability

  The ETS table is an **index**, not the record of truth. The durable record is
  the `efdi.forecast.registered` event in `Tiannara.Executive.EventStore`, an
  append-only framed log on disk. On start the registry replays that log and
  rebuilds the index, so forecast history survives a process restart.

  The previous implementation deleted the ETS table on every init and stored
  only the forecast id in the event, which meant that history was lost on
  restart *and* could not have been recovered even if the log had been kept.

  When the event store cannot be reached, the registry says so: `health/0`
  reports `eventstore_degraded: true` and `durable: false`. It does not
  silently present an in-memory forecast as a durably recorded one.
  """
  use GenServer

  require Logger

  alias Tiannara.Forecasting.Forecast
  alias Tiannara.Forecasting.Contracts.Forecast, as: ForecastRecord

  @table :efdi_forecast_registry
  @request_table :efdi_forecast_request_index
  @event_type "efdi.forecast.registered"

  # ------------------------------------------------------------------
  # Client API
  # ------------------------------------------------------------------

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec register(Forecast.t(), keyword()) :: {:ok, Forecast.t()} | {:error, term()}
  def register(%ForecastRecord{} = f, opts \\ []),
    do: GenServer.call(__MODULE__, {:register, f, opts})

  @doc "The request id index, rebuilt from the durable lineage."
  @spec request_index() :: %{optional(String.t()) => map()}
  def request_index, do: GenServer.call(__MODULE__, :request_index)

  @spec get(String.t()) :: {:ok, Forecast.t()} | :error
  def get(id) when is_binary(id), do: GenServer.call(__MODULE__, {:get, id})

  @spec all_ids() :: [String.t()]
  def all_ids, do: GenServer.call(__MODULE__, :all_ids)

  @doc """
  The number of forecasts registered through this process.

  Rehydrating a durable lineage restores history into the index; it is not a
  registration, so it is not counted.
  """
  @spec count() :: non_neg_integer()
  def count, do: GenServer.call(__MODULE__, :count)

  @spec health() :: map()
  def health, do: GenServer.call(__MODULE__, :health)

  @doc "Replays the durable lineage and rebuilds the in-memory index."
  @spec recover() :: {:ok, non_neg_integer()} | {:error, :eventstore_unavailable}
  def recover, do: GenServer.call(__MODULE__, :recover)

  # Server callbacks
  # ------------------------------------------------------------------

  @impl true
  def init(_opts) do
    if :ets.info(@table) == :undefined do
      :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
    end

    if :ets.info(@request_table) == :undefined do
      :ets.new(@request_table, [:set, :public, :named_table, read_concurrency: true])
    end

    {recovered, degraded} = rehydrate()

    {:ok, %{count: 0, eventstore_degraded: degraded, recovered_count: recovered}}
  end

  @impl true
  def handle_call({:register, f, opts}, _from, state) do
    request_id = Keyword.get(opts, :request_id)
    fingerprint = Keyword.get(opts, :request_fingerprint)

    case Forecast.validate(f) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:ok, f} ->
        case get_by_id(f.id) do
          {:ok, existing} ->
            {:reply, {:ok, existing}, state}

          :error ->
            :ets.insert(@table, {f.id, f})
            index_request_id(request_id, f.id, fingerprint)
            state = maybe_append_event(f, request_id, fingerprint, state)
            {:reply, {:ok, f}, bump(state)}
        end
    end
  end

  def handle_call(:request_index, _from, state) do
    {:reply, request_index_from_ets(), state}
  end

  def handle_call({:get, id}, _from, state), do: {:reply, get_by_id(id), state}

  def handle_call(:all_ids, _from, state), do: {:reply, all_ids_from_ets(), state}

  def handle_call(:count, _from, state), do: {:reply, state.count, state}

  def handle_call(:recover, _from, state) do
    {recovered, degraded} = rehydrate()

    state = %{
      state
      | recovered_count: recovered,
        eventstore_degraded: degraded
    }

    {:reply, {:ok, recovered}, state}
  end

  def handle_call(:health, _from, state) do
    {:reply,
     %{
       ets_available: :ets.info(@table) != :undefined,
       eventstore_degraded: state.eventstore_degraded,
       durable: not state.eventstore_degraded,
       forecast_count: :ets.info(@table, :size),
       recovered_count: state.recovered_count
     }, state}
  end

  # Persistence helpers
  # ------------------------------------------------------------------

  defp get_by_id(id) do
    case :ets.lookup(@table, id) do
      [{_, f}] -> {:ok, f}
      [] -> :error
    end
  end

  defp all_ids_from_ets do
    :ets.foldl(fn entry, acc ->
      case entry do
        {id, %ForecastRecord{}} when is_binary(id) -> [id | acc]
        _ -> acc
      end
    end, [], @table)
  end

  defp bump(state), do: %{state | count: state.count + 1}

  defp maybe_append_event(%ForecastRecord{} = f, request_id, fingerprint, state) do
    event =
      Tiannara.Executive.Event.new(@event_type, %{
        forecast_id: f.id,
        request_id: request_id,
        request_fingerprint: fingerprint,
        question: f.question,
        version: f.forecast_version,
        forecast_binary: :erlang.term_to_binary(f)
      })

    try do
      Tiannara.Executive.EventStore.append(event)
      state
    catch
      :exit, _reason ->
        Logger.error(
          "[EFDI.ForecastRegistry] durable lineage unavailable; forecast #{f.id} exists in memory only"
        )

        %{state | eventstore_degraded: true}

      :error, _reason ->
        Logger.error(
          "[EFDI.ForecastRegistry] durable lineage failed; forecast #{f.id} exists in memory only"
        )

        %{state | eventstore_degraded: true}
    rescue
      _error ->
        Logger.error(
          "[EFDI.ForecastRegistry] durable lineage raised; forecast #{f.id} exists in memory only"
        )

        %{state | eventstore_degraded: true}
    end
  end

  defp rehydrate do
    case safe_stream() do
      {:ok, events} ->
        recovered =
          Enum.reduce(events, 0, fn event, acc ->
            case forecast_from_event(event) do
              {:ok, forecast} ->
                :ets.insert(@table, {forecast.id, forecast})
                index_request(event, forecast)
                acc + 1

              :error ->
                acc
            end
          end)

        {recovered, false}

      :error ->
        {0, true}
    end
  end

  defp index_request_id(request_id, forecast_id, fingerprint) when is_binary(request_id) do
    :ets.insert(@request_table, {request_id, %{forecast_id: forecast_id, fingerprint: fingerprint}})
  end

  defp index_request_id(_request_id, _forecast_id, _fingerprint), do: :ok

  defp index_request(event, forecast) do
    with %{data: data} when is_map(data) <- event,
         request_id when is_binary(request_id) <- Map.get(data, :request_id) do
      :ets.insert(
        @request_table,
        {request_id,
         %{forecast_id: forecast.id, fingerprint: Map.get(data, :request_fingerprint)}}
      )
    else
      _ -> :ok
    end
  end

  defp request_index_from_ets do
    :ets.foldl(fn {request_id, entry}, acc ->
      Map.put(acc, request_id, entry)
    end, %{}, @request_table)
  end

  defp safe_stream do
    {:ok, Tiannara.Executive.EventStore.stream(0)}
  catch
    :exit, _reason -> :error
  rescue
    _error -> :error
  end

  defp forecast_from_event(%{type: @event_type, data: data}) when is_map(data) do
    case Map.get(data, :forecast_binary) do
      bin when is_binary(bin) ->
        try do
          {:ok, :erlang.binary_to_term(bin, [:safe])}
        rescue
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp forecast_from_event(_event), do: :error
end
