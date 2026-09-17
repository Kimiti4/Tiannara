# Operator Model

## Overview

Operators are agents (human or automated) that interact with the Observatory.
The Operator Model defines roles, each with specific observation scope, intervention scope, authority, and audit requirements.

This model is distinct from and sits above RBAC. RBAC implements the model; the model defines the roles.

---

## Role Hierarchy

```
Observer
    │
    ├── Engineer
    │       │
    │       ├── Scientist
    │       │       │
    │       │       ├── Governor
    │       │       │       │
    │       │       │       └── Administrator
    │       │       │
    │       │       └── Auditor
    │       │
    │       └── System (automated agents)
    │
    └── Auditor (cross-cutting, not under Observer)
```

---

## Role Definitions

### Observer

**Scope of Observation:**
- All public and internal data
- No restricted or secret data
- No constitutional data
- No operator audit trails

**Scope of Intervention:**
- None (read-only)

**Authority:**
- Can view any dashboard
- Can export public data
- Can set personal dashboard preferences

**Audit Trail:**
- All view actions logged
- Session duration logged
- Export actions logged

**Typical Operators:** Public stakeholders, partner organizations, read-only users.

---

### Engineer

**Scope of Observation:**
- All public, internal, and restricted data
- Infrastructure and system health data
- No secret data
- No constitutional data

**Scope of Intervention:**
- Can trigger system-level interventions (restart, redeploy, scale)
- Can modify infrastructure configuration
- Cannot modify scientific data or policies

**Authority:**
- All Observer authority
- Can access system health dashboards
- Can trigger engineering alerts
- Can acknowledge/resolve engineering alerts
- Can view engineering audit trails

**Audit Trail:**
- All Observer audit
- All engineering interventions logged with rationale
- Configuration changes logged with diff

**Typical Operators:** DevOps engineers, SREs, infrastructure team.

---

### Scientist

**Scope of Observation:**
- All public, internal, restricted, and secret data
- Full scientific, knowledge, and experimentation data
- No constitutional data

**Scope of Intervention:**
- Can design and trigger experiments
- Can modify hypotheses and knowledge concepts
- Cannot modify system configuration
- Cannot modify policies or constitutions

**Authority:**
- All Observer authority
- Can access full scientific data
- Can create/modify experiments
- Can annotate discoveries
- Can view scientific audit trails

**Audit Trail:**
- All Observer audit
- All scientific actions logged
- Hypothesis changes logged with version history
- Experiment modifications logged

**Typical Operators:** Research scientists, data analysts, domain experts.

---

### Governor

**Scope of Observation:**
- All data, including constitutional data
- Full operator audit trails
- Certification status across all domains

**Scope of Intervention:**
- Can modify policies and governance rules
- Can amend constitution
- Can change certification criteria
- Can override operator actions
- Cannot modify raw observations or events

**Authority:**
- All Observer, Engineer, and Scientist authority
- Can view all operator audit trails
- Can modify governance configuration
- Can invoke emergency procedures
- Can suspend operator accounts

**Audit Trail:**
- All actions logged at highest detail level
- Policy changes require secondary approval (another Governor)
- Constitutional amendments logged with full rationale and alternative considered
- Emergency procedures logged with post-facto review requirement

**Typical Operators:** System governors, ethics board, constitutional authority.

---

### Auditor

**Scope of Observation:**
- All data, including constitutional data and operator audit trails
- Full replay access for any timestamp
- Certification chain for any data product

**Scope of Intervention:**
- None (read-only by design, but can annotate findings)
- Cannot modify any data or configuration

**Authority:**
- Full read access to everything
- Can trigger replay verification at any timestamp
- Can generate audit reports
- Cannot be excluded from any data source (anti-lockout)

**Audit Trail:**
- All auditor actions logged
- Auditor audit trails are append-only and cannot be modified
- Audit findings are permanent

**Typical Operators:** Internal audit team, external compliance auditors.

---

### Administrator

**Scope of Observation:**
- All data, including constitutional data and full operator audit trails

**Scope of Intervention:**
- Can modify any system configuration
- Can manage operator accounts and role assignments
- Can manage API keys and credentials
- Cannot modify raw observations or events
- Cannot modify policies without Governor approval
- Cannot modify audit logs

**Authority:**
- Full system management authority
- Can create/disable operator accounts
- Can rotate credentials
- Can manage storage and retention policies
- Must not have sole authority over any critical governance function

**Audit Trail:**
- All actions logged
- Account changes logged with before/after state
- Credential changes logged (without secrets)
- Role assignments logged with approval chain

**Typical Operators:** Platform administrators.

---

### System

System is the role for automated agents — bots, automation scripts, CI/CD pipelines, scheduled jobs.

**Scope of Observation:**
- Determined by the System role's assigned permissions (must be explicitly configured)
- Restricted to minimum necessary for function

**Scope of Intervention:**
- Determined by automation policy
- All automated interventions require documented procedure
- Automated interventions are limited by rate and scope

**Authority:**
- Only what is explicitly granted in the automation's registered policy
- Must have a documented operating envelope
- Must have a fail-safe mechanism

**Audit Trail:**
- All actions logged with automation identity
- Automation policy is versioned and audited
- Operating envelope violations trigger alerts and automatic suspension

**Typical Operators:**
- `system/telemetry-gateway` — automated event ingestion
- `system/certification-engine` — automated certification checks
- `system/metrics-aggregator` — automated metric computation
- `system/backup-agent` — automated backup
- `system/replay-verifier` — automated replay consistency checks

---

## Cross-Cutting Role Properties

| Property | Observer | Engineer | Scientist | Governor | Auditor | Admin | System |
|----------|----------|----------|-----------|----------|---------|-------|--------|
| May view public data | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Config |
| May view internal data | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Config |
| May view restricted data | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | Config |
| May view secret data | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | Config |
| May view constitutional data | ✗ | ✗ | ✗ | ✓ | ✓ | ✓ | Config |
| May view operator audit trails | ✗ | Own only | Own only | ✓ | ✓ | ✓ | Config |
| May intervene on infrastructure | ✗ | ✓ | ✗ | ✓ | ✗ | ✓ | Config |
| May intervene on science | ✗ | ✗ | ✓ | ✓ | ✗ | ✗ | Config |
| May intervene on governance | ✗ | ✗ | ✗ | ✓ | ✗ | ✗ | Config |
| May modify accounts | ✗ | ✗ | ✗ | With Gov | ✗ | ✓ | Config |
| Requires secondary approval | — | — | — | Policy | — | Config | Config |
| Anti-lockout guaranteed | ✗ | ✗ | ✗ | ✓ | ✓ | ✓ | ✗ |

---

## Role Assignment Rules

| Rule | Description |
|------|-------------|
| **Single Role** | Each operator holds exactly one role at a time. |
| **Role Elevation** | Temporary role elevation is possible but requires: documented reason, time limit, secondary approval. |
| **Least Privilege** | Operators are assigned the minimum role necessary for their function. |
| **Separation of Duties** | No single operator can both intervene and audit the same domain. |
| **Rotation** | Governor and Auditor roles must be rotated periodically (configurable, default 90 days). |
| **System Role Restriction** | System operators cannot be assigned human roles, and vice versa. |
