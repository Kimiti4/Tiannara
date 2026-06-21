defmodule Tiannara.ASC.Interface.Mutations.ProtocolMutations do
  @moduledoc """
  Protocol Mutation Operators — evolve communication protocols through semantic transformations.

  Implements 5 mutation types:
  - Protocol switch (REST → GraphQL, etc.)
  - Capability addition
  - Capability removal
  - Hybrid protocol formation
  - Protocol merge

  Each mutation returns a Mutation record with full provenance for law discovery.
  """

  alias Tiannara.ASC.Interface.{Protocol, Mutation}
  alias Tiannara.ASC.Interface.Fitness

  @doc """
  Switch protocol type (e.g., REST → GraphQL).

  Migrates capabilities to the new protocol type.

  ## Returns

  - {new_genome, mutation_record}

  """
  def switch_protocol(genome, protocol_id, new_type) do
    case Enum.find_index(genome.protocols, fn p -> p.id == protocol_id end) do
      nil ->
        {:error, :not_found}

      index ->
        old_protocol = Enum.at(genome.protocols, index)
        new_protocol = Protocol.switch_type(old_protocol, new_type)

        new_protocols = List.replace_at(genome.protocols, index, new_protocol)

        fitness_before = Fitness.calculate(genome)
        new_genome = %{genome | protocols: new_protocols}
        fitness_after = Fitness.calculate(new_genome)

        mutation = Mutation.new(
          :switch_protocol,
          protocol_id,
          :protocol,
          old_protocol,
          new_protocol,
          "Switched protocol from #{old_protocol.type} to #{new_type}",
          fitness_before,
          fitness_after,
          genome.generation
        )

        {new_genome, mutation}
    end
  end

  @doc """
  Add a capability to a protocol.

  Example: Add :pagination to REST protocol.

  ## Returns

  - {new_genome, mutation_record} or {:error, :not_found}

  """
  def add_capability(genome, protocol_id, capability) do
    case Enum.find_index(genome.protocols, fn p -> p.id == protocol_id end) do
      nil ->
        {:error, :not_found}

      index ->
        old_protocol = Enum.at(genome.protocols, index)
        new_protocol = Protocol.add_capability(old_protocol, capability)

        new_protocols = List.replace_at(genome.protocols, index, new_protocol)

        fitness_before = Fitness.calculate(genome)
        new_genome = %{genome | protocols: new_protocols}
        fitness_after = Fitness.calculate(new_genome)

        mutation = Mutation.new(
          :add_capability,
          protocol_id,
          :protocol,
          old_protocol,
          new_protocol,
          "Added capability: #{capability}",
          fitness_before,
          fitness_after,
          genome.generation
        )

        {new_genome, mutation}
    end
  end

  @doc """
  Remove a capability from a protocol.

  Example: Remove :cors from REST protocol.

  ## Returns

  - {new_genome, mutation_record} or {:error, :not_found}

  """
  def remove_capability(genome, protocol_id, capability) do
    case Enum.find_index(genome.protocols, fn p -> p.id == protocol_id end) do
      nil ->
        {:error, :not_found}

      index ->
        old_protocol = Enum.at(genome.protocols, index)
        new_protocol = Protocol.remove_capability(old_protocol, capability)

        new_protocols = List.replace_at(genome.protocols, index, new_protocol)

        fitness_before = Fitness.calculate(genome)
        new_genome = %{genome | protocols: new_protocols}
        fitness_after = Fitness.calculate(new_genome)

        mutation = Mutation.new(
          :remove_capability,
          protocol_id,
          :protocol,
          old_protocol,
          new_protocol,
          "Removed capability: #{capability}",
          fitness_before,
          fitness_after,
          genome.generation
        )

        {new_genome, mutation}
    end
  end

  @doc """
  Create a hybrid protocol by merging two different protocol types.

  Example: REST + GraphQL → hybrid protocol supporting both.

  ## Returns

  - {new_genome, mutation_record}

  """
  def create_hybrid_protocol(genome, protocol_id1, protocol_id2) do
    protocol1 = Enum.find(genome.protocols, fn p -> p.id == protocol_id1 end)
    protocol2 = Enum.find(genome.protocols, fn p -> p.id == protocol_id2 end)

    if protocol1 && protocol2 do
      hybrid = Protocol.merge(protocol1, protocol2)

      # Remove both originals and add hybrid
      remaining = Enum.reject(genome.protocols, fn p ->
        p.id == protocol_id1 or p.id == protocol_id2
      end)
      new_protocols = remaining ++ [hybrid]

      fitness_before = Fitness.calculate(genome)
      new_genome = %{genome | protocols: new_protocols}
      fitness_after = Fitness.calculate(new_genome)

      mutation = Mutation.new(
        :create_hybrid_protocol,
        "#{protocol_id1}_#{protocol_id2}",
        :protocol,
        [protocol1, protocol2],
        hybrid,
        "Created hybrid protocol: #{protocol1.type} + #{protocol2.type}",
        fitness_before,
        fitness_after,
        genome.generation
      )

      {new_genome, mutation}
    else
      {:error, :not_found}
    end
  end

  @doc """
  Merge two protocols of the same type.

  Combines capabilities from both protocols.

  ## Returns

  - {new_genome, mutation_record} or {:error, :not_found}

  """
  def merge_protocols(genome, protocol_id1, protocol_id2) do
    protocol1 = Enum.find(genome.protocols, fn p -> p.id == protocol_id1 end)
    protocol2 = Enum.find(genome.protocols, fn p -> p.id == protocol_id2 end)

    if protocol1 && protocol2 do
      merged = Protocol.merge(protocol1, protocol2)

      # Remove both originals and add merged
      remaining = Enum.reject(genome.protocols, fn p ->
        p.id == protocol_id1 or p.id == protocol_id2
      end)
      new_protocols = remaining ++ [merged]

      fitness_before = Fitness.calculate(genome)
      new_genome = %{genome | protocols: new_protocols}
      fitness_after = Fitness.calculate(new_genome)

      mutation = Mutation.new(
        :merge_protocol,
        "#{protocol_id1}_#{protocol_id2}",
        :protocol,
        [protocol1, protocol2],
        merged,
        "Merged #{protocol1.type} protocols",
        fitness_before,
        fitness_after,
        genome.generation
      )

      {new_genome, mutation}
    else
      {:error, :not_found}
    end
  end

  @doc """
  Add a new protocol to the genome.

  Creates a protocol based on recommended type for use case.

  ## Returns

  - {new_genome, mutation_record}

  """
  def add_protocol(genome, use_case) do
    new_protocol = Protocol.recommend(use_case)
    new_protocols = genome.protocols ++ [new_protocol]

    fitness_before = Fitness.calculate(genome)
    new_genome = %{genome | protocols: new_protocols}
    fitness_after = Fitness.calculate(new_genome)

    mutation = Mutation.new(
      :add_protocol,
      new_protocol.id,
      :protocol,
      nil,
      new_protocol,
      "Added protocol for use case: #{use_case}",
      fitness_before,
      fitness_after,
      genome.generation
    )

    {new_genome, mutation}
  end

  @doc """
  Remove a protocol from the genome.

  Removes the specified protocol by ID.

  ## Returns

  - {new_genome, mutation_record} or {:error, :not_found}

  """
  def remove_protocol(genome, protocol_id) do
    case Enum.find_index(genome.protocols, fn p -> p.id == protocol_id end) do
      nil ->
        {:error, :not_found}

      index ->
        removed_protocol = Enum.at(genome.protocols, index)
        new_protocols = List.delete_at(genome.protocols, index)

        fitness_before = Fitness.calculate(genome)
        new_genome = %{genome | protocols: new_protocols}
        fitness_after = Fitness.calculate(new_genome)

        mutation = Mutation.new(
          :remove_protocol,
          protocol_id,
          :protocol,
          removed_protocol,
          nil,
          "Removed protocol #{protocol_id}",
          fitness_before,
          fitness_after,
          genome.generation
        )

        {new_genome, mutation}
    end
  end
end
