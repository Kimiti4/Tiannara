defmodule TiannaraOS.Governance.RFCValidationConstitution do
  @moduledoc """
  RFCValidationConstitution - Defines immutable validation requirements
  
  Establishes the constitutional requirements for RFC system validation.
  All validation campaigns MUST conform to these requirements.
  
  ## Owner
  GovernanceValidationLaboratory (existing, frozen)
  
  ## Validation Requirements
  1. Replay Campaign - Deterministic reconstruction from events
  2. Ledger Campaign - Event integrity and ordering
  3. Simulation Campaign - All 8 simulations pass
  4. Genome Campaign - Proposal genome calculation accuracy
  5. Migration Campaign - Deployment plan correctness
  6. Certification Campaign - Certificate structure validity
  7. Provenance Campaign - Complete history reconstruction
  8. Review Campaign - Review board quorum enforcement
  9. Voting Campaign - Vote tallying correctness
  10. Ratification Campaign - Threshold enforcement
  11. Stress Campaign - System under load/failure
  12. Long Horizon Campaign - Stability over extended execution
  
  ## Guarantees
  - Immutable requirements (cannot change without RFC)
  - All campaigns mandatory (no bypasses)
  - Each campaign produces verifiable evidence
  - Failure in any campaign → validation failure
  
  ## Usage
      iex> RFCValidationConstitution.campaigns()
      [:replay, :ledger, :simulation, ...]
  """

  # === Public API ===

  @doc """
  Get list of all mandatory validation campaigns.
  
  ## Returns
  List of campaign atoms (12 total)
  """
  @spec campaigns() :: [atom()]
  def campaigns do
    [
      :replay,
      :ledger,
      :simulation,
      :genome,
      :migration,
      :certification,
      :provenance,
      :review,
      :voting,
      :ratification,
      :stress,
      :long_horizon
    ]
  end

  @doc """
  Get validation requirements for a specific campaign.
  
  ## Parameters
  - `campaign` - Campaign atom
  
  ## Returns
  Map with campaign requirements
  """
  @spec requirements(atom()) :: map()
  def requirements(:replay) do
    %{
      name: "Replay Campaign",
      description: "Verify deterministic reconstruction from ledger events",
      success_criteria: [
        "All proposals replay identically with same seed",
        "Hash verification passes for all reconstructed states",
        "No divergence between original and replayed execution"
      ],
      evidence_required: [
        "Replay logs with timestamps",
        "Hash comparison results",
        "Divergence detection report"
      ]
    }
  end

  def requirements(:ledger) do
    %{
      name: "Ledger Campaign",
      description: "Verify event integrity and ordering",
      success_criteria: [
        "All events have valid hashes",
        "Event ordering is consistent",
        "No missing or duplicate events"
      ],
      evidence_required: [
        "Ledger audit log",
        "Hash chain verification",
        "Ordering consistency check"
      ]
    }
  end

  def requirements(:simulation) do
    %{
      name: "Simulation Campaign",
      description: "Verify all 8 mandatory simulations pass",
      success_criteria: [
        "Structural simulation passes",
        "Safety simulation passes",
        "Governance simulation passes",
        "Scientific simulation passes",
        "Economic simulation passes",
        "Performance simulation passes",
        "Migration simulation passes",
        "Replay simulation passes"
      ],
      evidence_required: [
        "Simulation certificates for all 8 types",
        "Certificate hash verification",
        "Simulation metrics report"
      ]
    }
  end

  def requirements(:genome) do
    %{
      name: "Genome Campaign",
      description: "Verify proposal genome calculation accuracy",
      success_criteria: [
        "Genome fields are quantifiable",
        "Score calculation is deterministic",
        "Fitness delta within valid range"
      ],
      evidence_required: [
        "Genome calculation logs",
        "Score verification results",
        "Range validation report"
      ]
    }
  end

  def requirements(:migration) do
    %{
      name: "Migration Campaign",
      description: "Verify deployment plan correctness",
      success_criteria: [
        "Migration plan is executable",
        "Rollback strategy exists",
        "No data loss during migration"
      ],
      evidence_required: [
        "Migration execution log",
        "Rollback test results",
        "Data integrity verification"
      ]
    }
  end

  def requirements(:certification) do
    %{
      name: "Certification Campaign",
      description: "Verify certificate structure validity",
      success_criteria: [
        "Certificates follow separated payload/signature pattern",
        "No self-referential hashing",
        "All required fields present"
      ],
      evidence_required: [
        "Certificate structure audit",
        "Hash verification results",
        "Field completeness check"
      ]
    }
  end

  def requirements(:provenance) do
    %{
      name: "Provenance Campaign",
      description: "Verify complete history reconstruction",
      success_criteria: [
        "All state changes traceable to events",
        "No orphaned states",
        "Complete causal chain"
      ],
      evidence_required: [
        "Provenance graph",
        "Causal chain verification",
        "Orphan detection report"
      ]
    }
  end

  def requirements(:review) do
    %{
      name: "Review Campaign",
      description: "Verify review board quorum enforcement",
      success_criteria: [
        "Quorum correctly calculated",
        "Approval threshold enforced",
        "Review events immutable"
      ],
      evidence_required: [
        "Review event logs",
        "Quorum calculation verification",
        "Immutability check"
      ]
    }
  end

  def requirements(:voting) do
    %{
      name: "Voting Campaign",
      description: "Verify vote tallying correctness",
      success_criteria: [
        "Vote counts are accurate",
        "Supermajority threshold correct",
        "Vote events immutable"
      ],
      evidence_required: [
        "Vote event logs",
        "Tally verification",
        "Threshold enforcement proof"
      ]
    }
  end

  def requirements(:ratification) do
    %{
      name: "Ratification Campaign",
      description: "Verify ratification threshold enforcement",
      success_criteria: [
        "Ratification only on supermajority",
        "No ratification on veto",
        "Ratification events immutable"
      ],
      evidence_required: [
        "Ratification event logs",
        "Threshold verification",
        "Veto handling proof"
      ]
    }
  end

  def requirements(:stress) do
    %{
      name: "Stress Campaign",
      description: "Verify system behavior under load/failure",
      success_criteria: [
        "System handles concurrent proposals",
        "Failures produce clear error messages",
        "No state corruption on failure"
      ],
      evidence_required: [
        "Load test results",
        "Failure scenario logs",
        "State integrity verification"
      ]
    }
  end

  def requirements(:long_horizon) do
    %{
      name: "Long Horizon Campaign",
      description: "Verify stability over extended execution",
      success_criteria: [
        "No memory leaks over time",
        "Consistent performance",
        "Deterministic behavior maintained"
      ],
      evidence_required: [
        "Extended execution logs",
        "Memory usage profile",
        "Performance stability report"
      ]
    }
  end

  @doc """
  Verify that all campaigns passed validation.
  
  ## Parameters
  - `results` - Map of campaign results (%{campaign => {:ok | :fail, reason}})
  
  ## Returns
  {:ok, :all_passed} or {:error, failures}
  """
  @spec verify_all_passed(map()) :: {:ok, :all_passed} | {:error, [String.t()]}
  def verify_all_passed(results) do
    required = campaigns()
    
    failures = Enum.flat_map(required, fn campaign ->
      case Map.get(results, campaign) do
        {:ok, _} -> []
        {:fail, reason} -> ["#{campaign}: #{reason}"]
        nil -> ["#{campaign}: No result provided"]
      end
    end)

    if Enum.empty?(failures) do
      {:ok, :all_passed}
    else
      {:error, failures}
    end
  end
end
