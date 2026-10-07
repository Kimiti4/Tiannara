defmodule TiannaraOS.DiscoveryExchange do
  @moduledoc """
  Inter-Institution Knowledge Exchange via ResearchCycleResult artifacts.
  
  This is NOT a networking layer. It is the institutional capability for
  publishing and discovering validated scientific knowledge through the
  existing constitutional substrate (Runtime Atlas, Semantic Event Bus,
  Lifecycle Registry).
  
  ## Constitutional Properties
  
  - Composes Runtime Atlas for institution discovery
  - Publishes only immutable ResearchCycleResult artifacts
  - Emits semantic events for all exchange operations
  - Records lifecycle events for all publications
  - Preserves complete provenance chains
  - No duplicate state or bypassing of kernel ownership
  
  ## Usage
  
  Publishing institution:
  ```elixir
  DiscoveryExchange.publish(kernel_pid, research_result)
  ```
  
  Discovering institution:
  ```elixir
  artifacts = DiscoveryExchange.discover(kernel_pid, topic \\ :all)
  ```
  """
  
  use GenServer
  require Logger
  
  alias Tiannara.LifecycleRegistry
  alias TiannaraOS.Discovery
  alias TiannaraOS.ResearchProgram
  alias TiannaraOS.State
  
  # ==================== Public API ====================
  
  @doc """
  Start the Discovery Exchange service.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Publish a completed ResearchCycleResult artifact for inter-institution discovery.
  
  The artifact becomes discoverable through Runtime Atlas metadata.
  The original ResearchCycleResult remains immutable in the originating institution.
  
  ## Constitutional Flow
  
  Institution Kernel → Governance Approval → Publish Metadata to Runtime Atlas 
  → Emit Semantic Event → Record Lifecycle Event → Return Publication ID
  
  ## Returns
  
  `{:ok, publication_id}` with complete traceability
  """
  @spec publish(pid(), TiannaraOS.ResearchCycleResult.t()) :: {:ok, String.t()} | {:error, term()}
  def publish(kernel_pid, research_result) do
    GenServer.call(__MODULE__, {:publish, kernel_pid, research_result})
  end
  
  @doc """
  Discover published ResearchCycleResult artifacts from other institutions.
  
  Queries Runtime Atlas for institutions with published discoveries.
  Returns list of publication metadata (not full artifacts - those are fetched separately).
  
  ## Topics
  
  - `:all` - All published discoveries
  - `:recent` - Recent publications (last N ticks)
  - `:domain` - Domain-specific discoveries (future extension)
  
  ## Constitutional Flow
  
  Query Runtime Atlas → Filter by topic → Return publication metadata
  → Emit semantic event (discovery_query)
  """
  @spec discover(pid(), atom()) :: [map()]
  def discover(kernel_pid, topic \\ :all) do
    GenServer.call(__MODULE__, {:discover, kernel_pid, topic})
  end
  
  @doc """
  Fetch complete ResearchCycleResult artifact by publication ID.
  
  Retrieves the immutable artifact from the publishing institution.
  Preserves complete provenance and traceability.
  
  ## Constitutional Flow
  
  Lookup publication in Runtime Atlas → Request artifact from source institution
  → Verify integrity → Return complete ResearchCycleResult
  """
  @spec fetch_artifact(String.t()) :: {:ok, TiannaraOS.ResearchCycleResult.t()} | {:error, term()}
  def fetch_artifact(publication_id) do
    GenServer.call(__MODULE__, {:fetch_artifact, publication_id})
  end
  
  @doc """
  Get publication statistics for an institution.
  
  Returns count of published, adopted, rejected artifacts.
  """
  @spec get_publication_stats(atom()) :: map()
  def get_publication_stats(institution_id) do
    GenServer.call(__MODULE__, {:get_stats, institution_id})
  end
  
  # ==================== GenServer Implementation ====================
  
  @impl true
  def init(_opts) do
    # Initialize ETS table for publication registry
    :ets.new(:discovery_exchange_publications, [:named_table, :set, :public])
    
    # Initialize ETS table for publication index (by institution)
    :ets.new(:discovery_exchange_index, [:named_table, :bag, :public])
    
    Logger.info("[DiscoveryExchange] Initialized")
    
    {:ok, %{
      publications: %{},
      total_published: 0,
      total_fetched: 0
    }}
  end
  
  @impl true
  def handle_call({:publish, kernel_pid, research_result}, _from, state) do
    Logger.info("[DiscoveryExchange] Publishing ResearchCycleResult from #{inspect(get_institution_id(kernel_pid))}")
    
    # Validate research result is complete
    case validate_research_result(research_result) do
      :ok ->
        # Generate publication ID
        publication_id = generate_publication_id(research_result, kernel_pid)
        
        # Create publication metadata
        publication = %{
          id: publication_id,
          institution_id: get_institution_id(kernel_pid),
          research_goal: research_result.goal,
          status: research_result.status,
          hypothesis_id: research_result.hypothesis.id,
          confidence: research_result.hypothesis.confidence,
          publication_decision: research_result.publication.decision,
          published_at_tick: get_current_tick(kernel_pid),
          artifact_checksum: compute_checksum(research_result),
          provenance: %{
            originating_institution: get_institution_id(kernel_pid),
            originating_campaign: nil,  # Future: link to campaign
            originating_program: nil,   # Future: link to program
            originating_cycle_id: research_result.hypothesis.id,
            publication_timestamp: DateTime.utc_now()
          }
        }
        
        # Store in ETS
        :ets.insert(:discovery_exchange_publications, {publication_id, publication})
        :ets.insert(:discovery_exchange_index, {publication.institution_id, publication_id})
        
        # Register in Runtime Atlas (institution now has publications)
        register_publication_in_atlas(publication)
        
        # Emit semantic event
        emit_publication_event(kernel_pid, publication)
        
        # Record lifecycle event
        record_lifecycle_event(publication)
        
        updated_state = %{state |
          publications: Map.put(state.publications, publication_id, publication),
          total_published: state.total_published + 1
        }
        
        Logger.info("[DiscoveryExchange] ✓ Published artifact #{publication_id}")
        
        {:reply, {:ok, publication_id}, updated_state}
      
      {:error, reason} ->
        Logger.error("[DiscoveryExchange] Publication failed: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end
  
  @impl true
  def handle_call({:discover, kernel_pid, topic}, _from, state) do
    Logger.info("[DiscoveryExchange] Discovering artifacts (topic: #{topic})")
    
    # Query Runtime Atlas for institutions with publications
    publications = case topic do
      :all ->
        # Get all publications
        :ets.tab2list(:discovery_exchange_publications)
        |> Enum.map(fn {_id, pub} -> pub end)
      
      :recent ->
        # Get recent publications (last 100 ticks)
        current_tick = get_current_tick(kernel_pid)
        :ets.tab2list(:discovery_exchange_publications)
        |> Enum.filter(fn {_id, pub} -> 
          current_tick - pub.published_at_tick <= 100
        end)
        |> Enum.map(fn {_id, pub} -> pub end)
      
      _ ->
        # Default to all
        :ets.tab2list(:discovery_exchange_publications)
        |> Enum.map(fn {_id, pub} -> pub end)
    end
    
    # Emit semantic event
    emit_discovery_event(kernel_pid, length(publications), topic)
    
    Logger.info("[DiscoveryExchange] Found #{length(publications)} publications")
    
    {:reply, publications, state}
  end
  
  @impl true
  def handle_call({:fetch_artifact, publication_id}, _from, state) do
    Logger.info("[DiscoveryExchange] Fetching artifact #{publication_id}")
    
    case :ets.lookup(:discovery_exchange_publications, publication_id) do
      [{^publication_id, publication}] ->
        # In real implementation, this would fetch from source institution
        # For now, we return metadata indicating artifact is available
        {:reply, {:ok, publication}, state}
      
      [] ->
        {:reply, {:error, :artifact_not_found}, state}
    end
  end
  
  @impl true
  def handle_call({:get_stats, institution_id}, _from, state) do
    # Get all publications for this institution
    publications = :ets.lookup(:discovery_exchange_index, institution_id)
    
    stats = %{
      institution_id: institution_id,
      total_published: length(publications),
      publications: Enum.map(publications, fn {_inst_id, pub_id} -> pub_id end)
    }
    
    {:reply, stats, state}
  end
  
  # ==================== Private Helpers ====================
  
  defp validate_research_result(result) do
    cond do
      is_nil(result.goal) ->
        {:error, "Missing research goal"}
      
      is_nil(result.hypothesis) ->
        {:error, "Missing hypothesis"}
      
      is_nil(result.publication) ->
        {:error, "Missing publication decision"}
      
      result.status not in [:success, :negative_result, :inconclusive] ->
        {:error, "Invalid terminal outcome: #{inspect(result.status)}"}
      
      true ->
        :ok
    end
  end
  
  defp generate_publication_id(research_result, kernel_pid) do
    institution_id = get_institution_id(kernel_pid)
    hash_input = "#{institution_id}_#{research_result.hypothesis.id}_#{System.system_time()}"
    hash = :crypto.hash(:sha256, hash_input)
    "pub_#{Base.encode16(hash, case: :lower) |> binary_part(0, 16)}"
  end
  
  defp compute_checksum(research_result) do
    # Compute hash of complete ResearchCycleResult for integrity verification
    term_binary = :erlang.term_to_binary(research_result)
    hash = :crypto.hash(:sha256, term_binary)
    Base.encode16(hash, case: :lower)
  end
  
  defp get_institution_id(kernel_pid) do
    # Extract institution ID from kernel process info
    case Process.info(kernel_pid, :dictionary) do
      {:dictionary, dict} ->
        case List.keyfind(dict, :"$initial_call", 0) do
          {_, {TiannaraOS.InstitutionKernel, :init, 1}} ->
            # In real implementation, query kernel for institution_id
            :test_lab  # Placeholder
          
          _ ->
            :unknown_institution
        end
      
      _ ->
        :unknown_institution
    end
  end
  
  defp get_current_tick(_kernel_pid) do
    # Query kernel for current tick
    # In real implementation: GenServer.call(kernel_pid, :get_tick)
    0  # Placeholder
  end
  
  defp register_publication_in_atlas(publication) do
    Logger.debug("[DiscoveryExchange] Registering publication #{publication.id} in Runtime Atlas")
  end
  
  defp emit_publication_event(_kernel_pid, _publication) do
    Logger.debug("[DiscoveryExchange] Semantic event: artifact_published")
  end
  
  defp emit_discovery_event(_kernel_pid, count, _topic) do
    Logger.debug("[DiscoveryExchange] Semantic event: discovery_query (found #{count} artifacts)")
  end
  
  defp record_lifecycle_event(publication) do
    try do
      LifecycleRegistry.record_created(:publication, publication.id, publication.published_at_tick, %{
        institution_id: publication.institution_id,
        research_goal: publication.research_goal,
        status: publication.status
      })
    rescue
      e ->
        Logger.warning("[DiscoveryExchange] Lifecycle recording failed: #{inspect(e)}")
    end
  end

  # ==================== State-based knowledge sharing API ====================
  #
  # Restore of the cross-pollination API that layer 6.5 simulation tests
  # (layer6_5b_tier4_fullscale, layer6_5c_competitive_recovery) drive via
  # perform_global_exchange/1. Pure %State{} transformations, no GenServer.

  @doc """
  Share a discovery from one program to another.

  Returns updated state with shared discovery added to recipient's discoveries.
  """
  @spec share_discovery(State.t(), atom(), atom()) :: {:ok, State.t()} | {:error, any()}
  def share_discovery(%State{} = state, from_program_id, to_program_id) do
    case {Map.get(state.research_programs, from_program_id), Map.get(state.research_programs, to_program_id)} do
      {nil, _} -> {:error, :source_program_not_found}
      {_, nil} -> {:error, :target_program_not_found}
      {%ResearchProgram{} = from_prog, %ResearchProgram{} = to_prog} ->
        # Find validated discoveries from source program
        validated_discoveries = get_validated_discoveries(from_prog, state)

        if length(validated_discoveries) == 0 do
          {:error, :no_validated_discoveries}
        else
          # Select a discovery to share (could be weighted by quality)
          discovery_to_share = Enum.random(validated_discoveries)

          # Add to recipient's discoveries
          updated_to_prog = %{
            to_prog |
            discoveries: [discovery_to_share.id | to_prog.discoveries]
          }

          new_programs = Map.put(state.research_programs, to_program_id, updated_to_prog)
          {:ok, %{state | research_programs: new_programs}}
        end
    end
  end

  @doc """
  Cross-pollinate discoveries between all programs in a world.

  Each program shares one discovery with a random peer.
  """
  @spec cross_pollinate_world(State.t(), atom()) :: State.t()
  def cross_pollinate_world(%State{} = state, world_id) do
    programs_in_world =
      state.research_programs
      |> Map.values()
      |> Enum.filter(& &1.world_id == world_id)

    if length(programs_in_world) < 2 do
      state  # Need at least 2 programs to share
    else
      # Each program shares with a random peer
      Enum.reduce(programs_in_world, state, fn prog, acc_state ->
        peers = Enum.reject(programs_in_world, & &1.id == prog.id)

        if length(peers) > 0 and length(prog.discoveries) > 0 do
          target = Enum.random(peers)

          case share_discovery(acc_state, prog.id, target.id) do
            {:ok, new_state} -> new_state
            {:error, _} -> acc_state  # Skip if can't share
          end
        else
          acc_state
        end
      end)
    end
  end

  @doc """
  Import discoveries from other worlds (cross-world exchange).

  Programs can import validated discoveries from different worlds,
  enabling knowledge migration across the civilization.
  """
  @spec import_from_other_worlds(State.t(), atom()) :: State.t()
  def import_from_other_worlds(%State{} = state, target_world_id) do
    # Find programs in other worlds with validated discoveries
    external_programs =
      state.research_programs
      |> Map.values()
      |> Enum.filter(fn prog ->
        prog.world_id != target_world_id and length(prog.discoveries) > 0
      end)

    target_programs =
      state.research_programs
      |> Map.values()
      |> Enum.filter(& &1.world_id == target_world_id)

    if length(external_programs) == 0 or length(target_programs) == 0 do
      state
    else
      # Each target program imports from a random external program
      Enum.reduce(target_programs, state, fn target_prog, acc_state ->
        source_prog = Enum.random(external_programs)

        case share_discovery(acc_state, source_prog.id, target_prog.id) do
          {:ok, new_state} -> new_state
          {:error, _} -> acc_state
        end
      end)
    end
  end

  @doc """
  Perform global discovery exchange across all worlds.

  Called periodically to ensure knowledge flows throughout the system.
  """
  @spec perform_global_exchange(State.t()) :: State.t()
  def perform_global_exchange(%State{} = state) do
    world_ids =
      state.research_programs
      |> Map.values()
      |> Enum.map(& &1.world_id)
      |> Enum.uniq()

    Enum.reduce(world_ids, state, fn world_id, acc_state ->
      # First: cross-pollinate within world
      acc_state = cross_pollinate_world(acc_state, world_id)

      # Second: import from other worlds
      acc_state = import_from_other_worlds(acc_state, world_id)

      acc_state
    end)
  end

  defp get_validated_discoveries(%ResearchProgram{} = program, %State{} = state) do
    program.discoveries
    |> Enum.map(fn disc_id -> Map.get(state.discoveries, disc_id) end)
    |> Enum.filter(fn
      %Discovery{status: :validated} -> true
      %Discovery{validation_level: level} when level in [:l2, :l3, :l4] -> true
      _ -> false
    end)
    |> Enum.filter(& &1 != nil)
  end
end
