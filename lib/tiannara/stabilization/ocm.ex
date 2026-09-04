defmodule Tiannara.Stabilization.OCM do
  @moduledoc """
  Ontological Consensus Mesh (OCM).

  Maintains semantic agreement across distributed cognition, reconciling ontologies,
  resolving conflicts, and ensuring distributed meaning alignment.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def achieve_consensus(ontologies) do
    GenServer.call(__MODULE__, {:achieve_consensus, ontologies})
  end

  def reconcile_ontologies(ontology_ids) do
    GenServer.call(__MODULE__, {:reconcile_ontologies, ontology_ids})
  end

  def resolve_semantic_conflicts(conflicts) do
    GenServer.call(__MODULE__, {:resolve_semantic_conflicts, conflicts})
  end

  def get_consensus_status() do
    GenServer.call(__MODULE__, :get_consensus_status)
  end

  def get_ontology_agreement(ontology_id) do
    GenServer.call(__MODULE__, {:get_ontology_agreement, ontology_id})
  end

  def vote_on_concept(concept_id, ontology_id, vote) do
    GenServer.call(__MODULE__, {:vote_on_concept, concept_id, ontology_id, vote})
  end

  def get_concept_consensus(concept_id) do
    GenServer.call(__MODULE__, {:get_concept_consensus, concept_id})
  end

  def get_mesh_stats() do
    GenServer.call(__MODULE__, :get_mesh_stats)
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize ETS tables for consensus management
    :ets.new(:ontology_mesh, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(:concept_votes, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:consensus_history, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:mesh_metadata, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    # Configuration parameters
    config = %{
      consensus_threshold: 0.75,          # 75% agreement needed
      byzantine_tolerance: 0.33,          # tolerate 33% malicious actors
      max_reconciliation_attempts: 3,
      voting_weight_threshold: 0.1,
      semantic_similarity_threshold: 0.8,
      convergence_timeout: 30_000,          # 30 seconds
      mesh_update_interval: 5000           # 5 seconds
    }

    # Initialize mesh metadata
    :ets.insert(:mesh_metadata, {
      config,
      System.system_time(:millisecond),
      0,
      0
    })

    Logger.info("OCM initialized with consensus parameters")
    
    {:ok, %{
      config: config,
      active_ontologies: 0,
      consensus_sessions: 0,
      resolved_conflicts: 0,
      failed_consensus: 0,
      last_convergence: 0
    }}
  end

  @impl true
  def handle_call({:achieve_consensus, ontologies}, _from, state) do
    # Validate ontologies
    case validate_ontologies_for_consensus(ontologies) do
      :ok ->
        # Start consensus session
        session_id = generate_session_id()
        
        # Collect votes from all ontologies
        votes = collect_concept_votes(ontologies)
        
        # Analyze consensus status
        consensus_analysis = analyze_consensus(votes, state.config)
        
        case consensus_analysis do
          {:achieved, consensus_ontology} ->
            # Store consensus result
            timestamp = System.system_time(:millisecond)
            :ets.insert(:consensus_history, {timestamp, session_id, consensus_ontology})
            
            Logger.info("Consensus achieved in session #{session_id}")
            
            {:reply, {:ok, consensus_ontology}, update_consensus_stats(state, :achieved)}
            
          {:failed, conflicts} ->
            # Attempt to resolve conflicts
            resolution = resolve_conflicts(conflicts, state.config)
            
            case resolution do
              {:resolved, resolved_ontology} ->
                # Store resolved consensus
                timestamp = System.system_time(:millisecond)
                :ets.insert(:consensus_history, {timestamp, session_id, resolved_ontology})
                
                Logger.info("Consensus resolved in session #{session_id} after conflict resolution")
                
                {:reply, {:ok, resolved_ontology}, update_consensus_stats(state, :resolved)}
                
              {:failed, remaining_conflicts} ->
                Logger.warning("Consensus failed in session #{session_id}: #{length(remaining_conflicts)} conflicts unresolved")
                
                {:reply, {:error, :consensus_failed, remaining_conflicts}, 
                 update_consensus_stats(state, :failed)}
            end
        end
        
      {:error, reason} ->
        Logger.error("Ontology validation failed: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:reconcile_ontologies, ontology_ids}, _from, state) do
    # Fetch ontologies
    case fetch_ontologies(ontology_ids) do
      {:ok, ontologies} ->
        # Perform reconciliation
        reconciled = reconcile_ontology_structures(ontologies, state.config)
        
        # Store reconciled ontology
        reconciled_id = "reconciled_#{System.system_time(:millisecond)}"
        :ets.insert(:ontology_mesh, {reconciled_id, reconciled})
        
        Logger.info("Reconciled #{length(ontology_ids)} ontologies into #{reconciled_id}")
        
        {:reply, {:ok, reconciled_id}, state}
        
      {:error, reason} ->
        Logger.error("Failed to fetch ontologies: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:resolve_semantic_conflicts, conflicts}, _from, state) do
    # Resolve semantic conflicts using voting and weighted consensus
    resolved = Enum.map(conflicts, fn conflict ->
      resolve_single_conflict(conflict, state.config)
    end)
    
    successful_resolutions = Enum.filter(resolved, fn
      {:resolved, _} -> true
      {:failed, _} -> false
    end)
    
    _failed_count = length(resolved) - length(successful_resolutions)

    Logger.info("Resolved #{length(successful_resolutions)}/#{length(conflicts)} semantic conflicts")
    
    case length(successful_resolutions) do
      0 ->
        {:reply, {:error, :no_resolutions}, state}
        
      _ ->
        # Store resolution results
        timestamp = System.system_time(:millisecond)
        :ets.insert(:consensus_history, {timestamp, :conflict_resolution, resolved})
        
        {:reply, {:ok, successful_resolutions}, 
         %{state | resolved_conflicts: state.resolved_conflicts + length(successful_resolutions)}}
    end
  end

  @impl true
  def handle_call(:get_consensus_status, _from, state) do
    # Calculate current consensus metrics
    mesh_stats = calculate_mesh_statistics()
    
    status = %{
      active_ontologies: state.active_ontologies,
      consensus_sessions: state.consensus_sessions,
      resolved_conflicts: state.resolved_conflicts,
      failed_consensus: state.failed_consensus,
      last_convergence: state.last_convergence,
      mesh_metrics: mesh_stats,
      config: state.config
    }
    
    {:reply, {:ok, status}, state}
  end

  @impl true
  def handle_call({:get_ontology_agreement, ontology_id}, _from, state) do
    case :ets.lookup(:ontology_mesh, ontology_id) do
      [{^ontology_id, ontology}] ->
        # Calculate agreement score with consensus
        agreement_score = calculate_ontology_agreement(ontology, state.config)
        
        {:reply, {:ok, agreement_score}, state}
        
      [] ->
        {:reply, {:error, :ontology_not_found}, state}
    end
  end

  @impl true
  def handle_call({:vote_on_concept, concept_id, ontology_id, vote}, _from, state) do
    # Validate vote
    case validate_vote(vote) do
      :ok ->
        # Store vote
        timestamp = System.system_time(:millisecond)
        vote_data = %{
          concept_id: concept_id,
          ontology_id: ontology_id,
          vote: vote,
          timestamp: timestamp,
          weight: calculate_vote_weight(ontology_id)
        }
        
        :ets.insert(:concept_votes, {concept_id, vote_data})
        
        # Check if consensus is achieved
        consensus_check = check_concept_consensus(concept_id, state.config)
        
        case consensus_check do
          {:consensus, consensus_value} ->
            Logger.debug("Consensus achieved for concept #{concept_id}: #{consensus_value}")
            {:reply, {:ok, :consensus_achieved, consensus_value}, state}
          :no_consensus ->
            {:reply, {:ok, :vote_recorded}, state}
        end
        
      {:error, reason} ->
        Logger.error("Invalid vote: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:get_concept_consensus, concept_id}, _from, state) do
    case :ets.lookup(:concept_votes, concept_id) do
      [_ | _] = votes ->
        # Analyze votes
        consensus_result = analyze_concept_votes(votes, state.config)
        {:reply, {:ok, consensus_result}, state}
      [] ->
        {:reply, {:error, :no_votes}, state}
    end
  end

  @impl true
  def handle_call(:get_mesh_stats, _from, state) do
    stats = %{
      ontology_count: :ets.info(:ontology_mesh, :size),
      vote_count: :ets.info(:concept_votes, :size),
      consensus_count: :ets.info(:consensus_history, :size),
      active_ontologies: state.active_ontologies,
      consensus_sessions: state.consensus_sessions,
      resolved_conflicts: state.resolved_conflicts,
      failed_consensus: state.failed_consensus,
      last_convergence: state.last_convergence
    }
    
    {:reply, {:ok, stats}, state}
  end

  # Helper functions
  defp validate_ontologies_for_consensus(ontologies) when is_list(ontologies) do
    # Validate that all ontologies have proper structure
    case Enum.all?(ontologies, &valid_ontology_structure?/1) do
      true -> :ok
      false -> {:error, :invalid_ontology_structure}
    end
  end

  defp validate_ontologies_for_consensus(_), do: {:error, :invalid_input}

  defp valid_ontology_structure?(ontology) when is_map(ontology) do
    Map.has_key?(ontology, :id) and Map.has_key?(ontology, :concepts)
  end

  defp valid_ontology_structure?(_), do: false

  defp collect_concept_votes(ontologies) do
    # Extract all concepts and collect votes
    Enum.flat_map(ontologies, fn ontology ->
      Enum.map(ontology.concepts, fn concept ->
        case concept do
          %{id: concept_id} -> {concept_id, ontology.id}
          concept_id when is_binary(concept_id) -> {concept_id, ontology.id}
        end
      end)
    end)
  end

  defp analyze_concept_votes(votes, config) when is_list(votes) do
    # Count votes for and against each concept
    vote_counts = Enum.reduce(votes, %{}, fn {_, vote_data}, counts ->
      concept_id = vote_data.concept_id
      vote = vote_data.vote
      
      current = Map.get(counts, concept_id, %{for: 0, against: 0, weight: 0})
      
      case vote do
        :for -> 
          %{current | for: current.for + vote_data.weight, weight: current.weight + vote_data.weight}
        :against ->
          %{current | against: current.against + vote_data.weight, weight: current.weight + vote_data.weight}
      end
    end)
    
    # Analyze consensus for each concept
    Enum.map(vote_counts, fn {concept_id, counts} ->
      total_weight = counts.weight
      if total_weight > 0 do
        agreement_ratio = counts.for / total_weight
        
        consensus = cond do
          agreement_ratio >= config.consensus_threshold -> :consensus
          agreement_ratio <= (1 - config.consensus_threshold) -> :rejected
          true -> :disputed
        end
        
        %{
          concept_id: concept_id,
          agreement_ratio: agreement_ratio,
          total_weight: total_weight,
          consensus: consensus
        }
      else
        %{
          concept_id: concept_id,
          agreement_ratio: 0.0,
          total_weight: 0,
          consensus: :no_votes
        }
      end
    end)
  end

  defp analyze_consensus(votes, config) when is_list(votes) do
    # Group votes by concept
    grouped_votes = Enum.group_by(votes, &elem(&1, 0))
    
    # Analyze each concept
    consensus_results = Enum.map(grouped_votes, fn {_concept_id, concept_votes} ->
      analyze_concept_concept_votes(concept_votes, config)
    end)
    
    # Determine overall consensus
    consensus_concepts = Enum.filter(consensus_results, &(&1.consensus == :consensus))
    disputed_concepts = Enum.filter(consensus_results, &(&1.consensus == :disputed))
    
    case length(consensus_concepts) do
      0 ->
        {:failed, disputed_concepts}
        
      _ when length(disputed_concepts) <= length(consensus_concepts) * config.byzantine_tolerance ->
        # Achieved consensus
        consensus_ontology = build_consensus_ontology(consensus_results)
        {:achieved, consensus_ontology}
        
      _ ->
        {:failed, disputed_concepts}
    end
  end

  defp analyze_concept_concept_votes(votes, config) when is_list(votes) do
    # Calculate weighted vote
    total_weight = votes |> Enum.map(&elem(&1, 1).weight) |> Enum.sum()
    for_weight = votes |> Enum.filter(&elem(&1, 1).vote == :for) |> Enum.map(&elem(&1, 1).weight) |> Enum.sum()
    
    agreement_ratio = if total_weight > 0, do: for_weight / total_weight, else: 0.0
    
    consensus = cond do
      agreement_ratio >= config.consensus_threshold -> :consensus
      agreement_ratio <= (1 - config.consensus_threshold) -> :rejected
      true -> :disputed
    end
    
    %{
      concept_id: hd(votes) |> elem(0),
      agreement_ratio: agreement_ratio,
      total_weight: total_weight,
      consensus: consensus
    }
  end

  defp build_consensus_ontology(consensus_results) do
    # Build consensus ontology from agreed concepts
    concepts = Enum.filter(consensus_results, &(&1.consensus == :consensus))
    |> Enum.map(fn result -> 
      %{id: result.concept_id, agreement: result.agreement_ratio}
    end)
    
    %{
      id: "consensus_#{System.system_time(:millisecond)}",
      concepts: concepts,
      consensus_score: calculate_consensus_score(consensus_results),
      timestamp: System.system_time(:millisecond)
    }
  end

  defp calculate_consensus_score(consensus_results) do
    agreed = Enum.filter(consensus_results, &(&1.consensus == :consensus))
    total = length(consensus_results)
    
    if total > 0, do: length(agreed) / total, else: 0.0
  end

  defp resolve_conflicts(conflicts, config) do
    # Attempt to resolve conflicts using weighted voting
    resolved = Enum.map(conflicts, fn conflict ->
      resolve_single_conflict(conflict, config)
    end)
    
    successful = Enum.filter(resolved, fn
      {:resolved, _} -> true
      {:failed, _} -> false
    end)
    
    case length(successful) do
      0 -> {:failed, conflicts}
      _ -> {:resolved, build_resolved_ontology(successful)}
    end
  end

  defp resolve_single_conflict(conflict, config) do
    # Simplified conflict resolution
    # In production, use more sophisticated algorithms
    case conflict do
      %{concept_id: concept_id, votes: votes} ->
        # Analyze votes
        for_votes = Enum.filter(votes, &(&1 == :for)) |> length()
        against_votes = Enum.filter(votes, &(&1 == :against)) |> length()
        total_votes = for_votes + against_votes
        
        if total_votes > 0 do
          agreement_ratio = for_votes / total_votes
          
          if agreement_ratio >= config.consensus_threshold do
            {:resolved, %{concept_id: concept_id, resolution: :accepted, agreement_ratio: agreement_ratio}}
          else
            {:failed, conflict}
          end
        else
          {:failed, conflict}
        end
    end
  end

  defp build_resolved_ontology(resolutions) when is_list(resolutions) do
    concepts = Enum.map(resolutions, fn
      {:resolved, %{concept_id: concept_id, resolution: resolution, agreement_ratio: agreement}} ->
        %{id: concept_id, resolution: resolution, agreement: agreement}
    end)
    
    %{
      id: "resolved_#{System.system_time(:millisecond)}",
      concepts: concepts,
      resolution_score: calculate_resolution_score(resolutions),
      timestamp: System.system_time(:millisecond)
    }
  end

  defp calculate_resolution_score(resolutions) do
    successful = Enum.filter(resolutions, fn
      {:resolved, _} -> true
      {:failed, _} -> false
    end)
    
    length(successful) / max(length(resolutions), 1)
  end

  defp reconcile_ontology_structures(ontologies, config) when is_list(ontologies) do
    # Merge ontology structures while preserving semantic meaning
    all_concepts = Enum.flat_map(ontologies, & &1.concepts)
    
    # Group concepts by ID
    grouped_concepts = Enum.group_by(all_concepts, &get_concept_id/1)
    
    # Reconcile each concept group
    reconciled_concepts = Enum.map(grouped_concepts, fn {concept_id, concept_instances} ->
      reconcile_concept_instances(concept_id, concept_instances, config)
    end)
    
    %{
      id: "reconciled_#{System.system_time(:millisecond)}",
      concepts: reconciled_concepts,
      reconciliation_score: calculate_reconciliation_score(reconciled_concepts),
      timestamp: System.system_time(:millisecond)
    }
  end

  defp get_concept_id(concept) do
    case concept do
      %{id: id} -> id
      id when is_binary(id) -> id
    end
  end

  defp reconcile_concept_instances(concept_id, instances, _config) do
    # Find the most common version of the concept
    version_counts = Enum.reduce(instances, %{}, fn instance, counts ->
      version = get_concept_version(instance)
      Map.update(counts, version, 1, &(&1 + 1))
    end)
    
    # Select most common version
    {selected_version, count} = Enum.max_by(version_counts, &elem(&1, 1))
    
    # Create reconciled concept
    reconciled = %{id: concept_id, 
                   version: selected_version,
                   agreement: count / length(instances),
                   metadata: %{
                     reconciled_at: System.system_time(:millisecond),
                     source_count: length(instances)
                   }}
    
    reconciled
  end

  defp get_concept_version(concept) do
    case concept do
      %{version: version} -> version
      %{metadata: %{version: version}} -> version
      _ -> "default"
    end
  end

  defp calculate_reconciliation_score(concepts) do
    if length(concepts) > 0 do
      agreements = Enum.map(concepts, & &1.agreement)
      Enum.sum(agreements) / length(agreements)
    else
      0.0
    end
  end

  defp calculate_ontology_agreement(ontology, _config) do
    # Compare ontology with consensus
    consensus_concepts = get_consensus_concepts()
    
    # Calculate agreement score
    matching_concepts = Enum.filter(ontology.concepts, fn concept ->
      Enum.any?(consensus_concepts, &consensus_match?(concept, &1))
    end)
    
    if length(ontology.concepts) > 0 do
      length(matching_concepts) / length(ontology.concepts)
    else
      0.0
    end
  end

  defp consensus_match?(concept, consensus_concept) do
    # Check if concept matches consensus
    concept_id = get_concept_id(concept)
    consensus_id = consensus_concept.id
    
    concept_id == consensus_id
  end

  defp get_consensus_concepts() do
    # Get most recent consensus ontology
    case :ets.last(:consensus_history) do
      :"$end_of_table" -> []
      timestamp ->
        case :ets.lookup(:consensus_history, timestamp) do
          [{^timestamp, _, ontology}] -> ontology.concepts
          _ -> []
        end
    end
  end

  defp validate_vote(vote) do
    case vote do
      :for -> :ok
      :against -> :ok
      :abstain -> :ok
      _ -> {:error, :invalid_vote_value}
    end
  end

  defp calculate_vote_weight(_ontology_id) do
    # Calculate vote weight based on ontology importance
    # In production, use more sophisticated weighting
    1.0  # Default weight
  end

  defp check_concept_consensus(concept_id, config) do
    case :ets.lookup(:concept_votes, concept_id) do
      [_ | _] = votes ->
        votes = Enum.map(votes, fn {_, vote_data} -> vote_data end)
        analyze_concept_votes([concept_id | votes], config)
        
        # Check if consensus threshold met
        concept_votes = hd(votes)
        if concept_votes.vote == :for do
          {:consensus, :accepted}
        else
          {:consensus, :rejected}
        end
        
      [] ->
        :no_consensus
    end
  end

  defp fetch_ontologies(ontology_ids) do
    # Fetch ontologies from storage
    ontologies = Enum.map(ontology_ids, fn id ->
      case :ets.lookup(:ontology_mesh, id) do
        [{^id, ontology}] -> ontology
        [] -> nil
      end
    end) |> Enum.reject(&is_nil/1)
    
    case length(ontologies) == length(ontology_ids) do
      true -> {:ok, ontologies}
      false -> {:error, :some_ontologies_not_found}
    end
  end

  defp calculate_mesh_statistics() do
    # Calculate overall mesh statistics
    %{
      ontology_count: :ets.info(:ontology_mesh, :size),
      concept_count: count_concepts_in_mesh(),
      vote_count: :ets.info(:concept_votes, :size),
      consensus_count: :ets.info(:consensus_history, :size)
    }
  end

  defp count_concepts_in_mesh() do
    ontologies = :ets.tab2list(:ontology_mesh)
    Enum.map(ontologies, fn {_, ontology} -> length(ontology.concepts) end) |> Enum.sum()
  end

  defp generate_session_id() do
    "session_#{System.system_time(:millisecond)}_#{:crypto.strong_rand_bytes(8) |> Base.url_encode64()}"
  end

  defp update_consensus_stats(state, result) do
    base_state = %{state | 
      consensus_sessions: state.consensus_sessions + 1,
      last_convergence: System.system_time(:millisecond),
      active_ontologies: :ets.info(:ontology_mesh, :size)
    }
    
    case result do
      :achieved -> %{base_state | resolved_conflicts: base_state.resolved_conflicts + 1}
      :resolved -> %{base_state | resolved_conflicts: base_state.resolved_conflicts + 1}
      :failed -> %{base_state | failed_consensus: base_state.failed_consensus + 1}
    end
  end
end
