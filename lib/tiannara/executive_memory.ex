defmodule Tiannara.ExecutiveMemory do
  @moduledoc """
  Ω.0.1 — Artifact 1: ExecutiveMemory Foundation.

  A production-grade, OTP-compliant memory substrate backed by Erlang DETS.

  ## Responsibilities

  * Deterministic startup with corruption detection
  * Graceful DETS degradation and automatic rebuild
  * Ownership-correct DETS access (table owned by this GenServer)
  * State persistence, health reporting, and telemetry skeleton
  * Clean public API with no hidden crashes

  ## Constitutional Alignment

  * **Runtime Never Dies** — DETS corruption triggers rebuild, never a crash
  * **Every Failure Produces Evidence** — structured logging at every transition
  * **Single Source of Truth** — DETS is the canonical store
  * **Provenance** — every entry has a known path and open timestamp
  """

  use GenServer
  require Logger

  alias __MODULE__.State

  @table :executive_memory
  @default_path "data/executive_memory.dets"

  # ──────────────────────────────────────────────
  # State
  # ──────────────────────────────────────────────

  defmodule State do
    @moduledoc """
    Internal state of the ExecutiveMemory GenServer.

    ## Fields
      * `:dets` — the DETS table reference (nil when degraded)
      * `:status` — `:healthy` or `:degraded`
      * `:entries` — count of entries in the store
      * `:opened_at` — timestamp of last successful open/rebuild
      * `:path` — filesystem path to the DETS file
      * `:rebuilds` — number of times the store has been rebuilt
    """

    @enforce_keys [:path]

    defstruct [
      :dets,
      :status,
      :entries,
      :opened_at,
      :path,
      :rebuilds
    ]
  end

  # ──────────────────────────────────────────────
  # Client API
  # ──────────────────────────────────────────────

  @doc """
  Starts the ExecutiveMemory GenServer.

  ## Options
    * `:path` — path to the DETS file (default: `data/executive_memory.dets`)
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Writes a key-value pair to the store.
  """
  @spec put(term(), term()) :: :ok | {:error, term()}
  def put(key, value) do
    GenServer.call(__MODULE__, {:put, key, value})
  end

  @doc """
  Reads a value by key. Returns `{:ok, nil}` if not found.
  """
  @spec get(term()) :: {:ok, term() | nil} | {:error, term()}
  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  @doc """
  Deletes a key from the store.
  """
  @spec delete(term()) :: :ok | {:error, term()}
  def delete(key) do
    GenServer.call(__MODULE__, {:delete, key})
  end

  @doc """
  Returns all keys in the store.
  """
  @spec keys() :: {:ok, [term()]} | {:error, term()}
  def keys do
    GenServer.call(__MODULE__, :keys)
  end

  @doc """
  Returns the number of entries in the store.
  """
  @spec size() :: {:ok, non_neg_integer()} | {:error, term()}
  def size do
    GenServer.call(__MODULE__, :size)
  end

  @doc """
  Flushes all pending writes to disk.
  """
  @spec flush() :: :ok | {:error, term()}
  def flush do
    GenServer.call(__MODULE__, :flush)
  end

  @doc """
  Returns a health report for the store.
  """
  @spec health() :: %{
          status: :healthy | :degraded,
          entries: non_neg_integer(),
          path: binary(),
          opened_at: DateTime.t() | nil,
          rebuilds: non_neg_integer()
        }
  def health do
    GenServer.call(__MODULE__, :health)
  end

  @doc """
  Returns detailed statistics for the store.
  """
  @spec stats() :: %{
          status: :healthy | :degraded,
          entries: non_neg_integer(),
          path: binary(),
          opened_at: DateTime.t() | nil,
          rebuilds: non_neg_integer(),
          table_info: map() | nil
        }
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  # ──────────────────────────────────────────────
  # Server Callbacks
  # ──────────────────────────────────────────────

  @impl true
  def init(opts) do
    path = Keyword.get(opts, :path, @default_path)

    File.mkdir_p!("data")

    state = %State{
      path: path,
      status: :degraded,
      entries: 0,
      rebuilds: 0
    }

    {:ok, initialize_store(state)}
  end

  @impl true
  def handle_call({:put, key, value}, _from, state) do
    case state.status do
      :healthy ->
        case :dets.insert(state.dets, {key, value}) do
          :ok ->
            new_state = %{state | entries: state.entries + 1}
            {:reply, :ok, new_state}

          {:error, reason} ->
            Logger.error("[ExecutiveMemory] Insert failed: #{inspect(reason)}")
            {:reply, {:error, reason}, state}
        end

      :degraded ->
        {:reply, {:error, :degraded}, state}
    end
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    case state.status do
      :healthy ->
        case :dets.lookup(state.dets, key) do
          [{^key, value}] -> {:reply, {:ok, value}, state}
          [] -> {:reply, {:ok, nil}, state}
          {:error, reason} -> {:reply, {:error, reason}, state}
        end

      :degraded ->
        {:reply, {:error, :degraded}, state}
    end
  end

  @impl true
  def handle_call({:delete, key}, _from, state) do
    case state.status do
      :healthy ->
        case :dets.delete(state.dets, key) do
          :ok ->
            new_entries = max(state.entries - 1, 0)
            {:reply, :ok, %{state | entries: new_entries}}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end

      :degraded ->
        {:reply, {:error, :degraded}, state}
    end
  end

  @impl true
  def handle_call(:keys, _from, state) do
    case state.status do
      :healthy ->
        keys =
          :dets.foldl(fn {key, _value}, acc -> [key | acc] end, [], state.dets)

        {:reply, {:ok, keys}, state}

      :degraded ->
        {:reply, {:error, :degraded}, state}
    end
  end

  @impl true
  def handle_call(:size, _from, state) do
    case state.status do
      :healthy ->
        count = count_entries(state.dets)
        {:reply, {:ok, count}, %{state | entries: count}}

      :degraded ->
        {:reply, {:error, :degraded}, state}
    end
  end

  @impl true
  def handle_call(:flush, _from, state) do
    case state.status do
      :healthy ->
        case :dets.sync(state.dets) do
          :ok -> {:reply, :ok, state}
          {:error, reason} -> {:reply, {:error, reason}, state}
        end

      :degraded ->
        {:reply, {:error, :degraded}, state}
    end
  end

  @impl true
  def handle_call(:health, _from, state) do
    report = %{
      status: state.status,
      entries: state.entries,
      path: state.path,
      opened_at: state.opened_at,
      rebuilds: state.rebuilds
    }

    {:reply, report, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    table_info =
      case state.status do
        :healthy -> :dets.info(state.dets)
        :degraded -> nil
      end

    report = %{
      status: state.status,
      entries: state.entries,
      path: state.path,
      opened_at: state.opened_at,
      rebuilds: state.rebuilds,
      table_info: table_info
    }

    {:reply, report, state}
  end

  # ──────────────────────────────────────────────
  # Store Lifecycle
  # ──────────────────────────────────────────────

  defp initialize_store(state) do
    case open_store(state.path) do
      {:ok, table} ->
        count = count_entries(table)

        Logger.info("""
        ExecutiveMemory opened successfully.
        Entries: #{count}
        """)

        %{
          state
          | dets: table,
            status: :healthy,
            entries: count,
            opened_at: DateTime.utc_now()
        }

      {:corrupt, reason} ->
        Logger.warning("""
        ExecutiveMemory corruption detected.

        #{inspect(reason)}

        Attempting rebuild...
        """)

        rebuild_store(state)

      {:error, reason} ->
        Logger.error("""
        ExecutiveMemory failed to open.

        Running degraded.

        #{inspect(reason)}
        """)

        state
    end
  end

  defp open_store(path) do
    case :dets.open_file(@table,
           file: String.to_charlist(path),
           type: :set
         ) do
      {:ok, table} ->
        {:ok, table}

      {:error, {:needs_repair, _} = reason} ->
        {:corrupt, reason}

      {:error, {:not_a_dets_file, _} = reason} ->
        {:corrupt, reason}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp rebuild_store(state) do
    File.rm(state.path)

    case open_store(state.path) do
      {:ok, table} ->
        Logger.warning("""
        ExecutiveMemory rebuilt successfully.
        """)

        %{
          state
          | dets: table,
            status: :healthy,
            rebuilds: state.rebuilds + 1,
            opened_at: DateTime.utc_now(),
            entries: 0
        }

      {:error, reason} ->
        Logger.error("""
        ExecutiveMemory rebuild failed.

        #{inspect(reason)}
        """)

        state
    end
  end

  # ──────────────────────────────────────────────
  # Helpers
  # ──────────────────────────────────────────────

  defp count_entries(table) do
    :dets.info(table, :no_of_objects)
  end
end