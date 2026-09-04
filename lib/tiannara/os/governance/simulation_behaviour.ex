defmodule TiannaraOS.Governance.SimulationBehaviour do
  @moduledoc """
  SimulationBehaviour - Contract for all simulation implementations
  
  Defines the interface that all 8 mandatory simulation types must implement.
  Each simulation type is an adapter that validates a specific aspect of proposal viability.
  
  ## Owner
  GovernanceValidationLaboratory (existing, frozen)
  
  ## Mandatory Simulations
  1. **Structural** - Validates system architecture integrity
  2. **Safety** - Validates risk mitigation and rollback capability
  3. **Governance** - Validates constitutional compliance
  4. **Scientific** - Validates scientific capital preservation
  5. **Economic** - Validates budget feasibility
  6. **Performance** - Validates performance impact
  7. **Migration** - Validates deployment strategy
  8. **Replay** - Validates determinism preservation
  
  ## Guarantees
  - All simulations must implement this behaviour
  - No bypasses allowed (all 8 required)
  - Evidence artifacts must be content-addressed
  - Certificates use separated structure
  
  ## Usage
      defmodule MySimulation do
        @behaviour TiannaraOS.Governance.SimulationBehaviour
        
        @impl true
        def run(proposal_id, config) do
          # Implementation
        end
      end
  """

  @doc """
  Run the simulation for a given proposal.
  
  Must execute the simulation and return results with evidence artifacts.
  
  ## Parameters
  - `proposal_id` - ID of proposal being tested
  - `config` - Simulation-specific configuration map
  
  ## Returns
  {:ok, %SimulationResult{}} on success, {:error, reason} on failure
  """
  @callback run(String.t(), map()) :: {:ok, TiannaraOS.Governance.SimulationResult.t()} | {:error, String.t()}

  @doc """
  Validate simulation configuration before execution.
  
  Ensures all required parameters are present and valid.
  
  ## Parameters
  - `config` - Configuration map to validate
  
  ## Returns
  {:ok, validated_config} or {:error, [validation_errors]}
  """
  @callback validate_config(map()) :: {:ok, map()} | {:error, [String.t()]}

  @doc """
  Generate evidence artifact from simulation results.
  
  Creates content-addressed evidence file for audit trail.
  
  ## Parameters
  - `result` - Simulation result to generate evidence for
  - `output_dir` - Directory to save evidence artifact
  
  ## Returns
  {:ok, %{hash: sha256_hash, path: file_path}} or {:error, reason}
  """
  @callback generate_evidence(TiannaraOS.Governance.SimulationResult.t(), String.t()) ::
              {:ok, %{hash: String.t(), path: String.t()}} | {:error, String.t()}

  @doc """
  Get simulation type identifier.
  
  Returns the atom identifying which simulation type this implements.
  
  ## Returns
  One of: :structural, :safety, :governance, :scientific, :economic, :performance, :migration, :replay
  """
  @callback simulation_type() :: atom()

  @doc """
  Get human-readable description of what this simulation validates.
  
  ## Returns
  Description string explaining simulation purpose
  """
  @callback description() :: String.t()

  @optional_callbacks description: 0
end
