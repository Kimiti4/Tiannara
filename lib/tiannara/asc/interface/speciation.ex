defmodule Tiannara.ASC.Interface.Speciation do
  @moduledoc """
  Interface Speciation — classifies genomes into species based on structural similarity.

  Prevents evolutionary collapse into a single optimum by preserving multiple
  interface paradigms (REST, GraphQL, gRPC, Event-Driven, Hybrid).

  Similarity metrics:
  - Protocol overlap (do they use same protocols?)
  - Contract overlap (do they expose similar operations?)
  - Schema overlap (do they share data models?)
  - Event topology overlap (do they produce/consume similar events?)

  ## Example

      iex> {:ok, species_map} = Tiannara.ASC.Interface.Speciation.classify_population(population)
      iex> map_size(species_map)
      3  # REST species, GraphQL species, Hybrid species

  """

  alias Tiannara.ASC.Interface.{Genome, Population}

  @doc """
  Classify all genomes in a population into species.

  Uses protocol type as primary speciation criterion, with secondary
  clustering based on contract/schema similarity.

  ## Returns

  - `{:ok, %{species_id => [genome_ids]}}`

  """
  def classify_population(%Population{genomes: genomes}) do
    # Group genomes by dominant protocol
    protocol_groups = genomes
      |> Enum.group_by(&dominant_protocol/1)
      |> Enum.map(fn {protocol, group} ->
        species_id = "#{protocol}_species_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"
        {species_id, Enum.map(group, & &1.genome_id)}
      end)
      |> Map.new()

    {:ok, protocol_groups}
  end

  @doc """
  Calculate similarity between two genomes.

  Returns similarity score (0.0-1.0) based on multiple dimensions:
  - Protocol compatibility (40%)
  - Contract overlap (30%)
  - Schema overlap (20%)
  - Event topology overlap (10%)

  Higher scores indicate more similar genomes.
  """
  def calculate_similarity(%Genome{} = genome_a, %Genome{} = genome_b) do
    protocol_score = protocol_overlap(genome_a, genome_b)
    contract_score = contract_overlap(genome_a, genome_b)
    schema_score = schema_overlap(genome_a, genome_b)
    event_score = event_overlap(genome_a, genome_b)

    # Weighted combination
    0.4 * protocol_score + 0.3 * contract_score + 0.2 * schema_score + 0.1 * event_score
  end

  @doc """
  Check if two genomes belong to the same species.

  Uses similarity threshold to determine species membership.
  Default threshold: 0.7 (70% similarity required)
  """
  def same_species?(%Genome{} = genome_a, %Genome{} = genome_b, threshold \\ 0.7) do
    calculate_similarity(genome_a, genome_b) >= threshold
  end

  @doc """
  Find most similar genome in population to a target genome.

  Useful for selecting crossover partners within same species.
  """
  def find_most_similar(%Genome{} = target, population_genomes) do
    population_genomes
    |> Enum.reject(fn g -> g.genome_id == target.genome_id end)
    |> Enum.max_by(fn g -> calculate_similarity(target, g) end, fn -> nil end)
  end

  @doc """
  Calculate species diversity index.

  Measures how evenly distributed genomes are across species.
  Uses Shannon diversity index: H = -Σ(p_i * ln(p_i))

  Higher values indicate more balanced species distribution.
  """
  def diversity_index(species_map) do
    total_genomes = species_map
      |> Map.values()
      |> Enum.flat_map(& &1)
      |> length()

    if total_genomes == 0 do
      0.0
    else
      species_map
      |> Map.values()
      |> Enum.map(fn genome_ids -> length(genome_ids) / total_genomes end)
      |> Enum.reduce(0.0, fn proportion, acc ->
        if proportion > 0 do
          acc - proportion * :math.log(proportion)
        else
          acc
        end
      end)
    end
  end

  # Private helpers

  defp dominant_protocol(%Genome{protocols: []}), do: :unknown
  defp dominant_protocol(%Genome{protocols: protocols}) do
    protocols
    |> Enum.map(& &1.type)
    |> Enum.frequencies()
    |> Enum.max_by(fn {_type, count} -> count end)
    |> elem(0)
  end

  defp protocol_overlap(%Genome{protocols: protos_a}, %Genome{protocols: protos_b}) do
    types_a = MapSet.new(Enum.map(protos_a, & &1.type))
    types_b = MapSet.new(Enum.map(protos_b, & &1.type))

    intersection = MapSet.intersection(types_a, types_b)
    union = MapSet.union(types_a, types_b)

    if MapSet.size(union) == 0 do
      0.0
    else
      MapSet.size(intersection) / MapSet.size(union)
    end
  end

  defp contract_overlap(%Genome{contracts: contracts_a}, %Genome{contracts: contracts_b}) do
    ids_a = MapSet.new(Enum.map(contracts_a, & &1.id))
    ids_b = MapSet.new(Enum.map(contracts_b, & &1.id))

    intersection = MapSet.intersection(ids_a, ids_b)
    union = MapSet.union(ids_a, ids_b)

    if MapSet.size(union) == 0 do
      0.0
    else
      MapSet.size(intersection) / MapSet.size(union)
    end
  end

  defp schema_overlap(%Genome{schemas: schemas_a}, %Genome{schemas: schemas_b}) do
    names_a = MapSet.new(Enum.map(schemas_a, & &1.name))
    names_b = MapSet.new(Enum.map(schemas_b, & &1.name))

    intersection = MapSet.intersection(names_a, names_b)
    union = MapSet.union(names_a, names_b)

    if MapSet.size(union) == 0 do
      0.0
    else
      MapSet.size(intersection) / MapSet.size(union)
    end
  end

  defp event_overlap(%Genome{events: events_a}, %Genome{events: events_b}) do
    ids_a = MapSet.new(Enum.map(events_a, & &1.id))
    ids_b = MapSet.new(Enum.map(events_b, & &1.id))

    intersection = MapSet.intersection(ids_a, ids_b)
    union = MapSet.union(ids_a, ids_b)

    if MapSet.size(union) == 0 do
      0.0
    else
      MapSet.size(intersection) / MapSet.size(union)
    end
  end
end
