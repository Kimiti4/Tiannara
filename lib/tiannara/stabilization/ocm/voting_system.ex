defmodule Tiannara.Stabilization.OCM.VotingSystem do
  @moduledoc """
  Handles voting mechanisms for consensus building.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def cast_vote(session_id, voter_id, concept_id, vote, weight \\ 1.0) do
    GenServer.call(__MODULE__, {:cast_vote, session_id, voter_id, concept_id, vote, weight})
  end

  def get_concept_votes(session_id, concept_id) do
    GenServer.call(__MODULE__, {:get_concept_votes, session_id, concept_id})
  end

  def get_session_votes(session_id) do
    GenServer.call(__MODULE__, {:get_session_votes, session_id})
  end

  def calculate_concept_consensus(session_id, concept_id) do
    GenServer.call(__MODULE__, {:calculate_concept_consensus, session_id, concept_id})
  end

  def get_voting_statistics(session_id) do
    GenServer.call(__MODULE__, {:get_voting_statistics, session_id})
  end

  def validate_voter_eligibility(voter_id, session_id) do
    GenServer.call(__MODULE__, {:validate_voter_eligibility, voter_id, session_id})
  end

  def register_voter(voter_id, session_id, weight \\ 1.0) do
    GenServer.call(__MODULE__, {:register_voter, voter_id, session_id, weight})
  end

  def get_voter_status(voter_id) do
    GenServer.call(__MODULE__, {:get_voter_status, voter_id})
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize ETS tables for voting
    :ets.new(:session_votes, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:voter_registry, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:voting_weights, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:vote_validation, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    Logger.info("Voting system initialized")
    
    {:ok, %{
      total_votes: 0,
      voter_count: 0,
      session_count: 0,
      last_vote: 0,
      fraud_detection_enabled: true
    }}
  end

  @impl true
  def handle_call({:cast_vote, session_id, voter_id, concept_id, vote, weight}, _from, state) do
    # Validate vote
    case validate_vote(vote) do
      :ok ->
        # Validate voter
        case validate_voter(voter_id, session_id) do
          :ok ->
            # Check for duplicate votes
            case check_duplicate_vote(session_id, voter_id, concept_id) do
              :no_duplicate ->
                # Cast vote
                timestamp = System.system_time(:millisecond)
                vote_data = %{
                  session_id: session_id,
                  voter_id: voter_id,
                  concept_id: concept_id,
                  vote: vote,
                  weight: weight,
                  timestamp: timestamp
                }

                :ets.insert(:session_votes, {session_id, vote_data})
                
                # Update voter registry
                update_voter_registry(voter_id, session_id, timestamp)
                
                Logger.debug("Vote cast by #{voter_id} on concept #{concept_id}")
                
                {:reply, {:ok, vote_data}, 
                 %{state | 
                   total_votes: state.total_votes + 1,
                   last_vote: timestamp
                 }}
                
              {:duplicate, existing_vote} ->
                Logger.warning("Duplicate vote detected from #{voter_id} on concept #{concept_id}")
                {:reply, {:error, :duplicate_vote, existing_vote}, state}
            end
            
          {:error, reason} ->
            Logger.error("Voter validation failed: #{reason}")
            {:reply, {:error, reason}, state}
        end
        
      {:error, reason} ->
        Logger.error("Invalid vote: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:get_concept_votes, session_id, concept_id}, _from, state) do
    votes = :ets.select(:session_votes, [{
      {session_id, :"$1"},
      [{:==, {:element, 3, :"$1"}, concept_id}],
      [:"$1"]
    }])
    
    {:reply, {:ok, votes}, state}
  end

  @impl true
  def handle_call({:get_session_votes, session_id}, _from, state) do
    votes = :ets.select(:session_votes, [{
      {session_id, :"$1"},
      [],
      [:"$1"]
    }])
    
    {:reply, {:ok, votes}, state}
  end

  @impl true
  def handle_call({:calculate_concept_consensus, session_id, concept_id}, _from, state) do
    case :ets.lookup(:session_votes, session_id) do
      votes when votes != [] ->
        # Filter votes for specific concept
        concept_votes = Enum.filter(votes, fn {_, vote_data} -> 
          vote_data.concept_id == concept_id
        end)
        
        case length(concept_votes) do
          0 ->
            {:reply, {:error, :no_votes}, state}
            
          _ ->
            # Calculate consensus
            consensus_result = calculate_consensus_for_concept(concept_votes)
            {:reply, {:ok, consensus_result}, state}
        end
        
      [] ->
        {:reply, {:error, :session_not_found}, state}
    end
  end

  @impl true
  def handle_call({:get_voting_statistics, session_id}, _from, state) do
    case :ets.lookup(:session_votes, session_id) do
      votes when votes != [] ->
        # Calculate statistics
        total_votes = length(votes)
        unique_voters = votes |> Enum.map(&elem(&1, 1).voter_id) |> Enum.uniq() |> length()
        concepts_voted_on = votes |> Enum.map(&elem(&1, 1).concept_id) |> Enum.uniq() |> length()
        
        # Calculate vote distribution
        vote_distribution = calculate_vote_distribution(votes)
        
        # Calculate participation rate
        registered_voters = :ets.lookup(:voter_registry, session_id)
        participation_rate = if length(registered_voters) > 0 do
          unique_voters / length(registered_voters)
        else
          0.0
        end
        
        statistics = %{
          session_id: session_id,
          total_votes: total_votes,
          unique_voters: unique_voters,
          concepts_voted_on: concepts_voted_on,
          vote_distribution: vote_distribution,
          participation_rate: participation_rate,
          timestamp: System.system_time(:millisecond)
        }
        
        {:reply, {:ok, statistics}, state}
        
      [] ->
        {:reply, {:error, :session_not_found}, state}
    end
  end

  @impl true
  def handle_call({:validate_voter_eligibility, voter_id, session_id}, _from, state) do
    case :ets.lookup(:voter_registry, voter_id) do
      [{^voter_id, registry_data}] ->
        case registry_data do
          %{session_id: ^session_id, status: :registered} ->
            {:reply, {:ok, :eligible}, state}
          %{session_id: ^session_id, status: :banned} ->
            {:reply, {:error, :voter_banned}, state}
          %{session_id: _other_session} ->
            {:reply, {:error, :wrong_session}, state}
        end
        
      [] ->
        {:reply, {:error, :voter_not_registered}, state}
    end
  end

  @impl true
  def handle_call({:register_voter, voter_id, session_id, weight}, _from, state) do
    # Check if voter already registered
    case :ets.lookup(:voter_registry, voter_id) do
      [{^voter_id, _}] ->
        Logger.warning("Voter #{voter_id} already registered")
        {:reply, {:error, :already_registered}, state}
        
      [] ->
        # Register voter
        registry_data = %{
          voter_id: voter_id,
          session_id: session_id,
          weight: weight,
          registered_at: System.system_time(:millisecond),
          status: :registered,
          votes_cast: 0
        }
        
        :ets.insert(:voter_registry, {voter_id, registry_data})
        :ets.insert(:voting_weights, {voter_id, weight})
        
        Logger.info("Registered voter #{voter_id} for session #{session_id}")
        
        {:reply, :ok, 
         %{state | 
           voter_count: state.voter_count + 1,
           session_count: state.session_count + 1
         }}
    end
  end

  @impl true
  def handle_call({:get_voter_status, voter_id}, _from, state) do
    case :ets.lookup(:voter_registry, voter_id) do
      [{^voter_id, status_data}] ->
        {:reply, {:ok, status_data}, state}
      [] ->
        {:reply, {:error, :voter_not_found}, state}
    end
  end

  # Helper functions
  defp validate_vote(vote) do
    case vote do
      :for -> :ok
      :against -> :ok
      :abstain -> :ok
      _ -> {:error, :invalid_vote_type}
    end
  end

  defp validate_voter(voter_id, session_id) do
    case :ets.lookup(:voter_registry, voter_id) do
      [{^voter_id, %{session_id: ^session_id, status: :registered}}] -> :ok
      [{^voter_id, %{status: :banned}}] -> {:error, :voter_banned}
      [{^voter_id, %{session_id: _other_session}}] -> {:error, :wrong_session}
      [] -> {:error, :voter_not_registered}
    end
  end

  defp check_duplicate_vote(session_id, voter_id, concept_id) do
    votes = :ets.select(:session_votes, [{
      {session_id, :"$1"},
      [{:==, {:element, 2, :"$1"}, voter_id}, {:==, {:element, 3, :"$1"}, concept_id}],
      [:"$1"]
    }])
    
    case length(votes) do
      0 -> :no_duplicate
      _ -> {:duplicate, hd(votes)}
    end
  end

  defp update_voter_registry(voter_id, _session_id, timestamp) do
    case :ets.lookup(:voter_registry, voter_id) do
      [{^voter_id, registry_data}] ->
        updated_data = %{registry_data | 
          votes_cast: registry_data.votes_cast + 1,
          last_vote: timestamp
        }
        :ets.insert(:voter_registry, {voter_id, updated_data})
      [] ->
        # This shouldn't happen if validation worked correctly
        :ok
    end
  end

  defp calculate_consensus_for_concept(concept_votes) do
    # Calculate weighted consensus
    total_weight = Enum.sum(Enum.map(concept_votes, & &1.weight))
    
    for_weight = Enum.filter(concept_votes, & &1.vote == :for)
    |> Enum.map(& &1.weight)
    |> Enum.sum()
    
    against_weight = Enum.filter(concept_votes, & &1.vote == :against)
    |> Enum.map(& &1.weight)
    |> Enum.sum()
    
    abstain_weight = Enum.filter(concept_votes, & &1.vote == :abstain)
    |> Enum.map(& &1.weight)
    |> Enum.sum()
    
    agreement_ratio = if total_weight > 0, do: for_weight / total_weight, else: 0.0
    
    consensus_status = cond do
      agreement_ratio >= 0.75 -> :strong_consensus
      agreement_ratio >= 0.6 -> :weak_consensus
      against_weight / max(total_weight, 1) >= 0.4 -> :consensus_against
      abstain_weight / max(total_weight, 1) >= 0.5 -> :insufficient_participation
      true -> :no_consensus
    end
    
    %{
      concept_id: hd(concept_votes).concept_id,
      total_weight: total_weight,
      for_weight: for_weight,
      against_weight: against_weight,
      abstain_weight: abstain_weight,
      agreement_ratio: agreement_ratio,
      consensus_status: consensus_status,
      total_votes: length(concept_votes),
      timestamp: System.system_time(:millisecond)
    }
  end

  defp calculate_vote_distribution(votes) do
    # Count votes by type
    vote_counts = Enum.reduce(votes, %{for: 0, against: 0, abstain: 0}, fn {_, vote_data}, counts ->
      case vote_data.vote do
        :for -> %{counts | for: counts.for + 1}
        :against -> %{counts | against: counts.against + 1}
        :abstain -> %{counts | abstain: counts.abstain + 1}
      end
    end)
    
    total = length(votes)
    if total > 0 do
      %{
        for: vote_counts.for / total,
        against: vote_counts.against / total,
        abstain: vote_counts.abstain / total,
        total_votes: total
      }
    else
      %{for: 0.0, against: 0.0, abstain: 0.0, total_votes: 0}
    end
  end
end
