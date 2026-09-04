defmodule Tiannara.Executive.EventBus do
  @moduledoc """
  Pub/sub dispatch for the Executive Memory event system.

  Subscribers register for specific event types and receive
  messages via `Process.send/3`. Dead subscribers are automatically
  cleaned up via process monitoring.
  """

  use GenServer

  require Logger

  defstruct [:subscribers, :dead_letters]

  @type subscriber :: %{pid: pid(), types: [String.t()], ref: reference()}

  @type t :: %__MODULE__{
    subscribers: [subscriber()],
    dead_letters: non_neg_integer()
  }

  @doc "Starts the EventBus GenServer."
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  @doc "Publishes an event to all matching subscribers."
  def publish(event), do: GenServer.call(__MODULE__, {:publish, event})

  @doc "Subscribes a pid to one or more event types."
  def subscribe(pid, types) when is_list(types) do
    GenServer.call(__MODULE__, {:subscribe, pid, types})
  end

  def subscribe(pid, type) when is_binary(type) do
    subscribe(pid, [type])
  end

  @doc "Unsubscribes a pid from all event types."
  def unsubscribe(pid) do
    GenServer.call(__MODULE__, {:unsubscribe, pid})
  end

  @doc "Returns the dead letter count."
  def dead_letters, do: GenServer.call(__MODULE__, :dead_letters)

  @doc "Returns the current subscriber list."
  def subscriptions, do: GenServer.call(__MODULE__, :subscriptions)

  @impl true
  def init(:ok) do
    {:ok, %__MODULE__{subscribers: [], dead_letters: 0}}
  end

  @impl true
  def handle_call({:publish, %Tiannara.Executive.Event{type: type} = event}, _from, state) do
    matched = Enum.filter(state.subscribers, fn s -> Enum.member?(s.types, type) or Enum.member?(s.types, "*") end)
    {success, failures} = deliver(event, matched, state.dead_letters)
    {:reply, %{delivered: success, dead: failures - state.dead_letters}, %{state | dead_letters: failures}}
  end

  @impl true
  def handle_call({:subscribe, pid, types}, _from, state) do
    Process.monitor(pid)
    ref = Process.monitor(pid)
    subscriber = %{pid: pid, types: types, ref: ref}
    {:reply, :ok, %{state | subscribers: [subscriber | state.subscribers]}}
  end

  @impl true
  def handle_call({:unsubscribe, pid}, _from, state) do
    {:reply, :ok, %{state | subscribers: Enum.reject(state.subscribers, fn s -> s.pid == pid end)}}
  end

  @impl true
  def handle_call(:dead_letters, _from, state) do
    {:reply, state.dead_letters, state}
  end

  @impl true
  def handle_call(:subscriptions, _from, state) do
    {:reply, state.subscribers, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    {:noreply, %{state | subscribers: Enum.reject(state.subscribers, fn s -> s.pid == pid or s.ref == ref end)}}
  end

  defp deliver(event, subscribers, dead_count) do
    Enum.reduce(subscribers, {0, dead_count}, fn %{pid: pid} = _sub, {ok, dead} ->
      case Process.send(pid, {:executive_event, event}, []) do
        :ok -> {ok + 1, dead}
        _ -> {ok, dead + 1}
      end
    end)
  end
end
