defmodule Tiannara.Executive.EventStore do
  @moduledoc """
  Append-only event log for the Executive Memory subsystem.

  Events are persisted as a framed binary log file, streamed
  sequentially for replay, and managed via a GenServer.
  """

  use GenServer

  require Logger

  defstruct [:file_path, :file_handle, :count]

  @type t :: %__MODULE__{
    file_path: String.t(),
    file_handle: File.io_device() | nil,
    count: non_neg_integer()
  }

  @doc "Starts the EventStore GenServer."
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    file_path = Keyword.get(opts, :file_path, "/tmp/tiannara_executive_events.log")
    GenServer.start_link(__MODULE__, {file_path, name}, name: name)
  end

  @doc "Appends an event to the log."
  def append(event), do: GenServer.call(__MODULE__, {:append, event})

  @doc "Streams all events since a given index."
  def stream(since \\ 0), do: GenServer.call(__MODULE__, {:stream, since})

  @doc "Returns events since a given timestamp."
  def since(timestamp), do: GenServer.call(__MODULE__, {:since, timestamp})

  @doc "Returns the current event count."
  def count, do: GenServer.call(__MODULE__, :count)

  @impl true
  def init({file_path, _name}) do
    File.mkdir_p!(Path.dirname(file_path))
    {:ok, fh} = File.open(file_path, [:append, :read, :binary])

    count =
      try do
        File.stream!(file_path, 1024) |> Enum.count()
      rescue
        _ -> 0
      end

    state = %__MODULE__{file_path: file_path, file_handle: fh, count: count}
    Logger.info("[ExecutiveMemory.EventStore] Started: #{file_path} (#{count} events)")
    {:ok, state}
  end

  @impl true
  def handle_call({:append, event}, _from, state) do
    bin = Tiannara.Executive.Event.to_binary(event)
    frame = <<byte_size(bin)::32, bin::binary>>
    IO.binwrite(state.file_handle, frame)
    state = %{state | count: state.count + 1}
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:stream, since}, _from, state) do
    events = read_events(state.file_path, since)
    {:reply, events, state}
  end

  @impl true
  def handle_call({:since, timestamp}, _from, state) do
    all_events = read_events(state.file_path, 0)
    filtered = Enum.filter(all_events, fn e -> DateTime.compare(e.timestamp, timestamp) != :lt end)
    {:reply, filtered, state}
  end

  @impl true
  def handle_call(:count, _from, state) do
    {:reply, state.count, state}
  end

  @impl true
  def terminate(_reason, state) do
    if state.file_handle, do: File.close(state.file_handle)
    :ok
  end

  defp read_events(file_path, since_offset) do
    case File.read(file_path) do
      {:ok, data} ->
        parse_frames(data, since_offset)
      _ -> []
    end
  end

  defp parse_frames(data, since_offset) do
    parse_frames(data, since_offset, 0, [])
  end

  defp parse_frames(<<size::32, frame::binary-size(size), rest::binary>>, since_offset, idx, acc) do
    event = Tiannara.Executive.Event.from_binary(frame)
    if idx >= since_offset do
      parse_frames(rest, since_offset, idx + 1, acc ++ [event])
    else
      parse_frames(rest, since_offset, idx + 1, acc)
    end
  end

  defp parse_frames(_, _, _, acc), do: acc
end
