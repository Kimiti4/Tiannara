defmodule Tiannara.ASC.Interface.Mutations.ContractMutations do
  @moduledoc """
  Contract Mutation Operators — evolve interface contracts through semantic transformations.

  Implements 6 mutation types:
  - Add contract
  - Remove contract
  - Split contract (by field or parameter)
  - Merge contracts
  - Version bump
  - Constraint modification (strengthen/relax)

  Each mutation returns a Mutation record with full provenance for law discovery.
  """

  alias Tiannara.ASC.Interface.{Contract, Mutation}
  alias Tiannara.ASC.Interface.Fitness

  @doc """
  Add a new contract to the genome.

  Creates a contract from capability description and adds it to the genome.

  ## Returns

  - {new_genome, mutation_record}

  """
  def add_contract(genome, capability, subject) do
    new_contract = Contract.from_capability(capability, subject)
    new_contracts = genome.contracts ++ [new_contract]

    fitness_before = Fitness.calculate(genome)
    new_genome = %{genome | contracts: new_contracts}
    fitness_after = Fitness.calculate(new_genome)

    mutation = Mutation.new(
      :add_contract,
      new_contract.id,
      :contract,
      nil,
      new_contract,
      fitness_before: fitness_before,
      fitness_after: fitness_after,
      rationale: "Added contract for #{subject}:#{capability}"
    )

    # Register in Knowledge Archive
    Mutation.register(mutation)

    {new_genome, mutation}
  end

  @doc """
  Remove a contract from the genome.

  Only removes if contract exists. Returns error if contract not found.

  ## Returns

  - {:ok, new_genome, mutation_record}
  - {:error, :not_found}

  """
  def remove_contract(genome, contract_id) do
    case Enum.find_index(genome.contracts, fn c -> c.id == contract_id end) do
      nil ->
        {:error, :not_found}

      index ->
        removed_contract = Enum.at(genome.contracts, index)
        new_contracts = List.delete_at(genome.contracts, index)

        fitness_before = Fitness.calculate(genome)
        new_genome = %{genome | contracts: new_contracts}
        fitness_after = Fitness.calculate(new_genome)

        mutation = Mutation.new(
          :remove_contract,
          contract_id,
          :contract,
          removed_contract,
          nil,
          fitness_before: fitness_before,
          fitness_after: fitness_after,
          rationale: "Removed contract #{contract_id}"
        )

        Mutation.register(mutation)

        {:ok, new_genome, mutation}
    end
  end

  @doc """
  Split a contract into multiple contracts by field.

  Example: `user.create` with fields [email, name, password] →
           [user.create.email, user.create.name, user.create.password]

  This reduces contract complexity and increases modularity.

  ## Returns

  - {:ok, new_genome, mutation_record}
  - {:error, :not_found}

  """
  def split_contract(genome, contract_id, split_by \\ :field) do
    case Enum.find_index(genome.contracts, fn c -> c.id == contract_id end) do
      nil ->
        {:error, :not_found}

      index ->
        original_contract = Enum.at(genome.contracts, index)

        # Generate split contracts based on strategy
        split_contracts = case split_by do
          :field ->
            split_by_field(original_contract)

          :parameter ->
            split_by_parameter(original_contract)
        end

        # Replace original with split contracts
        remaining = List.delete_at(genome.contracts, index)
        new_contracts = remaining ++ split_contracts

        fitness_before = Fitness.calculate(genome)
        new_genome = %{genome | contracts: new_contracts}
        fitness_after = Fitness.calculate(new_genome)

        mutation = Mutation.new(
          :split_contract,
          contract_id,
          :contract,
          original_contract,
          split_contracts,
          fitness_before: fitness_before,
          fitness_after: fitness_after,
          rationale: "Split contract #{contract_id} by #{split_by} to reduce complexity"
        )

        Mutation.register(mutation)

        {:ok, new_genome, mutation}
    end
  end

  @doc """
  Merge two contracts into a single contract.

  Combines inputs/outputs and constraints from both contracts.

  ## Returns

  - {:ok, new_genome, mutation_record}
  - {:error, :not_found}

  """
  def merge_contract(genome, contract_id_1, contract_id_2) do
    idx1 = Enum.find_index(genome.contracts, fn c -> c.id == contract_id_1 end)
    idx2 = Enum.find_index(genome.contracts, fn c -> c.id == contract_id_2 end)

    cond do
      is_nil(idx1) or is_nil(idx2) ->
        {:error, :not_found}

      true ->
        contract1 = Enum.at(genome.contracts, idx1)
        contract2 = Enum.at(genome.contracts, idx2)

        # Create merged contract
        merged = %Contract{
          id: "#{contract1.id}_#{contract2.id}",
          name: "#{contract1.name} + #{contract2.name}",
          version: "v1",
          operation: contract1.operation,
          inputs: contract1.inputs ++ contract2.inputs,
          outputs: contract1.outputs ++ contract2.outputs,
          constraints: contract1.constraints ++ contract2.constraints,
          compatibility_mode: :breaking
        }

        # Remove originals and add merged
        remaining = genome.contracts
          |> List.delete_at(max(idx1, idx2))
          |> List.delete_at(min(idx1, idx2))

        new_contracts = remaining ++ [merged]

        fitness_before = Fitness.calculate(genome)
        new_genome = %{genome | contracts: new_contracts}
        fitness_after = Fitness.calculate(new_genome)

        mutation = Mutation.new(
          :merge_contract,
          "#{contract_id_1},#{contract_id_2}",
          :contract,
          [contract1, contract2],
          merged,
          fitness_before: fitness_before,
          fitness_after: fitness_after,
          rationale: "Merged contracts #{contract_id_1} and #{contract_id_2}"
        )

        Mutation.register(mutation)

        {:ok, new_genome, mutation}
    end
  end

  @doc """
  Bump contract version (v1 → v2, etc.).

  Supports backward/forward/breaking compatibility modes.

  ## Returns

  - {:ok, new_genome, mutation_record}
  - {:error, :not_found}

  """
  def version_contract(genome, contract_id, compatibility_mode \\ :backward) do
    case Enum.find_index(genome.contracts, fn c -> c.id == contract_id end) do
      nil ->
        {:error, :not_found}

      index ->
        old_contract = Enum.at(genome.contracts, index)

        # Parse current version and increment
        current_version = String.replace_prefix(old_contract.version, "v", "")
        {version_num, _} = Integer.parse(current_version)
        new_version = "v#{version_num + 1}"

        new_contract = %{old_contract |
          version: new_version,
          compatibility_mode: compatibility_mode
        }

        new_contracts = List.replace_at(genome.contracts, index, new_contract)

        fitness_before = Fitness.calculate(genome)
        new_genome = %{genome | contracts: new_contracts}
        fitness_after = Fitness.calculate(new_genome)

        mutation = Mutation.new(
          :version_contract,
          contract_id,
          :contract,
          old_contract,
          new_contract,
          fitness_before: fitness_before,
          fitness_after: fitness_after,
          rationale: "Bumped version to #{new_version} with #{compatibility_mode} compatibility"
        )

        Mutation.register(mutation)

        {:ok, new_genome, mutation}
    end
  end

  @doc """
  Strengthen or relax contract constraints.

  Strengthens validation rules, rate limits, or auth requirements.

  ## Returns

  - {:ok, new_genome, mutation_record}
  - {:error, :not_found}

  """
  def constraint_mutation(genome, contract_id, action \\ :strengthen) do
    case Enum.find_index(genome.contracts, fn c -> c.id == contract_id end) do
      nil ->
        {:error, :not_found}

      index ->
        old_contract = Enum.at(genome.contracts, index)

        # Modify constraints based on action
        new_constraints = case action do
          :strengthen ->
            strengthen_constraints(old_contract.constraints)

          :relax ->
            relax_constraints(old_contract.constraints)
        end

        new_contract = %{old_contract | constraints: new_constraints}
        new_contracts = List.replace_at(genome.contracts, index, new_contract)

        fitness_before = Fitness.calculate(genome)
        new_genome = %{genome | contracts: new_contracts}
        fitness_after = Fitness.calculate(new_genome)

        mutation = Mutation.new(
          :constraint_mutation,
          contract_id,
          :contract,
          old_contract,
          new_contract,
          fitness_before: fitness_before,
          fitness_after: fitness_after,
          rationale: "#{action} constraints on contract #{contract_id}"
        )

        Mutation.register(mutation)

        {:ok, new_genome, mutation}
    end
  end

  # Private helpers

  defp split_by_field(contract) do
    # Split contract into one contract per input field
    Enum.map(contract.inputs, fn input ->
      %Contract{
        id: "#{contract.id}.#{input.name}",
        name: "#{contract.name} - #{input.name}",
        version: contract.version,
        operation: contract.operation,
        inputs: [input],
        outputs: contract.outputs,
        constraints: contract.constraints,
        compatibility_mode: contract.compatibility_mode
      }
    end)
  end

  defp split_by_parameter(contract) do
    # For now, same as split_by_field (can be extended later)
    split_by_field(contract)
  end

  defp strengthen_constraints(constraints) do
    # Add stricter validation rules
    constraints ++ [%{type: :rate_limit, max_requests: 100, window: "1m"}]
  end

  defp relax_constraints(constraints) do
    # Remove rate limiting if present
    Enum.reject(constraints, fn c -> Map.get(c, :type) == :rate_limit end)
  end
end
