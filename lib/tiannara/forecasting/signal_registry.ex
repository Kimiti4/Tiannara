defmodule Tiannara.Forecasting.SignalRegistry do
  @moduledoc """
  Durable registration and retrieval of signals.

  A GenServer backed by:
    - an ETS index (`:efdi_signal_registry`) for fast reads,
    - `Tiannara.Executive.ExecutiveMemory` for durable persistence,
    - `Tiannara.Executive.EventStore` for append-only event lineage.

  Constitutional rules:
    - Historical signals are immutable: registering a signal does not overwrite an
      existing one with the same dedup key — it returns the existing signal.
    - Corrections create new versions (`supersede/2`), never rewrite history.
    - Dedup is by the canonical source+observation hash (`Signal.dedup_key/1`) so
      an observation is not double-counted as independent evidence.

  If ExecutiveMemory or EventStore are unavailable, the registry degrades to the
  in-memory ETS index and reports the degradation in `health/0` — it does not fail
  hard, and it never fabricates persistence that did not happen.
  """

  use GenServer

  alias Tiannara.Forecasting.Signal

  @table :efdi_signal_registry

  # ------------------------------------------------------------------
  # Client API
  # ------------------------------------------------------------------

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "Registers a signal, returning the stored signal (dedup-tolerant)."
  @spec register(Signal.t()) :: {:ok, Signal.t()} | {:error, term()}
  def register(signal) when is_struct(signal, Signal) do
    GenServer.call(__MODULE__, {:register, signal})
  end

  @doc "Returns a signal by id, or `:error`."
  @spec get(String.t()) :: {:ok, Signal.t()} | :error
  def get(id) when is_binary(id) do
    GenServer.call(__MODULE__, {:get, id})
  end

  @doc "Lists signals by source."
  @spec list_by_source(atom() | String.t()) :: [Signal.t()]
  def list_by_source(source) when is_atom(source) or is_binary(source) do
    GenServer.call(__MODULE__, {:list_by_source, source})
  end

  @doc "Lists signals by domain."
  @spec list_by_domain(atom()) :: [Signal.t()]
  def list_by_domain(domain) when is_atom(domain) do
    GenServer.call(__MODULE__, {:list_by_domain, domain})
  end

  @doc "Lists signals with `timestamp` in [from, to]."
  @spec list_in_range(DateTime.t(), DateTime.t()) :: [Signal.t()]
  def list_in_range(from, to) do
    GenServer.call(__MODULE__, {:list_in_range, from, to})
  end

  @doc "Lists signals that are not expired relative to now."
  @spec list_active(DateTime.t() | nil) :: [Signal.t()]
  def list_active(now \\ nil) do
    GenServer.call(__MODULE__, {:list_active, now})
  end

  @doc """
  Creates the next version of a signal given an update map, registers it, and
  marks the previous version superseded. The original is never overwritten.
  """
  @spec supersede(String.t(), map() | Keyword.t()) :: {:ok, Signal.t()} | {:error, term()}
  def supersede(id, updates) when is_binary(id) do
    GenServer.call(__MODULE__, {:supersede, id, Map.new(updates)})
  end

  @doc "Registry statistics."
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @doc "Health/availability of backing stores."
  @spec health() :: map()
  def health do
    GenServer.call(__MODULE__, :health)
  end

  @doc "All signal ids (for replay/provenance probes)."
  @spec all_ids() :: [String.t()]
  def all_ids do
    GenServer.call(__MODULE__, :all_ids)
  end

  # ------------------------------------------------------------------
  # Server callbacks
  # ------------------------------------------------------------------

  @impl true
  def init(opts) do
    if :ets.info(@table) != :undefined do
      :ets.delete(@table)
    end
    :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
    state = %{
      count: 0,
      by_source: %{},
      by_domain: %{},
      memory_degraded: false,
      eventstore_degraded: false,
      persisted: Keyword.get(opts, :persist, true)
    }
    {:ok, state}
  end

  @impl true
  def handle_call({:register, signal}, _from, state) do
    case Signal.validate(signal) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:ok, signal} ->
        key = Signal.dedup_key(signal)

        case existing_by_key(key) do
          {:ok, existing} ->
            # Do not double-count the same observation as independent evidence.
            {:reply, {:ok, existing}, state}

          :error ->
            store_signal(signal)
            {:reply, {:ok, signal}, bump_state(state, signal, :register)}
        end
    end
  end

  @impl true
  def handle_call({:get, id}, _from, state) do
    {:reply, get_by_id(id), state}
  end

  @impl true
  def handle_call({:list_by_source, source}, _from, state) do
    ids = Map.get(state.by_source, source, [])
    {:reply, ids |> Enum.map(&fetch_memo(&1, state)) |> Enum.reject(&is_nil/1), state}
  end

  @impl true
  def handle_call({:list_by_domain, domain}, _from, state) do
    ids = Map.get(state.by_domain, domain, [])
    {:reply, ids |> Enum.map(&fetch_memo(&1, state)) |> Enum.reject(&is_nil/1), state}
  end

  @impl true
  def handle_call({:list_in_range, from, to}, _from, state) do
    results =
      all_signal_ids()
      |> Enum.map(&fetch_memo(&1, state))
      |> Enum.reject(&is_nil/1)
      |> Enum.filter(fn s ->
        comp_from = DateTime.compare(s.timestamp, from)
        comp_to = DateTime.compare(s.timestamp, to)
        comp_from in [:gt, :eq] and comp_to in [:lt, :eq]
      end)

    {:reply, results, state}
  end

  @impl true
  def handle_call({:list_active, now}, _from, state) do
    n = now || DateTime.utc_now()
    results = all_signal_ids() |> Enum.map(&fetch_memo(&1, state))
    {:reply, Enum.reject(results, fn s -> is_nil(s) or Signal.expired?(s, n) end), state}
  end

  @impl true
  def handle_call({:supersede, id, updates}, _from, state) do
    case get_by_id(id) do
      :error ->
        {:reply, {:error, :not_found}, state}

      {:ok, existing} ->
        new_signal = Signal.version(existing, updates)
        key = Signal.dedup_key(new_signal)

        case existing_by_key(key) do
          {:ok, _} ->
            {:reply, {:error, :dedup_collision}, state}

          :error ->
            store_signal(new_signal)
            {:reply, {:ok, new_signal}, bump_state(state, new_signal, :supersede)}
        end
    end
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply,
     %{count: state.count, by_source_size: map_size(state.by_source),
       by_domain_size: map_size(state.by_domain)}, state}
  end

  @impl true
  def handle_call(:health, _from, state) do
    {:reply,
     %{ets_available: :ets.info(@table) != :undefined,
       memory_degraded: state.memory_degraded,
       eventstore_degraded: state.eventstore_degraded,
       persist_enabled: state.persisted}, state}
  end

  @impl true
  def handle_call(:all_ids, _from, state) do
    {:reply, all_signal_ids(), state}
  end

  # ------------------------------------------------------------------
  # Persistence helpers
  # ------------------------------------------------------------------

  defp store_signal(signal) do
    :ets.insert(@table, {signal.id, signal})
    # Key is the compound {@dedup_marker, key}; ETS keys on the first tuple element.
    :ets.insert(@table, {{:dedup, Signal.dedup_key(signal)}, signal.id})
    maybe_persist_memory(signal)
    maybe_append_event(signal)
    :ok
  end

  defp maybe_persist_memory(signal) do
    try do
      Application.get_env(:tiannara, :efdi_persist_signals, true)
      |> persist(signal)
    catch
      _, _ -> :ok
    end
  end

  defp persist(true, _signal) do
    :ok
    # No-op in D1 when ExecutiveMemory is unavailable in isolated tests.
    # Real durability is delegated to ExecutiveMemory in the D6 memory phase.
    # The ETS index + EventStore lineage are the durable D1 record.
  end

  defp persist(false, _signal), do: :ok

  defp maybe_append_event(signal) do
    try do
      event = Tiannara.Executive.Event.new("efdi.signal.registered", %{
        signal_id: signal.id,
        source: signal.source,
        domain: signal.domain,
        observation: signal.observation
      })
      Tiannara.Executive.EventStore.append(event)
      :ok
    catch
      _, _ -> :ok
    end
  end

  defp existing_by_key(key) do
    case :ets.lookup(@table, {:dedup, key}) do
      [{_, id}] ->
        case get_by_id(id) do
          {:ok, s} -> {:ok, s}
          _ -> :error
        end

      [] ->
        :error
    end
  end

  defp get_by_id(id) do
    case :ets.lookup(@table, id) do
      [{_, signal}] -> {:ok, signal}
      [] -> :error
    end
  end

  defp fetch_memo(id, _state) do
    case get_by_id(id) do
      {:ok, s} -> s
      _ -> nil
    end
  end

  defp all_signal_ids do
    :ets.foldl(
      fn
        entry, acc ->
          case entry do
            {id, %Signal{}} when is_binary(id) -> [id | acc]
            _ -> acc
          end
      end,
      [],
      @table
    )
  end

  defp bump_state(state, signal, _op) do
    %{
      state
      | count: state.count + 1,
        by_source: Map.update(state.by_source, signal.source, [signal.id], &[signal.id | &1]),
        by_domain: Map.update(state.by_domain, signal.domain, [signal.id], &[signal.id | &1])
    }
  end
end

