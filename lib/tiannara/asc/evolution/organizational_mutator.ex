defmodule Tiannara.ASC.Evolution.OrganizationalMutator do
  alias Tiannara.ASC.Evolution.CivilizationGenome

  @doc """
  Inserts a new specialized agent role into the Guild pipeline.
  """
  def speciate_role(%CivilizationGenome{} = genome, new_role, opts) do
    before_role = Keyword.get(opts, :before, :coder)
    
    new_roles = Enum.flat_map(genome.guild_roles, fn role ->
      if role == before_role do
        [new_role, role]
      else
        [role]
      end
    end)
    
    %CivilizationGenome{genome | 
      guild_roles: new_roles, 
      generation: genome.generation + 1,
      id: "org_gen_#{genome.generation + 1}"
    }
  end

  @doc """
  Mutates the Constitution's Value Formula weights.
  """
  def mutate_governance(%CivilizationGenome{} = genome, metric, delta) do
    new_weights = Map.update!(genome.value_weights, metric, fn val -> val + delta end)
    
    %CivilizationGenome{genome | 
      value_weights: new_weights, 
      generation: genome.generation + 1,
      id: "org_gen_#{genome.generation + 1}"
    }
  end

  def drift(%CivilizationGenome{} = genome) do
    # Random micro-adjustments to prevent local optima
    new_tolerance = max(1, genome.loopback_tolerance + Enum.random([-1, 0, 1]))
    %CivilizationGenome{genome | loopback_tolerance: new_tolerance, generation: genome.generation + 1}
  end
end
