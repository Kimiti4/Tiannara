# MC-002-A0 — Logic Truth Classification

**Gate:** MC-002-A0 (Observational) — READ-ONLY
**Standard:** a capability is REAL only when its implementation and execution
evidence justify it. Passing a test of a theatrical implementation remains
theatrical evidence. Absence of evidence is recorded UNKNOWN/NOT_EXECUTED, never
converted into evidence of absence except where static absence is definitive (e.g. no function defined).

## Classification Matrix

| Capability | Module | Truth Class | Evidence (file:line) |
|-----------|--------|-------------|----------------------|
| lineage | Graph.Audit.lineage/2 | **REAL** | `lib/tiannara/graph/audit.ex:11-16` |
| blast-radius | Graph.Audit.blast_radius/2 | **REAL** | `lib/tiannara/graph/audit.ex:19-24` |
| cycle detection | Graph.Audit.has_cycle?/1 | **REAL** | `lib/tiannara/graph/audit.ex:27-31` |
| pairwise conflict detection | Contradiction.Engine.detect/1 | **REAL** (bounded: value-conflict only, no entailment) | `lib/tiannara/contradiction/engine.ex:38-48` |
| evidence-link contradiction | Sentinel.Verification (private /3) | **REAL** (bounded, private) | `lib/tiannara/sentinel/verification.ex:307-349` |
| audit queries | Epistemic.Debugger /1,/2 | **REAL** (narrow) | `lib/tiannara/epistemic/debugger.ex:123-137` |
| contradiction ranking | Discovery.ContradictionAnalyzer | **PARTIAL** (impact is heuristic estimate) | `lib/tiannara/discovery/contradiction_analyzer.ex` |
| "find_contradictions" at constitution/registry:118 | Audit (absent fn) | **NO / BROKEN** (`UndefinedFunctionError`) | `lib/tiannara/constitution/registry.ex:118` |
| "paradox resolution" | CTL.ParadoxResolver | **THEATRICAL** | `lib/tiannara/ctl/paradox_resolver.ex:7-24` |
| "contradiction/axiom detection & repair" | Substrate.GCK.* | **THEATRICAL** | `lib/tiannara/substrate/gck.ex` |
| "identity equivalence" | OSK.IdentityEquivalence | **THEATRICAL** | `lib/tiannara/substrate/osk.ex:85-89` |
| "continuity audit/paradox suppression" | OSK.ContinuityAuditor | **THEATRICAL** | `lib/tiannara/substrate/osk.ex` |
| "alternative causality sandbox" | Substrate.MCAL.* | **THEATRICAL** | `lib/tiannara/substrate/mcal.ex` |
| substrate detectors (cof/euf/opc/ose/hsv) | Substrate.* | **THEATRICAL** | `lib/tiannara/substrate/{cof,euf,opc,ose,hsv}.ex` |
| propositional/predicate inference engine | — | **NO** | no namespace/module |
| symbolic rewriting | — | **NO** | no dedicated layer |
| proof construction | — | **NO** | `check_proof`/`verify_proof`: 0 |
| proof checking | — | **NO** | `check_proof`: 0 |
| theorem proving | — | **NO** | no `*Prover` module |
| SAT/SMT integration | — | **NO** | no Z3/CVC; "SAT" hits are word-substring false positives |
| formal verification | Decommissioned | **UNAVAILABLE** | `lib/tiannara/foundations/formal_verification.ex:4-6` |

## Duplicate detection (A0.2 DUPLICATE)

Contradiction-detection is implemented in **≥5 distinct places** without a shared
kernel, each with diverging semantics:
1. `Contradiction.Engine.detect/1` (pairwise value conflicts) — sound
2. `Sentinel.Verification.find_contradictions/3` (evidence links) — sound, private
3. `Epistemic.Debugger.find_contradictions/1` (node-state filter) — narrow
4. `Discovery.ContradictionAnalyzer` (classification/ranking) — heuristic
5. `BeliefSystem` (negation keyword matching) — broken
Plus 2 conflict resolvers (`world/conflict_resolver.ex`, `stabilization/ocm/conflict_resolver.ex`)
and multiple invariant aggregators. This is **DUPLICATE** with no canonical substrate.

## Capability-inflation findings (A0.6)

| Lower capability | Presented / nameable as | Evidence |
|------------------|------------------------|----------|
| Boolean flag read (`:contradicts_base`) | "ParadoxResolver" | `ctl/paradox_resolver.ex:27-29` |
| Keyword substring match | "contradiction detection" | `belief_system.ex:345-356` |
| Logger + hardcoded metric | "contradiction detection" / "verification" / "consistency check" | `substrate/*.ex` |
| Unconditional `:ok` | "formal identity equivalence" | `osk.ex:85-89` |

## Summary counts

- REAL: 6 (L1–L6)
- PARTIAL: 1
- THEATRICAL: 8 (T1…, substrate modules)
- FABRICATED: overlaps THEATRICAL for substrate metric push_event values (counted under THEATRICAL)
- DUPLICATE: 1 group (contradiction detection, ≥5 impls)
- NO: proof/layer categories
- UNKNOWN: runtime reachability of some paths (NOT_EXECUTED)
