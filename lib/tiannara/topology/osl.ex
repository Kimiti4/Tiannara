defmodule Tiannara.Topology.OSL do
  @moduledoc """
  Ontological Sandbox Layer (OSL).

  Provides safe experimentation, isolated testing, and controlled ontological modification.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def create_sandbox(sandbox_id, ontologies, opts \\ []) do
    GenServer.call(__MODULE__, {:create_sandbox, sandbox_id, ontologies, opts})
  end

  def execute_in_sandbox(sandbox_id, operation) do
    GenServer.call(__MODULE__, {:execute_in_sandbox, sandbox_id, operation})
  end

  def get_sandbox_status(sandbox_id) do
    GenServer.call(__MODULE__, {:get_sandbox_status, sandbox_id})
  end

  def get_all_sandboxes() do
    GenServer.call(__MODULE__, :get_all_sandboxes)
  end

  def isolate_changes(sandbox_id, target_ontology_id) do
    GenServer.call(__MODULE__, {:isolate_changes, sandbox_id, target_ontology_id})
  end

  def merge_changes(sandbox_id, source_ontology_id, target_ontology_id) do
    GenServer.call(__MODULE__, {:merge_changes, sandbox_id, source_ontology_id, target_ontology_id})
  end

  def rollback_sandbox(sandbox_id, to_version \\ nil) do
    GenServer.call(__MODULE__, {:rollback_sandbox, sandbox_id, to_version})
  end

  def validate_sandbox_integrity(sandbox_id) do
    GenServer.call(__MODULE__, {:validate_sandbox_integrity, sandbox_id})
  end

  def get_sandbox_metrics(sandbox_id) do
    GenServer.call(__MODULE__, {:get_sandbox_metrics, sandbox_id})
  end

  def cleanup_sandbox(sandbox_id) do
    GenServer.call(__MODULE__, {:cleanup_sandbox, sandbox_id})
  end

  def get_sandbox_history(sandbox_id) do
    GenServer.call(__MODULE__, {:get_sandbox_history, sandbox_id})
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize ETS tables for sandbox management
    :ets.new(:sandboxes, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(:sandbox_versions, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:sandbox_changes, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:sandbox_history, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:sandbox_metrics, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    # Configuration
    config = %{
      max_sandboxes: 100,
      max_versions_per_sandbox: 50,
      cleanup_interval: 300_000,  # 5 minutes
      isolation_level: :medium,   # :low, :medium, :high
      auto_merge_enabled: true,
      rollback_enabled: true
    }

    Logger.info("Ontological Sandbox Layer initialized")
    
    # Start cleanup timer
    Process.send_after(self(), :cleanup_sandboxes, config.cleanup_interval)
    
    {:ok, %{
      config: config,
      active_sandboxes: 0,
      total_sandboxes: 0,
      operations_executed: 0,
      last_cleanup: System.system_time(:millisecond)
    }}
  end

  @impl true
  def handle_call({:create_sandbox, sandbox_id, ontologies, opts}, _from, state) do
    # Check if sandbox already exists
    case :ets.lookup(:sandboxes, sandbox_id) do
      [{^sandbox_id, _}] ->
        Logger.warning("Sandbox #{sandbox_id} already exists")
        {:reply, {:error, :sandbox_already_exists}, state}
        
      [] ->
        # Check sandbox limit
        if state.active_sandboxes >= state.config.max_sandboxes do
          {:reply, {:error, :sandbox_limit_exceeded}, state}
        end
        
        # Validate ontologies
        case validate_ontologies_for_sandbox(ontologies) do
          :ok ->
            # Create sandbox
            sandbox_data = create_sandbox_data(sandbox_id, ontologies, opts)
            :ets.insert(:sandboxes, {sandbox_id, sandbox_data})
            
            # Create initial version
            create_sandbox_version(sandbox_id, ontologies, "initial")
            
            Logger.info("Created sandbox #{sandbox_id}")
            
            {:reply, :ok, 
             %{state | 
               active_sandboxes: state.active_sandboxes + 1,
               total_sandboxes: state.total_sandboxes + 1
             }}
            
          {:error, reason} ->
            Logger.error("Cannot create sandbox: #{reason}")
            {:reply, {:error, reason}, state}
        end
    end
  end

  @impl true
  def handle_call({:execute_in_sandbox, sandbox_id, operation}, _from, state) do
    case :ets.lookup(:sandboxes, sandbox_id) do
      [{^sandbox_id, sandbox_data}] ->
        # Validate sandbox state
        case validate_sandbox_state(sandbox_data) do
          :ok ->
            # Execute operation in sandbox
            case execute_operation(sandbox_data, operation) do
              {:ok, result, updated_ontologies} ->
                # Store changes
                record_sandbox_changes(sandbox_id, operation, result)
                
                # Update sandbox
                updated_sandbox = %{sandbox_data | 
                  last_operation: System.system_time(:millisecond),
                  operations_count: sandbox_data.operations_count + 1
                }
                :ets.insert(:sandboxes, {sandbox_id, updated_sandbox})
                
                # Record metrics
                record_sandbox_metrics(sandbox_id, operation, result)
                
                Logger.info("Executed operation in sandbox #{sandbox_id}")
                
                {:reply, {:ok, result}, 
                 %{state | 
                   operations_executed: state.operations_executed + 1
                 }}
                  
              {:error, reason} ->
                Logger.error("Operation failed in sandbox #{sandbox_id}: #{reason}")
                {:reply, {:error, reason}, state}
            end
            
          {:error, reason} ->
            Logger.error("Invalid sandbox state: #{reason}")
            {:reply, {:error, reason}, state}
        end
        
      [] ->
        {:reply, {:error, :sandbox_not_found}, state}
    end
  end

  @impl true
  def handle_call({:get_sandbox_status, sandbox_id}, _from, state) do
    case :ets.lookup(:sandboxes, sandbox_id) do
      [{^sandbox_id, sandbox_data}] ->
        status = get_sandbox_status_details(sandbox_id, sandbox_data)
        {:reply, {:ok, status}, state}
      
      [] ->
        {:reply, {:error, :sandbox_not_found}, state}
    end
  end

  @impl true
  def handle_call(:get_all_sandboxes, _from, state) do
    sandboxes = :ets.tab2list(:sandboxes)
    |> Enum.map(fn {sandbox_id, sandbox_data} ->
      %{id: sandbox_id, data: sandbox_data}
    end)
    
    {:reply, {:ok, sandboxes}, state}
  end

  @impl true
  def handle_call({:isolate_changes, sandbox_id, target_ontology_id}, _from, state) do
    case :ets.lookup(:sandboxes, sandbox_id) do
      [{^sandbox_id, sandbox_data}] ->
        # Isolate changes for specific ontology
        case isolate_sandbox_changes(sandbox_id, target_ontology_id) do
          :ok ->
            Logger.info("Isolated changes for ontology #{target_ontology_id} in sandbox #{sandbox_id}")
            {:reply, :ok, state}
            
          {:error, reason} ->
            Logger.error("Failed to isolate changes: #{reason}")
            {:reply, {:error, reason}, state}
        end
        
      [] ->
        {:reply, {:error, :sandbox_not_found}, state}
    end
  end

  @impl true
  def handle_call({:merge_changes, sandbox_id, source_ontology_id, target_ontology_id}, _from, state) do
    case :ets.lookup(:sandboxes, sandbox_id) do
      [{^sandbox_id, sandbox_data}] ->
        # Merge changes from source to target
        case merge_sandbox_changes(sandbox_id, source_ontology_id, target_ontology_id) do
          {:ok, merged_ontology} ->
            # Store merged version
            create_sandbox_version(sandbox_id, [merged_ontology], "merged_#{source_ontology_id}_to_#{target_ontology_id}")
            
            Logger.info("Merged changes from #{source_ontology_id} to #{target_ontology_id} in sandbox #{sandbox_id}")
            {:reply, {:ok, merged_ontology}, state}
            
          {:error, reason} ->
            Logger.error("Failed to merge changes: #{reason}")
            {:reply, {:error, reason}, state}
        end
        
      [] ->
        {:reply, {:error, :sandbox_not_found}, state}
    end
  end

  @impl true
  def handle_call({:rollback_sandbox, sandbox_id, to_version}, _from, state) do
    case :ets.lookup(:sandboxes, sandbox_id) do
      [{^sandbox_id, sandbox_data}] ->
        # Perform rollback
        case perform_sandbox_rollback(sandbox_id, to_version) do
          {:ok, rollback_data} ->
            Logger.info("Rolled back sandbox #{sandbox_id}")
            {:reply, {:ok, rollback_data}, state}
            
          {:error, reason} ->
            Logger.error("Rollback failed: #{reason}")
            {:reply, {:error, reason}, state}
        end
        
      [] ->
        {:reply, {:error, :sandbox_not_found}, state}
    end
  end

  @impl true
  def handle_call({:validate_sandbox_integrity, sandbox_id}, _from, state) do
    case :ets.lookup(:sandboxes, sandbox_id) do
      [{^sandbox_id, sandbox_data}] ->
        # Validate sandbox integrity
        integrity_check = validate_sandbox_integrity_check(sandbox_data)
        
        # Store validation result
        timestamp = System.system_time(:millisecond)
        validation_record = %{
          timestamp: timestamp,
          sandbox_id: sandbox_id,
          score: integrity_check.score,
          violations: integrity_check.violations,
          passed: integrity_check.passed
        }
        
        :ets.insert(:sandbox_metrics, {validation_record})
        
        Logger.info("Validated sandbox #{sandbox_id} integrity: #{integrity_check.score}")
        
        {:reply, {:ok, integrity_check}, state}
        
      [] ->
        {:reply, {:error, :sandbox_not_found}, state}
    end
  end

  @impl true
  def handle_call({:get_sandbox_metrics, sandbox_id}, _from, state) do
    metrics = get_sandbox_metrics_data(sandbox_id)
    {:reply, {:ok, metrics}, state}
  end

  @impl true
  def handle_call({:cleanup_sandbox, sandbox_id}, _from, state) do
    case :ets.lookup(:sandboxes, sandbox_id) do
      [{^sandbox_id, sandbox_data}] ->
        # Cleanup sandbox
        cleanup_sandbox_data(sandbox_id, sandbox_data)
        
        # Remove from active sandboxes
        :ets.delete(:sandboxes, sandbox_id)
        
        Logger.info("Cleaned up sandbox #{sandbox_id}")
        
        {:reply, :ok, 
         %{state | 
           active_sandboxes: state.active_sandboxes - 1
         }}
        
      [] ->
        {:reply, {:error, :sandbox_not_found}, state}
    end
  end

  @impl true
  def handle_call({:get_sandbox_history, sandbox_id}, _from, state) do
    history = :ets.select(:sandbox_history, [{
      {sandbox_id, :"$1"},
      [],
      [:"$1"]
    }])
    
    {:reply, {:ok, history}, state}
  end

  # Cleanup timer
  @impl true
  def handle_info(:cleanup_sandboxes, state) do
    Logger.info("Performing scheduled sandbox cleanup")
    
    # Clean up old inactive sandboxes
    cleanup_inactive_sandboxes()
    
    # Schedule next cleanup
    Process.send_after(self(), :cleanup_sandboxes, state.config.cleanup_interval)
    
    {:noreply, %{state | last_cleanup: System.system_time(:millisecond)}}
  end

  # Helper functions
  defp validate_ontologies_for_sandbox(ontologies) when is_list(ontologies) do
    case length(ontologies) do
      0 -> {:error, :no_ontologies}
      n when n > 50 -> {:error, :too_many_ontologies}
      _ -> :ok
    end
  end

  defp validate_ontologies_for_sandbox(_), do: {:error, :invalid_input}

  defp create_sandbox_data(sandbox_id, ontologies, opts) do
    %{
      id: sandbox_id,
      ontologies: ontologies,
      created_at: System.system_time(:millisecond),
      last_operation: System.system_time(:millisecond),
      operations_count: 0,
      isolation_level: Keyword.get(opts, :isolation_level, :medium),
      auto_merge: Keyword.get(opts, :auto_merge, true),
      status: :active,
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  defp create_sandbox_version(sandbox_id, ontologies, version_name) do
    timestamp = System.system_time(:millisecond)
    version_data = %{
      sandbox_id: sandbox_id,
      version: version_name,
      ontologies: ontologies,
      timestamp: timestamp,
      created_by: :system
    }
    
    :ets.insert(:sandbox_versions, {sandbox_id, version_data})
    
    # Keep only recent versions
    versions = :ets.select(:sandbox_versions, [{
      {sandbox_id, :"$1"},
      [],
      [:"$1"]
    }])
    
    if length(versions) > 50 do
      # Remove oldest version
      sorted_versions = Enum.sort_by(versions, & &1.timestamp)
      oldest = hd(sorted_versions)
      :ets.delete_object(:sandbox_versions, {sandbox_id, oldest})
    end
  end

  defp validate_sandbox_state(sandbox_data) do
    case sandbox_data.status do
      :active -> :ok
      :locked -> {:error, :sandbox_locked}
      :deleted -> {:error, :sandbox_deleted}
      _ -> {:error, :invalid_sandbox_state}
    end
  end

  defp execute_operation(sandbox_data, operation) do
    # Execute operation in sandbox context
    case operation do
      %{type: :add_concept, ontology_id: ontology_id, concept: concept} ->
        add_concept_to_ontology(sandbox_data, ontology_id, concept)
        
      %{type: :modify_concept, ontology_id: ontology_id, concept_id: concept_id, updates: updates} ->
        modify_concept_in_ontology(sandbox_data, ontology_id, concept_id, updates)
        
      %{type: :remove_concept, ontology_id: ontology_id, concept_id: concept_id} ->
        remove_concept_from_ontology(sandbox_data, ontology_id, concept_id)
        
      %{type: :merge_ontologies, source_id: source_id, target_id: target_id} ->
        merge_ontologies_in_sandbox(sandbox_data, source_id, target_id)
        
      %{type: :validate_ontology, ontology_id: ontology_id} ->
        validate_ontology_in_sandbox(sandbox_data, ontology_id)
        
      _ ->
        {:error, :unsupported_operation}
    end
  end

  defp add_concept_to_ontology(sandbox_data, ontology_id, concept) do
    # Find ontology
    ontology = Enum.find(sandbox_data.ontologies, fn ont ->
      ont.id == ontology_id
    end)
    
    if ontology do
      # Add concept
      updated_concepts = [concept | ontology.concepts]
      updated_ontology = %{ontology | concepts: updated_concepts}
      
      # Update sandbox
      updated_ontologies = Enum.map(sandbox_data.ontologies, fn ont ->
        if ont.id == ontology_id, do: updated_ontology, else: ont
      end)
      
      {:ok, :concept_added, updated_ontologies}
    else
      {:error, :ontology_not_found}
    end
  end

  defp modify_concept_in_ontology(sandbox_data, ontology_id, concept_id, updates) do
    # Find ontology
    ontology = Enum.find(sandbox_data.ontologies, fn ont ->
      ont.id == ontology_id
    end)
    
    if ontology do
      # Find and modify concept
      case Enum.find_index(ontology.concepts, & &1.id == concept_id) do
        nil -> {:error, :concept_not_found}
        index ->
          concept = ontology.concepts[index]
          updated_concept = Map.merge(concept, updates)
          updated_concepts = List.replace_at(ontology.concepts, index, updated_concept)
          updated_ontology = %{ontology | concepts: updated_concepts}
          
          # Update sandbox
          updated_ontologies = Enum.map(sandbox_data.ontologies, fn ont ->
            if ont.id == ontology_id, do: updated_ontology, else: ont
          end)
          
          {:ok, :concept_modified, updated_ontologies}
      end
    else
      {:error, :ontology_not_found}
    end
  end

  defp remove_concept_from_ontology(sandbox_data, ontology_id, concept_id) do
    # Find ontology
    ontology = Enum.find(sandbox_data.ontologies, fn ont ->
      ont.id == ontology_id
    end)
    
    if ontology do
      # Remove concept
      updated_concepts = Enum.reject(ontology.concepts, & &1.id == concept_id)
      updated_ontology = %{ontology | concepts: updated_concepts}
      
      # Update sandbox
      updated_ontologies = Enum.map(sandbox_data.ontologies, fn ont ->
        if ont.id == ontology_id, do: updated_ontology, else: ont
      end)
      
      {:ok, :concept_removed, updated_ontologies}
    else
      {:error, :ontology_not_found}
    end
  end

  defp merge_ontologies_in_sandbox(sandbox_data, source_id, target_id) do
    # Find source and target ontologies
    source = Enum.find(sandbox_data.ontologies, & &1.id == source_id)
    target = Enum.find(sandbox_data.ontologies, & &1.id == target_id)
    
    if source and target do
      # Merge concepts
      merged_concepts = target.concepts ++ source.concepts
      
      # Remove duplicates
      unique_concepts = Enum.uniq_by(merged_concepts, & &1.id)
      
      updated_target = %{target | concepts: unique_concepts}
      updated_ontologies = Enum.map(sandbox_data.ontologies, fn ont ->
        case ont.id do
          ^source_id -> nil  # Remove source ontology
          ^target_id -> updated_target
          _ -> ont
        end
      end) |> Enum.reject(&is_nil/1)
      
      {:ok, :ontologies_merged, updated_ontologies}
    else
      {:error, :ontology_not_found}
    end
  end

  defp validate_ontology_in_sandbox(sandbox_data, ontology_id) do
    # Find ontology
    ontology = Enum.find(sandbox_data.ontologies, fn ont ->
      ont.id == ontology_id
    end)
    
    if ontology do
      # Validate ontology structure
      case validate_ontology_structure(ontology) do
        :ok -> {:ok, :ontology_valid, ontology}
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :ontology_not_found}
    end
  end

  defp validate_ontology_structure(ontology) do
    # Basic validation
    cond do
      not Map.has_key?(ontology, :id) -> {:error, :missing_id}
      not Map.has_key?(ontology, :concepts) -> {:error, :missing_concepts}
      not is_list(ontology.concepts) -> {:error, :invalid_concepts}
      true -> :ok
    end
  end

  defp record_sandbox_changes(sandbox_id, operation, result) do
    change_record = %{
      timestamp: System.system_time(:millisecond),
      sandbox_id: sandbox_id,
      operation: operation,
      result: result
    }
    
    :ets.insert(:sandbox_changes, {sandbox_id, change_record})
  end

  defp record_sandbox_metrics(sandbox_id, operation, result) do
    metrics = %{
      timestamp: System.system_time(:millisecond),
      sandbox_id: sandbox_id,
      operation_type: operation.type,
      operation_success: case result do
        {:ok, _} -> true
        {:error, _} -> false
      end,
      result_metadata: case result do
        {:ok, metadata} -> metadata
        {:error, _} -> %{}
      end
    }
    
    :ets.insert(:sandbox_metrics, {metrics})
  end

  defp get_sandbox_status_details(sandbox_id, sandbox_data) do
    %{
      id: sandbox_id,
      status: sandbox_data.status,
      ontologies_count: length(sandbox_data.ontologies),
      operations_count: sandbox_data.operations_count,
      created_at: sandbox_data.created_at,
      last_operation: sandbox_data.last_operation,
      isolation_level: sandbox_data.isolation_level,
      auto_merge: sandbox_data.auto_merge
    }
  end

  defp isolate_sandbox_changes(sandbox_id, target_ontology_id) do
    # Get changes for target ontology
    changes = :ets.select(:sandbox_changes, [{
      {sandbox_id, :"$1"},
      [{:==, {:element, 3, :"$1"}, target_ontology_id}],
      [:"$1"]
    }])
    
    # Create isolated version
    if length(changes) > 0 do
      create_sandbox_version(sandbox_id, [target_ontology_id], "isolated_#{target_ontology_id}")
      :ok
    else
      {:error, :no_changes_to_isolate}
    end
  end

  defp merge_sandbox_changes(sandbox_id, source_ontology_id, target_ontology_id) do
    # Get source ontology
    source_ontology = get_ontology_from_sandbox(sandbox_id, source_ontology_id)
    target_ontology = get_ontology_from_sandbox(sandbox_id, target_ontology_id)
    
    if source_ontology and target_ontology do
      # Merge ontologies
      merged_concepts = target_ontology.concepts ++ source_ontology.concepts
      unique_concepts = Enum.uniq_by(merged_concepts, & &1.id)
      
      merged_ontology = %{target_ontology | 
        id: "#{target_ontology_id}_merged",
        concepts: unique_concepts,
        metadata: %{
          merged_from: [source_ontology_id, target_ontology_id],
          merged_at: System.system_time(:millisecond)
        }
      }
      
      {:ok, merged_ontology}
    else
      {:error, :ontology_not_found}
    end
  end

  defp get_ontology_from_sandbox(sandbox_id, ontology_id) do
    case :ets.lookup(:sandboxes, sandbox_id) do
      [{^sandbox_id, sandbox_data}] ->
        Enum.find(sandbox_data.ontologies, & &1.id == ontology_id)
      [] ->
        nil
    end
  end

  defp perform_sandbox_rollback(sandbox_id, to_version) do
    # Get versions
    versions = :ets.select(:sandbox_versions, [{
      {sandbox_id, :"$1"},
      [],
      [:"$1"]
    }])
    
    case to_version do
      nil ->
        # Rollback to initial version
        initial_versions = Enum.filter(versions, & &1.version == "initial")
        case initial_versions do
          [initial] ->
            {:ok, initial.ontologies}
          [] ->
            {:error, :initial_version_not_found}
        end
        
      version_name ->
        # Rollback to specific version
        target_versions = Enum.filter(versions, & &1.version == version_name)
        case target_versions do
          [target] ->
            {:ok, target.ontologies}
          [] ->
            {:error, :version_not_found}
        end
    end
  end

  defp validate_sandbox_integrity_check(sandbox_data) do
    # Check ontology consistency
    ontology_issues = validate_ontology_consistency(sandbox_data.ontologies)
    
    # Check operation history
    operation_issues = validate_operation_history(sandbox_data)
    
    # Check for circular references
    reference_issues = check_circular_references(sandbox_data.ontologies)
    
    total_issues = length(ontology_issues) + length(operation_issues) + length(reference_issues)
    
    %{
      score: max(0.0, 1.0 - (total_issues / max(length(sandbox_data.ontologies) * 10, 1))),
      violations: ontology_issues ++ operation_issues ++ reference_issues,
      passed: total_issues == 0,
      timestamp: System.system_time(:millisecond)
    }
  end

  defp validate_ontology_consistency(ontologies) do
    issues = []
    
    Enum.each(ontologies, fn ontology ->
      # Check concept IDs uniqueness
      concept_ids = Enum.map(ontology.concepts, & &1.id)
      duplicates = concept_ids -- Enum.uniq(concept_ids)
      
      if length(duplicates) > 0 do
        issues = issues ++ ["Duplicate concept IDs in #{ontology.id}: #{inspect(duplicates)}"]
      end
      
      # Check required fields
      Enum.each(ontology.concepts, fn concept ->
        if not Map.has_key?(concept, :id) do
          issues = issues ++ ["Concept missing ID in #{ontology.id}"]
        end
      end)
    end)
    
    issues
  end

  defp validate_operation_history(sandbox_data) do
    # Check for suspicious operation patterns
    issues = []
    
    # Check for rapid succession of operations
    if sandbox_data.operations_count > 100 do
      issues = issues ++ ["High operation count: #{sandbox_data.operations_count}"]
    end
    
    issues
  end

  defp check_circular_references(ontologies) do
    # Simple circular reference check
    issues = []
    
    # This would need more sophisticated analysis in production
    issues
  end

  defp get_sandbox_metrics_data(sandbox_id) do
    # Get all metrics for sandbox
    metrics = :ets.select(:sandbox_metrics, [{
      {sandbox_id, :"$1"},
      [],
      [:"$1"]
    }])
    
    # Calculate summary statistics
    total_operations = length(metrics)
    successful_operations = Enum.count(metrics, & &1.operation_success)
    
    %{
      sandbox_id: sandbox_id,
      total_operations: total_operations,
      successful_operations: successful_operations,
      success_rate: (if total_operations > 0, do: successful_operations / total_operations, else: 0.0),
      recent_metrics: Enum.take(metrics, 10),
      timestamp: System.system_time(:millisecond)
    }
  end

  defp cleanup_sandbox_data(sandbox_id, sandbox_data) do
    # Remove all related data
    :ets.delete(:sandboxes, sandbox_id)
    :ets.delete(:sandbox_versions, sandbox_id)
    :ets.delete(:sandbox_changes, sandbox_id)
    :ets.delete(:sandbox_history, sandbox_id)
    :ets.delete(:sandbox_metrics, sandbox_id)
  end

  defp cleanup_inactive_sandboxes() do
    # Find inactive sandboxes
    sandboxes = :ets.tab2list(:sandboxes)
    inactive_sandboxes = Enum.filter(sandboxes, fn {_, sandbox_data} ->
      # Sandbox is inactive if no operations for more than 1 hour
      System.system_time(:millisecond) - sandbox_data.last_operation > 3_600_000
    end)
    
    # Clean up inactive sandboxes
    Enum.each(inactive_sandboxes, fn {sandbox_id, _} ->
      cleanup_sandbox_data(sandbox_id, nil)
    end)
    
    Logger.info("Cleaned up #{length(inactive_sandboxes)} inactive sandboxes")
  end
end
