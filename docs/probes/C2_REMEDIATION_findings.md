# C2 Remediation Mission — Evidence Report (C2-REM-001)

**Mission:** C2 Remediation (Unified Reality Graph) · **ID:** C2-REM-001
**Authorization:** `priv/tiannara/authorization/C2_REMEDIATION_MISSION.human.yaml` (AUTHORIZED, operator `schtickman`, signature `mock_test_c2`)
**Executed:** 2026-08-20 · **Result JSON:** `priv/tiannara/probes/results/C2_REMEDIATION_mission_result.json`
**Mode:** ACTION (C14-authorized) — isolated BEAM VMs only; no production mutation; no merge; no adoption.

## Verdict: CANDIDATE_ACCEPTED

> **C2's `ExecutiveMemory` dependency is an INTENTIONAL supervised-runtime invariant (outcome A).** The canonical C2 module (`Tiannara.World.UnifiedRealityGraph`) declares `[:executive_memory, :executive_service_bus]` as CEL service dependencies and is designed to run inside the Kernel's DynamicSupervisor. The C1→C2→C3 causal edge is **restored** by Candidate B (minimal dependency bootstrap) with **zero production code change**, and also functions under the full production supervision tree.

## Gate results

### M1 — Dependency characterization
```
UnifiedRealityGraph (canonical: Tiannara.World.UnifiedRealityGraph)
   ├── CEL ServiceRegistry id=:unified_reality_graph (Tier-3, critical)
   ├── depends_on: [:executive_memory, :executive_service_bus]
   └── Tiannara.CEL.Services.ExecutiveMemory (Tier-0, critical)
         └── depends_on: [:event_store]  →  Tiannara.CEL.Services.EventStore (Tier-0, DETS)
         └── DETS ./cel_memory_v2.dets (fallback: volatile ETS)
Lifecycle: Application.start → CEL Kernel.boot() → BootSequencer → DynamicSupervisor (Tiannara.CEL.ServiceSupervisor)
```
- **Legacy module discovery:** `Tiannara.Graph.UnifiedRealityGraph` (the module U1/U5 probed) is **NOT registered in ServiceRegistry** — it is orphaned. The canonical C2 is `Tiannara.World.UnifiedRealityGraph` (`add_entity/1`), which does not touch ExecutiveMemory at runtime for entity mutations.
- **Intent docs:** `docs/phase3_validation_report.md` codifies the defensive-wrapping intent; the legacy module's `rescue _ -> :ok` (does not catch exits) is the F2 defect.

### M2 — Candidates (both executed in isolated BEAMs)
| Candidate | Topology | Result |
|---|---|---|
| B — minimal bootstrap (safe lazy init) | EventStore → ExecutiveMemory → both graphs, probe-local `Supervisor` | **PASS** — boot 81 ms, all pids registered |
| A — supervised bootstrap | `Application.ensure_all_started(:tiannara)` (production tree) | **PASS functionally** — boot 5.68 s, services registered, C2 works (EOS report caveat in F9) |

Decision: **B** restores the causal edge in isolation with zero production code change; **A** confirms the production-topology intent.

### M3 — Correctness invariants (B run)
- Canonical world state: `add_entity/1` → `get_entity/1` read-back `{:ok, spec}` (single canonical graph, no shadow state).
- Lineage: legacy `add_node/3` → `ExecutiveMemory.record_event/4` → `EventStore.append/2` confirmed — `executive_memory.count()=1`, `event_store.count(:executive_memory)=1`.
- Knowledge consistency: C3 stored `mem-2be80dbee8a8` only on an intact canonical chain (same refusal logic as U5 — no shadow state).
- Failure semantics: measured in M4 (below).
- C14/C15/C16: zero governance/audit code touched.

### M4 — Performance / resource
| Metric | Candidate B | Candidate A |
|---|---|---|
| boot time | 81,715 µs (4 services) | 5,681,868 µs (full tree) |
| memory total | ~50.1 MB | ~105.3 MB |
| ETS tables | 46 | 197 |
| DETS tables | 2 | 10 |
| C2 `add_entity` latency | ~0 µs (hot) / 102 µs | 102 µs |
| legacy `add_node` latency | 15,155 µs (first call, DETS write) | 102 µs |
| C3 append latency | 3,276 µs | 1,536 µs |
| failure recovery | stop ExecutiveMemory (204 µs): both graphs recovered via supervision (one_for_one restart) | legacy graph: **non-graceful** (F2 confirmed: `:noproc` exit kills the graph; no `catch` in `log_mutation`) — canonical graph unaffected |

### M5 — Causal verification (decisive test)
```
C1 event → C2 canonical mutation → C3 persisted knowledge
```
**VERIFIED** — single trace envelope chain `c1_perception → c2_canonical → c3_knowledge`, all phases OK, single trace id lineage. (Envelopes carry `authorization_state.required=true`, granted_by=schtickman.)

### M6 — No automatic adoption
Honored. This mission produced evidence only. **Adoption requires a SEPARATE C14 artifact (C2-ADOPTION-001)** — not created, not requested.

## Findings

### F8 — `ExecutiveMemory.get_lineage/1` crashes on DETS traverse (defect)
`handle_call({:lineage, ...})` uses `:dets.traverse` with a continuation callback whose `{:continue}` return escapes the Enum pipeline (`Protocol.UndefinedError: Enumerable for {:continue}`). Lineage retrieval by correlation id is broken for live tables. Persistence itself is unaffected (`EventStore.count` = 1). Severity: MEDIUM (C7/C15 lineage path).

### F9 — CEL Kernel boot report contradicts live registration (false emergency)
Under full production boot, EOS boot report: `status: failed`, `failed_critical: [unified_world_model, event_store, executive_memory]`, `replay_engine: degraded`, `kernel_state: emergency` — **while all those processes are in fact registered and C2 functions correctly** (duplicate-start/name-clash semantics inside BootSequencer vs other supervisors). This reproduces the historical substrate signals and is a C15/C16 observability concern: the kernel may treat a live system as `:emergency`.

## Decision point (per mission charter)

- **Candidate B passed all gates** → the C2 causal blocker is resolved at the *topology* level (documented invariant), not by code change.
- **Next step for human/C14:** ratify the mission verdict; if adoption of the documented bootstrap topology into production supervision is desired, that is a **separate** C14 action (`C2-ADOPTION-001`).
- C2 matrix disposition (proposal): **R ✓, I ✓, C ✓** under the supervised bootstrap topology (outcome A); standalone-operability is NOT claimed. The DEC-U1-C2-DEFER-003 open question is resolved: defect vs by-design → **by-design (documented supervised-runtime invariant)**.

## Boundaries honored
Isolated VMs only; no production mutation; no merge; temp DETS files removed (declared side effect); no adoption authorized or executed.