defmodule TiannaraOS.Governance.ProposalIndex do
  @moduledoc """
  ProposalIndex - Fast lookup index for proposals
  
  Provides O(1) lookup of proposals by various keys using ETS tables.
  Indexes are automatically updated when events are appended to the ledger.
  
  ## Index Types
  - By proposal_id
  - By rfc_id
  - By status
  - By proposer
  - By created_at (time range queries)
  
  ## Owner
  ProposalLedger maintains this index automatically.
  """

  # === Initialization ===

  @doc """
  Initialize all index tables.
  """
  @spec init() :: :ok
  def init() do
    :ets.new(:proposal_index_by_id, [:set, :named_table, :public])
    :ets.new(:proposal_index_by_rfc, [:bag, :named_table, :public])
    :ets.new(:proposal_index_by_status, [:bag, :named_table, :public])
    :ets.new(:proposal_index_by_proposer, [:bag, :named_table, :public])
    :ets.new(:proposal_index_by_time, [:ordered_set, :named_table, :public])
    
    :ok
  end

  # === Index Operations ===

  @doc """
  Index a proposal by all keys.
  """
  @spec index_proposal(map()) :: :ok
  def index_proposal(proposal) do
    proposal_id = proposal.proposal_id
    rfc_id = proposal.rfc_id
    status = proposal.status
    proposer = proposal.proposer
    created_at = proposal.created_at
    
    # Index by ID
    :ets.insert(:proposal_index_by_id, {proposal_id, proposal})
    
    # Index by RFC
    :ets.insert(:proposal_index_by_rfc, {rfc_id, proposal_id})
    
    # Index by status
    :ets.insert(:proposal_index_by_status, {status, proposal_id})
    
    # Index by proposer
    :ets.insert(:proposal_index_by_proposer, {proposer, proposal_id})
    
    # Index by time (for range queries)
    timestamp = DateTime.to_unix(created_at, :millisecond)
    :ets.insert(:proposal_index_by_time, {{timestamp, proposal_id}, proposal_id})
    
    :ok
  end

  @doc """
  Update proposal status in index.
  """
  @spec update_status(String.t(), atom(), atom()) :: :ok
  def update_status(proposal_id, old_status, new_status) do
    # Remove from old status index
    :ets.match_delete(:proposal_index_by_status, {old_status, proposal_id})
    
    # Add to new status index
    :ets.insert(:proposal_index_by_status, {new_status, proposal_id})
    
    :ok
  end

  @doc """
  Get proposal by ID (O(1) lookup).
  """
  @spec get_by_id(String.t()) :: map() | nil
  def get_by_id(proposal_id) do
    case :ets.lookup(:proposal_index_by_id, proposal_id) do
      [{^proposal_id, proposal}] -> proposal
      [] -> nil
    end
  end

  @doc """
  Get all proposals for an RFC.
  """
  @spec get_by_rfc(String.t()) :: [map()]
  def get_by_rfc(rfc_id) do
    case :ets.lookup(:proposal_index_by_rfc, rfc_id) do
      [] -> []
      matches ->
        matches
        |> Enum.map(fn {^rfc_id, proposal_id} -> get_by_id(proposal_id) end)
        |> Enum.filter(& &1)
    end
  end

  @doc """
  Get all proposals with a specific status.
  """
  @spec get_by_status(atom()) :: [map()]
  def get_by_status(status) do
    case :ets.lookup(:proposal_index_by_status, status) do
      [] -> []
      matches ->
        matches
        |> Enum.map(fn {^status, proposal_id} -> get_by_id(proposal_id) end)
        |> Enum.filter(& &1)
    end
  end

  @doc """
  Get all proposals by a specific proposer.
  """
  @spec get_by_proposer(String.t()) :: [map()]
  def get_by_proposer(proposer) do
    case :ets.lookup(:proposal_index_by_proposer, proposer) do
      [] -> []
      matches ->
        matches
        |> Enum.map(fn {^proposer, proposal_id} -> get_by_id(proposal_id) end)
        |> Enum.filter(& &1)
    end
  end

  @doc """
  Get proposals created within a time range.
  """
  @spec get_by_time_range(DateTime.t(), DateTime.t()) :: [map()]
  def get_by_time_range(start_time, end_time) do
    start_ts = DateTime.to_unix(start_time, :millisecond)
    end_ts = DateTime.to_unix(end_time, :millisecond)
        
    # Simple range query (ETS select is complex, use filter instead)
    :ets.tab2list(:proposal_index_by_time)
    |> Enum.filter(fn {{timestamp, _proposal_id}, _} ->
      timestamp >= start_ts and timestamp < end_ts
    end)
    |> Enum.map(fn {{_, proposal_id}, _} -> get_by_id(proposal_id) end)
    |> Enum.filter(& &1)
  end

  @doc """
  Count proposals by status.
  """
  @spec count_by_status() :: map()
  def count_by_status() do
    statuses = [:draft, :submitted, :under_review, :simulating, :approved,
                :ratified, :executing, :completed, :certified, :rejected, :withdrawn]
    
    Enum.into(statuses, %{}, fn status ->
      count = length(get_by_status(status))
      {status, count}
    end)
  end

  @doc """
  Get total proposal count.
  """
  @spec total_count() :: integer()
  def total_count() do
    :ets.info(:proposal_index_by_id, :size)
  end

  @doc """
  Clear all indexes (for testing).
  """
  @spec clear() :: :ok
  def clear() do
    :ets.delete_all_objects(:proposal_index_by_id)
    :ets.delete_all_objects(:proposal_index_by_rfc)
    :ets.delete_all_objects(:proposal_index_by_status)
    :ets.delete_all_objects(:proposal_index_by_proposer)
    :ets.delete_all_objects(:proposal_index_by_time)
    
    :ok
  end
end
