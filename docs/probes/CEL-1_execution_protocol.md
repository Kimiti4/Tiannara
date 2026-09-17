# CEL-1 Execution Protocol

## Objective
Determine empirically whether the CEL executive can dynamically discover, evaluate, select, govern, and delegate to a provider from live registry state — rather than relying on hardcoded `event_type → handler` or `objective → provider` mappings.

## Frozen Constraints
- Do **not** modify production architecture or implementation.
- Do **not** rewrite `CapabilityRegistry`.
- Do **not** modify `ControlCenter.@subsystems`.
- Do **not** add providers merely to make the test pass.
- Certification is **authorization-free** under `POL-CERT-AUTH-001`.
- Do not mint, modify, or simulate a C14 authorization.
- Do not upgrade capability statuses based on mocks or structural existence.
- Use real repository modules and executable paths only.
- Preserve the finalized contract hash: `9c7dfc1a293e64b5c61fea18d37a7026eaa9fc5bbd749da90733fdf318ee2fc1`.

## Real Integration Points (resolved)
- `Tiannara.CEL.Services.CapabilityRegistry.all_providers/0` — enumerates live providers with `capabilities`, `health`, `workload`
- `Tiannara.CEL.Services.CapabilityRegistry.find_provider/1` — dynamic lookup by capability
- `Tiannara.CEL.Services.MissionDirector.create_mission/3` — mission submission entrypoint
- Hardcoded dispatch detection — `ControlCenter.@subsystems` static list + `CapabilityRegistry` 4-entry map

## Required Causal Chain
```
objective
  ↓
registry_query
  ↓
live provider records
  ↓
candidate_set
  ↓
health / ownership / dependency evaluation
  ↓
provider selection
  ↓
governance_gate
  ↓
delegation
  ↓
resulting mission/provider state
```
`registry_query` must be **causal**, not decorative. The selected provider must demonstrably depend on information returned by the registry.

## Required Tests

**T1 — Novel objective**
Submit an objective whose provider is not directly encoded as an objective→provider mapping.
Prove: objective is submitted; registry is queried; live providers are returned; candidate set is derived from registry information; selection follows candidate evaluation; governance is consulted; delegation follows the governed selection.
A hardcoded `objective → ASC` result is **FAIL**.

**T2 — Missing provider**
Request a capability for which no eligible provider exists.
Expected: `unresolved / unavailable` — No hardcoded fallback and no fabricated provider.

**T3 — Unhealthy provider**
Present an otherwise capable provider whose live health state is unhealthy.
Prove it is excluded/rejected by the selection process.
Expected: `unhealthy provider ≠ eligible delegate`

**T4 — Governance denial**
Allow registry discovery and candidate selection to succeed, then apply a real governance denial.
Expected: `registry → candidate → selection → C14 gate DENY → delegation blocked`
Governance must be causally upstream of consequential delegation.

## Evidence Requirements
For every test capture:
- objective;
- `registry_query`;
- exact provider records returned;
- candidate set;
- ownership;
- health;
- dependency information;
- selection rationale;
- governance result;
- delegation result;
- trace ID;
- provenance;
- payload/state hash where applicable;
- failure/recovery state where applicable.
Do not create evidence files that were not actually produced by execution.

## Verdict Rules
```
PASS
  dynamic registry discovery +
  candidate derivation +
  valid selection +
  governance +
  delegation

PARTIAL
  some required edges proven, others unproven

FAIL
  hardcoded delegation,
  non-causal registry query,
  governance bypass,
  fabricated fallback,
  or equivalent architectural violation

BLOCKED
  real executable integration path cannot be exercised
```
Do not reinterpret `PARTIAL`, `FAIL`, or `BLOCKED` as success.

## Certification/Authorization Boundary
`certification ≠ authorization` — CEL-1 is auth-free per `POL-CERT-AUTH-001`. It must not mint a fake C14 authorization.
