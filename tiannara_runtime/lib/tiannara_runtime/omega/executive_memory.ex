defmodule TiannaraRuntime.Omega.ExecutiveMemory do
  @moduledoc """
  Hardened executive memory with bounded state and atomic local snapshots.
  """

  use GenServer

  alias TiannaraRuntime.Omega.{FailureObservatory, SafeCPL, SentinelEventBus}

  @default_checkpoint_interval 30_000
  @default_max_entries 10_000
  @default_storage_path "data/omega/executive_memory"
  @snapshot_file "snapshot.etf"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec put(term(), term()) :: :ok
  def put(key, value), do: GenServer.call(__MODULE__, {:put, key, value})

  @spec get(term(), term()) :: term()
  def get(key, default \\ nil), do: GenServer.call(__MODULE__, {:get, key, default})

  @spec delete(term()) :: :ok
  def delete(key), do: GenServer.call(__MODULE__, {:delete, key})

  @spec snapshot() :: map()
  def snapshot, do: GenServer.call(__MODULE__, :snapshot)

  @spec checkpoint() :: {:ok, map()} | {:error, term()}
  def checkpoint, do: GenServer.call(__MODULE__, :checkpoint)

  @spec health() :: map()
  def health, do: GenServer.call(__MODULE__, :health)

  @impl true
  def init(opts) do
    storage_path = Keyword.get(opts, :storage_path, @default_storage_path)
    File.mkdir_p!(storage_path)

    state =
      %{
        memory: %{},
        writes: 0,
        deletes: 0,
        max_entries: Keyword.get(opts, :max_entries, @default_max_entries),
        storage_path: storage_path,
        checkpoint_interval:
          Keyword.get(opts, :checkpoint_interval, @default_checkpoint_interval),
        last_checkpoint: nil,
        last_checkpoint_error: nil
      }
      |> load_snapshot()

    schedule_checkpoint(state.checkpoint_interval)
    {:ok, state}
  end

  @impl true
  def handle_call({:put, key, value}, _from, state) do
    entry = %{value: value, version: next_version(state.memory[key]), updated_at: now()}
    memory = state.memory |> Map.put(key, entry) |> trim_memory(state.max_entries)
    {:reply, :ok, %{state | memory: memory, writes: state.writes + 1}}
  end

  @impl true
  def handle_call({:get, key, default}, _from, state) do
    value =
      case Map.get(state.memory, key) do
        nil -> default
        %{value: value} -> value
      end

    {:reply, value, state}
  end

  @impl true
  def handle_call({:delete, key}, _from, state) do
    {:reply, :ok, %{state | memory: Map.delete(state.memory, key), deletes: state.deletes + 1}}
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    {:reply, snapshot_state(state), state}
  end

  @impl true
  def handle_call(:checkpoint, _from, state) do
    {reply, new_state} = perform_checkpoint(state)
    {:reply, reply, new_state}
  end

  @impl true
  def handle_call(:health, _from, state) do
    {:reply,
     %{
       status: if(state.last_checkpoint_error, do: :degraded, else: :healthy),
       entries: map_size(state.memory),
       writes: state.writes,
       deletes: state.deletes,
       last_checkpoint: state.last_checkpoint,
       last_checkpoint_error: state.last_checkpoint_error
     }, state}
  end

  @impl true
  def handle_info(:checkpoint, state) do
    {_reply, state} = perform_checkpoint(state)
    schedule_checkpoint(state.checkpoint_interval)
    {:noreply, state}
  end

  defp perform_checkpoint(state) do
    snapshot = snapshot_state(state)

    with :ok <- write_snapshot(state.storage_path, snapshot),
         {:ok, checkpoint} <-
           SafeCPL.create_checkpoint(:runtime_state, Map.drop(snapshot, [:memory])) do
      publish(:executive_memory_checkpoint, %{entries: snapshot.entries, checkpoint: checkpoint})
      {{:ok, checkpoint}, %{state | last_checkpoint: checkpoint, last_checkpoint_error: nil}}
    else
      {:error, reason} ->
        FailureObservatory.record_failure(:executive_memory_checkpoint, reason)
        {{:error, reason}, %{state | last_checkpoint_error: inspect(reason)}}
    end
  end

  defp snapshot_state(state) do
    %{
      component: :executive_memory,
      entries: map_size(state.memory),
      writes: state.writes,
      deletes: state.deletes,
      memory: state.memory,
      timestamp: now()
    }
  end

  defp write_snapshot(storage_path, snapshot) do
    file = Path.join(storage_path, @snapshot_file)
    tmp = file <> ".tmp"

    with :ok <- File.write(tmp, :erlang.term_to_binary(snapshot)),
         :ok <- replace_file(tmp, file) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp replace_file(tmp, file) do
    case File.rename(tmp, file) do
      :ok ->
        :ok

      {:error, :eexist} ->
        with :ok <- File.rm(file),
             :ok <- File.rename(tmp, file) do
          :ok
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp load_snapshot(%{storage_path: storage_path} = state) do
    file = Path.join(storage_path, @snapshot_file)

    case File.read(file) do
      {:ok, binary} ->
        case :erlang.binary_to_term(binary) do
          %{memory: memory, writes: writes, deletes: deletes} ->
            %{state | memory: memory, writes: writes, deletes: deletes}

          _ ->
            state
        end

      {:error, :enoent} ->
        state

      {:error, reason} ->
        %{state | last_checkpoint_error: inspect(reason)}
    end
  rescue
    error -> %{state | last_checkpoint_error: inspect(error)}
  end

  defp trim_memory(memory, max_entries) when map_size(memory) <= max_entries, do: memory

  defp trim_memory(memory, max_entries) do
    memory
    |> Enum.sort_by(fn {_key, entry} -> entry.updated_at end, :desc)
    |> Enum.take(max_entries)
    |> Map.new()
  end

  defp next_version(nil), do: 1
  defp next_version(%{version: version}), do: version + 1

  defp schedule_checkpoint(interval), do: Process.send_after(self(), :checkpoint, interval)

  defp publish(topic, payload) do
    if Process.whereis(SentinelEventBus) do
      SentinelEventBus.publish(topic, payload, %{source: __MODULE__})
    end
  end

  defp now, do: System.system_time(:millisecond)
end
