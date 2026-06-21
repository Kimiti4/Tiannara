defmodule Tiannara.ASC.Interface.Crossover do
  @moduledoc """
  Interface Crossover — combines two parent genomes to produce offspring.

  Uses semantic crossover rather than random field swapping:
  - Contracts are merged by operation semantics
  - Events are combined by producer/consumer topology
  - Protocols form hybrid topologies
  - Schemas are unified by type compatibility

  This preserves meaningful interface patterns while enabling innovation.

  ## Example

      iex> child = Tiannara.ASC.Interface.Crossover.crossover(parent_a, parent_b)
      iex> length(child.contracts) >= length(parent_a.contracts)
      true

  """

  alias Tiannara.ASC.Interface.{Genome, Contract, Event, Protocol}

  @doc """
  Perform semantic crossover between two parent genomes.

  Combines contracts, events, protocols, and schemas from both parents
  using domain-aware merging strategies.

  ## Returns

  - New child genome with combined features

  """
  def crossover(%Genome{} = parent_a, %Genome{} = parent_b) do
    # Merge contracts (union of operations)
    merged_contracts = merge_contracts(parent_a.contracts, parent_b.contracts)

    # Merge events (combine producers/consumers)
    merged_events = merge_events(parent_a.events, parent_b.events)

    # Merge protocols (create hybrid if different types)
    merged_protocols = merge_protocols(parent_a.protocols, parent_b.protocols)

    # Merge schemas (unify by name)
    merged_schemas = merge_schemas(parent_a.schemas, parent_b.schemas)

    # Merge interfaces (BEAM message contracts)
    merged_interfaces = Enum.uniq_by(parent_a.interfaces ++ parent_b.interfaces, & &1.id)

    # Merge auth models (union)
    merged_auth_models = Enum.uniq_by(parent_a.auth_models ++ parent_b.auth_models, & &1.name)

    # Select versioning strategy (prefer more explicit)
    versioning_strategy = select_versioning_strategy(
      parent_a.versioning_strategy,
      parent_b.versioning_strategy
    )

    # Select compatibility mode (prefer safer)
    compatibility_mode = select_compatibility_mode(
      parent_a.compatibility_mode,
      parent_b.compatibility_mode
    )

    # Merge deployment units
    merged_deployment_units = Enum.uniq_by(
      parent_a.deployment_units ++ parent_b.deployment_units,
      & &1.name
    )

    # Merge scaling policies
    merged_scaling_policies = Enum.uniq_by(
      parent_a.scaling_policies ++ parent_b.scaling_policies,
      & &1.unit_name
    )

    # Merge network topology (use more detailed)
    network_topology = select_network_topology(
      parent_a.network_topology,
      parent_b.network_topology
    )

    # Increment generation
    new_generation = max(parent_a.generation, parent_b.generation) + 1

    %Genome{
      genome_id: generate_id(),
      generation: new_generation,
      fitness: 0.0,  # Will be calculated by Fitness module

      # Merged features
      contracts: merged_contracts,
      events: merged_events,
      protocols: merged_protocols,
      schemas: merged_schemas,
      interfaces: merged_interfaces,
      auth_models: merged_auth_models,
      versioning_strategy: versioning_strategy,
      compatibility_mode: compatibility_mode,
      deployment_units: merged_deployment_units,
      scaling_policies: merged_scaling_policies,
      network_topology: network_topology,

      # Metadata
      blueprints_used: Enum.uniq(parent_a.blueprints_used ++ parent_b.blueprints_used),
      policies_applied: Enum.uniq(parent_a.policies_applied ++ parent_b.policies_applied),
      deployment_target: parent_a.deployment_target
    }
  end

  @doc """
  Merge contracts from two parents.

  Strategy: Union of all contracts, avoiding duplicates by ID.
  If same contract exists in both parents, keep the one with more fields.
  """
  def merge_contracts(contracts_a, contracts_b) do
    # Index contracts by ID
    map_a = Map.new(contracts_a, fn c -> {c.id, c} end)
    map_b = Map.new(contracts_b, fn c -> {c.id, c} end)

    # Get all unique IDs
    all_ids = Map.keys(map_a) ++ Map.keys(map_b) |> Enum.uniq()

    # For each ID, select the better contract
    Enum.map(all_ids, fn id ->
      case {Map.get(map_a, id), Map.get(map_b, id)} do
        {nil, contract_b} -> contract_b
        {contract_a, nil} -> contract_a
        {contract_a, contract_b} ->
          # Keep contract with more input/output fields
          size_a = length(contract_a.inputs) + length(contract_a.outputs)
          size_b = length(contract_b.inputs) + length(contract_b.outputs)
          if size_a >= size_b, do: contract_a, else: contract_b
      end
    end)
  end

  @doc """
  Merge events from two parents.

  Strategy: Union of all events, combining consumers for duplicate event IDs.
  """
  def merge_events(events_a, events_b) do
    # Index events by ID
    map_a = Map.new(events_a, fn e -> {e.id, e} end)
    map_b = Map.new(events_b, fn e -> {e.id, e} end)

    # Get all unique IDs
    all_ids = Map.keys(map_a) ++ Map.keys(map_b) |> Enum.uniq()

    # For each ID, merge consumers
    Enum.map(all_ids, fn id ->
      case {Map.get(map_a, id), Map.get(map_b, id)} do
        {nil, event_b} -> event_b
        {event_a, nil} -> event_a
        {event_a, event_b} ->
          # Merge consumers and use stronger delivery guarantee
          merged_consumers = Enum.uniq(event_a.consumers ++ event_b.consumers)
          stronger_guarantee = select_stronger_guarantee(
            event_a.delivery_guarantee,
            event_b.delivery_guarantee
          )

          %{event_a |
            consumers: merged_consumers,
            delivery_guarantee: stronger_guarantee
          }
      end
    end)
  end

  @doc """
  Merge protocols from two parents.

  Strategy: If parents have different protocol types, create hybrid protocol.
  Otherwise, union of capabilities.
  """
  def merge_protocols(protocols_a, protocols_b) do
    # If only one protocol each and they're different, create hybrid
    case {protocols_a, protocols_b} do
      {[proto_a], [proto_b]} when proto_a.type != proto_b.type ->
        # Create hybrid protocol
        hybrid = Protocol.hybrid(proto_a.type, proto_b.type)
        [hybrid]

      _ ->
        # Union of all protocols
        Enum.uniq_by(protocols_a ++ protocols_b, & &1.id)
    end
  end

  @doc """
  Merge schemas from two parents.

  Strategy: Union by schema name, keeping more detailed version.
  """
  def merge_schemas(schemas_a, schemas_b) do
    # Index schemas by name
    map_a = Map.new(schemas_a, fn s -> {s.name, s} end)
    map_b = Map.new(schemas_b, fn s -> {s.name, s} end)

    # Get all unique names
    all_names = Map.keys(map_a) ++ Map.keys(map_b) |> Enum.uniq()

    # For each name, select the more detailed schema
    Enum.map(all_names, fn name ->
      case {Map.get(map_a, name), Map.get(map_b, name)} do
        {nil, schema_b} -> schema_b
        {schema_a, nil} -> schema_a
        {schema_a, schema_b} ->
          # Keep schema with more properties
          props_a = map_size(schema_a.properties || %{})
          props_b = map_size(schema_b.properties || %{})
          if props_a >= props_b, do: schema_a, else: schema_b
      end
    end)
  end

  # Private helpers

  defp generate_id do
    "genome_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end

  defp select_versioning_strategy(strategy_a, strategy_b) do
    # Prefer more explicit versioning: url_path > header > none
    priority = %{url_path: 3, header: 2, none: 1}
    if priority[strategy_a] >= priority[strategy_b], do: strategy_a, else: strategy_b
  end

  defp select_compatibility_mode(mode_a, mode_b) do
    # Prefer safer compatibility: backward > forward > breaking
    priority = %{backward: 3, forward: 2, breaking: 1}
    if priority[mode_a] >= priority[mode_b], do: mode_a, else: mode_b
  end

  defp select_network_topology(topo_a, topo_b) do
    # Use non-nil topology, or default to simple
    case {topo_a, topo_b} do
      {nil, nil} -> "simple"
      {nil, topo} -> topo
      {topo, nil} -> topo
      {topo_a, _topo_b} -> topo_a  # Prefer first parent's topology
    end
  end

  defp select_stronger_guarantee(g1, g2) do
    # Priority: exactly_once > at_least_once > at_most_once
    priority = %{
      exactly_once: 3,
      at_least_once: 2,
      at_most_once: 1
    }

    if priority[g1] >= priority[g2], do: g1, else: g2
  end
end
