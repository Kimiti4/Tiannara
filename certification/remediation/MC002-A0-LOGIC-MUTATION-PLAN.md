# MC-002-A0 — Logic Mutation Recommendations

**Gate:** MC-002-A0 (Observational) — READ-ONLY
**These are RECOMMENDATIONS ONLY. No authorization created. No production mutation performed.**

## Recommended mutation groups (future, in dependency order)

| ID | Name | Content | Seed evidence |
|----|------|---------|---------------|
| **L4** | Canonical logic substrate establishment | Extract ~6-function `lib/tiannara/logic/` kernel from sound sites (`Contradiction.Engine`, `Sentinel.Verification`, `Graph.Audit`): `Contradiction.detect/2`, `Contradiction.from_refutations/1`, `Invariant.check/2`, `Rule.evaluate/3`, `Transition.valid?/3`, `Complementarity.holds?/3`. Enforce Logic-sits-ABOVE-Math (consumes scored claims; no own confidence computation). | `TIANNARA_LOGIC_ARCHAEOLOGY.md:35-49`; sound sites verified REAL |
| **L1** | Duplicate resolution | Delegate all ≥5 contradiction sites to the kernel; remove divergent implementations; single semantics + collect-all violation reporting. | inventory; architecture |
| **L2** | Theatrical logic decommission | Replace `CTL.ParadoxResolver`, `Substrate.GCK.*`, `OSK.*`, `MCAL.*`, `COF/EUF/OPC/OSE/HSV` detectors with unavailable/removed rather than `:ok`+metric-nonsense. | truth classification |
| **L3** | Fabricated logical-metric removal | Remove/adjust the hardcoded `Aggregator.push_event` fabrications in substrate logic modules (mirror MC-001-M5 physics.metrics pattern). | truth classification (F6) |
| **L5** | Proof/inference infrastructure | (Recommendation only, NOT in the bounded kernel scope.) Symbolic representation + proof object/checker + a real consistency/entailment primitive; prerequisites for formal verification claim. Earmarked as separate future gate, NOT MC-002 scope | inventory; readiness |

## Acceptance-test boundary (L-AT-1..5, from archaeology §6, NOT executed here)

- L-AT-1: `lib/tiannara/logic/` exists; ≤1 contradiction engine outside shims.
- L-AT-2: `detect(a,b)` symmetric; golden corpus maps to expected contradictions.
- L-AT-3: `constitution/registry.ex:118` resolves without crash.
- L-AT-4: BeliefSystem delegates to kernel; old matcher deleted; false-positive rate drops on labeled fixtures.
- L-AT-5: invariant aggregators agree on shared 20-case fixture matrix.

## Shadow-run requirement

Because contradictions feed Loop B question-stream (`discovery_scheduler.ex:259-267`),
any L1/L4 cutover must shadow-run the kernel against the old analyzer for N cycles
and diff reports before cutover. This is a precondition, not optional.

## Explicitly OUT of MC-002 scope

- Full theorem proving / SAT/SMT / formal verification — NO layer currently.
- "Mathematics becomes an object of discovery" / Constitutional-Mathematics
  discovery engines (knowledge graph, conjecture engine, meta-mathematics observatory,
  Millennium machinery) — none exist in code; they are a design direction, NOT deferred
  debt with a codebase; they must NOT be built on this substrate until L4/L2/L3 land.

## Vision-gap note (evidence-backed)

The broader "Autonomous Mathematical Discovery" vision (per the campaign's side
conversation) has NO implemented sites in this repository (proof layer: absent;
conjecture engine: absent; meta-math observatory: absent). Documented here as a
foundation gap: building it now would place new apparent capability on the current
duplicated/heuristic/theatrical logic — a direct violation of the governing
principle "fix the epistemic substrate before expanding apparent intelligence."

## Do not open

MC-002 mutation gate stays CLOSED. It opens only on a separate human-authorized
ASC record, after this reconciliation is reviewed.