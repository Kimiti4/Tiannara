defmodule Tiannara.Executive.Cognitive.ExecutiveBlackboard do
  @moduledoc """
  Executive Blackboard — shared knowledge space for the cognitive runtime.

  All cognitive modules post observations, interpretations, plans, executions,
  validations, and reflections to the blackboard. Any module can read any
  topic, enabling loosely coupled coordination.
  """

  use GenServer

  require Logger

  @max_entries_per_topic 100

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec post(atom(), term()) :: :ok
  def post(topic, entry) do
    GenServer.cast(__MODULE__, {:post, topic, entry})
  end

  @spec read(atom()) :: [term()]
  def read(topic) do
    GenServer.call(__MODULE__, {:read, topic})
  end

  @spec read_latest(atom()) :: term() | nil
  def read_latest(topic) do
    GenServer.call(__MODULE__, {:read_latest, topic})
  end

  @spec topics() :: [atom()]
  def topics do
    GenServer.call(__MODULE__, :topics)
  end

  @spec clear_topic(atom()) :: :ok
  def clear_topic(topic) do
    GenServer.cast(__MODULE__, {:clear_topic, topic})
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(_opts) do
    {:ok, %{board: %{}, total_posts: 0, total_reads: 0}}
  end

  @impl true
  def handle_cast({:post, topic, entry}, state) do
    entries = Map.get(state.board, topic, [])
    new_entries = [entry | Enum.take(entries, @max_entries_per_topic - 1)]
    {:noreply, %{state | board: Map.put(state.board, topic, new_entries), total_posts: state.total_posts + 1}}
  end

  @impl true
  def handle_cast({:clear_topic, topic}, state) do
    {:noreply, %{state | board: Map.delete(state.board, topic)}}
  end

  @impl true
  def handle_call({:read, topic}, _from, state) do
    {:reply, Map.get(state.board, topic, []), %{state | total_reads: state.total_reads + 1}}
  end

  @impl true
  def handle_call({:read_latest, topic}, _from, state) do
    entry = case Map.get(state.board, topic, []) do
      [latest | _] -> latest
      [] -> nil
    end
    {:reply, entry, %{state | total_reads: state.total_reads + 1}}
  end

  @impl true
  def handle_call(:topics, _from, state) do
    {:reply, Map.keys(state.board), state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{
      topics: Map.keys(state.board),
      topic_counts: Map.new(state.board, fn {k, v} -> {k, length(v)} end),
      total_posts: state.total_posts,
      total_reads: state.total_reads
    }, state}
  end
end
