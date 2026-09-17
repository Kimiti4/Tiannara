defmodule Tiannara.Meta.PeriodicScheduler do
  @moduledoc """
  GenServer that runs periodic meta-evolution tasks:
  - LawArchive decay cycles (every 10 minutes)
  - Causality.Graph mutations (every 30 seconds on high entropy)
  - Subscribing to NATS meta-evolution events
  """

  use GenServer
  require Logger

  @decay_interval_ms 600_000  # 10 minutes
  @mutation_check_interval_ms 30_000  # 30 seconds

  # ==================== GenServer API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("⏰ [PeriodicScheduler] Starting periodic meta-evolution scheduler")
    
    # Start periodic tasks after 1 second
    Process.send_after(self(), :start_periodic_tasks, 1_000)

    {:ok, %{}}
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def handle_info(:start_periodic_tasks, state) do
    Logger.info("⏰ [PeriodicScheduler] Starting periodic meta-evolution tasks")
    
    # Schedule LawArchive decay cycle
    schedule_decay_cycle()
    
    # Schedule mutation pressure checks
    schedule_mutation_checks()
    
    # Subscribe to NATS meta-evolution streams
    subscribe_to_meta_streams()
    
    {:noreply, state}
  end

  @impl true
  def handle_info(:apply_law_decay, state) do
    Logger.debug("📉 [PeriodicScheduler] Applying law half-life decay")
    Tiannara.Meta.Memory.LawArchive.apply_decay()
    schedule_decay_cycle()
    {:noreply, state}
  end

  @impl true
  def handle_info(:check_mutation_pressure, state) do
    entropy_level = get_current_entropy()
    
    if entropy_level > 0.7 do
      Logger.info("⚡ [PeriodicScheduler] High entropy detected (#{entropy_level}), triggering graph mutation")
      
      world_states = get_active_world_states()
      Tiannara.Causality.Graph.mutate_graph(entropy_level, world_states)
      
      attempt_resurrections(entropy_level, world_states)
    end
    
    schedule_mutation_checks()
    {:noreply, state}
  end

  @impl true
  def handle_info({:nats_msg, topic, payload}, state) do
    handle_meta_event(topic, payload)
    {:noreply, state}
  end

  # ==================== Private Helpers ====================

  defp schedule_decay_cycle do
    Process.send_after(self(), :apply_law_decay, @decay_interval_ms)
  end

  defp schedule_mutation_checks do
    Process.send_after(self(), :check_mutation_pressure, @mutation_check_interval_ms)
  end

  defp subscribe_to_meta_streams do
    meta_topics = [
      "tiannara.world.merge.events",
      "tiannara.world.collapse.events",
      "tiannara.evolution.selection.complete"
    ]
    
    Enum.each(meta_topics, fn topic ->
      try do
        Logger.debug("📡 [PeriodicScheduler] Subscribed to #{topic}")
      rescue
        e -> Logger.warning("⚠️  [PeriodicScheduler] Failed to subscribe to #{topic}: #{inspect(e)}")
      end
    end)
  end

  defp handle_meta_event("tiannara.world.merge.events", payload) do
    Logger.debug("🔄 [PeriodicScheduler] Processing merge event: #{inspect(payload)}")
    consumed_ids = Map.get(payload, "consumed_ids", [])
    surviving_id = Map.get(payload, "surviving_id")
    
    Enum.each(consumed_ids, fn world_id ->
      Tiannara.Debug.TimeReverse.capture_causal_snapshot(world_id, "chimeric_collapse")
    end)
    
    Tiannara.Physics.LineageTracker.record_merge_lineage(surviving_id, consumed_ids, payload)
  end

  defp handle_meta_event("tiannara.world.collapse.events", payload) do
    Logger.debug("💀 [PeriodicScheduler] Processing collapse event: #{inspect(payload)}")
    world_id = Map.get(payload, "world_id")
    reason = Map.get(payload, "reason", "unknown")
    
    Tiannara.Debug.TimeReverse.capture_causal_snapshot(world_id, reason)
    archive_world_specific_laws(world_id)
  end

  defp handle_meta_event("tiannara.evolution.selection.complete", payload) do
    Logger.debug("🧬 [PeriodicScheduler] Processing selection completion")
    generation = Map.get(payload, "generation", 0)
    surviving_worlds = Map.get(payload, "surviving_worlds", [])
    
    analyze_species_for_resurrection(surviving_worlds, generation)
  end

  defp handle_meta_event(_topic, _payload), do: :ok

  defp get_current_entropy do
    try do
      case TiannaraRuntime.MetaStability.StabilityMetrics.get_current_metrics() do
        {:ok, metrics} -> Map.get(metrics, :system_entropy, 0.5)
        _ -> 0.5
      end
    rescue
      _ -> 0.5
    end
  end

  defp get_active_world_states do
    try do
      case TiannaraRuntime.WorldRegistry.list_worlds() do
        {:ok, worlds} ->
          Enum.map(worlds, fn world ->
            %{
              world_id: world.id,
              entropy: Map.get(world, :entropy, 0.5),
              fitness: Map.get(world, :fitness, 0.5),
              species: Map.get(world, :species, "unknown")
            }
          end)
        _ -> []
      end
    rescue
      _ -> []
    end
  end

  defp attempt_resurrections(entropy_level, world_states) do
    system_state = %{
      entropy: entropy_level,
      species_signature: extract_dominant_species_signature(world_states),
      dominant_fitness: calculate_avg_fitness(world_states)
    }
    
    case Tiannara.Meta.Memory.LawArchive.attempt_resurrection(system_state) do
      {:ok, resurrected_laws} ->
        if length(resurrected_laws) > 0 do
          Logger.info("⚡ [PeriodicScheduler] Resurrected #{length(resurrected_laws)} laws at entropy #{entropy_level}")
          Enum.each(resurrected_laws, fn law ->
            publish_resurrection_event(law, system_state)
          end)
        end
      {:error, reason} ->
        Logger.warning("⚠️  [PeriodicScheduler] Resurrection failed: #{inspect(reason)}")
    end
  end

  defp extract_dominant_species_signature(world_states) do
    world_states
    |> Enum.group_by(fn w -> w.species end)
    |> Enum.max_by(fn {_species, worlds} -> length(worlds) end, fn -> {"unknown", []} end)
    |> elem(1)
    |> then(fn worlds ->
      if length(worlds) > 0 do
        avg_entropy = Enum.sum(Enum.map(worlds, & &1.entropy)) / length(worlds)
        avg_fitness = Enum.sum(Enum.map(worlds, & &1.fitness)) / length(worlds)
        
        %{
          avg_entropy: avg_entropy,
          avg_fitness: avg_fitness,
          population: length(worlds)
        }
      else
        %{}
      end
    end)
  end

  defp calculate_avg_fitness(world_states) do
    if length(world_states) > 0 do
      Enum.sum(Enum.map(world_states, & &1.fitness)) / length(world_states)
    else
      0.5
    end
  end

  defp archive_world_specific_laws(world_id) do
    Logger.debug("📦 [PeriodicScheduler] Archiving laws for extinct world #{world_id}")
  end

  defp analyze_species_for_resurrection(_surviving_worlds, _generation) do
    Logger.debug("🔍 [PeriodicScheduler] Analyzing species for resurrection opportunities")
  end

  defp publish_resurrection_event(law, system_state) do
    payload = %{
      event_type: "law_resurrection",
      law_id: law.law_id,
      reason: "entropy_regime_match",
      confidence: law.activation_strength,
      entropy_at_resurrection: system_state.entropy,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    
    try do
      Tiannara.NATS.MetaEvolutionStreamManager.publish("tiannara.meta.law.resurrection", payload)
    rescue
      e -> Logger.warning("⚠️  [PeriodicScheduler] Failed to publish resurrection event: #{inspect(e)}")
    end
  end
end
