# U5/U6 Probe Findings — External Reality Ingress & Propagation

**Audit:** U0 · **Mode:** CERTIFICATION (auth-free per POL-CERT-AUTH-001)
**Contract:** `priv/tiannara/probes/contracts/U5_U6_external_reality_ingress.contract.yaml`
**Contract hash:** `dd416de37d049a929e58759945645b11deecfb6a6b5d32ed53482087fc2d7d14`
**Executed:** 2026-08-20 (two controls: valid signed ingress / tampered ingress)
**Result JSON:** `priv/tiannara/probes/results/U5_U6_external_reality_ingress_result.json`

## Verdict

**PARTIAL_SUCCESS_CAUSAL_BREAK** — exactly as predicted by the contract's
`known_dependencies` clause.

- Valid signed ingress: **C11 → C1 verified**; C2 attempted with the real
  `UnifiedRealityGraph.add_node/3`; causal break recorded honestly; C3 refused
  state on the broken chain (no shadow state).
- Tampered ingress: **REJECTED at the boundary**; C1/C2/C3 skipped; no
  unauthorized side channel.

## Real modules exercised (inside the BEAM, `mix run --no-start`)

| Phase | Module / Function | Result |
|---|---|---|
| C11 Ingress | filesystem payload read + sha256 signature verification + `TiannaraOS.Governance.CapabilityChecker.authorize?/3` (Observatory, `:can_observe` @ `:observability`) | `:ok` |
| C1 Perception | `Tiannara.Sentinel.Activation.Event.new/1` + `Engine.process/1` | ingested (priority `ignore`, causal interpretation, confidence 0.3) |
| C2 Reality Model | `Tiannara.Graph.UnifiedRealityGraph.add_node/3` | `:noproc` ExecutiveMemory exit — **causal break** |
| C3 Knowledge | `Tiannara.Memory.KnowledgeStore` | refused state on broken chain (correct) |

## U5 acceptance items — evidence

1. **Real external boundary exists** — filesystem ingress with signed payload; read-only, Egress forbidden by contract (`external_mutations_allowed: false`).
2. **Input captured with provenance** — source file, payload sha256, signature, receive timestamp recorded in the C11 envelope.
3. **Trace envelope emitted** — 4-phase envelope chain (C11→C1→C2→C3) + rejection envelope; single trace lineage verified.
4. **C14 consulted where required** — Observatory `:can_observe` @ `:observability` → `:ok` at the ingress boundary.
5. **No mock external reality accepted as evidence** — tampered payload (stale signature) REJECTED at C11; hash mismatch verified; no downstream propagation.
6. **Payload cryptographically committed** — sha256 over canonical payload bytes; python-side and BEAM-side hashes matched.
7. **Failure/timeout represented honestly** — C2 `:noproc` exit recorded as `causal_break` in result JSON, envelopes mark `failure_state.detected=true`, `recovery_behavior=record_causal_break_no_mask`.
8. **External input reaches the canonical path, not a shadow path** — C2 is the canonical mutation target and was attempted; `UnifiedWorldModel` shadow state was never touched (no shadow path created).

## Findings

### F5 — Engine.process/1 consumes the shaped map, not the Event struct (C1 boundary contract)
`Tiannara.Sentinel.Activation.Engine.process/1` indexes fields with Access
(`event[:id]`), which fails on the `Event` struct (`Event does not implement the
Access behaviour`). U5 wires `Event.new/1` to validate/normalize the shaped event
and passes the **map** to `Engine.process/1`. This is a concrete C1 boundary
contract: *shaped map in → Event struct out; engine consumes the map form.*
Confirms F1 (atom-key shape requirement) as the ingest-side contract.

### F6 — C2 causal break reconfirmed with fresh runtime evidence
Real `add_node/3` → `GenServer.call(Tiannara.Graph.UnifiedRealityGraph, ..., 5000)`
→ `{:noproc, ...}`: the graph is a supervised GenServer with no standalone path.
This is now the **formal justification for the C2 Remediation Mission** (the
mission itself remains ACTION and requires C14 authorization).

### F7 — Observatory governance consult works standalone
`CapabilityChecker.authorize?/3` with `define_observatory/0` (`:can_observe` @
`:observability`) returned `:ok` with no running supervision tree — the C14
consultation path at the ingress boundary is real, not stubbed.

## Constraints honored

- Auth-free certification; no human authorization required or requested.
- No mutation, no service bootstrap, no external writes (Egress), no adoption.
- Verdict targets integration edges (C11→C1, C1→C2, C2→C3), not whole capabilities.
- C2 not upgraded; not downgraded to `✗` (it is a dependency question, not a defect).

## Proposed matrix updates (await human ratification)

- C11 External Reality Interface — Ingress side: R `✓`, I `✓`, C `✓`; Egress side: `?` (ACTION).
- C2: unchanged (`?`, deferred). C3: re-confirmed. No whole-capability changes.

## Next step

**C2 Remediation Mission** (C14-authorized ACTION): resolve the ExecutiveMemory
dependency question — outcome A (documented + verified supervised bootstrap
topology) or outcome B (repaired standalone independence). Then U7 (Homeostasis,
C12) per the locked sequence.