# Phase 14.1 — RFC Certification Flow Specification

**Date**: July 3, 2026  
**Phase**: 14.1.0 (Architecture Review)  
**Status**: 🔒 PENDING FREEZE  

---

## Overview

This document defines the complete certification flow for RFC proposals, ensuring every proposal is cryptographically verified, archaeologically explainable, and deterministically replayable before freezing.

**Critical Principle**: No bypasses allowed. Every proposal must pass all 12 mandatory steps.

---

## Certification Pipeline

### Mandatory 12-Step Flow

```
[1] Proposal Submission
    ↓ Schema validation
[2] Structural Validation
    ↓ Must PASS
[3] Safety Simulation
    ↓ Must PASS
[4] Governance Simulation
    ↓ Must PASS
[5] Scientific Simulation
    ↓ Must PASS
[6] Economic Simulation
    ↓ Must PASS
[7] Performance Simulation
    ↓ Must PASS
[8] Migration Simulation
    ↓ Must PASS
[9] Replay Simulation
    ↓ Must PASS
[10] Institutional Review
    ↓ Quorum approval required
[11] Ratification Vote
    ↓ Supermajority/unanimous required
[12] Migration & Deployment
    ↓ Post-deployment verification
    ↓
PROPOSAL CERTIFIED & FROZEN
```

### Failure Handling

Any step failure → **IMMEDIATE REJECTION**

No retries. No appeals. Must submit new proposal with modifications.

---

## Certificate Types

Six certificates generated during lifecycle:

| # | Certificate | Generated At | Contains |
|---|-------------|--------------|----------|
| 1 | **ProposalCertificate** | After submission | Proposal metadata + genome hash |
| 2 | **SimulationCertificate** | After simulations (step 9) | All 8 simulation results |
| 3 | **ReviewCertificate** | After institutional review (step 10) | Review board decisions |
| 4 | **RatificationCertificate** | After vote (step 11) | Vote results + quorum verification |
| 5 | **MigrationCertificate** | After deployment (step 12) | Migration log + rollback status |
| 6 | **ReplayCertificate** | After replay verification | Post-deployment replay proof |

### Final Aggregate Certificate

After all 6 certificates generated:

**RFC_CERTIFICATE.json** - Aggregates all certificate hashes into single verifiable artifact.

---

## Certificate Structure (Separated Payload/Signature)

Following Phase 14 fix to avoid self-referential hashing:

### Example: ProposalCertificate

**File 1: `proposal_certificate.json`**
```json
{
  "payload": {
    "certificate_type": "proposal_certification",
    "proposal_id": "abc123...",
    "rfc_id": "def456...",
    "version": 1,
    "timestamp": "2026-07-03T00:00:00Z",
    "genome_hash": "sha256:...",
    "proposer_id": "user_789",
    "proposer_institution": "institution_xyz",
    "status": "submitted"
  },
  "signature": null
}
```

**File 2: `proposal_certificate.sha256`**
```
b69fee34460012f2c521bbd7f8325c1739a79f677499a5ba5a941bad44d77d8a
```

The signature is computed from the JSON bytes of `proposal_certificate.json` at save time by `PureArtifactGenerator`.

---

## Detailed Certification Steps

### Step 1: Proposal Submission

**Actor**: Proposer  
**Action**: Submit proposal with genome  
**Validation**: Schema compliance check  

```elixir
def submit_proposal(genome, proposer_id) do
  # Validate genome structure
  case ProposalGenome.validate(genome) do
    {:ok, validated_genome} ->
      # Generate immutable IDs
      proposal_id = Proposal.generate_id(validated_genome, proposer_id, DateTime.utc_now())
      rfc_id = RFC.generate_id(validated_genome)
      
      # Create initial ledger event
      event = LedgerEvent.create(:proposal_submitted, %{
        proposal_id: proposal_id,
        rfc_id: rfc_id,
        genome: validated_genome,
        proposer_id: proposer_id
      })
      
      # Record in ledger
      ProposalLedger.append(event)
      
      # Generate ProposalCertificate
      cert = generate_proposal_certificate(proposal_id, rfc_id, validated_genome)
      
      {:ok, %{proposal_id: proposal_id, rfc_id: rfc_id, certificate: cert}}
    
    {:error, errors} ->
      {:error, "Schema validation failed: #{inspect(errors)}"}
  end
end
```

**Output**: ProposalCertificate  
**Failure Mode**: Schema validation errors → REJECTED

---

### Step 2: Structural Validation

**Actor**: GovernanceValidationLaboratory  
**Action**: Verify schema compliance, field types, required fields  
**Simulation Type**: `:structural`  

```elixir
def structural_validation(proposal_id) do
  proposal = ProposalLedger.get_proposal(proposal_id)
  
  checks = [
    check_genome_structure(proposal.proposal_genome),
    check_required_fields(proposal),
    check_field_types(proposal),
    check_id_format(proposal.proposal_id),
    check_timestamp_validity(proposal.created_at)
  ]
  
  if Enum.all?(checks, & &1.passed) do
    {:pass, generate_evidence_artifact(checks)}
  else
    {:fail, generate_failure_report(checks)}
  end
end
```

**Output**: SimulationResult (structural)  
**Failure Mode**: Any structural issue → REJECTED

---

### Step 3: Safety Simulation

**Actor**: GovernanceValidationLaboratory  
**Action**: Assess potential harmful impacts  
**Simulation Type**: `:safety`  

```elixir
def safety_simulation(proposal_id) do
  proposal = ProposalLedger.get_proposal(proposal_id)
  genome = proposal.proposal_genome
  
  risk_assessment = %{
    kernel_impact: assess_kernel_risk(genome.affected_kernel),
    governance_stability: assess_governance_risk(genome.expected_entropy_delta),
    data_integrity: assess_data_risk(genome.migration_difficulty),
    rollback_feasibility: assess_rollback_risk(genome.rollback_difficulty)
  }
  
  safety_score = calculate_safety_score(risk_assessment)
  
  if safety_score >= 0.7 do  # Minimum safety threshold
    {:pass, %{safety_score: safety_score, risks: risk_assessment}}
  else
    {:fail, %{safety_score: safety_score, reason: "Safety score below threshold"}}
  end
end
```

**Output**: SimulationResult (safety)  
**Failure Mode**: Safety score < 0.7 → REJECTED

---

### Step 4: Governance Simulation

**Actor**: GovernanceValidationLaboratory  
**Action**: Verify constitutional compliance  
**Simulation Type**: `:governance`  

```elixir
def governance_simulation(proposal_id) do
  proposal = ProposalLedger.get_proposal(proposal_id)
  
  checks = [
    verify_authority_chain(proposal),
    verify_capability_conservation(proposal),
    verify_institutional_impact(proposal),
    verify_ratification_requirements(proposal),
    verify_migration_authority(proposal)
  ]
  
  if Enum.all?(checks, & &1.compliant) do
    {:pass, %{compliance_checks: checks}}
  else
    violations = Enum.reject(checks, & &1.compliant)
    {:fail, %{violations: violations}}
  end
end
```

**Output**: SimulationResult (governance)  
**Failure Mode**: Constitutional violation → REJECTED

---

### Step 5: Scientific Simulation

**Actor**: GovernanceValidationLaboratory  
**Action**: Assess epistemic integrity impact  
**Simulation Type**: `:scientific`  

```elixir
def scientific_simulation(proposal_id) do
  proposal = ProposalLedger.get_proposal(proposal_id)
  genome = proposal.proposal_genome
  
  metrics = %{
    reproducibility_impact: assess_reproducibility(genome.expected_replay_impact),
    evidence_quality: assess_evidence_requirements(genome),
    methodology_soundness: assess_methodology(genome),
    falsifiability: assess_falsifiability(genome)
  }
  
  scientific_capital_delta = calculate_scientific_capital_change(metrics)
  
  if scientific_capital_delta >= -0.1 do  # Cannot significantly harm science
    {:pass, %{scientific_capital_delta: scientific_capital_delta, metrics: metrics}}
  else
    {:fail, %{scientific_capital_delta: scientific_capital_delta, reason: "Harms scientific integrity"}}
  end
end
```

**Output**: SimulationResult (scientific)  
**Failure Mode**: Scientific capital delta < -0.1 → REJECTED

---

### Step 6: Economic Simulation

**Actor**: GovernanceValidationLaboratory  
**Action**: Assess resource feasibility  
**Simulation Type**: `:economic`  

```elixir
def economic_simulation(proposal_id) do
  proposal = ProposalLedger.get_proposal(proposal_id)
  genome = proposal.proposal_genome
  
  cost_analysis = %{
    implementation_cost: genome.expected_cost,
    maintenance_cost: estimate_maintenance_cost(genome),
    migration_cost: genome.expected_migration_cost,
    opportunity_cost: estimate_opportunity_cost(genome),
    total_cost: sum_costs(cost_analysis)
  }
  
  budget_available = get_available_budget()
  
  if cost_analysis.total_cost <= budget_available do
    {:pass, %{cost_analysis: cost_analysis, budget_remaining: budget_available - cost_analysis.total_cost}}
  else
    {:fail, %{cost_analysis: cost_analysis, deficit: cost_analysis.total_cost - budget_available}}
  end
end
```

**Output**: SimulationResult (economic)  
**Failure Mode**: Cost exceeds budget → REJECTED

---

### Step 7: Performance Simulation

**Actor**: GovernanceValidationLaboratory  
**Action**: Assess scalability and performance impact  
**Simulation Type**: `:performance`  

```elixir
def performance_simulation(proposal_id) do
  proposal = ProposalLedger.get_proposal(proposal_id)
  genome = proposal.proposal_genome
  
  performance_metrics = %{
    throughput_impact: estimate_throughput_change(genome),
    latency_impact: estimate_latency_change(genome),
    memory_impact: estimate_memory_change(genome),
    complexity_impact: genome.expected_complexity_score
  }
  
  if performance_metrics.complexity_impact <= 0.8 and
     performance_metrics.latency_impact < 0.2 do  # < 20% latency increase
    {:pass, %{performance_metrics: performance_metrics}}
  else
    {:fail, %{performance_metrics: performance_metrics, reason: "Performance degradation too high"}}
  end
end
```

**Output**: SimulationResult (performance)  
**Failure Mode**: Complexity > 0.8 or latency increase > 20% → REJECTED

---

### Step 8: Migration Simulation

**Actor**: GovernanceValidationLaboratory  
**Action**: Simulate deployment and assess rollback feasibility  
**Simulation Type**: `:migration`  

```elixir
def migration_simulation(proposal_id) do
  proposal = ProposalLedger.get_proposal(proposal_id)
  genome = proposal.proposal_genome
  
  migration_plan = MigrationPlanner.generate_plan(proposal)
  
  simulation_result = simulate_migration(migration_plan)
  
  if simulation_result.success and can_rollback?(migration_plan) do
    {:pass, %{migration_plan: migration_plan, simulation: simulation_result}}
  else
    {:fail, %{migration_plan: migration_plan, simulation: simulation_result, reason: "Migration unsafe or unrollable"}}
  end
end
```

**Output**: SimulationResult (migration)  
**Failure Mode**: Migration failure or impossible rollback → REJECTED

---

### Step 9: Replay Simulation

**Actor**: GovernanceValidationLaboratory  
**Action**: Verify deterministic reconstruction capability  
**Simulation Type**: `:replay`  

```elixir
def replay_simulation(proposal_id) do
  proposal = ProposalLedger.get_proposal(proposal_id)
  
  # Attempt replay with different seeds
  seeds = [42, 123, 999, 2026]
  
  replay_results = Enum.map(seeds, fn seed ->
    case ProposalReplayEngine.replay_proposal(proposal_id, seed, proposal.created_at) do
      {:ok, reconstructed} ->
        hash_match = verify_hash_match(proposal, reconstructed)
        %{seed: seed, success: true, hash_match: hash_match}
      {:error, reason} ->
        %{seed: seed, success: false, error: reason}
    end
  end)
  
  if Enum.all?(replay_results, & &1.success and &1.hash_match) do
    {:pass, %{replay_results: replay_results}}
  else
    failures = Enum.reject(replay_results, &(&1.success and &1.hash_match))
    {:fail, %{replay_results: replay_results, failures: failures}}
  end
end
```

**Output**: SimulationResult (replay)  
**Failure Mode**: Any seed fails replay → REJECTED

---

### Step 10: Institutional Review

**Actor**: ReviewBoard(s)  
**Action**: Human oversight and expert review  
**Requirement**: Quorum of approvals (configurable per domain)  

```elixir
def institutional_review(proposal_id) do
  proposal = ProposalLedger.get_proposal(proposal_id)
  
  # Assign review boards based on affected domains
  review_boards = assign_review_boards(proposal.proposal_genome.affected_domains)
  
  # Collect reviews
  reviews = Enum.map(review_boards, fn board_id ->
    ReviewBoard.submit_review(board_id, proposal_id)
  end)
  
  # Check quorum
  approvals = Enum.count(reviews, &(&1.decision == :approve))
  rejections = Enum.count(reviews, &(&1.decision == :reject))
  
  quorum_size = length(review_boards) |> div(2) |> Kernel.+(1)  # Majority
  
  if approvals >= quorum_size and rejections == 0 do
    {:approved, %{reviews: reviews, quorum_met: true}}
  else
    {:rejected, %{reviews: reviews, quorum_met: false, reason: "Insufficient approvals or veto exercised"}}
  end
end
```

**Output**: ReviewCertificate  
**Failure Mode**: Quorum not met or any veto → REJECTED

---

### Step 11: Ratification Vote

**Actor**: InstitutionGraph (all institutions)  
**Action**: Formal institutional voting  
**Requirement**: Supermajority (66%) or unanimous (for constitutional amendments)  

```elixir
def ratification_vote(proposal_id) do
  proposal = ProposalLedger.get_proposal(proposal_id)
  
  # Determine voting threshold
  threshold = if proposal.proposal_genome.affected_kernel do
    :unanimous  # 100% for kernel changes
  else
    :supermajority  # 66% for standard proposals
  end
  
  # Open voting period (1-7 days)
  votes = InstitutionGraph.open_vote(proposal_id, threshold)
  
  # Tally results
  yes_votes = Enum.count(votes, &(&1.vote == :yes))
  no_votes = Enum.count(votes, &(&1.vote == :no))
  total_votes = length(votes)
  
  approved = case threshold do
    :unanimous -> yes_votes == total_votes and no_votes == 0
    :supermajority -> yes_votes / total_votes >= 0.66
  end
  
  if approved do
    {:approved, %{votes: votes, yes: yes_votes, no: no_votes, total: total_votes}}
  else
    {:rejected, %{votes: votes, yes: yes_votes, no: no_votes, total: total_votes, reason: "Insufficient votes"}}
  end
end
```

**Output**: RatificationCertificate  
**Failure Mode**: Threshold not met → REJECTED

---

### Step 12: Migration & Deployment

**Actor**: MigrationPlanner  
**Action**: Execute migration plan and verify deployment  
**Requirement**: Successful deployment + post-deployment verification  

```elixir
def migrate_and_deploy(proposal_id) do
  proposal = ProposalLedger.get_proposal(proposal_id)
  
  # Generate migration plan
  migration_plan = MigrationPlanner.generate_plan(proposal)
  
  # Pre-migration backup
  backup_hash = backup_current_state()
  
  # Execute migration
  case MigrationPlanner.execute(migration_plan) do
    {:ok, deployment_log} ->
      # Post-deployment verification
      case verify_deployment(deployment_log) do
        :ok ->
          # Generate MigrationCertificate
          cert = generate_migration_certificate(proposal_id, deployment_log)
          
          {:deployed, %{deployment_log: deployment_log, certificate: cert}}
        
        {:error, reason} ->
          # Rollback
          rollback(backup_hash)
          {:failed, %{reason: "Post-deployment verification failed: #{reason}", rolled_back: true}}
      end
    
    {:error, reason} ->
      # Automatic rollback
      rollback(backup_hash)
      {:failed, %{reason: "Migration execution failed: #{reason}", rolled_back: true}}
  end
end
```

**Output**: MigrationCertificate  
**Failure Mode**: Migration failure → ROLLBACK + REJECTED

---

## Post-Deployment: Replay Verification

After successful deployment, verify deterministic reconstruction:

```elixir
def post_deployment_replay_verification(proposal_id) do
  proposal = ProposalLedger.get_proposal(proposal_id)
  
  # Replay with canonical seed
  {:ok, reconstructed} = ProposalReplayEngine.replay_proposal(
    proposal_id,
    42,  # Canonical seed
    proposal.created_at
  )
  
  # Compare with deployed state
  deployed_hash = get_deployed_state_hash(proposal_id)
  reconstructed_hash = compute_state_hash(reconstructed)
  
  if deployed_hash == reconstructed_hash do
    # Generate ReplayCertificate
    cert = generate_replay_certificate(proposal_id, deployed_hash)
    {:verified, %{certificate: cert}}
  else
    {:error, "Replay mismatch: deployed=#{deployed_hash}, reconstructed=#{reconstructed_hash}"}
  end
end
```

**Output**: ReplayCertificate  
**Failure Mode**: Hash mismatch → FLAGGED for investigation

---

## Final Certification: RFC_CERTIFICATE

After all 6 certificates generated, create aggregate certificate:

```elixir
def generate_final_rfc_certificate(rfc_id, proposal_id) do
  # Collect all certificate hashes
  cert_hashes = %{
    proposal: get_certificate_hash(proposal_id, :proposal),
    simulation: get_certificate_hash(proposal_id, :simulation),
    review: get_certificate_hash(proposal_id, :review),
    ratification: get_certificate_hash(proposal_id, :ratification),
    migration: get_certificate_hash(proposal_id, :migration),
    replay: get_certificate_hash(proposal_id, :replay)
  }
  
  # Create aggregate payload
  payload = %{
    certificate_type: "rfc_final_certification",
    rfc_id: rfc_id,
    proposal_id: proposal_id,
    timestamp: DateTime.utc_now(),
    certificate_hashes: cert_hashes,
    status: "frozen"
  }
  
  # Save using PureArtifactGenerator (separated structure)
  PureArtifactGenerator.save_certificate(payload, "rfc_certificate")
end
```

**Output Files**:
- `rfc_certificate.json` (payload)
- `rfc_certificate.sha256` (signature)

---

## Certificate Registry

Track all certificates for independent verification:

```elixir
defmodule TiannaraOS.Governance.CertificateRegistry do
  @type t :: %__MODULE__{
    proposal_id: String.t(),
    certificates: %{
      proposal: String.t(),
      simulation: String.t(),
      review: String.t(),
      ratification: String.t(),
      migration: String.t(),
      replay: String.t()
    },
    final_certificate_hash: String.t()
  }

  defstruct [:proposal_id, :certificates, :final_certificate_hash]

  @doc """
  Register all certificates for a proposal.
  """
  @spec register(String.t(), map()) :: :ok
  def register(proposal_id, cert_hashes) do
    registry = %__MODULE__{
      proposal_id: proposal_id,
      certificates: cert_hashes,
      final_certificate_hash: compute_aggregate_hash(cert_hashes)
    }
    
    # Store in ETS table
    :ets.insert(:certificate_registry, {proposal_id, registry})
    
    :ok
  end

  @doc """
  Verify all certificates for proposal.
  """
  @spec verify_all(String.t()) :: {:ok, boolean()} | {:error, [String.t()]}
  def verify_all(proposal_id) do
    case :ets.lookup(:certificate_registry, proposal_id) do
      [{^proposal_id, registry}] ->
        mismatches = []
        
        # Verify each certificate
        mismatches = verify_certificate(registry.certificates.proposal, :proposal) ++ mismatches
        mismatches = verify_certificate(registry.certificates.simulation, :simulation) ++ mismatches
        mismatches = verify_certificate(registry.certificates.review, :review) ++ mismatches
        mismatches = verify_certificate(registry.certificates.ratification, :ratification) ++ mismatches
        mismatches = verify_certificate(registry.certificates.migration, :migration) ++ mismatches
        mismatches = verify_certificate(registry.certificates.replay, :replay) ++ mismatches
        
        if Enum.empty?(mismatches) do
          {:ok, true}
        else
          {:error, mismatches}
        end
      
      [] ->
        {:error, ["No certificate registry found for proposal #{proposal_id}"]}
    end
  end

  defp verify_certificate(cert_hash, cert_type) do
    # Load certificate files
    cert_path = "phase14/rfc_system/certificates/#{cert_type}_#{cert_hash}.json"
    sig_path = "phase14/rfc_system/certificates/#{cert_type}_#{cert_hash}.sha256"
    
    case File.read(cert_path) do
      {:ok, cert_json} ->
        # Recompute hash
        computed_hash = :crypto.hash(:sha256, cert_json) |> Base.encode16(case: :lower)
        
        # Load stored signature
        case File.read(sig_path) do
          {:ok, sig_content} ->
            stored_sig = String.trim(sig_content)
            
            if computed_hash == stored_sig do
              []  # Match
            else
              ["#{cert_type} certificate signature mismatch"]
            end
          
          {:error, _} ->
            ["#{cert_type} signature file missing"]
        end
      
      {:error, _} ->
        ["#{cert_type} certificate file missing"]
    end
  end
end
```

---

## Independent Verification

External auditor can verify entire certification using ONLY artifacts:

```elixir
def independent_verification(rfc_id) do
  # Load certificate registry
  registry = CertificateRegistry.get(rfc_id)
  
  # Verify all 6 certificates
  case CertificateRegistry.verify_all(registry.proposal_id) do
    {:ok, true} ->
      # Verify aggregate certificate
      verify_aggregate_certificate(registry.final_certificate_hash)
    
    {:error, mismatches} ->
      {:error, "Certificate verification failed: #{inspect(mismatches)}"}
  end
end
```

**No runtime imports required**. Only JSON artifacts and SHA-256 hashes.

---

## Certification Metrics

Track certification health:

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Pass rate** | > 50% | % of submitted proposals reaching FROZEN |
| **Average time to certify** | < 14 days | Days from SUBMITTED to FROZEN |
| **Simulation pass rate** | > 80% | % passing all 8 simulations |
| **Ratification success rate** | > 70% | % achieving required threshold |
| **Migration success rate** | > 95% | % deploying without rollback |
| **Replay verification rate** | 100% | % passing post-deployment replay |

---

## Conclusion

This certification flow ensures:

✅ **No bypasses** - All 12 steps mandatory  
✅ **Cryptographic verification** - Content-addressed certificates  
✅ **Archaeological explainability** - Full provenance chain  
✅ **Deterministic replay** - Post-deployment verification  
✅ **Independent auditability** - Trustless verification possible  
✅ **Separated structure** - No self-referential hashes (Phase 14 fix)  

**Next Step**: Implement certification flow after schema freeze.
