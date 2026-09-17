defmodule Tiannara.Phase14.Formal.ByzantineConsensus do
  @moduledoc """
  PBFT-lite consensus engine for cross-instance REG axiom adoption.
  Operates over NATS/JetStream with durable phase transitions.
  """
  use GenServer
  require Logger

  alias Tiannara.Phase14.Formal.{EquivocationDetector, ViewChangeEngine}

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, %{
      conn_name: opts[:connection_name],
      instance_count: Keyword.get(opts, :instance_count, 4),
      max_faulty: Keyword.get(opts, :max_faulty, 1),
      rounds: %{},
      finalized_axioms: %{}
    }}
  end

  @doc "Propose axiom set for cross-instance consensus"
  @spec propose_round(round_id :: String.t(), axioms :: map(), leader :: String.t()) :: :ok
  def propose_round(rid, axioms, leader), do: GenServer.cast(__MODULE__, {:propose, rid, axioms, leader})

  @doc "Cast prepare/commit vote"
  @spec cast_vote(round_id :: String.t(), voter :: String.t(), phase :: :prepare | :commit, axioms_hash :: String.t()) :: :ok
  def cast_vote(rid, voter, phase, hash), do: GenServer.cast(__MODULE__, {:vote, rid, voter, phase, hash})

  @impl true
  def handle_cast({:propose, rid, axioms, leader}, state) do
    hash = :crypto.hash(:sha256, :erlang.term_to_binary(axioms)) |> Base.encode16()
    round = %{leader: leader, axioms_hash: hash, prepare_votes: %{}, commit_votes: %{}, status: :proposed}
    
    # Broadcast pre-prepare via NATS
    Gnat.pub(state.conn_name, "tiannara.reg.bft.preprepare", 
             Jason.encode!(%{round_id: rid, leader: leader, axioms_hash: hash}))
    
    {:noreply, %{state | rounds: Map.put(state.rounds, rid, round)}}
  end

  def handle_cast({:vote, rid, voter, phase, hash}, state) do
    case Map.fetch(state.rounds, rid) do
      {:ok, round} ->
        # Equivocation check
        if EquivocationDetector.detect(round, voter, phase, hash) do
          Logger.warning("🚨 BFT: Equivocation detected from #{voter} in round #{rid}")
          {:noreply, state}
        end
        
        new_round = update_votes(round, phase, voter)
        required = 2 * state.max_faulty + 1
        
        cond do
          phase == :prepare and map_size(new_round.prepare_votes) >= required ->
            broadcast_phase(rid, :commit, state.conn_name)
            {:noreply, %{state | rounds: Map.put(state.rounds, rid, %{new_round | status: :prepared})}}
          phase == :commit and map_size(new_round.commit_votes) >= required + 1 ->
            Logger.info("✅ BFT: Finality reached for round #{rid}")
            Gnat.pub(state.conn_name, "tiannara.reg.bft.finalized", Jason.encode!(%{round_id: rid, hash: round.axioms_hash}))
            {:noreply, %{state | rounds: Map.put(state.rounds, rid, %{new_round | status: :committed})}}
          true ->
            {:noreply, %{state | rounds: Map.put(state.rounds, rid, new_round)}}
        end
      :error -> {:noreply, state}
    end
  end

  defp update_votes(round, phase, voter), do: Map.update!(round, :"#{phase}_votes", &Map.put(&1, voter, true))
  defp broadcast_phase(rid, phase, conn), do: Gnat.pub(conn, "tiannara.reg.bft.#{phase}", Jason.encode!(%{round_id: rid}))
end