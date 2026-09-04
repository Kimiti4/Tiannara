defmodule TiannaraOS.Governance.RatificationManager do
  @moduledoc """
  RatificationManager - Manage RFC ratification process.

  Coordinates governance council voting, enforces quorum requirements,
  records ratification decisions, and triggers deployment on approval.

  ## Archaeology

  - **purpose**: Orchestrate formal ratification of RFC proposals
  - **introduced_in**: Phase 14.1
  - **depends_on**: TiannaraOS.Governance.RFC, TiannaraOS.Governance.RFCRegistry
  - **constitution_reference**: PHASE14_1_RFC_SYSTEM_SPECIFICATION.md Section 3.6
  - **owner**: Governance Council

  ## Usage

      {:ok, vote_id} = RatificationManager.initiate_vote(rfc_id)
      {:ok, result} = RatificationManager.cast_vote(vote_id, voter_id, :approve)
      {:ok, record} = RatificationManager.finalize_vote(vote_id)
  """

  use GenServer

  alias TiannaraOS.Governance.{RFC, RFCRegistry}

  @type rfc_id :: String.t()
  @type vote_id :: String.t()
  @type voter_id :: String.t()
  @type vote :: :approve | :reject | :abstain
  @type ratification_record :: map()

  # Client API

  @doc """
  Start the RatificationManager.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Initiate a ratification vote for an RFC.

  Returns {:ok, vote_id} or {:error, reason}.
  """
  @spec initiate_vote(rfc_id(), [voter_id()]) :: {:ok, vote_id()} | {:error, term()}
  def initiate_vote(rfc_id, voters) do
    GenServer.call(__MODULE__, {:initiate_vote, rfc_id, voters})
  end

  @doc """
  Cast a vote in a ratification process.

  Returns {:ok, vote_record} or {:error, reason}.
  """
  @spec cast_vote(vote_id(), voter_id(), vote()) :: {:ok, map()} | {:error, term()}
  def cast_vote(vote_id, voter_id, vote) do
    GenServer.call(__MODULE__, {:cast_vote, vote_id, voter_id, vote})
  end

  @doc """
  Finalize a vote and determine ratification outcome.

  Checks quorum (>= 2/3 participation) and approval threshold (>= 2/3 approve).
  Returns {:ok, ratification_record} or {:error, reason}.
  """
  @spec finalize_vote(vote_id()) :: {:ok, ratification_record()} | {:error, term()}
  def finalize_vote(vote_id) do
    GenServer.call(__MODULE__, {:finalize_vote, vote_id})
  end

  @doc """
  Get vote status and results.

  Returns {:ok, vote_summary} or {:error, :not_found}.
  """
  @spec get_vote_status(vote_id()) :: {:ok, map()} | {:error, :not_found}
  def get_vote_status(vote_id) do
    GenServer.call(__MODULE__, {:get_vote_status, vote_id})
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    {:ok, %{
      votes: %{},          # %{vote_id => vote_record}
      active_votes: %{}    # %{rfc_id => vote_id}
    }}
  end

  @impl true
  def handle_call({:initiate_vote, rfc_id, voters}, _from, state) do
    # Verify RFC exists and is ready for ratification
    case RFCRegistry.get_rfc(rfc_id) do
      {:error, :not_found} ->
        {:reply, {:error, :rfc_not_found}, state}
      {:ok, %RFC{status: :simulation_passed}} ->
        vote_id = generate_vote_id()
        
        vote_record = %{
          vote_id: vote_id,
          rfc_id: rfc_id,
          voters: voters,
          votes_cast: %{},   # %{voter_id => {:approve | :reject | :abstain, timestamp}}
          initiated_at: DateTime.utc_now(),
          finalized_at: nil,
          status: :active,
          result: nil
        }
        
        votes = Map.put(state.votes, vote_id, vote_record)
        active_votes = Map.put(state.active_votes, rfc_id, vote_id)
        
        {:reply, {:ok, vote_id}, %{state | votes: votes, active_votes: active_votes}}
      {:ok, %RFC{status: status}} ->
        {:reply, {:error, {:invalid_status, status}}, state}
    end
  end

  @impl true
  def handle_call({:cast_vote, vote_id, voter_id, vote}, _from, state) do
    case Map.get(state.votes, vote_id) do
      nil ->
        {:reply, {:error, :vote_not_found}, state}
      vote_record when vote_record.status != :active ->
        {:reply, {:error, :vote_not_active}, state}
      vote_record ->
        # Check voter is authorized
        unless voter_id in vote_record.voters do
          {:reply, {:error, :unauthorized_voter}, state}
        else
          # Check voter hasn't already voted
          if Map.has_key?(vote_record.votes_cast, voter_id) do
            {:reply, {:error, :already_voted}, state}
          else
            # Record vote
            votes_cast = Map.put(vote_record.votes_cast, voter_id, {vote, DateTime.utc_now()})
            updated_vote = %{vote_record | votes_cast: votes_cast}
            
            votes = Map.put(state.votes, vote_id, updated_vote)
            
            {:reply, {:ok, %{voter_id: voter_id, vote: vote, timestamp: DateTime.utc_now()}}, 
             %{state | votes: votes}}
          end
        end
    end
  end

  @impl true
  def handle_call({:finalize_vote, vote_id}, _from, state) do
    case Map.get(state.votes, vote_id) do
      nil ->
        {:reply, {:error, :vote_not_found}, state}
      vote_record when vote_record.status != :active ->
        {:reply, {:error, :vote_already_finalized}, state}
      vote_record ->
        # Calculate results
        total_voters = length(vote_record.voters)
        votes_cast_count = map_size(vote_record.votes_cast)
        
        # Count vote types
        {approvals, rejections, abstentions} = count_votes(vote_record.votes_cast)
        
        # Check quorum (>= 2/3 participation)
        quorum_met = votes_cast_count >= ceil(total_voters * 2 / 3)
        
        # Determine result
        result = if quorum_met do
          approval_rate = approvals / votes_cast_count
          if approval_rate >= 2 / 3 do
            :approved
          else
            :rejected
          end
        else
          :failed_quorum
        end
        
        # Update RFC status
        rfc_status = case result do
          :approved -> :ratified
          :rejected -> :rejected
          :failed_quorum -> :failed_quorum
        end
        
        # Update RFC
        update_rfc_status(vote_record.rfc_id, rfc_status)
        
        # Create ratification record
        ratification_record = %{
          vote_id: vote_id,
          rfc_id: vote_record.rfc_id,
          result: result,
          total_voters: total_voters,
          votes_cast: votes_cast_count,
          approvals: approvals,
          rejections: rejections,
          abstentions: abstentions,
          quorum_met: quorum_met,
          approval_rate: if(votes_cast_count > 0, do: approvals / votes_cast_count, else: 0),
          finalized_at: DateTime.utc_now(),
          votes_detail: vote_record.votes_cast
        }
        
        # Update vote record
        updated_vote = %{
          vote_record |
          status: :finalized,
          finalized_at: DateTime.utc_now(),
          result: result
        }
        
        votes = Map.put(state.votes, vote_id, updated_vote)
        
        {:reply, {:ok, ratification_record}, %{state | votes: votes}}
    end
  end

  @impl true
  def handle_call({:get_vote_status, vote_id}, _from, state) do
    case Map.get(state.votes, vote_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      vote_record ->
        {approvals, rejections, abstentions} = count_votes(vote_record.votes_cast)
        
        summary = %{
          vote_id: vote_id,
          rfc_id: vote_record.rfc_id,
          status: vote_record.status,
          total_voters: length(vote_record.voters),
          votes_cast: map_size(vote_record.votes_cast),
          approvals: approvals,
          rejections: rejections,
          abstentions: abstentions,
          result: vote_record.result
        }
        
        {:reply, {:ok, summary}, state}
    end
  end

  # Private helpers

  defp generate_vote_id() do
    "VOTE-#{:erlang.unique_integer([:positive])}"
  end

  defp count_votes(votes_cast) do
    Enum.reduce(votes_cast, {0, 0, 0}, fn {_voter, {vote, _ts}}, {a, r, ab} ->
      case vote do
        :approve -> {a + 1, r, ab}
        :reject -> {a, r + 1, ab}
        :abstain -> {a, r, ab + 1}
      end
    end)
  end

  defp update_rfc_status(rfc_id, status) do
    case RFCRegistry.get_rfc(rfc_id) do
      {:ok, rfc} ->
        updated_rfc = %RFC{rfc | status: status, updated_at: DateTime.utc_now()}
        RFCRegistry.update_rfc(updated_rfc)
      _ ->
        :ok
    end
  end
end
