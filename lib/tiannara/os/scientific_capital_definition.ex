defmodule TiannaraOS.ScientificCapitalDefinition do
  @moduledoc """
  ScientificCapitalDefinition - Constitutional definition of what constitutes scientific capital.

  This module defines:
  - What canonical transactions contribute to capital
  - The accounting identity for capital accumulation
  - The constitutional sources of evidence

  IMPORTANT: This module NEVER contains coefficients. Coefficients belong in
  ScientificCapitalPolicy. This module only defines WHAT counts, not HOW MUCH.

  ## Constitutional Role

  Scientific Capital Definition is an immutable constitutional artifact that answers:
  "What activities generate scientific capital?"

  The answer is derived from canonical transactions:
  - TheoryFormationResult → discoveries and theories
  - DistributedValidationResult → resolved unknowns
  - Future: LawsRegistry → validated laws
  - Future: ApplicationDeployments → operational applications

  ## Usage

      # Get canonical transaction types that contribute to capital
      sources = ScientificCapitalDefinition.canonical_sources()
      # [:theory_formation_result, :distributed_validation_result]

      # Get contribution fields for a transaction type
      fields = ScientificCapitalDefinition.contribution_fields(:theory_formation_result)
      # [:discoveries_made, :theories_formed]

  ## Architecture

  ```
  Canonical Transactions (immutable evidence)
          │
          │ define contribution fields
          ▼
  ScientificCapitalDefinition (WHAT counts as capital)
          │
          │ provides structure
          ▼
  ScientificCapitalPolicy (HOW MUCH each contribution is worth)
          │
          │ applies coefficients
          ▼
  ScientificCapitalLedger (calculates and records capital)
  ```

  This separation ensures that changes to coefficient values (policy) cannot
  silently change what counts as capital (definition).
  """

  @type canonical_source :: atom()
  @type contribution_field :: atom()

  @doc """
  Returns list of canonical transaction types that contribute to scientific capital.

  Each source represents an immutable constitutional artifact that serves as
  evidence for capital accumulation.
  """
  @spec canonical_sources() :: [canonical_source()]
  def canonical_sources() do
    [
      :theory_formation_result,     # Produces discoveries and theories
      :distributed_validation_result # Resolves unknowns (research debt reduction)
      # Future additions require Phase 14 governance approval:
      # :laws_registry,            # Validated fundamental principles
      # :application_deployment     # Operational utility demonstrations
    ]
  end

  @doc """
  Returns the contribution fields for a given canonical transaction type.

  These are the field names in GenerationHistory that represent capital-generating
  activities from this transaction type.

  ## Examples

      ScientificCapitalDefinition.contribution_fields(:theory_formation_result)
      # [:discoveries_made, :theories_formed]

      ScientificCapitalDefinition.contribution_fields(:distributed_validation_result)
      # [:unknowns_resolved]
  """
  @spec contribution_fields(canonical_source()) :: [contribution_field()]
  def contribution_fields(:theory_formation_result) do
    [:discoveries_made, :theories_formed]
  end

  def contribution_fields(:distributed_validation_result) do
    [:unknowns_resolved]
  end

  # Future sources (require governance approval to activate):
  # def contribution_fields(:laws_registry) do
  #   [:laws_validated]
  # end
  #
  # def contribution_fields(:application_deployment) do
  #   [:applications_deployed]
  # end

  @doc """
  Returns the constitutional accounting identity for scientific capital.

  The identity states that capital at generation G equals:
  Capital(G) = Capital(G-1) + ΔCapital(G)

  Where ΔCapital(G) is calculated by applying policy coefficients to
  canonical transaction contributions.

  This function returns the symbolic representation for documentation purposes.
  Actual calculation is performed by ScientificCapitalLedger using current policy.
  """
  @spec accounting_identity() :: String.t()
  def accounting_identity() do
    """
    Capital(G) = Capital(G-1) + ΔCapital(G)

    Where:
      ΔCapital(G) = Σ (coefficient_i × contribution_i)

    Contributions come from canonical transactions:
      - theory_formation_result.discoveries_made
      - theory_formation_result.theories_formed
      - distributed_validation_result.unknowns_resolved
      - [future: laws_registry.laws_validated]
      - [future: application_deployment.applications_deployed]

    Coefficients are defined by active ScientificCapitalPolicy version.
    """
  end

  @doc """
  Validates that a GenerationHistory record contains all required fields
  for scientific capital calculation.

  Returns {:ok} if all required fields are present, {:error, missing_fields} otherwise.
  """
  @spec validate_generation_record(map()) :: {:ok} | {:error, [atom()]}
  def validate_generation_record(record) do
    required_fields = all_contribution_fields()

    missing = Enum.reject(required_fields, fn field ->
      Map.has_key?(record, field)
    end)

    if length(missing) == 0 do
      {:ok}
    else
      {:error, missing}
    end
  end

  @doc """
  Returns all contribution fields across all canonical sources.
  """
  @spec all_contribution_fields() :: [contribution_field()]
  def all_contribution_fields() do
    canonical_sources()
    |> Enum.flat_map(&contribution_fields/1)
    |> Enum.uniq()
  end
end
