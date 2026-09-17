# Audit Independence Requirements (Phase 20.96)

## Purpose

Define the strict requirements that make the audit truly independent. An audit is only meaningful if the auditor does not trust or rely on the system being audited.

## Core Requirements

### R1: No Runtime Access
- Auditor must not execute the runtime
- All verification must be done from cold storage alone
- Exception: deterministic replay of spec-defined computations using independent tools

### R2: No Implicit Trust
- Every claim in the system must be independently verified
- No trust chain shorter than "auditor verified from cold storage"
- Even seemingly trivial claims (e.g., "this is a valid struct") must be verified

### R3: Isolated Cold Storage
- Auditor must use an independently obtained, verified copy of cold storage
- Storage must be frozen (no ongoing writes during audit)
- Storage integrity must be verified before audit begins

### R4: Deterministic Tools
- Auditor tools must be deterministic
- Same cold storage → same audit results
- Cross-auditor reproducibility is mandatory

### R5: Dual Audit
- Two independent auditors must reach identical conclusions
- If auditors disagree, a third auditor resolves the discrepancy
- Disagreement itself is a finding

### R6: Evidence-Only Acceptance
- No assertion accepted without verifiable evidence chain
- Authority claims ("certified by X") are irrelevant
- Only data + deterministic verification matter

### R7: Full Transparency
- Audit methodology must be fully documented
- All audit tools must be open and verifiable
- Audit findings must include complete evidence chains

## Auditor Qualifications

- No prior involvement in Tiannara development
- Access to cold storage only (no runtime, no development environment)
- Expertise in cryptographic hash verification
- Expertise in deterministic replay systems
- Independence confirmed in audit certificate

## Independence Declaration

The auditor must sign an independence declaration stating:
- No conflict of interest
- No access to runtime
- No implicit trust of any system claim
- All verification performed from cold storage alone
- Audit tools are deterministic and reproducible
