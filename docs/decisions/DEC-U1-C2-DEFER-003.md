# Decision: Defer C2 Unified Reality Graph Runtime Certification

**Decision ID:** DEC-U1-C2-DEFER-003
**Timestamp:** 2026-08-20
**Authority:** Human operator
**Status:** ACTIVE

## Decision
Defer C2 runtime certification (option 3). Do NOT bootstrap ExecutiveMemory
(option 1). Do NOT downgrade to `~` (option 2).

## C2 Status
`?` BLOCKED — dependency unresolved. Runtime question remains unanswered.

**Do not convert to `~` merely because the dependency is documented.**
Documented-dependency is not runtime-evidence.

## Rationale
- C2 is not independently operable under the tested runtime (`--no-start`).
- Option 1 (bootstrap ExecutiveMemory) is a **runtime mutation / service
  bootstrap**, which per POL-CERT-AUTH-001 is ACTION, not certification, and
  would require its own C14 authorization. Choosing it would mix diagnosis
  with remediation and pollute the causal record.
- Cleaner sequence:

```text
U1 (record finding) → remove cert-auth dependency → U1-C2 remediation
   mission (authorized, if/when chosen) → independent re-probe
```

## Evidence Established
- C2 is NOT standalone-operable under `--no-start`.
- `UnifiedRealityGraph.add_node/3` hard-depends on `ExecutiveMemory`
  (GenServer `:noproc`).
- Guard `rescue _ -> :ok` (unified_reality_graph.ex:325) does not catch
  process exits; the graph process dies. Probe required `trap_exit`.

## Open Design Question (NOT resolved here)
Is C2's hard dependency on ExecutiveMemory a **defect** (should degrade
gracefully) or **by design** (graph legitimately requires memory)? This is a
design decision, not a certification finding. Recorded, not presupposed.

## Lineage
- Triggers future: U1-C2 remediation mission (requires C14 authorization)
