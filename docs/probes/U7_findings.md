# U7 Findings: Homeostasis & Cognitive Immune System (C12)

Status: SUCCESS (all phases U7-A..U7-E PASS)
Contract: `priv/tiannara/probes/contracts/U7_homeostasis.contract.yaml`
Hash: `28eb43ab36fd8a066416b622fd5eda092be7e519ea38884c17ca57d6116aacb8`
Result: `priv/tiannara/probes/results/U7_homeostasis_result.json`
Evidence: `priv/tiannara/probes/evidence/U7_*.json`

Bounded proposition (verbatim):
> Under this tested execution path, C12 accurately detects injected faults and
> state anomalies (including F9 false-emergency signals) without executing
> unauthorized corrective mutations outside the isolated test harness.

## Summary

All five test phases passed:

| Phase | Claim | Evidence |
|---|---|---|
| U7-A | Healthy-state detection | Test topology (Metrics.Aggregator, EventStore, ExecutiveMemory, World.UnifiedRealityGraph, CIS.Supervisor) all up; `ImmuneDecisionEngine.evaluate(:baseline, 0.1)` → `:monitor`; `CIS.validate_plan` → ok; classification **HEALTHY** |
| U7-B | Fault detection | `Supervisor.terminate_child/2` (child-id form) killed ExecutiveMemory in 102µs; `Process.whereis` → nil; direct `ExecutiveMemory.count()` → `:noproc`; measured severity 0.8 → `ImmuneDecisionEngine.evaluate` → **quarantine**; classification **FAILED/DEGRADED** |
| U7-C | Recovery observation | `RegulationExecutor.execute(:restart, ...)` → `:ok` (log-only, no mutation authority); test-harness `restart_child/2` → new pid in 1126µs; service restored; canonical state preserved (`add_entity` ok); EventStore intact (count 0, no corruption) |
| U7-D | False-emergency resistance | Full production boot (`ensure_all_started`) 24.9s: `Kernel.boot_report()` claims `failed_critical: [unified_world_model, event_store, executive_memory]`, `runtime_state()` → `emergency` — while all three services are **actually live** (whereis). No recovery action triggered from bad telemetry. **F9 reproduced as test input and correctly resisted** |
| U7-E | Autonomy boundary | Observation ≠ authorization. All recovery activity confined to the isolated test topology under the declared contract (`test_topology_bootstrap_allowed`, `test_fault_injection_allowed`). No production mutation, no C14 bypass; `production_mutation_allowed`/`production_service_bootstrap_allowed`/`production_adoption_allowed` all false and enforced |

## Findings

### F10: CollapsePredictor.assess_risk/1 returns random telemetry (NEW — open defect)
`Tiannara.CIS.CollapsePredictor.assess_risk(:reality_graph)` returned
`collapse_risk: 0.2489...` — a uniform random draw in 0..0.3, with no dependency
on any measured state (healthy baseline, no injected fault). Risk assessments
are therefore not grounded in telemetry; any consumer of `collapse_risk` would
receive noise. Severity in U7-B was derived by the test harness from real
measurement (process absence + `:noproc`), not from CIS telemetry — the honest
labeling required by the contract.

### F11: CIS.Supervisor is not in the production supervision tree (NEW — open defect)
Full-mode run (`Application.ensure_all_started(:tiannara)`): `Process.whereis(Tiannara.CIS.Supervisor)` → `nil`. The C12 machinery exists and is exercised in test topologies, but is not started under production supervision — so the immune system would not observe or respond to real production faults. This mirrors the historical "service present but not wired" pattern (cf. legacy graph, F2).

### F9 (carried): reproduced and resisted, not patched
EOS `boot_report()`/`runtime_state()` claim `failed`/`emergency` for
executive_memory, event_store, and unified_world_model while all are live.
U7-D passed BECAUSE the test harness relied on direct probes (whereis,
`:noproc`), not on the EOS report — i.e. the system's claimed telemetry is
unreliable and was correctly treated as such. F9 remains open; per directive it
was used as test input, not patched.

### F8 (carried): not exercised by U7 (lineage persistence verified indirectly)
F8 (`ExecutiveMemory.get_lineage/1` crash on `:dets.traverse` continuation) was
not directly re-triggered; lineage preservation was evidenced via EventStore
intactness. F8 disposition follows in the locked sequence.

## Defects for disposition

| ID | Defect | Status |
|---|---|---|
| F8 | `ExecutiveMemory.get_lineage/1` crashes on `:dets.traverse` continuation | open — carried |
| F9 | EOS boot report false emergency while services are live | open — carried (resisted in U7-D) |
| F10 | `CollapsePredictor.assess_risk/1` random, not telemetry-derived | NEW — open |
| F11 | `CIS.Supervisor` not in production supervision tree | NEW — open |

## Constitutional compliance notes

- Fault injection was bounded, declared in the contract, and confined to the
  isolated test topology.
- Recovery was observed, not executed by certification: `RegulationExecutor`
  is log-only, and the actual `restart_child/2` was performed by the test
  harness under `test_topology_bootstrap_allowed`.
- No C14 authorization artifact was minted or implied by this probe; no
  production mutation occurred; C2-ADOPTION-001 remains uncreated.
- One minor encoding bug fixed during execution: chain `to_jsonable/2` converted
  Elixir booleans (atoms) to strings, breaking boolean checks; now emits real
  booleans (`is_boolean/1` clause before the atom clause).