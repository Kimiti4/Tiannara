# U1x-R2 Remediation — Harness Wiring Failure (Live CapabilityGraph)

**Classification:** HARNESS_WIRING_FAILURE (not an organism failure).
**Date:** 2026-08-23

## Previous wiring (incorrect)
- Helper discovery adapter `registry_find_by_task` delegated to `CapabilityRegistry.find_provider`.
- `CapabilityRegistry` is NOT started in the tested topology (it is `nil`).
- The 4-entry static map in `CapabilityRegistry` is a STUB, not the live substrate.

## Actual live discovery mechanism
- `Tiannara.CEL.Services.CapabilityGraph` (capability_graph.ex:82).
- Discovery APIs: `find_optimal_provider`, `providers_of`.
- Live graph: 6 subsystems, 19 capabilities.

## Exact root cause
- The helper queried the wrong subsystem → `found:false` (empty candidate_set).
- Selection had no provider → no-hardcoded check failed; math never invoked.
- R9/R10/R13 were therefore INVALID tests of organism executive discovery.

## Helper change (bounded)
Replace ONLY the discovery adapter so discovery delegates to the live
`CapabilityGraph`. No parallel registry abstraction. No hardcoded provider map.
No objective-specific routing.

## Architecture NOT changed
- No production topology mutation.
- `CapabilityRegistry` is NOT started to satisfy the probe.
- No math-domain expansion.
- `bayes_update/3` implementation untouched.

## New topology finding (requires C14)
CEL-2 registered `constitutional_mathematics` in the STUB `CapabilityRegistry`,
not the live `CapabilityGraph`. For the positive math path to be discoverable,
the capability must be registered in the SAME live graph used for discovery.
That is a graph MUTATION → requires C14 authorization
(`ASC-U1X-R2-GRAPH-REGISTRATION.human.yaml`) BEFORE applying. STOP until authorized.

## Authorization boundary
- Harness repair (helper) = no authorization needed (not a production change).
- Graph registration of `constitutional_mathematics` = C14-gated ACTION.
- No production adoption without a separate adoption artifact.

## Before / after discovery path
```text
BEFORE: objective -> CapabilityRegistry.find_provider  (nil / not started) -> found:false
AFTER : objective -> CapabilityGraph.find_optimal_provider/providers_of (live) -> real result
```
