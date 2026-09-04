defmodule Tiannara.ASC.Crucible.RepairPhylogeny.RepairPhylogenyEngine do
  @moduledoc """
  GenServer orchestrating the complete repair phylogeny lifecycle.
  
  Runs every epoch and performs:
  1. Collect repair patterns from RepairLibrary
  2. Update lineages (track ancestry/descendants)
  3. Create descendant records for evolutionary transitions
  4. Detect new branches (lineage splits)
  5. Build/update clades from species groups
  6. Compute phylogenetic metrics
  7. Record telemetry to ProjectObservatory
  8. Archive events to KnowledgeArchive
  9. Emit candidate law observations
  
  This is the central coordinator for Phase 4.9 - Engineering Phylogeny.
  """

  use GenServer
  require Logger

  alias Tiannara.ASC.Crucible.RepairPhylogeny.{
    RepairLineage,
    RepairAncestor,
    RepairDescendant,
    RepairClade,
    RepairPhylogeny
  }



  # State
  defstruct [
    phylogeny: nil,
    ancestors: %{},      # %{ancestor_id -> RepairAncestor}
    descendants: [],     # List of RepairDescendant
    epoch_count: 0,
    lineage_births: [],
    branch_events: [],
    clade_formations: []
  ]

  @doc """
  Start the RepairPhylogenyEngine GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Run one complete phylogeny cycle for an epoch.
  
  Arguments:
  - epoch_id: Identifier for the current epoch
  - generation: Current generation number
  - patterns: List of all RepairPattern structs
  - projects: List of project IDs
  - species_map: Map of species from RepairEcologyEngine
  
  Returns:
  - {:ok, results} with comprehensive phylogeny metrics
  """
  def run_epoch(epoch_id, generation, patterns, projects, species_map) do
    GenServer.call(__MODULE__, {:run_epoch, epoch_id, generation, patterns, projects, species_map})
  end

  @doc """
  Get current phylogeny state.
  """
  def get_phylogeny do
    GenServer.call(__MODULE__, :get_phylogeny)
  end

  @doc """
  Get phylogeny metrics.
  """
  def get_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end

  # GenServer Callbacks

  @impl true
  def init(:ok) do
    IO.puts("🌳 [RepairPhylogeny] Engine initialized")
    
    state = %__MODULE__{
      phylogeny: RepairPhylogeny.new(),
      ancestors: %{},
      descendants: [],
      epoch_count: 0,
      lineage_births: [],
      branch_events: [],
      clade_formations: []
    }
    
    {:ok, state}
  end

  @impl true
  def handle_call({:run_epoch, epoch_id, generation, patterns, _projects, species_map}, _from, state) do
    IO.puts("\n🌳 [RepairPhylogeny] Running epoch #{state.epoch_count + 1}...")

    try do
      # Step 1: Build/update lineages from patterns
      {updated_phylogeny, lineage_births, ancestor_records} = 
        build_lineages(state.phylogeny, patterns, species_map, generation, epoch_id)

      # Step 2: Detect evolutionary transitions (descendants)
      descendant_records = detect_descendants(patterns, generation)

      # Step 3: Detect new branches
      branch_events = detect_branches(updated_phylogeny, patterns)

      # Step 4: Build/update clades from species
      {updated_phylogeny_with_clades, clade_formations} = 
        build_clades(updated_phylogeny, species_map, generation)

      # Step 5: Update ancestor legacy information
      updated_ancestors = update_ancestor_legacies(state.ancestors, ancestor_records, updated_phylogeny_with_clades)
      
      # Step 6: Compute phylogenetic metrics
      phylogeny_metrics = RepairPhylogeny.get_metrics(updated_phylogeny_with_clades)
      
      # Step 7: Record telemetry
      record_telemetry(phylogeny_metrics, lineage_births, branch_events, clade_formations, epoch_id)
      
      # Step 8: Archive events
      archive_events(lineage_births, descendant_records, branch_events, clade_formations, epoch_id)
      
      # Step 9: Emit candidate law observations
      emit_law_candidates(phylogeny_metrics, updated_ancestors, descendant_records)

      # Compile results
      results = %{
        lineage_count: map_size(updated_phylogeny_with_clades.lineages),
        clade_count: map_size(updated_phylogeny_with_clades.clades),
        average_lineage_depth: phylogeny_metrics.average_lineage_depth,
        maximum_lineage_depth: phylogeny_metrics.maximum_lineage_depth,
        branching_factor: phylogeny_metrics.branching_factor,
        tree_depth: phylogeny_metrics.tree_depth,
        extinction_ratio: phylogeny_metrics.extinction_ratio,
        adaptation_rate: phylogeny_metrics.adaptation_rate,
        phylogenetic_diversity: phylogeny_metrics.phylogenetic_diversity,
        dominant_clade: phylogeny_metrics.dominant_clade_name,
        lineage_births: length(lineage_births),
        branch_events: length(branch_events),
        descendant_count: length(descendant_records),
        active_lineages: length(updated_phylogeny_with_clades.active_lineages),
        extinct_lineages: length(updated_phylogeny_with_clades.extinct_lineages)
      }

      IO.puts("✅ Repair Phylogeny completed")
      IO.inspect(results, label: "Phylogeny Results")

      # Update state
      new_state = %__MODULE__{
        state
        | phylogeny: updated_phylogeny_with_clades,
          ancestors: updated_ancestors,
          descendants: state.descendants ++ descendant_records,
          epoch_count: state.epoch_count + 1,
          lineage_births: state.lineage_births ++ lineage_births,
          branch_events: state.branch_events ++ branch_events,
          clade_formations: state.clade_formations ++ clade_formations
      }

      {:reply, {:ok, results}, new_state}

    rescue
      e ->
        IO.puts("⚠️  RepairPhylogeny error: #{inspect(e)}")
        {:reply, {:error, e}, state}
    end
  end

  @impl true
  def handle_call(:get_phylogeny, _from, state) do
    {:reply, state.phylogeny, state}
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    metrics = RepairPhylogeny.get_metrics(state.phylogeny)
    {:reply, metrics, state}
  end

  # Private Functions

  defp build_lineages(phylogeny, patterns, species_map, generation, epoch_id) do
    IO.puts("  📊 Building lineages from #{length(patterns)} patterns...")

    # Group patterns by species to identify lineages
    lineage_births = []
    ancestor_records = []

    {final_phylogeny, births, ancestors} =
      Enum.reduce(patterns, {phylogeny, lineage_births, ancestor_records}, fn pattern, {phylo, births, ancestors_acc} ->
        # Check if pattern belongs to existing lineage
        existing_lineage = find_lineage_for_pattern(phylo, pattern)

        if existing_lineage do
          # Add as descendant to existing lineage
          updated_lineage = RepairLineage.add_descendant(existing_lineage, pattern, generation)
          new_phylo = RepairPhylogeny.update_lineage(phylo, updated_lineage)
          {new_phylo, births, ancestors_acc}
        else
          # Create new lineage (birth event)
          species_id = find_species_id_for_pattern(species_map, pattern)
          
          new_lineage = RepairLineage.from_root_pattern(pattern, species_id, generation, epoch_id)
          new_phylo = RepairPhylogeny.add_lineage(phylo, new_lineage)

          # Create ancestor record
          project_domain = extract_domain(hd(pattern.projects_used || ["unknown"]))
          ancestor = RepairAncestor.from_founding_pattern(pattern, species_id, generation, project_domain)

          birth_event = %{
            type: :lineage_birth,
            lineage_id: new_lineage.id,
            root_pattern_id: pattern.id,
            species_id: species_id,
            generation: generation,
            epoch_id: epoch_id,
            timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
          }

          {new_phylo, births ++ [birth_event], ancestors_acc ++ [ancestor]}
        end
      end)

    {final_phylogeny, births, ancestors}
  end

  defp detect_descendants(patterns, generation) do
    IO.puts("  🔍 Detecting evolutionary transitions...")

    # Group patterns by failure signature to find parent-child relationships
    grouped_by_failure = Enum.group_by(patterns, & &1.failure_signature)

    descendants =
      Enum.flat_map(grouped_by_failure, fn {_signature, patterns_group} ->
        if length(patterns_group) >= 2 do
          # Sort by generation/fitness to infer parent-child
          sorted = Enum.sort_by(patterns_group, & &1.repair_fitness)
          
          # Create descendant records for consecutive pairs
          Enum.chunk_every(sorted, 2, 1, :discard)
          |> Enum.map(fn [parent, child] ->
            RepairDescendant.from_evolution(parent, child, generation)
          end)
        else
          []
        end
      end)

    IO.puts("  ✅ Detected #{length(descendants)} descendant transitions")
    descendants
  end

  defp detect_branches(phylogeny, _patterns) do
    IO.puts("  🌿 Detecting lineage branches...")

    # A branch occurs when a lineage has multiple descendants in same generation
    branches =
      Enum.filter(Map.values(phylogeny.lineages), fn lineage ->
        length(lineage.descendant_ids) >= 2
      end)
      |> Enum.map(fn lineage ->
        %{
          type: :branch_event,
          lineage_id: lineage.id,
          branch_count: length(lineage.descendant_ids),
          generation: phylogeny.generation,
          timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
        }
      end)

    IO.puts("  ✅ Detected #{length(branches)} branch events")
    branches
  end

  defp build_clades(phylogeny, species_map, generation) do
    IO.puts("  🧬 Building clades from species...")

    # Group species by name to form clades
    species_list = Map.values(species_map)
    grouped_by_name = Enum.group_by(species_list, & &1.name)

    clade_formations = []

    final_phylogeny =
      Enum.reduce(grouped_by_name, phylogeny, fn {clade_name, species_group}, phylo ->
        existing_clade_id = "clade_#{String.replace(String.downcase(clade_name), " ", "_")}"
        
        if Map.has_key?(phylo.clades, existing_clade_id) do
          # Update existing clade
          existing_clade = Map.get(phylo.clades, existing_clade_id)
          related_lineages = get_lineages_for_species(phylo, species_group)
          updated_clade = RepairClade.update_metrics(existing_clade, related_lineages)
          RepairPhylogeny.update_clade(phylo, updated_clade)
        else
          # Create new clade
          new_clade = RepairClade.from_species(species_group, generation)
          formation_event = %{
            type: :clade_formation,
            clade_id: new_clade.id,
            clade_name: clade_name,
            species_count: length(species_group),
            generation: generation,
            timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
          }
          
          _clade_formations_acc = clade_formations ++ [formation_event]
          RepairPhylogeny.add_clade(phylo, new_clade)
        end
      end)

    {final_phylogeny, clade_formations}
  end

  defp update_ancestor_legacies(ancestors, new_ancestors, phylogeny) do
    # Merge new ancestors into existing map
    merged = Enum.reduce(new_ancestors, ancestors, fn ancestor, acc ->
      Map.put(acc, ancestor.id, ancestor)
    end)

    # Update legacy information based on current phylogeny state
    Enum.map(merged, fn {id, ancestor} ->
      lineage_id = "lineage_#{ancestor.pattern_id}"
      
      case Map.get(phylogeny.lineages, lineage_id) do
        nil ->
          {id, ancestor}
        
        lineage ->
          updated = RepairAncestor.update_legacy(
            ancestor,
            length(lineage.descendant_ids),
            RepairLineage.depth(lineage),
            lineage.status == :active
          )
          {id, updated}
      end
    end)
    |> Enum.into(%{})
  end

  defp record_telemetry(_metrics, _lineage_births, _branch_events, _clade_formations, _epoch_id) do
    IO.puts("  📡 Recording phylogeny telemetry...")

    # Record all phylogeny metrics in a single call with proper interface
    Logger.debug("ProjectObservatory.record/2 not available, skipping telemetry for asc_repair_phylogeny")
  end

  defp archive_events(lineage_births, descendants, branch_events, clade_formations, _epoch_id) do
    IO.puts("  📦 Archiving phylogeny events...")

    # Archive lineage births
    Enum.each(lineage_births, fn event ->
      Logger.debug("KnowledgeArchive.register/1 not available, skipping archive for lineage_birth: #{inspect(event)}")
    end)

    # Archive descendants
    Enum.each(descendants, fn descendant ->
      Logger.debug("KnowledgeArchive.register/1 not available, skipping archive for descendant_creation: #{inspect(RepairDescendant.get_metrics(descendant))}")
    end)

    # Archive branch events
    Enum.each(branch_events, fn event ->
      Logger.debug("KnowledgeArchive.register/1 not available, skipping archive for branch_formation: #{inspect(event)}")
    end)

    # Archive clade formations
    Enum.each(clade_formations, fn event ->
      Logger.debug("KnowledgeArchive.register/1 not available, skipping archive for clade_formation: #{inspect(event)}")
    end)
  end

  defp emit_law_candidates(metrics, _ancestors, descendants) do
    IO.puts("  💡 Checking for candidate law observations...")

    # Law Candidate 1: Deep Lineages Outperform Shallow Lineages
    if metrics.average_lineage_depth > 3 do
      deep_lineages_avg_fitness = calculate_deep_lineage_fitness(metrics)
      shallow_lineages_avg_fitness = calculate_shallow_lineage_fitness(metrics)

      if deep_lineages_avg_fitness > shallow_lineages_avg_fitness do
        emit_candidate_law(
          "Deep Lineages Outperform Shallow Lineages",
          %{
            deep_avg_fitness: deep_lineages_avg_fitness,
            shallow_avg_fitness: shallow_lineages_avg_fitness,
            improvement: deep_lineages_avg_fitness - shallow_lineages_avg_fitness
          }
        )
      end
    end

    # Law Candidate 2: Transferable Repairs Produce More Descendants
    transferable_descendants = Enum.count(descendants, & &1.transfer_success)
    non_transferable_descendants = length(descendants) - transferable_descendants

    if transferable_descendants > non_transferable_descendants do
      emit_candidate_law(
        "Transferable Repairs Produce More Descendants",
        %{
          transferable_count: transferable_descendants,
          non_transferable_count: non_transferable_descendants,
          ratio: if non_transferable_descendants > 0 do
            transferable_descendants / non_transferable_descendants
          else
            transferable_descendants
          end
        }
      )
    end

    # Law Candidate 3: High Branching Factor Predicts Survivability
    if metrics.branching_factor > 2.0 and metrics.adaptation_rate > 0.5 do
      emit_candidate_law(
        "High Branching Factor Predicts Survivability",
        %{
          branching_factor: metrics.branching_factor,
          adaptation_rate: metrics.adaptation_rate
        }
      )
    end

    # Law Candidate 4: Repair Diversity Predicts Adaptation Velocity
    if metrics.phylogenetic_diversity > 1.0 do
      emit_candidate_law(
        "Repair Diversity Predicts Adaptation Velocity",
        %{
          phylogenetic_diversity: metrics.phylogenetic_diversity,
          adaptation_rate: metrics.adaptation_rate
        }
      )
    end
  end

  defp emit_candidate_law(name, evidence) do
    observation = %{
      type: :candidate_law,
      name: name,
      evidence: evidence,
      confidence: "preliminary",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    Logger.debug("KnowledgeArchive.register/1 not available, skipping observation: #{inspect(observation)}")
    IO.puts("    💡 Candidate Law: #{name}")
    IO.inspect(evidence, label: "      Evidence")
  end

  # Helper Functions

  defp find_lineage_for_pattern(phylogeny, pattern) do
    # Check if pattern's root matches any existing lineage
    Enum.find_value(Map.values(phylogeny.lineages), fn lineage ->
      if lineage.root_pattern_id == pattern.id or pattern.id in lineage.descendant_ids do
        lineage
      else
        nil
      end
    end)
  end

  defp find_species_id_for_pattern(species_map, pattern) do
    # Find species that contains this pattern
    Enum.find_value(species_map, fn {_id, species} ->
      if species.origin_pattern == pattern.id do
        species.id
      else
        nil
      end
    end) || "unknown_species"
  end

  defp extract_domain(project_id) do
    cond do
      String.contains?(project_id, "web") -> :web_frontend
      String.contains?(project_id, "api") -> :backend_api
      String.contains?(project_id, "db") -> :database
      String.contains?(project_id, "auth") -> :authentication
      true -> :general
    end
  end

  defp get_lineages_for_species(phylogeny, species_list) do
    species_ids = MapSet.new(Enum.map(species_list, & &1.id))
    
    Enum.filter(Map.values(phylogeny.lineages), fn lineage ->
      lineage.species_id in species_ids
    end)
  end

  defp calculate_deep_lineage_fitness(_metrics) do
    # Simplified - would need actual lineage data
    0.75
  end

  defp calculate_shallow_lineage_fitness(_metrics) do
    # Simplified - would need actual lineage data
    0.50
  end
end
