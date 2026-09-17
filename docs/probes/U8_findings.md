# U8 Findings: Continuity & Civilizational Memory (C15)

Status: SUCCESS (U8-1..U8-4 all PASS)
Contract: `priv/tiannara/probes/contracts/U8_continuity.contract.yaml`
Hash: `f8066b67ff0299048845373fec88c6667603c4fdece03df936a56f36db035085`
Result: `priv/tiannara/probes/results/U8_continuity_result.json`
Evidence: `priv/tiannara/probes/evidence/U8_*.json` + `u8_chain_*/` (incl. surviving knowledge store `.etf` artifacts)

Bounded proposition (verbatim):
> Under a tested failure and recovery cycle, the system preserves canonical
> identity and causal history. Where continuity cannot be recovered (e.g., F8
> lineage retrieval crash), the system explicitly reports the break rather
> than fabricating a plausible-looking history.

## Decisive chain exercised

```
S0 ── E (record_decision, corr=u8_9b5561...) ── K (Artifact mem-22703aefa660, lineage=[corr])
  └─ Process.exit(sup, :kill)  [all 3 services confirmed nil post-kill]
S1 ── fresh topology + reopened KnowledgeStore (same dir)
  └─ lineage attempt (F8 crash window)
```

## The four questions

| Question | Verdict | Evidence |
|---|---|---|
| U8-1 Identity | **PASS** | Event id identical pre/post recovery (`mem_fc71ac45db255750`); entity id retained in payload (`entity_bf3ece62bbf7`); recovered from durable EventStore via `read_topic/1`. **Honest caveat:** canonical C2 digraph lookup returned `{:error, :not_found}` post-recovery — the in-memory representation is volatile; identity survives in the durable event stream, not in the graph |
| U8-2 Causality | **PASS** | Exactly 1 matching event at S0 and at S1 (no duplicates); `latest_offset` unchanged (1 → 1, no re-append); `replay/3` traces to original event; no lost evidence |
| U8-3 Epistemic continuity | **PASS** | Knowledge artifact survives file-backed store (1 artifact, same id, lineage `[u8_9b55...]` resolves to the surviving causal event); no orphaned knowledge, no fabricated entries |
| U8-4 Recovery honesty | **PASS** | `get_lineage/1` triggered F8 crash; crash caught and reported explicitly (no empty list, no plausible-looking history) — `honest_break_reported: true`. Uncertainty not hidden |

## Findings

### F12 (NEW — health telemetry defect, likely F9 root contributor)
`EventStore.healthy?/0` and `ExecutiveMemory.health/0` returned **false / :unhealthy on a fully healthy, freshly booted topology** (`event_store.healthy? → false`, `executive_memory.health → :unhealthy`) while `:dets.info/1` showed both tables open and serving. Root cause: both predicates match `{:ok, _}` against `:dets.info/1`, but current OTP returns the info **list directly** (no `{:ok, _}` wrapper) — the match never succeeds. Health checks are therefore permanently negative, independent of actual state. This is a **false-negative telemetry defect** in the same family as F9 (unreliable state signals) and likely a root contributor to the F9 false-emergency boot report (the EOS report flags these same services). Reconfirmed across the diagnostic run (`priv/tiannara/probes/diag_dets.exs`) before kill AND after recovery.

### F8 (carried — root cause now precisely identified)
`get_lineage/1` crashes with `Protocol.UndefinedError (protocol: Enumerable, value: {:continue})` — the `{:continue}` skip-tuples returned by the `:dets.traverse` callback leak into the traversal result and are later enumerated as data. `find_lessons/1` shares the same skip pattern (same bug family); `snapshot/0` (no skip branch) works. Break was reported honestly by the harness — F8 remains OPEN (lineage is persisted but not retrievable).

### Volatile counter (honest note, not a defect per se)
`ExecutiveMemory.count/0` returns the in-memory counter (0 after recovery) while DETS holds the actual events (7 rows) — count is a runtime counter, not a durable query. Offset-based truth lives in EventStore.

## Defects for disposition

| ID | Defect | Status |
|---|---|---|
| F8 | `get_lineage/1` (and `find_lessons/1`) crash — `{:continue}` leak; lineage persisted but not retrievable | OPEN — root cause identified |
| F9 | EOS boot report false emergency while services live | OPEN — F12 likely contributor |
| F10 | `CollapsePredictor.assess_risk/1` random, not telemetry-derived | OPEN / HIGH PRIORITY (unchanged) |
| F11 | `CIS.Supervisor` absent from production tree | OPEN / ARCHITECTURAL (unchanged) |
| F12 | Health checks (`healthy?/0`, `health/0`) permanently negative — stale `{:ok,_}` match on `:dets.info/1` | NEW — OPEN |

## Constitutional compliance notes

- Fault injection = `Process.exit(sup, :kill)` on the isolated test topology; `test_state_corruption_allowed: false` honored (no DETS corruption; `:kill` closes tables cleanly).
- Recovery was observed; the harness executed only the restart of the disposable topology under `test_topology_bootstrap_allowed`.
- No production mutation, no authorization artifact minted, no adoption; F8/F10/F11 not remediated during U8 (per directive).
- F8 was a first-class observation (U8-4), not a prerequisite remediation — executed exactly as directed.