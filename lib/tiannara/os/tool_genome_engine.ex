defmodule TiannaraOS.ToolGenomeEngine do
  @moduledoc """
  Evolves tool specifications (ToolGenomes) through mutation, parent/lineage logging, and selection.
  """

  alias TiannaraOS.ToolGenome

  @doc """
  Generates a new ToolGenome specification.
  """
  @spec generate_genome(atom(), atom(), atom(), atom(), map(), keyword()) :: ToolGenome.t()
  def generate_genome(id, capability, capability_type, execution_backend, execution_spec, opts \\ []) do
    security_profile = opts[:security_profile] || %{read_sandbox: true}
    provenance = opts[:provenance] || ["initial_generation"]
    version = opts[:version] || "0.1.0"

    %ToolGenome{
      id: id,
      capability: capability,
      capability_type: capability_type,
      execution_backend: execution_backend,
      execution_spec: execution_spec,
      security_profile: security_profile,
      parent_genomes: [],
      provenance: provenance,
      version: version,
      fitness: 0.5
    }
  end

  @doc """
  Mutates an existing ToolGenome, tracking parent lineage and updating provenance.
  """
  @spec mutate_spec(ToolGenome.t(), map(), String.t()) :: ToolGenome.t()
  def mutate_spec(%ToolGenome{} = genome, spec_updates, provenance_msg) do
    # Tweak execution spec
    mutated_spec = Map.merge(genome.execution_spec, spec_updates)

    # Increment version (e.g. minor increment)
    [major, minor, patch] = 
      genome.version 
      |> String.split(".") 
      |> Enum.map(&String.to_integer/1)

    new_version = "#{major}.#{minor + 1}.#{patch}"
    new_id = String.to_atom("#{genome.capability}_mut_#{System.unique_integer([:positive])}")

    %ToolGenome{
      genome |
      id: new_id,
      execution_spec: mutated_spec,
      parent_genomes: [genome.id | genome.parent_genomes],
      provenance: genome.provenance ++ [provenance_msg],
      version: new_version,
      fitness: 0.5 # Reset fitness for the new mutant
    }
  end

  @doc """
  Selects the highest fitness genome from a list or map of ToolGenomes.
  """
  @spec select_best([ToolGenome.t()] | %{atom() => ToolGenome.t()}) :: ToolGenome.t() | nil
  def select_best(genomes) when is_map(genomes) do
    genomes
    |> Map.values()
    |> select_best()
  end

  def select_best([]), do: nil
  def select_best(genomes) when is_list(genomes) do
    Enum.max_by(genomes, & &1.fitness, fn -> nil end)
  end
end
