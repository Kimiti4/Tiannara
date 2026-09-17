# Audit Replay Procedure (Phase 20.96)

## Purpose

Define the deterministic procedure for replaying the entire Constitutional OS from cold storage artifacts, independent of any runtime. This is the core of the independent audit.

## Replay Principle

The auditor reconstructs the OS by replaying every recorded step in order, recomputing every hash from first principles. No runtime is needed — only the cold storage artifact set and the replay specification.

## Procedure

### Step 1: Acquire Cold Storage
- Obtain an isolated, verified copy of cold storage
- Verify cold storage integrity via its root hash
- Confirm no runtime artifacts included

### Step 2: Reconstruct Artifact Index
- Walk cold storage to enumerate all artifacts
- Build artifact dependency graph
- Verify all dependencies resolvable within cold storage

### Step 3: Replay Subsystem Chains
For each subsystem:
1. Locate the subsystem's replay chain root in cold storage
2. Walk the chain step by step
3. For each step:
   a. Read input artifacts from cold storage
   b. Compute expected output deterministically
   c. Compute step hash = SHA-256(stage || input_hash || output_hash || previous_hash)
   d. Compare against recorded step hash
4. Verify chain root hash matches final computed hash

### Step 4: Replay Cross-Subsystem Chains
- Replay integration chains that span multiple subsystems
- Verify cross-subsystem handoff hashes match

### Step 5: Replay Generation Lifecycle
- Replay generation promotions, transitions, rollbacks, rollforwards
- Verify generation lineage tree continuity

### Step 6: Replay Validation Campaigns
- Replay all 8 validation campaigns (20.95)
- Verify all campaign results produce identical hashes

### Step 7: Replay Full OS
- Replay the complete OS from genesis to latest generation
- Verify final state hash matches recorded root

## Replay Verification

At each step, the auditor records:
- Step number
- Stage identifier
- Input hash (from cold storage)
- Expected output hash (from cold storage)
- Computed output hash (from deterministic replay)
- Match result (true/false)
- Step hash (computed)

## Replay Chain Properties

- Every step is independently verifiable
- Steps form an acyclic chain
- Chain root summarizes entire replay
- Cold storage independence means replay can be done offline
- Two independent auditors must produce identical results
