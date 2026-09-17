# U1 Findings — Reality → Knowledge (Metabolism) — REAL MODULE RUN

Date: 2026-08-20
Authorization: ASC-U0-U1-2026-08-20 (operator: schtickman, signed 2026-08-20T03:09:00Z)
Execution: `priv/tiannara/probes/U1_reality_to_knowledge.py` (real modules, `mix run --no-start`, MIX_ENV=test)
Result: **PARTIAL_FAILURE** — C1/C3/C4/C7 demonstrated; C2 blocked by a hard dependency on an unstarted service.
Evidence: `priv/tiannara/probes/results/U1_reality_to_knowledge_result.json` + 4 evidence files in `priv/tiannara/probes/evidence/` (per-phase chain results, payload hash `ff8604e9...`).

## Per-Capability Findings

### C1 Perception / Ingestion — PASS (with boundary contract finding)
- `Tiannara.Sentinel.Activation.Event.new/1` **rejects raw string-keyed JSON** (`KeyError: key "data" not found`). The boundary requires atom-keyed Sentinel event attrs (`:id, :timestamp, :source, :category, :severity, :observation, ...`).
- With a correctly-shaped event map, `Event.new/1` succeeds and **`Engine.process/1` completes end-to-end standalone**: returns `priority: :ignore`, interpretation `"Causal analysis pending"`, confidence 0.3, causal_links built, `crav_triggered: :ok`.
- Finding: ingestion is functional but the raw-JSON → event boundary is an explicit shape contract, not a documented adapter. Real external observations must be shaped before entry.

### C2 Reality Model — BLOCKED (dependency finding)
- `Tiannara.Graph.UnifiedRealityGraph.add_node/3` internally calls `Tiannara.CEL.Services.ExecutiveMemory.record_event/4` → `GenServer.call(ExecutiveMemory, ...)`.
- With no supervision tree (`--no-start`), this raises a **`:noproc` exit**. `log_mutation/3` wraps it in `rescue _ -> :ok` (lib/tiannara/graph/unified_reality_graph.ex:325) — **but `rescue` does not catch exits**, so the exit propagates and kills the graph GenServer (linked exit); `read_back`/`stats` then also fail with `:noproc`.
- Finding: `UnifiedRealityGraph` is **not standalone-operable**; it has an undocumented hard dependency on the ExecutiveMemory service. The `rescue _ -> :ok` guard is ineffective for its stated purpose (exit vs exception).
- Shadow check: `Tiannara.World.UnifiedWorldModel.get_entity/1` unreachable standalone (`:noproc`) — no divergence assertable; recorded as honest `unassessed`, not pass.

### C3 Knowledge / Memory — PASS
- `Tiannara.Memory.KnowledgeStore.open/1` accepted the isolated probe directory; `Artifact.new(:knowledge, ...)` + `append/2` wrote artifact `mem-4bebb8f275f8` (verified via `all/1` read-back, 1 artifact).
- Isolation contract held (probe dir, not production/memory path).

### C4 Epistemic — PASS
- `Tiannara.Epistemic.Node` constructed at stage `:knowledge` (confidence 0.95, disposition `:provisional`, assumptions/unknowns recorded); `Tiannara.Epistemic.View.render_node/1` produced the auditable provenance render.

### C7 Lineage — PASS
- 4 hash-chained `Tiannara.Lineage.Entry` records persisted to `u1_lineage.etf`; `reconstruct/1` + `verify_chain/1` returned **True**; `head_hash` recorded.

## Instrument Verification (passed)
- C14 gate enforced (probe refused unsigned/mock state; run gated on human-signed artifact).
- Payload hash consistent Python↔BEAM (sha256 over identical observation-file bytes).
- Correct lineage walk (C1 root, C2→C1, C3→C2, C4→C3).
- Evidence files physically written and existence-verified.
- Per-phase try/rescue: no probe crash; C2 failure captured as data, not crash.

## Statuses (unchanged — human review required)
C1 `?`, C2 `?`, C3 `~`, C4 `~` — no matrix edits made by the probe. Proposed markers for human ratification: C1 `✓` (with boundary-contract caveat), C3 `✓`, C4 `✓`; C2 **remains `?`** pending decision below.

## Decision Required (human)
C2 follow-up options:
1. **U1b — minimal bootstrap:** start a supervision tree containing only ExecutiveMemory (+ its deps) under the probe, re-run C2 in isolation. Tests the full graph path; risks touching whatever ExecutiveMemory's config points at — requires a fresh authorization note.
2. **Record C2 as `~` documented-dependency** and continue to U4; revisit in the substrate audit where EOS boot failures are already flagged.
3. Defer C2 entirely.

## Constraints Honored
- No production code, instrument, or archive modifications. No audit matrix edits. No rollback. Synthetic input only. Freeze state: unchanged (post-AE-003 open).

## U1 Findings — recorded as observations, not conclusions

### F1 — C1 ingestion boundary contract (integration defect candidate)
`Event.new/1` rejects raw string-keyed JSON. The ingestion boundary enforces an
UNDERTED atom-key shape contract. Flagged against the Engineering Principles
(Explainability, well-defined interfaces). Remediation is a separate authorized
action, not part of certification.

### F2 — C2 rescue guard does not catch exits (runtime behavior)
`rescue _ -> :ok` (unified_reality_graph.ex:325) does not catch process exits.
Under `--no-start`, ExecutiveMemory is `:noproc`, the graph process dies, and the
probe required `trap_exit` to survive. Establishes: C2 is not independently
operable under this runtime config. Whether graceful degradation is REQUIRED is an
open design question (see DEC-U1-C2-DEFER-003), not a certification conclusion.