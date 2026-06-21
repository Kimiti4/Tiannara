defmodule Tiannara.ROS.EvolutionEngine do
  @moduledoc """
  Drives the natural evolution of civilizations.
  Handles reproduction, fission, speciation, and migration.
  """

  use GenServer
  require Logger

  alias Tiannara.OMCS
  alias Tiannara.OMCS.Engine, as: OMCSEngine
  alias Tiannara.ROS.ShardManager
  alias Tiannara.ROS.CivilizationSpawner
  alias Tiannara.Core.WorldModel.BeliefSystem
  alias Tiannara.ROS.CivilizationRuin

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Reproduce: Parent survives, creates a descendant.
  """
  def reproduce(shard_id, parent_civ_id, new_civ_name) do
    Logger.info("🧬 [Evolution] Civilization #{parent_civ_id} attempting reproduction into #{new_civ_name}")
    
    cost = %{energy: 500, compute: 100, attention: 50, ontological_capital: 0}
    with :ok <- Tiannara.REL.EconomyEngine.consume(parent_civ_id, cost) do
      Logger.info("✅ [Evolution] #{parent_civ_id} afforded reproduction.")
      # Capture parent identity
      parent_seed = OMCS.capture_identity(shard_id, parent_civ_id)
      
      # Fetch parent genome
      parent_genome =
        case Tiannara.Core.WorldModel.EntityRegistry.get_entity(parent_civ_id, shard_id) do
          {:ok, ent} -> Map.get(ent.attributes, :epistemic_genome, Tiannara.Core.WorldModel.EpistemicGenome.new())
          _ -> Tiannara.Core.WorldModel.EpistemicGenome.new()
        end
      child_genome = Tiannara.Core.WorldModel.EpistemicGenome.mutate(parent_genome, 0.1)

    # Spawn child (we need to pass the genome to the spawner, so we'll update Spawner next or inject it here)
    {:ok, child_id} = CivilizationSpawner.spawn_civilization(shard_id, new_civ_name, [])
    # Override genome
    {:ok, child_entity} = Tiannara.Core.WorldModel.EntityRegistry.get_entity(child_id, shard_id)
    Tiannara.Core.WorldModel.EntityRegistry.update_entity(child_id, %{attributes: Map.put(child_entity.attributes, :epistemic_genome, child_genome)}, shard_id)
    
    # Link child to parent via :reproduced_from
    OMCSEngine.register_civilization(child_id, parent_civ_id, :reproduced_from)

    # Inject parent beliefs into child (100% copy for reproduction, diverge later)
    inject_ontology(shard_id, parent_seed.ontology_fingerprint)

    # Record milestones
    OMCSEngine.record_milestone(parent_civ_id, OMCS.Milestone.new(:reproduction, "Reproduced #{new_civ_name}"))
    OMCSEngine.record_milestone(child_id, OMCS.Milestone.new(:reproduction, "Reproduced from #{parent_civ_id}"))

    {:ok, child_id}
    else
      err ->
        Logger.warn("❌ [Evolution] #{parent_civ_id} failed reproduction: #{inspect(err)}")
        err
    end
  end

  @doc """
  Fission: Parent terminates, splits into two descendants with partitioned ontologies in new shards.
  """
  def fission(parent_shard, parent_civ_id, child_a_shard, child_b_shard, child_a_name, child_b_name) do
    Logger.info("⚡ [Evolution] Civilization #{parent_civ_id} attempting fission into #{child_a_name} and #{child_b_name}")

    cost = %{energy: 800, compute: 200, attention: 100, ontological_capital: 0}
    with :ok <- Tiannara.REL.EconomyEngine.consume(parent_civ_id, cost) do
      Logger.info("✅ [Evolution] #{parent_civ_id} afforded fission.")
      # Capture parent
    parent_seed = OMCS.capture_identity(parent_shard, parent_civ_id)
    
    {:ok, parent_entity} = Tiannara.Core.WorldModel.EntityRegistry.get_entity(parent_civ_id, parent_shard)
    parent_genome = Map.get(parent_entity.attributes, :epistemic_genome, Tiannara.Core.WorldModel.EpistemicGenome.new())
    # Fission causes a heavier mutation (0.3)
    child_a_genome = Tiannara.Core.WorldModel.EpistemicGenome.mutate(parent_genome, 0.3)
    child_b_genome = Tiannara.Core.WorldModel.EpistemicGenome.mutate(parent_genome, 0.3)

    # Terminate parent
    {:ok, parent_ent} = Tiannara.Core.WorldModel.EntityRegistry.get_entity(parent_civ_id, parent_shard)
    Tiannara.Core.WorldModel.EntityRegistry.update_entity(parent_civ_id, %{attributes: Map.put(parent_ent.attributes, :status, "dead")}, parent_shard)
    _ruin = CivilizationRuin.create(parent_shard, parent_civ_id, :fission, parent_seed)

    # Community detection
    {core_a, core_b, shared} = detect_belief_communities(parent_seed.ontology_fingerprint)

    # Spawn Shards
    ShardManager.spawn_shard(child_a_shard)
    ShardManager.spawn_shard(child_b_shard)
    Process.sleep(50) # give time for GenServers to start

    # Spawn Child A
    {:ok, child_a_id} = CivilizationSpawner.spawn_civilization(child_a_shard, child_a_name, [])
    {:ok, ent_a} = Tiannara.Core.WorldModel.EntityRegistry.get_entity(child_a_id, child_a_shard)
    Tiannara.Core.WorldModel.EntityRegistry.update_entity(child_a_id, %{attributes: Map.put(ent_a.attributes, :epistemic_genome, child_a_genome)}, child_a_shard)
    OMCSEngine.register_civilization(child_a_id, parent_civ_id, :fissioned_from)
    inject_ontology(child_a_shard, core_a ++ shared)
    OMCSEngine.record_milestone(child_a_id, OMCS.Milestone.new(:fission, "Fissioned from #{parent_civ_id} (Core A)"))

    # Spawn Child B
    {:ok, child_b_id} = CivilizationSpawner.spawn_civilization(child_b_shard, child_b_name, [])
    {:ok, ent_b} = Tiannara.Core.WorldModel.EntityRegistry.get_entity(child_b_id, child_b_shard)
    Tiannara.Core.WorldModel.EntityRegistry.update_entity(child_b_id, %{attributes: Map.put(ent_b.attributes, :epistemic_genome, child_b_genome)}, child_b_shard)
    OMCSEngine.register_civilization(child_b_id, parent_civ_id, :fissioned_from)
    inject_ontology(child_b_shard, core_b ++ shared)
    OMCSEngine.record_milestone(child_b_id, OMCS.Milestone.new(:fission, "Fissioned from #{parent_civ_id} (Core B)"))

    {:ok, child_a_id, child_b_id}
    else
      err ->
        Logger.warn("❌ [Evolution] #{parent_civ_id} failed fission: #{inspect(err)}")
        err
    end
  end

  @doc """
  Migrate: Moves a civilization to a new shard, leaving a ruin behind.
  """
  def migrate(from_shard, to_shard, civ_id) do
    Logger.info("🚀 [Evolution] Civilization #{civ_id} attempting migration from #{from_shard} to #{to_shard}")
    
    cost = %{energy: 700, compute: 300, attention: 200, ontological_capital: 0}
    with :ok <- Tiannara.REL.EconomyEngine.consume(civ_id, cost) do
      Logger.info("✅ [Evolution] #{civ_id} afforded migration.")
      # 1. Capture Identity
    seed = OMCS.capture_identity(from_shard, civ_id)

    # 2. Leave Ruin
    _ruin = CivilizationRuin.create(from_shard, civ_id, :migration, seed)

    # 3. Form new migrated Identity
    migrated_id = "#{civ_id}-migrated-#{System.system_time(:millisecond)}"
    
    # Update seed for new ID
    migrated_seed = %{seed | civilization_id: migrated_id}
    
    # Register the edge in OMCS
    OMCSEngine.register_civilization(migrated_id, civ_id, :migrated_from)
    
    # Restore in new Shard
    {:ok, continuity} = OMCS.restore_identity(to_shard, migrated_seed)
    
    # Record milestone
    OMCSEngine.record_milestone(migrated_id, OMCS.Milestone.new(:migration, "Migrated from #{from_shard} to #{to_shard}"))
    
    {:ok, continuity, migrated_id}
    else
      err ->
        Logger.warn("❌ [Evolution] #{civ_id} failed migration: #{inspect(err)}")
        err
    end
  end

  @doc """
  Check Speciation: Automatic divergence check.
  """
  def check_speciation(shard_id, civ_id, baseline_seed) do
    # Evaluating divergence costs 50 Attention
    case Tiannara.REL.EconomyEngine.consume(civ_id, %{attention: 50}) do
      :ok ->
        current_seed = OMCS.capture_identity(shard_id, civ_id)
        continuity = OMCS.ContinuityScorer.score(baseline_seed, current_seed)
        
        # Divergence is 1.0 - Continuity
        ontology_divergence = 1.0 - continuity.ontology_continuity
        narrative_divergence = 1.0 - continuity.narrative_continuity

        if ontology_divergence > 0.7 or narrative_divergence > 0.6 do
          Logger.info("🧬 [Evolution] Automatic speciation triggered for #{civ_id}")
          
          base_name = String.replace(civ_id, "lineage:", "")
          new_species_name = "#{base_name}-Species-#{System.system_time(:millisecond)}"
          
          # We don't charge reproduction cost here because reproduction() already charges 500 Energy
          case reproduce(shard_id, civ_id, new_species_name) do
            {:ok, new_species_id} -> {:speciated, new_species_id}
            err -> err
          end
        else
          :stable
        end
      err ->
        Logger.warn("⚠️ [Evolution] #{civ_id} lacks attention to evaluate speciation.")
        err
    end
  end

  @doc """
  Extinction: Stage 4 Death. A civilization is completely purged from active state
  but leaves behind its Identity, Discoveries, and an EpochClosure.
  """
  def extinct(shard_id, civ_id) do
    Logger.info("💀 [Evolution] Civilization #{civ_id} has breached the dormancy threshold. Initiating Extinction.")
    
    # 1. Fetch current state (budget and fitness)
    budget = Tiannara.REL.EconomyEngine.get_budget(civ_id) || %{}
    # The fitness score could be fetched from EntityRegistry or elsewhere
    entity = Tiannara.Core.WorldModel.EntityRegistry.get_entity(civ_id, shard_id) |> case do
      {:ok, ent} -> ent
      _ -> %{attributes: %{}}
    end
    
    # 2. Capture Identity
    identity_seed = Tiannara.OMCS.capture_identity(shard_id, civ_id)

    # 3. Orphan Discoveries (to :relic state)
    relic_discoveries = Tiannara.REL.DiscoveryLedger.orphan_for_civilization(civ_id)
    
    # 4. Extract known diseases
    known_discoveries = Tiannara.REL.DiscoveryLedger.get_known_discoveries(civ_id)
    diseases = Enum.filter(known_discoveries, fn d -> Map.get(d, :is_disease, false) or String.starts_with?(d.id, "disease_") end)
    |> Enum.map(& &1.id)

    # 4.5. Extract active operators
    operators = Map.get(entity.attributes, :active_operators, [])

    # 5. Construct Context for EpochClosure
    context = %{
      fitness_score: Map.get(entity.attributes, :fitness_score, 0.0),
      continuity_score: length(Map.get(entity.attributes, :lineage, [])) * 10.0,
      truth_capital: Map.get(budget, :truth_capital, 0.0),
      influence_capital: Map.get(budget, :influence_capital, 0.0),
      identity_seed: identity_seed,
      maintenance_drain: Map.get(budget, :maintenance_drain, 0), # Mocked or fetched
      ontology_drift: 0, 
      sync_failures: 0,
      competitive_pressure: 0.0,
      relic_discoveries: Enum.map(relic_discoveries, & &1.id),
      epoch_duration: Map.get(entity.attributes, :epoch_duration, 100),
      generation_count: Map.get(entity.attributes, :generation_count, 10),
      diseases: diseases,
      operators: operators
    }
    
    # We construct a mock civ_state for the EpochClosure
    civ_state = %{
      id: civ_id,
      shard_id: shard_id,
      lineage: [], # could fetch from OMCS
      discovery_portfolio: Enum.map(relic_discoveries, & &1.id),
      resource_budget: budget
    }

    # 5. Emit EpochClosure
    closure = Tiannara.REL.Types.EpochClosure.from_civilization(civ_state, context)

    # 6. Create Ruin
    ruin = %{
      shard_id: shard_id,
      civ_id: civ_id,
      extinguished_at: System.system_time(:millisecond),
      identity_seed: identity_seed,
      relic_discoveries: relic_discoveries,
      final_fitness: closure.final_fitness,
      epoch_survived: 0 # Placeholder
    }
    Tiannara.ROS.RuinRegistry.store(ruin)
    
    # 7. Purge Active State
    Tiannara.Core.WorldModel.EntityRegistry.remove_entity(civ_id, shard_id)
    Tiannara.REL.EconomyEngine.remove_budget(civ_id)

    # 8. LEOC Compression
    {:ok, eigen} = Tiannara.LEOC.CompressionEngine.compress(closure)
    
    # Update closure with LEOC flag
    closure = %{closure | compressed_to_latent: true}

    # Provide the closure to SEA
    # Tiannara.Sentinel.EpistemologyArchive.archive_closure(closure)

    {:ok, %{ruin: ruin, closure: closure, eigen_seed: eigen}}
  end

  @impl true
  def init(_opts) do
    Logger.info("Initializing Evolution Engine")
    {:ok, %{}}
  end

  # --- Helpers ---

  defp detect_belief_communities(beliefs) when is_list(beliefs) do
    shuffled = Enum.shuffle(beliefs)
    len = length(shuffled)
    
    if len < 4 do
      {shuffled, shuffled, []}
    else
      part_size = div(len, 4)
      # 25% core A, 25% core B, 50% shared -> intersection=2, union=4 -> 0.5 similarity
      {core_a, rest} = Enum.split(shuffled, part_size)
      {core_b, shared} = Enum.split(rest, part_size)
      {core_a, core_b, shared}
    end
  end

  defp detect_belief_communities(_), do: {[], [], []}

  defp inject_ontology(shard_id, fingerprint) do
    name = Tiannara.ROS.Registry.via(BeliefSystem, shard_id)
    Enum.each(fingerprint || [], fn statement ->
      try do
        GenServer.call(name, {:add_belief, %{
          id: "evo:#{:crypto.strong_rand_bytes(4) |> Base.encode16()}",
          statement: statement,
          confidence: 0.9,
          source: "evolution",
          evidence: [],
          created_at: DateTime.utc_now(),
          last_verified: DateTime.utc_now()
        }})
      catch
        :exit, _ -> :ok
      end
    end)
  end
end
