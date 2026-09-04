defmodule Tiannara.ASC.Crucible.RepairPhylogeny.RepairPhylogeny do
  @moduledoc """
  Represents the entire evolutionary tree of repair patterns.
  
  The phylogeny tracks:
  - All active and extinct lineages
  - Clade structure (major evolutionary branches)
  - Root ancestors
  - Phylogenetic metrics (diversity, depth, branching factor)
  
  This is the top-level data structure for engineering evolution analysis.
  """

  alias Tiannara.ASC.Crucible.RepairPhylogeny.{RepairLineage, RepairClade}

  @derive Jason.Encoder
  defstruct [
    # Evolutionary Structure
    lineages: %{},        # %{lineage_id -> RepairLineage}
    clades: %{},          # %{clade_id -> RepairClade}
    roots: [],            # List of root ancestor pattern IDs
    
    # Status Tracking
    extinct_lineages: [],
    active_lineages: [],
    
    # Temporal
    generation: 0
    
  ]

  @type t :: %__MODULE__{}

  @doc """
  Initialize an empty phylogeny.
  """
  def new(generation \\ 0) do
    %__MODULE__{
      lineages: %{},
      clades: %{},
      roots: [],
      extinct_lineages: [],
      active_lineages: [],
      generation: generation
    }
  end

  @doc """
  Add a new lineage to the phylogeny.
  """
  def add_lineage(%__MODULE__{} = phylogeny, %RepairLineage{} = lineage) do
    %__MODULE__{
      phylogeny
      | lineages: Map.put(phylogeny.lineages, lineage.id, lineage),
        roots: phylogeny.roots ++ [lineage.root_pattern_id],
        active_lineages: phylogeny.active_lineages ++ [lineage.id]
    }
  end

  @doc """
  Update an existing lineage in the phylogeny.
  """
  def update_lineage(%__MODULE__{} = phylogeny, %RepairLineage{} = updated_lineage) do
    %__MODULE__{
      phylogeny
      | lineages: Map.put(phylogeny.lineages, updated_lineage.id, updated_lineage)
    }
  end

  @doc """
  Mark a lineage as extinct.
  """
  def mark_lineage_extinct(%__MODULE__{} = phylogeny, lineage_id) do
    case Map.get(phylogeny.lineages, lineage_id) do
      nil ->
        phylogeny
      
      lineage ->
        extinct_lineage = RepairLineage.mark_extinct(lineage)
        
        %__MODULE__{
          phylogeny
          | lineages: Map.put(phylogeny.lineages, lineage_id, extinct_lineage),
            active_lineages: List.delete(phylogeny.active_lineages, lineage_id),
            extinct_lineages: phylogeny.extinct_lineages ++ [lineage_id]
        }
    end
  end

  @doc """
  Add a new clade to the phylogeny.
  """
  def add_clade(%__MODULE__{} = phylogeny, %RepairClade{} = clade) do
    %__MODULE__{
      phylogeny
      | clades: Map.put(phylogeny.clades, clade.id, clade)
    }
  end

  @doc """
  Update an existing clade in the phylogeny.
  """
  def update_clade(%__MODULE__{} = phylogeny, %RepairClade{} = updated_clade) do
    %__MODULE__{
      phylogeny
      | clades: Map.put(phylogeny.clades, updated_clade.id, updated_clade)
    }
  end

  @doc """
  Calculate average lineage depth across all lineages.
  """
  def average_lineage_depth(%__MODULE__{} = phylogeny) do
    case Map.values(phylogeny.lineages) do
      [] -> 0.0
      lineages ->
        Enum.sum_by(lineages, & RepairLineage.depth/1) / length(lineages)
    end
  end

  @doc """
  Calculate maximum lineage depth.
  """
  def maximum_lineage_depth(%__MODULE__{} = phylogeny) do
    case Map.values(phylogeny.lineages) do
      [] -> 0
      lineages ->
        Enum.max_by(lineages, & RepairLineage.depth/1) |> RepairLineage.depth()
    end
  end

  @doc """
  Calculate branching factor (average descendants per lineage).
  """
  def branching_factor(%__MODULE__{} = phylogeny) do
    case Map.values(phylogeny.lineages) do
      [] -> 0.0
      lineages ->
        total_descendants = Enum.sum_by(lineages, fn l -> length(l.descendant_ids) end)
        total_lineages = length(lineages)
        total_descendants / total_lineages
    end
  end

  @doc """
  Calculate tree depth (longest path from root to leaf).
  """
  def tree_depth(%__MODULE__{} = phylogeny) do
    maximum_lineage_depth(phylogeny)
  end

  @doc """
  Calculate extinction ratio.
  """
  def extinction_ratio(%__MODULE__{} = phylogeny) do
    total = length(phylogeny.active_lineages) + length(phylogeny.extinct_lineages)
    
    if total == 0 do
      0.0
    else
      length(phylogeny.extinct_lineages) / total
    end
  end

  @doc """
  Calculate adaptation rate (percentage of lineages with improving fitness).
  """
  def adaptation_rate(%__MODULE__{} = phylogeny) do
    case Map.values(phylogeny.lineages) do
      [] -> 0.0
      lineages ->
        improving = 
          Enum.count(lineages, fn lineage ->
            RepairLineage.fitness_improvement_rate(lineage) > 0
          end)
        
        improving / length(lineages)
    end
  end

  @doc """
  Calculate phylogenetic diversity using Shannon index on clade distribution.
  """
  def phylogenetic_diversity(%__MODULE__{} = phylogeny) do
    clades = Map.values(phylogeny.clades)
    
    case clades do
      [] -> 0.0
      _ ->
        total_population = Enum.sum_by(clades, & &1.population_size)
        
        if total_population == 0 do
          0.0
        else
          # Calculate Shannon diversity index
          diversities =
            Enum.map(clades, fn clade ->
              proportion = clade.population_size / total_population
              if proportion > 0 do
                -proportion * :math.log(proportion)
              else
                0.0
              end
            end)
          
          Enum.sum(diversities)
        end
    end
  end

  @doc """
  Get dominant clade (largest population).
  """
  def dominant_clade(%__MODULE__{} = phylogeny) do
    case Map.values(phylogeny.clades) do
      [] -> nil
      clades ->
        Enum.max_by(clades, & &1.population_size)
    end
  end

  @doc """
  Get comprehensive phylogeny metrics for observability.
  """
  def get_metrics(%__MODULE__{} = phylogeny) do
    %{
      total_lineages: map_size(phylogeny.lineages),
      active_lineages: length(phylogeny.active_lineages),
      extinct_lineages: length(phylogeny.extinct_lineages),
      total_clades: map_size(phylogeny.clades),
      
      average_lineage_depth: Float.round(average_lineage_depth(phylogeny), 3),
      maximum_lineage_depth: maximum_lineage_depth(phylogeny),
      
      branching_factor: Float.round(branching_factor(phylogeny), 3),
      tree_depth: tree_depth(phylogeny),
      
      extinction_ratio: Float.round(extinction_ratio(phylogeny), 3),
      adaptation_rate: Float.round(adaptation_rate(phylogeny), 3),
      
      phylogenetic_diversity: Float.round(phylogenetic_diversity(phylogeny), 3),
      
      dominant_clade_name: case dominant_clade(phylogeny) do
        nil -> "none"
        clade -> clade.name
      end,
      
      generation: phylogeny.generation
    }
  end
end
