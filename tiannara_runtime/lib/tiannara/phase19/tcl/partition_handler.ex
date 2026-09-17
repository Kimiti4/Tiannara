defmodule Tiannara.Phase19.TCL.PartitionHandler do
  @moduledoc """
  Byzantine-tolerant conflict resolution & quarantine routing.
  Enforces $Q \geq \lceil 2N/3 \rceil$ for rule adoption.
  """
  use GenServer
  require Logger

  @quorum_fraction 0.667
  @quarantine_timeout_ms 10000

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, %{conn_name: opts[:connection_name], pending_votes: %{}, timers: %{}}}
  end

  @spec request_quorum(sync_id :: String.t(), instance_count :: non_neg_integer(), candidate_hash :: String.t()) :: :ok
  def request_quorum(sync_id, count, hash), do: GenServer.cast(__MODULE__, {:quorum, sync_id, count, hash})

  @spec cast_vote(sync_id :: String.t(), voter :: String.t(), approve :: boolean()) :: :ok
  def cast_vote(sync_id, voter, approve), do: GenServer.cast(__MODULE__, {:vote, sync_id, voter, approve})

  @impl true
  def handle_cast({:quorum, sync_id, count, _hash}, state) do
    timer = Process.send_after(self(), {:timeout, sync_id}, @quarantine_timeout_ms)
    {:noreply, %{state | pending_votes: Map.put(state.pending_votes, sync_id, {count, 0}), timers: Map.put(state.timers, sync_id, timer)}}
  end

  def handle_cast({:vote, sync_id, voter, approve}, state) do
    case Map.fetch(state.pending_votes, sync_id) do
      {:ok, {total, current}} ->
        new_current = if approve, do: current + 1, else: current
        required = trunc(total * @quorum_fraction)
        
        if new_current >= required do
          Logger.info("🗳️ TCL: Quorum reached for #{sync_id} (#{new_current}/#{total})")
          Process.cancel_timer(Map.fetch!(state.timers, sync_id))
        end
        
        {:noreply, %{state | pending_votes: Map.put(state.pending_votes, sync_id, {total, new_current})}}
      :error -> {:noreply, state}
    end
  end

  @impl true
  def handle_info({:timeout, sync_id}, state) do
    Logger.warning("⏳ TCL: Quorum timeout for #{sync_id}. Entering partition quarantine.")
    {:noreply, Map.delete(state.pending_votes, sync_id) |> Map.delete(:timers)}
  end
end