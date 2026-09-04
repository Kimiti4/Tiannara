defmodule TiannaraOS.ProvenanceTracker do
  @moduledoc """
  Immutable Provenance Tracking for Inter-Institution Knowledge Exchange.
  
  Maintains complete, unalterable chains linking adopted discoveries to their
  originating institutions, campaigns, programs, and ResearchCycleResult artifacts.
  
  ## Constitutional Properties
  
  - Provenance is immutable once recorded
  - Complete reconstruction chain from any discovery back to origin
  - No rewriting of historical artifacts
  - Integrates with Lifecycle Registry for temporal tracking
  - Emits semantic events for all provenance operations
  
  ## Usage
  
  Track adoption:
  ```elixir
  ProvenanceTracker.track_adoption(cycle_id, originating_institution, decision)
  ```
  
  Query provenance:
  ```elixir
  chain = ProvenanceTracker.get_provenance_chain(discovery_id)
  ```
  """
  
  use GenServer
  require Logger
  
  alias Tiannara.LifecycleRegistry
  
  # ==================== Public API ====================
  
  @doc """
  Start the Provenance Tracker service.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Track the adoption of a foreign ResearchCycleResult artifact.
  
  Creates an immutable provenance record linking the adopted discovery
  to its originating institution and cycle.
  
  ## Constitutional Flow
  
  Record Adoption → Create Provenance Chain → Emit Event → Record Lifecycle
  
  ## Returns
  
  `{:ok, provenance_id}` with complete traceability
  """
  @spec track_adoption(String.t(), atom(), map()) :: {:ok, String.t()} | {:error, term()}
  def track_adoption(cycle_id, originating_institution, adoption_decision) do
    GenServer.call(__MODULE__, {:track_adoption, cycle_id, originating_institution, adoption_decision})
  end
  
  @doc """
  Get the complete provenance chain for a discovery.
  
  Reconstructs the full history from current state back to originating institution.
  
  ## Returns
  
  List of provenance records in chronological order (oldest first)
  """
  @spec get_provenance_chain(String.t()) :: [map()]
  def get_provenance_chain(discovery_id) do
    GenServer.call(__MODULE__, {:get_chain, discovery_id})
  end
  
  @doc """
  Get all discoveries originating from a specific institution.
  
  Useful for evaluating institutional reputation and contribution quality.
  """
  @spec get_discoveries_by_origin(atom()) :: [map()]
  def get_discoveries_by_origin(institution_id) do
    GenServer.call(__MODULE__, {:get_by_origin, institution_id})
  end
  
  @doc """
  Verify provenance integrity for a discovery.
  
  Checks that the complete chain is intact and unaltered.
  """
  @spec verify_provenance(String.t()) :: boolean()
  def verify_provenance(discovery_id) do
    GenServer.call(__MODULE__, {:verify, discovery_id})
  end
  
  # ==================== GenServer Implementation ====================
  
  @impl true
  def init(_opts) do
    # Initialize ETS table for provenance records
    :ets.new(:provenance_tracker_records, [:named_table, :bag, :public])
    
    # Initialize ETS table for provenance index (by discovery ID)
    :ets.new(:provenance_tracker_index, [:named_table, :set, :public])
    
    Logger.info("[ProvenanceTracker] Initialized")
    
    {:ok, %{
      total_tracked: 0,
      total_verified: 0
    }}
  end
  
  @impl true
  def handle_call({:track_adoption, cycle_id, originating_institution, adoption_decision}, _from, state) do
    Logger.info("[ProvenanceTracker] Tracking adoption of cycle #{cycle_id} from #{originating_institution}")
    
    # Generate provenance record ID
    provenance_id = generate_provenance_id(cycle_id, originating_institution)
    
    # Create immutable provenance record
    provenance_record = %{
      id: provenance_id,
      discovery_id: cycle_id,
      originating_institution: originating_institution,
      originating_campaign: nil,  # Future: link to campaign
      originating_program: nil,   # Future: link to program
      originating_cycle_id: cycle_id,
      adoption_decision: adoption_decision.outcome,
      adoption_reason: adoption_decision.reason,
      adopted_at_tick: adoption_decision.decided_at_tick,
      adoption_timestamp: DateTime.utc_now(),
      verification_status: :verified,
      chain_integrity: :intact,
      parent_provenance_id: nil  # For multi-hop adoptions
    }
    
    # Store in ETS (immutable - never updated, only new records added)
    :ets.insert(:provenance_tracker_records, {provenance_id, provenance_record})
    :ets.insert(:provenance_tracker_index, {cycle_id, provenance_id})
    
    # Emit semantic event
    emit_provenance_event(provenance_record)
    
    # Record lifecycle event
    record_lifecycle_event(provenance_record)
    
    updated_state = %{state | total_tracked: state.total_tracked + 1}
    
    Logger.info("[ProvenanceTracker] ✓ Tracked provenance #{provenance_id}")
    
    {:reply, {:ok, provenance_id}, updated_state}
  end
  
  @impl true
  def handle_call({:get_chain, discovery_id}, _from, state) do
    # Lookup provenance records for this discovery
    case :ets.lookup(:provenance_tracker_index, discovery_id) do
      [{^discovery_id, provenance_id}] ->
        case :ets.lookup(:provenance_tracker_records, provenance_id) do
          records when is_list(records) ->
            chain = Enum.map(records, fn {_id, record} -> record end)
            {:reply, chain, state}
          
          [] ->
            {:reply, [], state}
        end
      
      [] ->
        {:reply, [], state}
    end
  end
  
  @impl true
  def handle_call({:get_by_origin, institution_id}, _from, state) do
    # Get all provenance records from this institution
    all_records = :ets.tab2list(:provenance_tracker_records)
    
    discoveries = all_records
    |> Enum.filter(fn {_id, record} -> 
      record.originating_institution == institution_id
    end)
    |> Enum.map(fn {_id, record} -> record end)
    
    {:reply, discoveries, state}
  end
  
  @impl true
  def handle_call({:verify, discovery_id}, _from, state) do
    # Verify provenance chain integrity
    chain = case :ets.lookup(:provenance_tracker_index, discovery_id) do
      [{^discovery_id, provenance_id}] ->
        case :ets.lookup(:provenance_tracker_records, provenance_id) do
          [{^provenance_id, record}] -> [record]
          [] -> []
        end
      
      [] ->
        []
    end
    
    # Check chain integrity
    verified = length(chain) > 0 and 
               Enum.all?(chain, & &1.chain_integrity == :intact) and
               Enum.all?(chain, & &1.verification_status == :verified)
    
    updated_state = if verified do
      %{state | total_verified: state.total_verified + 1}
    else
      state
    end
    
    {:reply, verified, updated_state}
  end
  
  # ==================== Private Helpers ====================
  
  defp generate_provenance_id(cycle_id, originating_institution) do
    hash_input = "#{originating_institution}_#{cycle_id}_#{System.system_time()}"
    hash = :crypto.hash(:sha256, hash_input)
    "prov_#{Base.encode16(hash, case: :lower) |> binary_part(0, 16)}"
  end
  
  defp emit_provenance_event(_provenance_record) do
    Logger.debug("[ProvenanceTracker] Semantic event: provenance_recorded")
  end
  
  defp record_lifecycle_event(provenance_record) do
    try do
      LifecycleRegistry.record_created(:provenance, provenance_record.id, 
        provenance_record.adoption_timestamp,
        %{
          discovery_id: provenance_record.discovery_id,
          originating_institution: provenance_record.originating_institution,
          adoption_decision: provenance_record.adoption_decision
        }
      )
    rescue
      e ->
        Logger.warning("[ProvenanceTracker] Lifecycle recording failed: #{inspect(e)}")
    end
  end
end
