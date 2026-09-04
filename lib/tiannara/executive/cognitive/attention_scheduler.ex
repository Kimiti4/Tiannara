defmodule Tiannara.Executive.Cognitive.AttentionScheduler do
  @moduledoc """
  Attention Scheduler — determines what the executive runtime focuses on.

  Implements priority-based attention allocation, ensuring that the most
  urgent and constitutionally relevant items receive processing first.
  """

  use GenServer

  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec prioritize(map()) :: [map()]
  def prioritize(context) do
    GenServer.call(__MODULE__, {:prioritize, context})
  end

  @spec queue() :: [map()]
  def queue do
    GenServer.call(__MODULE__, :queue)
  end

  @spec active_count() :: non_neg_integer()
  def active_count do
    GenServer.call(__MODULE__, :active_count)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(_opts) do
    {:ok, %{queue: [], total_prioritized: 0, last_prioritization_at: nil}}
  end

  @impl true
  def handle_call({:prioritize, context}, _from, state) do
    priorities = compute_priorities(context)
    {:reply, priorities, %{state | queue: priorities, total_prioritized: state.total_prioritized + 1, last_prioritization_at: DateTime.utc_now()}}
  end

  @impl true
  def handle_call(:queue, _from, state) do
    {:reply, state.queue, state}
  end

  @impl true
  def handle_call(:active_count, _from, state) do
    {:reply, length(state.queue), state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{queue_length: length(state.queue), total_prioritized: state.total_prioritized, last_prioritization_at: state.last_prioritization_at}, state}
  end

  defp compute_priorities(%{urgency: urgency_map}) when is_map(urgency_map) do
    urgency_map
    |> Enum.map(fn {type, %{count: count, urgency: score}} ->
      %{target: type, priority: score, count: count, rationale: "urgency=#{score}, count=#{count}", created_at: DateTime.utc_now()}
    end)
    |> Enum.sort_by(& &1.priority, :desc)
  end

  defp compute_priorities(_context) do
    []
  end
end
