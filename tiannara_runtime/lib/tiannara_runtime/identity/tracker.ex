defmodule TiannaraRuntime.Identity.Tracker do
  @moduledoc """
  PHASE 4B: Identity Tracker
  
  Integrates identity persistence with the state snapshot system.
  
  Responsibilities:
  - Listen for coalition lifecycle events from CAL
  - Automatically generate fingerprints when coalitions stabilize
  - Register coalitions in Species Registry
  - Track identity matches across time
  
  This module bridges the gap between raw coalition data and persistent identity.
  """
  
  use GenServer
  require Logger
  
  @fingerprint_threshold 0.75  # Minimum coherence to generate fingerprint
  @stability_window 5          # Number of stable ticks before fingerprinting
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Process a coalition event (birth, update, split, merge, death).
  """
  def process_event(coalition_id, event_type, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:process_event, coalition_id, event_type, metadata})
  end
  
  @doc """
  Manually trigger fingerprint generation for a coalition.
  """
  def generate_fingerprint(coalition_id) do
    GenServer.call(__MODULE__, {:generate_fingerprint, coalition_id})
  end
  
  @doc """
  Get identity match history for a coalition.
  """
  def get_identity_matches(coalition_id) do
    GenServer.call(__MODULE__, {:identity_matches, coalition_id})
  end
  
  # Server Implementation
  
  @impl true
  def init(_opts) do
    state = %{
      stability_counters: %{},  # coalition_id -> count of stable ticks
      pending_fingerprints: %{},  # coalition_id -> accumulated data
      identity_matches: %{}  # coalition_id -> [match_history]
    }
    
    Logger.info("🧬 Identity Tracker initialized")
    
    # Subscribe to coalition events if needed
    # Phoenix.PubSub.subscribe(TiannaraRuntime.PubSub, "coalition_events")
    
    {:ok, state}
  end
  
  @impl true
  def handle_cast({:process_event, coalition_id, event_type, metadata}, state) do
    Logger.debug("🧬 Processing coalition event: #{event_type} for #{coalition_id}")
    
    case event_type do
      "birth" ->
        handle_birth(coalition_id, metadata, state)
      
      "update" ->
        handle_update(coalition_id, metadata, state)
      
      "split" ->
        handle_split(coalition_id, metadata, state)
      
      "merge" ->
        handle_merge(coalition_id, metadata, state)
      
      "death" ->
        handle_death(coalition_id, metadata, state)
      
      _ ->
        Logger.warning("Unknown coalition event type: #{event_type}")
    end
    
    {:ok, state}
  end
  
  @impl true
  def handle_call({:generate_fingerprint, coalition_id}, _from, state) do
    result = do_generate_fingerprint(coalition_id, state)
    {:reply, result, state}
  end
  
  @impl true
  def handle_call({:identity_matches, coalition_id}, _from, state) do
    matches = Map.get(state.identity_matches, coalition_id, [])
    {:reply, {:ok, matches}, state}
  end
  
  # Event Handlers
  
  defp handle_birth(coalition_id, metadata, state) do
    # Record birth event in history
    TiannaraRuntime.Identity.CoalitionHistory.record_event(
      coalition_id,
      "birth",
      metadata
    )
    
    # Initialize stability counter
    new_counters = Map.put(state.stability_counters, coalition_id, 0)
    
    # Initialize pending data
    new_pending = Map.put(state.pending_fingerprints, coalition_id, %{
      snapshots: [],
      decisions: [],
      entropy_curve: []
    })
    
    %{state | 
      stability_counters: new_counters,
      pending_fingerprints: new_pending
    }
  end
  
  defp handle_update(coalition_id, metadata, state) do
    # Check coherence/stability
    coherence = Map.get(metadata, "coherence", 0.0)
    
    if coherence >= @fingerprint_threshold do
      # Increment stability counter
      current_count = Map.get(state.stability_counters, coalition_id, 0)
      new_count = current_count + 1
      
      new_counters = Map.put(state.stability_counters, coalition_id, new_count)
      
      # Accumulate data for fingerprint
      pending = Map.get(state.pending_fingerprints, coalition_id, %{
        snapshots: [],
        decisions: [],
        entropy_curve: []
      })
      
      new_pending = Map.update!(state.pending_fingerprints, coalition_id, fn data ->
        %{
          snapshots: [metadata | data.snapshots],
          decisions: extract_decisions(metadata) ++ data.decisions,
          entropy_curve: [Map.get(metadata, "entropy", 0.5) | data.entropy_curve]
        }
      end)
      
      # If stable for enough ticks, generate fingerprint
      if new_count >= @stability_window do
        Logger.info("🧬 Coalition #{coalition_id} stabilized, generating fingerprint...")
        
        # Generate and register fingerprint
        case do_generate_fingerprint(coalition_id, %{state | 
          stability_counters: new_counters,
          pending_fingerprints: new_pending
        }) do
          {:ok, fingerprint, species_id} ->
            Logger.info("✅ Fingerprint generated for #{coalition_id}, matched to species: #{species_id}")
            
            # Reset stability counter after fingerprinting
            reset_counters = Map.put(new_counters, coalition_id, 0)
            
            %{state |
              stability_counters: reset_counters,
              pending_fingerprints: new_pending
            }
          
          {:error, reason} ->
            Logger.error("Failed to generate fingerprint: #{reason}")
            %{state |
              stability_counters: new_counters,
              pending_fingerprints: new_pending
            }
        end
      else
        %{state |
          stability_counters: new_counters,
          pending_fingerprints: new_pending
        }
      end
    else
      # Low coherence, reset stability counter
      new_counters = Map.put(state.stability_counters, coalition_id, 0)
      %{state | stability_counters: new_counters}
    end
  end
  
  defp handle_split(coalition_id, metadata, state) do
    # Record split event
    TiannaraRuntime.Identity.CoalitionHistory.record_event(
      coalition_id,
      "split",
      metadata
    )
    
    # Record birth events for child coalitions
    children = Map.get(metadata, "children", [])
    Enum.each(children, fn child_id ->
      TiannaraRuntime.Identity.CoalitionHistory.record_event(
        child_id,
        "birth",
        %{parent: coalition_id, split_from: coalition_id}
      )
    end)
    
    state
  end
  
  defp handle_merge(coalition_id, metadata, state) do
    # Record merge event
    TiannaraRuntime.Identity.CoalitionHistory.record_event(
      coalition_id,
      "merge",
      metadata
    )
    
    # Record death events for merged coalitions
    merged_ids = Map.get(metadata, "merged_ids", [])
    Enum.each(merged_ids, fn merged_id ->
      TiannaraRuntime.Identity.CoalitionHistory.record_event(
        merged_id,
        "death",
        %{merged_into: coalition_id}
      )
    end)
    
    state
  end
  
  defp handle_death(coalition_id, metadata, state) do
    # Record death event
    TiannaraRuntime.Identity.CoalitionHistory.record_event(
      coalition_id,
      "death",
      metadata
    )
    
    # Clean up tracking data
    new_counters = Map.delete(state.stability_counters, coalition_id)
    new_pending = Map.delete(state.pending_fingerprints, coalition_id)
    
    %{state |
      stability_counters: new_counters,
      pending_fingerprints: new_pending
    }
  end
  
  # Fingerprint Generation
  
  defp do_generate_fingerprint(coalition_id, state) do
    # Get coalition history
    history_result = TiannaraRuntime.Identity.CoalitionHistory.get_history(coalition_id)
    
    case history_result do
      {:ok, history} ->
        # Get accumulated snapshot data
        pending = Map.get(state.pending_fingerprints, coalition_id, %{
          snapshots: [],
          decisions: [],
          entropy_curve: []
        })
        
        # Extract snapshots for entropy signature
        snapshots = Enum.reverse(pending.snapshots)
        
        # Generate fingerprint
        case TiannaraRuntime.Identity.Fingerprint.generate(coalition_id, history, snapshots) do
          {:ok, fingerprint} ->
            # Prepare metadata
            metadata = %{
              version: "1.0",
              generated_at: DateTime.utc_now() |> DateTime.to_iso8601(),
              snapshot_count: length(snapshots),
              decision_count: length(pending.decisions)
            }
            
            # Register in species registry
            case TiannaraRuntime.Identity.SpeciesRegistry.register_coalition(
              coalition_id,
              fingerprint,
              metadata
            ) do
              {:ok, species_id, is_new_species} ->
                # Record identity match if not new species
                if not is_new_species do
                  record_identity_match(coalition_id, species_id, state)
                end
                
                {:ok, fingerprint, species_id}
              
              {:error, reason} ->
                {:error, "Species registration failed: #{reason}"}
            end
          
          {:error, reason} ->
            {:error, "Fingerprint generation failed: #{reason}"}
        end
      
      {:error, reason} ->
        {:error, "History retrieval failed: #{reason}"}
    end
  end
  
  defp record_identity_match(coalition_id, species_id, state) do
    match_record = %{
      coalition_id: coalition_id,
      species_id: species_id,
      matched_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    
    current_matches = Map.get(state.identity_matches, coalition_id, [])
    new_matches = [match_record | current_matches]
    
    # In production, this would persist to database
    # For now, keep in memory
    Map.put(state.identity_matches, coalition_id, new_matches)
  end
  
  # Helper Functions
  
  defp extract_decisions(metadata) do
    # Extract CAL decisions from metadata
    Map.get(metadata, "decisions", [])
  end
end
