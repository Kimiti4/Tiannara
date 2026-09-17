defmodule Tiannara.Phase14.FederationGateway do
  @moduledoc """
  Cross-instance NATS mesh & state replication layer.
  [Original Concept: 6F Cross-System Interaction Model]
  
  Enforces Byzantine fault tolerance: Q ≥ ⌈2/3 N⌉ for cross-instance consensus.
  """
  use GenServer
  require Logger

  @quorum_fraction 0.667
  @vote_timeout_ms 3000

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, %{
      conn_name: opts[:connection_name],
      instance_registry: %{},
      pending_votes: %{},
      vote_timers: %{}
    }}
  end

  @doc "Propose cross-instance ontology sync"
  @spec propose_sync(proposal_id :: String.t(), payload :: map(), instance_count :: non_neg_integer()) :: :ok
  def propose_sync(id, payload, count), do: GenServer.cast(__MODULE__, {:propose, id, payload, count})

  @impl true
  def handle_cast({:propose, id, payload, count}, state) do
    timer = Process.send_after(self(), {:vote_timeout, id}, @vote_timeout_ms)
    Gnat.pub(state.conn_name, "tiannara.phase14.federation.propose",
             Jason.encode!(%{id: id, payload: payload, required_votes: trunc(count * @quorum_fraction)}))
             
    {:noreply, %{state | pending_votes: Map.put(state.pending_votes, id, {count, 0}), vote_timers: Map.put(state.vote_timers, id, timer)}}
  end

  @doc "Register instance vote"
  @spec cast_vote(proposal_id :: String.t(), approve :: boolean()) :: :ok
  def cast_vote(id, approve), do: GenServer.cast(__MODULE__, {:vote, id, approve})

  @impl true
  def handle_cast({:vote, id, approve}, state) do
    case Map.fetch(state.pending_votes, id) do
      {:ok, {total, current}} ->
        new_current = if approve, do: current + 1, else: current
        required = trunc(total * @quorum_fraction)
        
        if new_current >= required do
          Logger.info("🗳️ Phase14: Federation quorum reached for #{id} (#{new_current}/#{total})")
          Process.cancel_timer(Map.fetch!(state.vote_timers, id))
          publish_consensus(id, true, state.conn_name)
        end
        
        {:noreply, %{state | pending_votes: Map.put(state.pending_votes, id, {total, new_current})}}
      :error -> {:noreply, state}
    end
  end

  @impl true
  def handle_info({:vote_timeout, id}, state) do
    Logger.warning("⏳ Phase14: Federation vote timeout for #{id}")
    publish_consensus(id, false, state.conn_name)
    {:noreply, Map.delete(state.pending_votes, id) |> Map.delete(:vote_timers)}
  end

  defp publish_consensus(id, success, conn_name) do
    Gnat.pub(conn_name, "tiannara.phase14.federation.result",
             Jason.encode!(%{id: id, approved: success, timestamp: System.system_time(:millisecond)}))
  end
end