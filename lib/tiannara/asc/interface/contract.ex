defmodule Tiannara.ASC.Interface.Contract do
  @moduledoc """
  Interface Contract — represents a single interface operation (REST endpoint, GraphQL query, gRPC method).

  Contracts are the fundamental unit of interface evolution. They define:
  - Operation semantics (what the interface does)
  - Input/output schemas (data contracts)
  - Version compatibility (backward/forward/breaking)
  - Constraints (validation rules, rate limits, auth requirements)

  Contracts evolve through mutations like split, merge, version bump, constraint strengthening.

  ## Example

      iex> contract = %Tiannara.ASC.Interface.Contract{
      ...>   id: "create_user",
      ...>   name: "Create User",
      ...>   version: "v1",
      ...>   operation: :post,
      ...>   inputs: [%{name: "email", type: "string", required: true}],
      ...>   outputs: [%{name: "user_id", type: "string"}],
      ...>   constraints: [%{type: :rate_limit, value: "100/min"}],
      ...>   compatibility_mode: :backward
      ...> }

  """

  @derive Jason.Encoder
  defstruct [
    # Identity
    id: nil,
    name: nil,
    version: "v1",

    # Operation semantics
    operation: nil,  # :get, :post, :put, :delete, :patch, :query, :mutation, :rpc
    path: nil,       # REST path or GraphQL field name

    # Data contracts
    inputs: [],      # List of input parameter schemas
    outputs: [],     # List of output result schemas

    # Constraints
    constraints: [], # Validation rules, rate limits, auth requirements

    # Evolution metadata
    compatibility_mode: :backward,  # :backward, :forward, :breaking
    created_at: nil,
    modified_at: nil,
    parent_contract_id: nil  # For tracking contract lineage during evolution
  ]

  @typedoc "Interface contract structure"
  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t() | nil,
          version: String.t(),
          operation: atom() | nil,
          path: String.t() | nil,
          inputs: [map()],
          outputs: [map()],
          constraints: [map()],
          compatibility_mode: atom(),
          created_at: DateTime.t() | nil,
          modified_at: DateTime.t() | nil,
          parent_contract_id: String.t() | nil
        }

  @doc """
  Create a new contract from capability description.

  Infers operation type and path from the capability name and subject.

  ## Parameters

  - `capability` — Capability struct from ImplementationPlan
  - `subject` — Resource subject (e.g., "User", "Payment")

  ## Examples

      iex> capability = %{name: "Create User", subject: "User"}
      iex> contract = Tiannara.ASC.Interface.Contract.from_capability(capability, "User")
      iex> contract.operation
      :post

  """
  def from_capability(capability, subject) do
    operation = infer_operation(capability.name || "")
    path = generate_path(operation, subject)
    id = generate_id(capability.name, subject)

    %__MODULE__{
      id: id,
      name: capability.name,
      version: "v1",
      operation: operation,
      path: path,
      inputs: infer_inputs(capability),
      outputs: infer_outputs(capability, subject),
      constraints: [],
      compatibility_mode: :backward,
      created_at: DateTime.utc_now(),
      modified_at: DateTime.utc_now(),
      parent_contract_id: nil
    }
  end

  @doc """
  Split a contract into multiple specialized contracts.

  Example: GET /users → GET /users/profile, GET /users/settings

  ## Returns

  - List of new contracts derived from the original

  """
  def split(%__MODULE__{} = contract, split_strategy) do
    case split_strategy do
      :by_field ->
        # Split based on output fields
        outputs = contract.outputs
        mid = div(length(outputs), 2)
        {outputs1, outputs2} = Enum.split(outputs, mid)

        [
          %{contract | id: "#{contract.id}_part1", outputs: outputs1, modified_at: DateTime.utc_now()},
          %{contract | id: "#{contract.id}_part2", outputs: outputs2, modified_at: DateTime.utc_now()}
        ]

      :by_parameter ->
        # Split based on input parameters
        inputs = contract.inputs
        mid = div(length(inputs), 2)
        {inputs1, inputs2} = Enum.split(inputs, mid)

        [
          %{contract | id: "#{contract.id}_required", inputs: inputs1, modified_at: DateTime.utc_now()},
          %{contract | id: "#{contract.id}_optional", inputs: inputs2, modified_at: DateTime.utc_now()}
        ]

      _ ->
        [contract]  # No split
    end
  end

  @doc """
  Merge two compatible contracts into one.

  Combines inputs and outputs from both contracts.
  """
  def merge(%__MODULE__{} = contract1, %__MODULE__{} = contract2) do
    if can_merge?(contract1, contract2) do
      %__MODULE__{
        id: "#{contract1.id}_#{contract2.id}",
        name: "#{contract1.name} + #{contract2.name}",
        version: "v1",
        operation: contract1.operation,
        path: contract1.path,
        inputs: contract1.inputs ++ contract2.inputs,
        outputs: contract1.outputs ++ contract2.outputs,
        constraints: contract1.constraints ++ contract2.constraints,
        compatibility_mode: :backward,
        created_at: DateTime.utc_now(),
        modified_at: DateTime.utc_now(),
        parent_contract_id: nil
      }
    else
      nil  # Cannot merge incompatible contracts
    end
  end

  @doc """
  Bump contract version.

  Increments version number while maintaining compatibility mode.
  """
  def bump_version(%__MODULE__{} = contract, new_version) do
    %__MODULE__{
      contract
      | version: new_version,
        modified_at: DateTime.utc_now()
    }
  end

  @doc """
  Strengthen contract constraints.

  Adds stricter validation or rate limiting.
  """
  def strengthen_constraints(%__MODULE__{} = contract, new_constraint) do
    %__MODULE__{
      contract
      | constraints: contract.constraints ++ [new_constraint],
        modified_at: DateTime.utc_now()
    }
  end

  @doc """
  Relax contract constraints.

  Removes or weakens existing constraints.
  """
  def relax_constraints(%__MODULE__{} = contract, constraint_type) do
    relaxed_constraints = Enum.reject(contract.constraints, fn c ->
      Map.get(c, :type) == constraint_type
    end)

    %__MODULE__{
      contract
      | constraints: relaxed_constraints,
        modified_at: DateTime.utc_now()
    }
  end

  @doc """
  Check if two contracts can be merged.

  Contracts must have compatible operations and paths.
  """
  def can_merge?(%__MODULE__{} = c1, %__MODULE__{} = c2) do
    c1.operation == c2.operation and
      String.starts_with?(c1.path || "", c2.path || "") or
      String.starts_with?(c2.path || "", c1.path || "")
  end

  @doc """
  Calculate contract complexity score.

  Based on number of inputs, outputs, and constraints.
  """
  def complexity_score(%__MODULE__{} = contract) do
    input_complexity = length(contract.inputs) * 0.3
    output_complexity = length(contract.outputs) * 0.3
    constraint_complexity = length(contract.constraints) * 0.4

    Float.round(input_complexity + output_complexity + constraint_complexity, 2)
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp infer_operation(name) do
    name_lower = String.downcase(name)

    cond do
      String.contains?(name_lower, ["create", "add", "new", "register"]) -> :post
      String.contains?(name_lower, ["update", "modify", "change", "edit"]) -> :put
      String.contains?(name_lower, ["delete", "remove", "destroy"]) -> :delete
      String.contains?(name_lower, ["list", "get", "fetch", "retrieve"]) -> :get
      true -> :get
    end
  end

  defp generate_path(operation, subject) do
    subject_snake = Macro.underscore(subject)

    case operation do
      :post -> "/api/v1/#{subject_snake}"
      :get -> "/api/v1/#{subject_snake}"
      :put -> "/api/v1/#{subject_snake}/{id}"
      :delete -> "/api/v1/#{subject_snake}/{id}"
      _ -> "/api/v1/#{subject_snake}"
    end
  end

  defp generate_id(name, subject) do
    "#{Macro.underscore(subject)}.#{String.downcase(String.replace(name || "", " ", "_"))}"
  end

  defp infer_inputs(_capability) do
    # Default input schema - would be enhanced with actual capability analysis
    [%{name: "data", type: "object", required: true}]
  end

  defp infer_outputs(_capability, subject) do
    # Default output schema
    [%{name: "#{Macro.underscore(subject)}_id", type: "string"}]
  end
end
