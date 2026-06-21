defmodule Tiannara.ASC.Interface.Transfer do
  @moduledoc """
  Interface Knowledge Transfer — enables cross-species knowledge sharing.

  When one species discovers a beneficial pattern (e.g., JWT authentication),
  other species can adopt it, enabling Tiannara to learn universal principles
  rather than local optimizations.

  ## Example

      iex> {:ok, transfer} = Tiannara.ASC.Interface.Transfer.apply(
      ...>   source_genome,
      ...>   target_genome,
      ...>   :auth_pattern,
      ...>   "JWT authentication"
      ...> )
      iex> transfer.success?
      true

  This enables law discovery like:
  > "Authentication patterns transfer successfully between REST and GraphQL ecosystems"

  """

  alias Tiannara.ASC.Interface.{Genome, Mutation}
  alias Tiannara.ASC.Interface.Fitness

  @derive Jason.Encoder
  defstruct [
    # Identity
    id: nil,                    # Unique transfer identifier
    type: nil,                  # Transfer type (:auth_pattern, :schema_reuse, etc.)

    # Source/Target
    source_genome_id: nil,      # Genome that discovered the pattern
    source_species_id: nil,     # Species of source genome
    target_genome_id: nil,      # Genome receiving the pattern
    target_species_id: nil,     # Species of target genome

    # Knowledge transferred
    pattern_name: nil,          # Name of transferred pattern
    pattern_data: nil,          # Actual pattern data (auth model, schema, etc.)

    # Outcome
    fitness_before: 0.0,        # Target fitness before transfer
    fitness_after: 0.0,         # Target fitness after transfer
    fitness_delta: 0.0,         # Change in fitness
    success?: false,            # Did transfer improve fitness?

    # Metadata
    timestamp: nil,             # When transfer occurred
    generation: 0               # Evolution generation number
  ]

  @typedoc "Knowledge transfer record"
  @type t :: %__MODULE__{
          id: String.t() | nil,
          type: atom() | nil,
          source_genome_id: String.t() | nil,
          source_species_id: String.t() | nil,
          target_genome_id: String.t() | nil,
          target_species_id: String.t() | nil,
          pattern_name: String.t() | nil,
          pattern_data: any(),
          fitness_before: float(),
          fitness_after: float(),
          fitness_delta: float(),
          success?: boolean(),
          timestamp: DateTime.t() | nil,
          generation: non_neg_integer()
        }

  @doc """
  Apply knowledge transfer from source genome to target genome.

  Copies beneficial patterns (auth models, schemas, protocols) from source
  to target, then evaluates fitness impact.

  ## Returns

  - `{:ok, new_genome, transfer_record}`

  """
  def apply(%Genome{} = source, %Genome{} = target, transfer_type, pattern_name) do
    fitness_before = Fitness.calculate(target)

    # Apply transfer based on type
    new_genome = case transfer_type do
      :auth_pattern ->
        transfer_auth_pattern(source, target)

      :schema_reuse ->
        transfer_schema(source, target)

      :protocol_adoption ->
        transfer_protocol(source, target)

      :event_topology ->
        transfer_event_topology(source, target)

      _ ->
        target
    end

    fitness_after = Fitness.calculate(new_genome)
    fitness_delta = fitness_after - fitness_before

    transfer = %__MODULE__{
      id: generate_id(),
      type: transfer_type,
      source_genome_id: source.genome_id,
      source_species_id: source.deployment_target,  # Placeholder for species ID
      target_genome_id: target.genome_id,
      target_species_id: target.deployment_target,  # Placeholder for species ID
      pattern_name: pattern_name,
      pattern_data: extract_pattern_data(transfer_type, source),
      fitness_before: fitness_before,
      fitness_after: fitness_after,
      fitness_delta: fitness_delta,
      success?: fitness_delta > 0,
      timestamp: DateTime.utc_now(),
      generation: target.generation
    }

    # Register in Knowledge Archive
    register_transfer(transfer)

    {:ok, new_genome, transfer}
  end

  @doc """
  Calculate transfer success rate across multiple transfers.

  Returns fraction of transfers that improved fitness.
  """
  def success_rate(transfers) when length(transfers) == 0 do
    0.0
  end

  def success_rate(transfers) do
    successful = Enum.count(transfers, & &1.success?)
    successful / length(transfers)
  end

  @doc """
  Extract transfer patterns by type.

  Groups transfers by type and calculates average fitness delta per type.
  Useful for identifying which patterns transfer most successfully.
  """
  def patterns_by_type(transfers) do
    transfers
    |> Enum.group_by(& &1.type)
    |> Enum.map(fn {type, type_transfers} ->
      avg_delta = Enum.sum_by(type_transfers, & &1.fitness_delta) / length(type_transfers)
      success_rate = success_rate(type_transfers)

      %{
        type: type,
        count: length(type_transfers),
        avg_fitness_delta: Float.round(avg_delta, 3),
        success_rate: Float.round(success_rate, 3)
      }
    end)
  end

  # Private helpers

  defp generate_id do
    "transfer_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end

  defp transfer_auth_pattern(%Genome{} = source, %Genome{} = target) do
    # Copy auth models from source to target
    merged_auth = Enum.uniq_by(source.auth_models ++ target.auth_models, & &1.name)
    %{target | auth_models: merged_auth}
  end

  defp transfer_schema(%Genome{} = source, %Genome{} = target) do
    # Copy schemas from source to target
    merged_schemas = Enum.uniq_by(source.schemas ++ target.schemas, & &1.name)
    %{target | schemas: merged_schemas}
  end

  defp transfer_protocol(%Genome{} = source, %Genome{} = target) do
    # Add source protocols to target if not already present
    existing_types = MapSet.new(Enum.map(target.protocols, & &1.type))
    new_protocols = Enum.reject(source.protocols, &MapSet.member?(existing_types, &1.type))
    %{target | protocols: target.protocols ++ new_protocols}
  end

  defp transfer_event_topology(%Genome{} = source, %Genome{} = target) do
    # Merge event topologies
    merged_events = Enum.uniq_by(source.events ++ target.events, & &1.id)
    %{target | events: merged_events}
  end

  defp extract_pattern_data(:auth_pattern, %Genome{auth_models: auth}), do: auth
  defp extract_pattern_data(:schema_reuse, %Genome{schemas: schemas}), do: schemas
  defp extract_pattern_data(:protocol_adoption, %Genome{protocols: protocols}), do: protocols
  defp extract_pattern_data(:event_topology, %Genome{events: events}), do: events
  defp extract_pattern_data(_, _), do: nil

  defp register_transfer(%__MODULE__{} = transfer) do
    require Logger

    Logger.info(
      "[Interface.Transfer] #{transfer.type}: #{transfer.pattern_name} " <>
      "(source: #{transfer.source_genome_id}, target: #{transfer.target_genome_id}, " <>
      "fitness_delta: #{transfer.fitness_delta})"
    )

    :ok
  end
end
