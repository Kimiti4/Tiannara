# Decision: AE-010 Closure — All U0 Blockers Cleared, CEL-1 Gate Open

**Decision ID:** DEC-AE-010-CLOSURE
**Timestamp:** 2026-08-22
**Authority:** Human operator (via ASC-AE-010-ADOPTION.human.yaml)
**Status:** CLOSED (ADOPTED)

## Resolution
F13 (duplicate ownership) is remediated and adopted.
`DiscoveryEngine`/`Scheduler` removed from `ControlCenter.@subsystems`;
`DiscoverySupervisor` is sole owner of the Discovery subtree.
`DiscoveryMetrics` is now resident; `DiscoverySupervisor.health() == :healthy`;
EOS `ready`/`operational`, `failed_critical == []`.

## All Prior Blockers Cleared
| Finding | Status |
|---------|--------|
| F8  (lineage retrieval)     | ✅ RESOLVED |
| F9  (false emergency)       | ✅ RESOLVED |
| F10 (epistemic grounding)   | ✅ RESOLVED |
| F11 (CIS residency)         | ✅ RESOLVED |
| F12 (DETS health contract)  | ✅ RESOLVED |
| F13 (duplicate ownership)   | ✅ RESOLVED |

## Architectural Boundary Crossed
- **Before:** "Can the organs function?" (capability probes U1–U8, AE-004→010)
- **Now:** "Can the executive dynamically coordinate the organs?" (CEL-1)
- **Next:** "Can the organism act on reality and learn from the consequence?" (C11 egress + E2E)

## CEL-1 Gate: OPEN
Preconditions satisfied: AE-010 adopted, F13 closed, topology clean,
EOS ready, discovery healthy, CIS resident, grounded risk, honest lineage.
CEL-1 (Registry-Driven Executive Delegation) is now authorized to begin.

## Organizing Frame: Seven Capability Layers
| Layer | Contents | Status |
|-------|----------|--------|
| 0 Epistemic substrate | Mathematics, Logic, Information | substrate-to-be (not a domain) |
| 1 Reality | C11 → C1 → C2 | demonstrated (egress gap) |
| 2 Cognition | C3 → C4 → C5 → C6 | C3/C4 strong; C5/C6 need probes |
| 3 Intelligence/Engineering | C8 → C10 → C9 ASC | ASC = software-engineering civilization, not the center |
| 4 Executive | CEL: Registry, Mission Director, Resource Governor | **CEL-1 target** |
| 5 Homeostasis + Evolution | C12–C17 | conditionally demonstrated |
| 6 External agency | C11 egress closed loop | critical remaining gap |

## Locked Evolution Sequence
```text
1  CEL-1                    registry-driven delegation
2  C5 probe                 experimentation actually operates
3  C6 probe                 autonomous discovery/research
4  C10 probe                engineering intelligence
5  C17 probe                meta-scientific prioritization
6  C11 egress               governed external action + feedback
7  End-to-end mission       organism operates as one system
8  Constitutional Math v1   universal mathematical substrate (discoverable via CEL)
9  Long-horizon execution   days → weeks → months
10 Production pilot         real objective against real external reality
```
Do NOT expand domains/REA/civilization layers before this sequence runs.
