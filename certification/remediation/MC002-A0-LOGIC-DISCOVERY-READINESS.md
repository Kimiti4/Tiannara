# MC-002-A0 — Logic Discovery Readiness

**Gate:** MC-002-A0 (Observational) — READ-ONLY

Pipeline: Representation → Logical transformation → Inference → Hypothesis
generation → Prediction → Verification → Evidence integration.

## Stage-by-stage truth assessment

| Stage | Class | Evidence / explanation |
|-------|-------|------------------------|
| **Representation** | **REAL/PARTIAL** | Graph substrate is real (`graph/*.ex`; `Graph.Behaviour`, `Graph.Audit` walkers). Belief representation (`belief_system.ex`) is real but its conflict matcher is broken. No symbolic representation layer for formulas/terms. |
| **Logical transformation** | **PARTIAL** | Only structured claim/evidence transformations (`Engine.detect`, `Sentinel.find_contradictions`). No rewriting/term manipulation. |
| **Inference** | **PARTIAL** | Evidence-link inference (Sentinel, `verification.ex:307-349`) is real but narrow; no general inference engine, no deduction, no entailment. |
| **Hypothesis generation** | **PARTIAL** | `DiscoveryScheduler.run_cycle` produces research questions from gaps+contradictions (`discovery_scheduler.ex:252-289`); `EpistemicSeeder` produces seeded reports (`epistemic_seeder.ex:241`). But the logic under it (ContradictionAnalyzer + BeliefSystem) is partially heuristic/broken — so the question stream is partially unreliable. |
| **Prediction** | **PARTIAL/NO** | No general prediction stage keyed to logic; discovery score exists (`DiscoveryScore.composite` at `discovery_scheduler.ex:287`). No attached falsifiable logical predictions. |
| **Verification** | **PARTIAL** | Sentinel evidence assessment is real; proof/form verification is UNAVAILABLE; substrate "verification" is theatrical. |
| **Evidence integration** | **REAL** | Evidence records with `contradicts`/`supports` links, confidence, decay (`sentinel/verification.ex:300-305`) are genuinely computed and stored. |

## Autonomous logical discovery readiness (A0.9)

**NOT READY.** The pipeline exists only as a Sequence of partially-real, partially
broken, partially theatrical stages. In particular:

1. No inference/entailment engine → no sound logical discovery primitive.
2. The contradiction stage that feeds hypothesis generation is unreliable
   (broken BeliefSystem) and heuristic (ContradictionAnalyzer).
3. No proof layer → no candidate-soundness check.
4. No symbolic representation → no manipulation of logical structures.

A bounded conclusion: Tiannara can do **evidence-based discovery** (REAL, from
Sentinel + DiscoveryScheduler), but **not sound autonomous logical discovery**. The
latter requires the canonical kernel (a mutation, not performed here) before it can
be truthfully claimed.

## Readiness gate mapping to the vision

Per the campaign's "Not ready" is honest reporting: if MC-002 later adds discovery
infrastructure, it must rest on the sound kernel (L4 mutation), not on the
currently duplicated/heuristic/theatrical logic sites.