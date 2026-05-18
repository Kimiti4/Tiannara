defmodule TiannaraRuntime.NATS.Subscriber do
  @moduledoc """
  NATS Event Subscriber
  
  Receives events from Python simulation layer and forwards them to appropriate
  Elixir components (GRCC identities, CIS monitors, AEO agents).
  
  Subscribed Topics:
  - tiannara.ecological.state - Full ecosystem state from Python
  - tiannara.fitness.scores - Identity fitness updates
  - tiannara.cis.intervention - CIS intervention commands from Python
  """
  
  use GenServer
  require Logger

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    # Subscribe to Python event topics
    subscribe_to_topics()
    
    Logger.info("📥 NATS Subscriber started")
    
    {:ok, %{}}
  end

  @doc """
  Handle incoming NATS message.
  This is called by NATS.Connection when a message arrives.
  """
  def handle_message(subject, payload) when is_binary(subject) do
    try do
      decoded = Jason.decode!(payload)
      
      case subject do
        "tiannara.ecological.state" ->
          handle_ecological_state(decoded)
        
        "tiannara.fitness.scores" ->
          handle_fitness_scores(decoded)
        
        "tiannara.cis.intervention" ->
          handle_cis_intervention(decoded)
        
        _ ->
          Logger.warning("⚠️  Unknown NATS subject: #{subject}")
      end
    rescue
      e ->
        Logger.error("❌ Failed to process NATS message on #{subject}: #{inspect(e)}")
    end
  end

  # Private handlers
  
  defp handle_ecological_state(data) do
    Logger.debug("📥 Received ecological state: step=#{data["step"]}, entropy=#{data["entropy"]}")
    
    # TODO: Update GRCC identity processes with Python-calculated state
    # Broadcast to Phoenix channel for monitoring
    Phoenix.PubSub.broadcast(
      TiannaraRuntime.PubSub,
      "ecological_events",
      %{type: :python_ecological_state, data: data}
    )
  end

  defp handle_fitness_scores(data) do
    Logger.debug("📥 Received fitness scores for #{length(data["scores"] || [])} identities")
    
    # TODO: Update individual identity processes with fitness scores
    # For each identity, call IdentityLineage.update_fitness/2
  end

  defp handle_cis_intervention(data) do
    Logger.info("🛡️  Received CIS intervention from Python: #{data["type"]}")
    
    # Forward to CIS Recovery Orchestrator
    intervention_type = String.to_atom(data["type"])
    params = data["params"] || %{}
    
    TiannaraRuntime.CIS.RecoveryOrchestrator.apply_intervention(intervention_type, params)
  end

  defp subscribe_to_topics() do
    topics = [
      "tiannara.ecological.state",
      "tiannara.fitness.scores",
      "tiannara.cis.intervention"
    ]
    
    Enum.each(topics, fn topic ->
      TiannaraRuntime.NATS.Connection.subscribe(topic, __MODULE__)
    end)
  end
end

defmodule TiannaraRuntime.NATS.Publisher do
  @moduledoc """
  NATS Event Publisher
  
  Publishes Elixir runtime events to Python simulation layer.
  
  Published Topics:
  - tiannara.identity.created - New identity spawned
  - tiannara.identity.died - Identity extinct
  - tiannara.hybridization.success - Cross-lineage synthesis
  - tiannara.cis.intervention - Immune system action taken
  - tiannara.ecosystem.health - Overall ecosystem health metrics
  """
  
  @doc """
  Publish event to NATS topic.
  """
  def publish(topic, payload) when is_binary(topic) and is_map(payload) do
    enriched_payload = Map.merge(payload, %{
      "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "source" => "elixir_runtime"
    })
    
    case TiannaraRuntime.NATS.Connection.publish(topic, enriched_payload) do
      :ok ->
        Logger.debug("📤 Published to #{topic}")
        :ok
      
      {:error, reason} ->
        Logger.error("❌ Failed to publish to #{topic}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Publish identity creation event.
  """
  def publish_identity_created(identity_id, lineage_id, genome) do
    publish("tiannara.identity.created", %{
      "identity_id" => identity_id,
      "lineage_id" => lineage_id,
      "genome" => genome
    })
  end

  @doc """
  Publish hybridization success event.
  """
  def publish_hybridization_success(parent1_id, parent2_id, offspring_id) do
    publish("tiannara.hybridization.success", %{
      "parent1_id" => parent1_id,
      "parent2_id" => parent2_id,
      "offspring_id" => offspring_id
    })
  end

  @doc """
  Publish CIS intervention event.
  """
  def publish_cis_intervention(intervention_type, target, details) do
    publish("tiannara.cis.intervention", %{
      "type" => intervention_type,
      "target" => target,
      "details" => details
    })
  end

  @doc """
  Publish ecosystem health summary.
  """
  def publish_ecosystem_health(metrics) do
    publish("tiannara.ecosystem.health", metrics)
  end
end
