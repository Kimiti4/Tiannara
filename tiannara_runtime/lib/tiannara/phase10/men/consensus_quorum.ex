defmodule Tiannara.Phase10.MEN.ConsensusQuorum do
  @moduledoc """
  Distributed partition validation & supermajority tracking.
  """
  use GenServer
  require Logger

  @quorum_fraction 0.667
  @vote_timeout_ms 5000

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, %{
      conn_name: opts[:connection_name],
      pending_votes: %{},
      vote_timers: %{}
    }}
  end

  @doc "Request partition validation for a negotiation ID"
  @spec request_quorum(neg_id :: String.t(), partition_count :: non_neg_integer()) :: :ok
  def request_quorum(neg_id, count), do: GenServer.cast(__MODULE__, {:quorum_request, neg_id, count})

  @impl true
  def handle_cast({:quorum_request, neg_id, count}, state) do
    timer = Process.send_after(self(), {:quorum_timeout, neg_id}, @vote_timeout_ms)
    {:noreply, %{state | pending_votes: Map.put(state.pending_votes, neg_id, {count, 0}), vote_timers: Map.put(state.vote_timers, neg_id, timer)}}
  end

  @doc "Register partition vote"
  @spec cast_vote(neg_id :: String.t(), approve :: boolean()) :: :ok
  def cast_vote(neg_id, approve), do: GenServer.cast(__MODULE__, {:vote, neg_id, approve})

  @impl true
  def handle_cast({:vote, neg_id, approve}, state) do
    case Map.fetch(state.pending_votes, neg_id) do
      {:ok, {total, current}} ->
        new_current = if approve, do: current + 1, else: current
        new_pending = Map.put(state.pending_votes, neg_id, {total, new_current})
        
        if new_current >= trunc(total * @quorum_fraction) do
          Logger.info("🗳️ MEN: Quorum reached for #{neg_id} (#{new_current}/#{total})")
          Process.cancel_timer(Map.fetch!(state.vote_timers, neg_id))
        end
        
        {:noreply, %{state | pending_votes: new_pending}}
      :error -> {:noreply, state}
    end
  end

  @impl true
  def handle_info({:quorum_timeout, neg_id}, state) do
    Logger.warning("⏳ MEN: Quorum timeout for #{neg_id}")
    {:noreply, Map.delete(state.pending_votes, neg_id) |> Map.delete(:vote_timers)}
  end
end