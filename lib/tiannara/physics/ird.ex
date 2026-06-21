defmodule Tiannara.Physics.IRD do
  @moduledoc """
  Intervention Resonance Dampener (IRD).

  Dampens intervention resonances, manages distributed interventions, and coordinates across the system.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def register_intervention(intervention_id, intervention_data, opts \\ []) do
    GenServer.call(__MODULE__, {:register_intervention, intervention_id, intervention_data, opts})
  end

  def dampen_resonance(intervention_id, resonance_data, opts \\ []) do
    GenServer.call(__MODULE__, {:dampen_resonance, intervention_id, resonance_data, opts})
  end

  def get_intervention_status(intervention_id) do
    GenServer.call(__MODULE__, {:get_intervention_status, intervention_id})
  end

  def get_all_interventions() do
    GenServer.call(__MODULE__, :get_all_interventions)
  end

  def coordinate_distributed_intervention(target_systems, intervention_data) do
    GenServer.call(__MODULE__, {:coordinate_distributed_intervention, target_systems, intervention_data})
  end

  def get_resonance_damping_metrics() do
    GenServer.call(__MODULE__, :get_resonance_damping_metrics)
  end

  def validate_intervention_safety(intervention_data) do
    GenServer.call(__MODULE__, {:validate_intervention_safety, intervention_data})
  end

  def calculate_resonance_potential(target_system) do
    GenServer.call(__MODULE__, {:calculate_resonance_potential, target_system})
  end

  def get_system_coordination_status() do
    GenServer.call(__MODULE__, :get_system_coordination_status)
  end

  def publish_coordination_event(event_data) do
    GenServer.call(__MODULE__, {:publish_coordination_event, event_data})
  end

  def subscribe_to_coordination_events(subscription_id, filters \\ []) do
    GenServer.call(__MODULE__, {:subscribe_to_coordination_events, subscription_id, filters})
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize ETS tables for intervention management
    :ets.new(:interventions, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(:resonance_data, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:coordination_events, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:subscriptions, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:damping_metrics, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    # Configuration
    config = %{
      max_interventions: 1000,
      resonance_threshold: 0.8,
      damping_factor: 0.7,
      coordination_timeout: 30_000,  # 30 seconds
      safety_validation_enabled: true,
      auto_dampening_enabled: true,
      event_retention_period: 864_00000,  # 24 hours
      nats_enabled: true,
      jetstream_enabled: true
    }

    # Initialize coordination state
    coordination_state = %{
      connected_systems: [],
      coordination_sessions: 0,
      last_coordination: 0,
      coordination_success_rate: 1.0,
      active_subscriptions: 0
    }

    Logger.info("Intervention Resonance Dampener initialized")
    
    # Start NATS/JetStream connection if enabled
    if config.nats_enabled do
      start_nats_connection(config)
    end

    {:ok, %{
      config: config,
      coordination_state: coordination_state,
      total_interventions: 0,
      total_dampening_operations: 0,
      average_damping_efficiency: 0.0,
      last_dampening: 0,
      resonance_levels: %{}
    }}
  end

  @impl true
  def handle_call({:register_intervention, intervention_id, intervention_data, opts}, _from, state) do
    # Validate intervention
    case validate_intervention(intervention_id, intervention_data) do
      :ok ->
        # Check intervention limit
        if state.total_interventions >= state.config.max_interventions do
          {:reply, {:error, :intervention_limit_exceeded}, state}
        end
        
        # Create intervention
        intervention = create_intervention(intervention_id, intervention_data, opts)
        :ets.insert(:interventions, {intervention_id, intervention})
        
        # Calculate initial resonance potential
        resonance_potential = calculate_resonance_potential_for_system(intervention.target_systems)
        
        # Store resonance data
        resonance_data = %{
          intervention_id: intervention_id,
          resonance_level: resonance_potential,
          timestamp: System.system_time(:millisecond),
          damping_applied: false
        }
        
        :ets.insert(:resonance_data, {intervention_id, resonance_data})
        
        # Update resonance levels
        updated_resonance_levels = Map.put(state.resonance_levels, intervention_id, resonance_potential)
        
        Logger.info("Registered intervention #{intervention_id}")
        
        {:reply, {:ok, intervention_id, resonance_potential}, 
         %{state | 
           total_interventions: state.total_interventions + 1,
           resonance_levels: updated_resonance_levels
         }}
        
      {:error, reason} ->
        Logger.error("Invalid intervention: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:dampen_resonance, intervention_id, resonance_data, opts}, _from, state) do
    case :ets.lookup(:interventions, intervention_id) do
      [{^intervention_id, intervention}] ->
        # Validate safety
        case validate_intervention_safety_for_dampening(intervention, resonance_data) do
          :ok ->
            # Apply dampening
            dampening_result = apply_resonance_dampening(intervention, resonance_data, state.config)
            
            # Update resonance data
            updated_resonance_data = %{resonance_data | 
              damping_applied: true,
              dampening_timestamp: System.system_time(:millisecond),
              damping_efficiency: dampening_result.efficiency
            }
            
            :ets.insert(:resonance_data, {intervention_id, updated_resonance_data})
            
            # Record damping metrics
            record_damping_metrics(intervention_id, dampening_result)
            
            # Publish coordination event
            coordination_event = %{
              type: :resonance_dampened,
              intervention_id: intervention_id,
              target_systems: intervention.target_systems,
              resonance_level: resonance_data.resonance_level,
              damping_efficiency: dampening_result.efficiency,
              timestamp: System.system_time(:millisecond)
            }
            
            publish_coordination_event(coordination_event)
            
            Logger.info("Dampened resonance for intervention #{intervention_id}")
            
            {:reply, {:ok, dampening_result}, 
             %{state | 
               total_dampening_operations: state.total_dampening_operations + 1,
               last_dampening: System.system_time(:millisecond),
               average_damping_efficiency: calculate_average_damping_efficiency(state, dampening_result)
             }}
            
          {:error, reason} ->
            Logger.error("Safety validation failed for dampening: #{reason}")
            {:reply, {:error, reason}, state}
        end
        
      [] ->
        {:reply, {:error, :intervention_not_found}, state}
    end
  end

  @impl true
  def handle_call({:get_intervention_status, intervention_id}, _from, state) do
    case :ets.lookup(:interventions, intervention_id) do
      [{^intervention_id, intervention}] ->
        # Get resonance data
        resonance_data = :ets.select(:resonance_data, [{
          {intervention_id, :"$1"},
          [],
          [:"$1"]
        }])
        
        status = %{
          intervention_id: intervention_id,
          intervention_data: intervention,
          resonance_data: hd(resonance_data),
          coordination_status: get_intervention_coordination_status(intervention_id)
        }
        
        {:reply, {:ok, status}, state}
        
      [] ->
        {:reply, {:error, :intervention_not_found}, state}
    end
  end

  @impl true
  def handle_call(:get_all_interventions, _from, state) do
    interventions = :ets.tab2list(:interventions)
    |> Enum.map(fn {intervention_id, intervention_data} ->
      %{id: intervention_id, data: intervention_data}
    end)
    
    {:reply, {:ok, interventions}, state}
  end

  @impl true
  def handle_call({:coordinate_distributed_intervention, target_systems, intervention_data}, _from, state) do
    # Validate target systems
    case validate_target_systems(target_systems) do
      :ok ->
        # Perform coordination
        coordination_result = coordinate_across_systems(target_systems, intervention_data, state.config)
        
        # Update coordination state
        updated_coordination_state = update_coordination_state(state.coordination_state, coordination_result)
        
        case coordination_result do
          {:success, coordinated_systems, coordination_id} ->
            # Store coordination result
            coordination_record = %{
              coordination_id: coordination_id,
              target_systems: target_systems,
              coordinated_systems: coordinated_systems,
              intervention_data: intervention_data,
              timestamp: System.system_time(:millisecond),
              status: :success
            }
            
            :ets.insert(:coordination_events, {coordination_record})
            
            Logger.info("Coordinated distributed intervention across #{length(coordinated_systems)} systems")
            
            {:reply, {:ok, coordination_result}, 
             %{state | 
               coordination_state: updated_coordination_state
             }}
            
          {:failure, reason} ->
            Logger.error("Distributed coordination failed: #{reason}")
            
            # Store failed coordination
            coordination_record = %{
              coordination_id: "failed_#{System.system_time(:millisecond)}",
              target_systems: target_systems,
              intervention_data: intervention_data,
              timestamp: System.system_time(:millisecond),
              status: :failed,
              error: reason
            }
            
            :ets.insert(:coordination_events, {coordination_record})
            
            {:reply, {:error, reason}, 
             %{state | 
               coordination_state: updated_coordination_state
             }}
        end
        
      {:error, reason} ->
        Logger.error("Invalid target systems: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:get_resonance_damping_metrics, _from, state) do
    metrics = %{
      total_interventions: :ets.info(:interventions, :size),
      total_resonance_data: :ets.info(:resonance_data, :size),
      total_coordination_events: :ets.info(:coordination_events, :size),
      total_subscriptions: :ets.info(:subscriptions, :size),
      total_damping_operations: state.total_dampening_operations,
      average_damping_efficiency: state.average_damping_efficiency,
      last_dampening: state.last_dampening,
      coordination_state: state.coordination_state,
      resonance_levels: state.resonance_levels
    }
    
    {:reply, {:ok, metrics}, state}
  end

  @impl true
  def handle_call({:validate_intervention_safety, intervention_data}, _from, state) do
    # Validate intervention safety
    safety_validation = perform_safety_validation(intervention_data, state.config)
    
    # Store validation result
    validation_record = %{
      timestamp: System.system_time(:millisecond),
      intervention_data: intervention_data,
      safety_score: safety_validation.score,
      risks_identified: safety_validation.risks,
      validation_passed: safety_validation.passed
    }
    
    :ets.insert(:damping_metrics, {validation_record})
    
    Logger.info("Safety validation for intervention: #{safety_validation.score}")
    
    {:reply, {:ok, safety_validation}, state}
  end

  @impl true
  def handle_call({:calculate_resonance_potential, target_system}, _from, state) do
    # Calculate resonance potential for target system
    potential = calculate_system_resonance_potential(target_system, state.config)
    
    # Store potential calculation
    calculation_record = %{
      timestamp: System.system_time(:millisecond),
      target_system: target_system,
      resonance_potential: potential,
      calculation_parameters: state.config
    }
    
    :ets.insert(:damping_metrics, {calculation_record})
    
    {:reply, {:ok, potential}, state}
  end

  @impl true
  def handle_call(:get_system_coordination_status, _from, state) do
    coordination_status = get_system_coordination_details(state.coordination_state)
    
    {:reply, {:ok, coordination_status}, state}
  end

  @impl true
  def handle_call({:publish_coordination_event, event_data}, _from, state) do
    # Validate event data
    case validate_coordination_event(event_data) do
      :ok ->
        # Store event
        :ets.insert(:coordination_events, {event_data})
        
        # Notify subscribers
        notify_event_subscribers(event_data)
        
        # Publish to NATS/JetStream if enabled
        if state.config.nats_enabled do
          publish_to_nats(event_data)
        end
        
        Logger.info("Published coordination event: #{event_data.type}")
        
        {:reply, :ok, state}
        
      {:error, reason} ->
        Logger.error("Invalid coordination event: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:subscribe_to_coordination_events, subscription_id, filters}, _from, state) do
    # Create subscription
    subscription = create_coordination_subscription(subscription_id, filters)
    :ets.insert(:subscriptions, {subscription_id, subscription})
    
    # Update subscription count
    updated_coordination_state = %{state.coordination_state | 
      active_subscriptions: state.coordination_state.active_subscriptions + 1
    }
    
    Logger.info("Created coordination subscription #{subscription_id}")
    
    {:reply, :ok, 
     %{state | 
       coordination_state: updated_coordination_state
     }}
  end

  # Helper functions
  defp validate_intervention(intervention_id, intervention_data) when is_binary(intervention_id) and is_map(intervention_data) do
    case intervention_id do
      "" -> {:error, :empty_intervention_id}
      _ ->
        case intervention_data do
          %{target_systems: systems} when is_list(systems) -> :ok
          _ -> {:error, :invalid_intervention_data}
        end
    end
  end

  defp validate_intervention(_, _), do: {:error, :invalid_parameters}

  defp create_intervention(intervention_id, intervention_data, opts) do
    %{
      id: intervention_id,
      target_systems: intervention_data.target_systems,
      intervention_type: intervention_data.intervention_type,
      parameters: intervention_data.parameters,
      created_at: System.system_time(:millisecond),
      status: :active,
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  defp calculate_resonance_potential_for_system(target_systems) when is_list(target_systems) do
    # Calculate overall resonance potential for target systems
    system_potentials = Enum.map(target_systems, fn system ->
      calculate_system_resonance_potential(system, %{})
    end)
    
    if length(system_potentials) > 0 do
      Enum.sum(system_potentials) / length(system_potentials)
    else
      0.0
    end
  end

  defp calculate_system_resonance_potential(target_system, config) do
    # Simplified resonance potential calculation
    # In production would use more sophisticated algorithms
    
    # Base potential calculation
    base_potential = :rand.uniform() * 0.5 + 0.3
    
    # Apply system-specific factors
    case target_system do
      "core_system" -> base_potential * 1.2
      "memory_system" -> base_potential * 0.8
      "processing_system" -> base_potential * 1.0
      _ -> base_potential
    end
  end

  defp validate_intervention_safety_for_dampening(intervention, resonance_data) do
    # Check if intervention can safely dampen resonance
    case intervention do
      %{status: :active} ->
        case resonance_data do
          %{resonance_level: level} when level > 0.9 ->
            {:error, :resonance_level_too_high}
          _ -> :ok
        end
      _ ->
        {:error, :intervention_not_active}
    end
  end

  defp apply_resonance_dampening(intervention, resonance_data, config) do
    # Apply dampening algorithm
    original_resonance = resonance_data.resonance_level
    
    # Calculate dampening factor
    dampening_factor = config.damping_factor
    
    # Apply dampening
    damped_resonance = original_resonance * dampening_factor
    
    # Calculate efficiency
    efficiency = 1.0 - (damped_resonance / original_resonance)
    
    # Generate dampening report
    dampening_report = %{
      original_resonance: original_resonance,
      damped_resonance: damped_resonance,
      dampening_factor: dampening_factor,
      efficiency: efficiency,
      target_systems: intervention.target_systems
    }
    
    dampening_report
  end

  defp record_damping_metrics(intervention_id, dampening_result) do
    metrics = %{
      timestamp: System.system_time(:millisecond),
      intervention_id: intervention_id,
      efficiency: dampening_result.efficiency,
      original_resonance: dampening_result.original_resonance,
      damped_resonance: dampening_result.damped_resonance,
      target_systems: dampening_result.target_systems
    }
    
    :ets.insert(:damping_metrics, {metrics})
  end

  defp calculate_average_damping_efficiency(state, dampening_result) do
    if state.total_dampening_operations > 0 do
      (state.average_damping_efficiency * (state.total_dampening_operations - 1) + dampening_result.efficiency) / state.total_dampening_operations
    else
      dampening_result.efficiency
    end
  end

  defp get_intervention_coordination_status(intervention_id) do
    # Get coordination events for this intervention
    coordination_events = :ets.select(:coordination_events, [{
      {:_, :"$1"},
      [{:==, {:element, 2, :"$1"}, intervention_id}],
      [:"$1"]
    }])
    
    case length(coordination_events) do
      0 -> :not_coordinated
      _ ->
        latest_event = hd(Enum.sort_by(coordination_events, & &1.timestamp, :desc))
        latest_event.status
    end
  end

  defp validate_target_systems(target_systems) when is_list(target_systems) do
    case length(target_systems) do
      0 -> {:error, :no_target_systems}
      n when n > 50 -> {:error, :too_many_target_systems}
      _ -> :ok
    end
  end

  defp coordinate_across_systems(target_systems, intervention_data, config) do
    coordinated_systems =
      Enum.filter(target_systems, fn system ->
        case attempt_system_coordination(system, intervention_data, config) do
          :success -> true
          :failure -> false
        end
      end)

    if length(coordinated_systems) > 0 do
      {:success, coordinated_systems, generate_coordination_id()}
    else
      {:failure, :no_systems_coordinated}
    end
  end

  defp attempt_system_coordination(_system, _intervention_data, _config) do
    if :rand.uniform() > 0.8, do: :success, else: :failure
  end

  defp generate_coordination_id() do
    "coordination_#{System.system_time(:millisecond)}_#{:crypto.strong_rand_bytes(8) |> Base.url_encode64()}"
  end

  defp update_coordination_state(coordination_state, coordination_result) do
    case coordination_result do
      {:success, _, _} ->
        %{coordination_state | 
          coordination_sessions: coordination_state.coordination_sessions + 1,
          last_coordination: System.system_time(:millisecond)
        }
      {:failure, _} ->
        %{coordination_state | 
          coordination_sessions: coordination_state.coordination_sessions + 1,
          last_coordination: System.system_time(:millisecond),
          coordination_success_rate: coordination_state.coordination_success_rate * 0.95
        }
    end
  end

  defp get_system_coordination_details(coordination_state) do
    %{
      connected_systems: coordination_state.connected_systems,
      coordination_sessions: coordination_state.coordination_sessions,
      last_coordination: coordination_state.last_coordination,
      coordination_success_rate: coordination_state.coordination_success_rate,
      active_subscriptions: coordination_state.active_subscriptions
    }
  end

  defp validate_coordination_event(event_data) do
    case event_data do
      %{type: type, timestamp: timestamp} when is_binary(type) and is_integer(timestamp) -> :ok
      _ -> {:error, :invalid_event_data}
    end
  end

  defp notify_event_subscribers(event_data) do
    # Get all subscriptions
    subscriptions = :ets.tab2list(:subscriptions)
    
    # Filter subscriptions that match event
    matching_subscriptions = Enum.filter(subscriptions, fn {_, subscription} ->
      event_matches_subscription?(event_data, subscription)
    end)
    
    # Notify matching subscribers
    Enum.each(matching_subscriptions, fn {subscription_id, _} ->
      notify_subscriber(subscription_id, event_data)
    end)
  end

  defp event_matches_subscription?(event_data, subscription) do
    # Check if event matches subscription filters
    case subscription.filters do
      [] -> true  # No filters means match all events
      filters ->
        Enum.all?(filters, fn filter ->
          case filter do
            {:type, expected_type} -> event_data.type == expected_type
            {:timestamp_range, {start, end_time}} -> 
              event_data.timestamp >= start and event_data.timestamp <= end_time
            _ -> true
          end
        end)
    end
  end

  defp notify_subscriber(subscription_id, event_data) do
    # Simulate subscriber notification
    Logger.debug("Notifying subscriber #{subscription_id} of event: #{event_data.type}")
  end

  defp create_coordination_subscription(subscription_id, filters) do
    %{
      id: subscription_id,
      filters: filters,
      created_at: System.system_time(:millisecond),
      active: true
    }
  end

  defp perform_safety_validation(intervention_data, config) do
    # Simplified safety validation
    # In production would use sophisticated safety algorithms
    
    risks = []
    
    # Check for dangerous parameters
    case intervention_data do
      %{parameters: params} ->
        case params do
          %{force: force} when force > 100 -> 
            risks = risks ++ ["High force parameter: #{force}"]
          _ -> :ok
        end
      _ -> :ok
    end
    
    # Calculate safety score
    safety_score = if length(risks) == 0, do: 1.0, else: 0.7
    
    %{
      score: safety_score,
      risks: risks,
      passed: length(risks) == 0,
      timestamp: System.system_time(:millisecond)
    }
  end

  defp start_nats_connection(config) do
    # Initialize NATS/JetStream connection
    # This is a placeholder - in production would use actual NATS client
    Logger.info("Starting NATS/JetStream connection")
    
    # Start connection process
    # {:ok, pid} = NATS.connect([...])
    # {:ok, jetstream_pid} = NATS.JetStream.stream(pid, [...])
    
    :ok
  end

  defp publish_to_nats(event_data) do
    # Publish event to NATS/JetStream
    # This is a placeholder - in production would use actual NATS client
    Logger.info("Publishing event to NATS: #{event_data.type}")
    
    # NATS.publish(jetstream_pid, "coordination.events", event_data)
    
    :ok
  end
end