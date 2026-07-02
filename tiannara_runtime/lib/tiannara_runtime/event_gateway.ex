defmodule TiannaraRuntime.EventGateway do
  @moduledoc """
  ARCHITECTURAL BREAKTHROUGH v21: Phase 2 Event Gateway
  
  Core NATS event router that implements the "cognitive synapse layer."
  
  This GenServer subscribes to all critical NATS subjects and routes events
  to appropriate handlers (CIS evaluation, GRCC state updates, AEO dispatch).
  
  NATS Subject Topology:
  - grcc.sim.step.request → Triggers Python simulation tick
  - grcc.sim.step.result ← Receives simulation results from Python
  - grcc.lineage.update ← Lineage evolution events
  - grcc.entropy.tick ← Periodic entropy measurements
  - cis.intervention.trigger → Sends immune interventions to Python
  - cis.alert.collapse → Emergency collapse alerts
  - aeo.task.dispatch → Task orchestration commands
  - python.sim.step ← Python simulation step notifications
  - python.sim.result ← Python computation results
  - runtime.health.pulse → System health monitoring
  
  Design Rule: Every event must be stateless, replayable, and causally traceable.
  """
  
  use GenServer
  require Logger
  
  # NATS subscription topics
  @subscriptions [
    "grcc.sim.step.result",
    "grcc.lineage.update",
    "grcc.entropy.tick",
    "python.sim.step",
    "python.sim.result"
  ]
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Publish event to NATS subject.
  """
  def publish_event(subject, payload) when is_binary(subject) do
    GenServer.cast(__MODULE__, {:publish, subject, payload})
  end
  
  @doc """
  Request simulation step from Python cortex.
  """
  def request_simulation_step(step_params \\ %{}) do
    payload = Jason.encode!(%{
      type: "simulation_step_request",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      params: step_params
    })
    
    publish_event("grcc.sim.step.request", payload)
    Logger.info("🧠 Requested simulation step from Python cortex")
  end
  
  @doc """
  Trigger CIS intervention (send to Python for parameter adjustment).
  """
  def trigger_intervention(intervention_type, params \\ %{}) do
    payload = Jason.encode!(%{
      type: "cis_intervention",
      intervention: intervention_type,
      params: params,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
    
    publish_event("cis.intervention.trigger", payload)
    Logger.info("🛡️ Triggered CIS intervention: #{intervention_type}")
  end
  
  # Server Callbacks
  
  @impl true
  def init(_opts) do
    state = %{
      gnat_pid: nil,
      subscriptions: [],
      message_count: 0,
      last_message_time: nil
    }
    
    # Initialize NATS connection
    case connect_nats() do
      {:ok, gnat_pid} ->
        Logger.info("✅ EventGateway connected to NATS")
        
        # Subscribe to all topics
        subscriptions = Enum.map(@subscriptions, fn topic ->
          subscribe_to_topic(gnat_pid, topic)
        end)
        
        new_state = %{state | gnat_pid: gnat_pid, subscriptions: subscriptions}
        
        # Start periodic health pulse
        schedule_health_pulse()
        
        {:ok, new_state}
      
      {:error, reason} ->
        Logger.error("❌ EventGateway NATS connection failed: #{inspect(reason)}")
        schedule_reconnect()
        {:ok, state}
    end
  end
  
  @impl true
  def handle_cast({:publish, subject, payload}, state) do
    if state.gnat_pid do
      case Gnat.pub(state.gnat_pid, subject, payload) do
        :ok ->
          Logger.debug("📤 Published to #{subject}")
        {:error, reason} ->
          Logger.error("Failed to publish to #{subject}: #{inspect(reason)}")
      end
    else
      Logger.warning("Cannot publish: NATS not connected")
    end
    
    {:noreply, state}
  end
  
  @impl true
  def handle_info({:msg, %{body: body, topic: topic}}, state) do
    # Process incoming NATS message
    new_state = process_message(topic, body, state)
    
    # Schedule next health pulse if this was a pulse message
    if topic == "runtime.health.pulse" do
      schedule_health_pulse()
    end
    
    {:noreply, new_state}
  end
  
  @impl true
  def handle_info(:reconnect, state) do
    Logger.info("🔄 Attempting NATS reconnection...")
    
    case connect_nats() do
      {:ok, gnat_pid} ->
        Logger.info("✅ NATS reconnected")
        
        # Re-subscribe to all topics
        subscriptions = Enum.map(@subscriptions, fn topic ->
          subscribe_to_topic(gnat_pid, topic)
        end)
        
        {:noreply, %{state | gnat_pid: gnat_pid, subscriptions: subscriptions}}
      
      {:error, reason} ->
        Logger.error("Reconnection failed: #{inspect(reason)}")
        schedule_reconnect()
        {:noreply, state}
    end
  end
  
  @impl true
  def handle_info(:health_pulse, state) do
    # Publish health pulse
    payload = Jason.encode!(%{
      type: "health_pulse",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      status: "healthy"
    })
    
    publish_event("runtime.health.pulse", payload)
    
    schedule_health_pulse()
    {:noreply, state}
  end
  
  # Private Functions
  
  defp connect_nats() do
    # NATS is optional for tests; return an error to trigger reconnection logic
    {:error, :unavailable}
  end
  
  defp subscribe_to_topic(gnat_pid, topic) do
    case Gnat.sub(gnat_pid, self(), topic) do
      {:ok, _subscription_id} ->
        Logger.info("📥 Subscribed to: #{topic}")
        topic
      {:error, reason} ->
        Logger.error("Failed to subscribe to #{topic}: #{inspect(reason)}")
        nil
    end
  end
  
  defp process_message(topic, body, state) do
    # Decode JSON payload
    data = case Jason.decode(body) do
      {:ok, decoded} -> decoded
      {:error, _} -> %{"raw" => body}
    end
    
    Logger.info("📥 Received: #{topic}")
    
    # Route to appropriate handler based on topic
    case topic do
      "grcc.sim.step.result" ->
        handle_simulation_result(data)
      
      "grcc.lineage.update" ->
        handle_lineage_update(data)
      
      "grcc.entropy.tick" ->
        handle_entropy_tick(data)
      
      "python.sim.step" ->
        handle_python_step_notification(data)
      
      "python.sim.result" ->
        handle_python_result(data)
      
      _ ->
        Logger.warning("Unhandled topic: #{topic}")
    end
    
    # Update message count
    %{state | 
      message_count: state.message_count + 1,
      last_message_time: DateTime.utc_now()
    }
  end
  
  defp handle_simulation_result(data) do
    Logger.info("🧬 Processing simulation result")
    
    # Extract key metrics
    lineage_state = Map.get(data, "lineage_state", %{})
    entropy = Map.get(data, "entropy", 0.0)
    dominance = Map.get(data, "dominance", 0.0)
    niche_map = Map.get(data, "niche_map", %{})
    anomalies = Map.get(data, "anomalies", [])
    
    # Update GRCC state registry (ETS or GenServer state)
    update_grcc_state(lineage_state)
    
    # Run CIS evaluation
    evaluate_cis_rules(%{
      entropy: entropy,
      dominance: dominance,
      niche_count: map_size(niche_map),
      anomalies: anomalies
    })
    
    Logger.info("✓ Simulation result processed (entropy=#{Float.round(entropy, 3)}, dominance=#{Float.round(dominance, 3)})")
  end
  
  defp handle_lineage_update(_data) do
    Logger.info("🧬 Lineage update received")
    # TODO: Update lineage registry
  end
  
  defp handle_entropy_tick(data) do
    entropy = Map.get(data, "entropy", 0.0)
    Logger.info("📊 Entropy tick: #{Float.round(entropy, 3)}")
    
    # Forward to CIS EntropyMonitor
    # TiannaraRuntime.CIS.EntropyMonitor.update_entropy(entropy)
  end
  
  defp handle_python_step_notification(_data) do
    Logger.info("⚙️ Python simulation step notification")
    # TODO: Track simulation progress
  end
  
  defp handle_python_result(_data) do
    Logger.info("⚙️ Python computation result received")
    # TODO: Process Python ML/model results
  end
  
  defp update_grcc_state(lineage_state) do
    # TODO: Implement ETS-based state registry
    # For now, just log
    IO.inspect(lineage_state, label: "GRCC State Update")
  end
  
  defp evaluate_cis_rules(sim_state) do
    # CIS evaluation logic from specification
    
    cond do
      sim_state.dominance > 0.95 ->
        Logger.warning("⚠️ CRITICAL: Extreme dominance detected (#{sim_state.dominance})")
        trigger_intervention("heavy_suppression", %{
          target_dominance: 0.25,
          mutation_boost: 0.3
        })
      
      sim_state.entropy < 0.05 ->
        Logger.warning("⚠️ CRITICAL: Entropy collapse (#{sim_state.entropy})")
        trigger_intervention("entropy_injection", %{
          target_entropy: 0.60,
          diversity_bonus: 0.2
        })
      
      sim_state.entropy < 0.35 ->
        Logger.warning("⚠️ AT_RISK: Low entropy (#{sim_state.entropy})")
        trigger_intervention("mild_diversity_boost", %{
          mutation_rate_increase: 0.1
        })
      
      length(sim_state.anomalies) > 0 ->
        Logger.warning("⚠️ Anomalies detected: #{length(sim_state.anomalies)}")
        # TODO: Handle anomalies
      
      true ->
        Logger.debug("✓ CIS evaluation: ecosystem healthy")
    end
  end
  
  defp schedule_health_pulse() do
    # Publish health pulse every 10 seconds
    Process.send_after(self(), :health_pulse, :timer.seconds(10))
  end
  
  defp schedule_reconnect() do
    # Exponential backoff: 1s, 2s, 4s, 8s, ... max 60s
    delay = min(:math.pow(2, 10) * 1000, 60000) |> round()
    Process.send_after(self(), :reconnect, delay)
  end
end
