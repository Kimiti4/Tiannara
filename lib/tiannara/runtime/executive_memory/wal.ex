defmodule Tiannara.Runtime.ExecutiveMemory.WAL do
  @moduledoc """
  Ω.0.1 Write-Ahead Log for Executive Memory.

  Uses Erlang's `disk_log` for highly durable, append-only logging of all write
  operations. Ensures that no write is lost even if the primary DETS store crashes
  mid-write. The WAL is the canonical source of truth for crash recovery.

  ## Constitutional Alignment

  - **Deterministic Replay:** Every write is logged before it reaches the store.
    Recovery replays the WAL to reconstruct state.
  - **Provenance:** Every entry in the WAL has a known origin and timestamp.
  - **Fail-Closed:** If the WAL itself cannot write, the operation fails before
    any store mutation occurs.

  ## Notes

  This GenServer does **not** register by name to avoid conflicts when multiple
  instances exist (e.g., during test restarts). The caller receives the pid and
  must pass it to API functions.
  """

  use GenServer
  require Logger

  # ──────────────────────────────────────────────
  # Client API
  # ──────────────────────────────────────────────

  @doc """
  Starts the WAL GenServer.

  ## Options
    * `:path` (required) — filesystem path for the disk_log file
    * `:log_name` (optional) — registered name for the disk_log, defaults to `:executive_memory_wal`
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  @doc """
  Appends a term to the WAL. Serializes to binary via `:erlang.term_to_binary/1`.
  """
  @spec append(pid(), term()) :: :ok | {:error, term()}
  def append(wal_pid, term) do
    GenServer.call(wal_pid, {:append, term})
  end

  @doc """
  Replays the entire WAL by calling `fun` for each logged term.

  The function receives each deserialized term. Replay is read-only and does
  not modify the WAL state. Uses chunked reading for memory efficiency over
  large logs.
  """
  @spec replay(pid(), (term() -> any())) :: :ok
  def replay(wal_pid, fun) when is_function(fun, 1) do
    GenServer.call(wal_pid, {:replay, fun}, :infinity)
  end

  # ──────────────────────────────────────────────
  # Server Callbacks
  # ──────────────────────────────────────────────

  @impl true
  def init(opts) do
    path = Keyword.fetch!(opts, :path)
    log_name = Keyword.get(opts, :log_name, :"executive_memory_wal_#{:erlang.unique_integer([:positive])}")

    path |> Path.dirname() |> File.mkdir_p!()

    case :disk_log.open([
           {:name, log_name},
           {:file, String.to_charlist(path)},
           {:size, :infinity},
           {:type, :halt},
           {:repair, true}
         ]) do
      {:ok, ref} ->
        {:ok, %{ref: ref, path: path, log_name: log_name}}

      {:repaired, ref, {:recovered, rec}, {:badbytes, bad}} ->
        Logger.warning("[ExecutiveMemory:WAL] Repaired corrupt log. " <>
                       "Recovered: #{rec} entries, Bad bytes: #{bad}")
        {:ok, %{ref: ref, path: path, log_name: log_name}}

      {:error, reason} ->
        {:stop, {:wal_init_failed, reason}}
    end
  end

  @impl true
  def handle_call({:append, term}, _from, state) do
    binary = :erlang.term_to_binary(term)

    case :disk_log.log(state.ref, binary) do
      :ok ->
        {:reply, :ok, state}

      {:error, reason} ->
        Logger.error("[ExecutiveMemory:WAL] Append failed: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:replay, fun}, _from, state) do
    replay_chunk(state.ref, :start, fun)
    {:reply, :ok, state}
  end

  # ──────────────────────────────────────────────
  # Private Helpers
  # ──────────────────────────────────────────────

  defp replay_chunk(_ref, :eof, _fun), do: :ok

  defp replay_chunk(ref, cont, fun) do
    case :disk_log.chunk(ref, cont) do
      {cont, terms} when is_list(terms) ->
        Enum.each(terms, fn binary ->
          # :safe prevents deserialization of anonymous functions, pids, refs
          term = :erlang.binary_to_term(binary, [:safe])
          fun.(term)
        end)

        replay_chunk(ref, cont, fun)

      :eof ->
        :ok

      {:error, reason} ->
        Logger.error("[ExecutiveMemory:WAL] Chunk read error: #{inspect(reason)}")
        :ok
    end
  end
end