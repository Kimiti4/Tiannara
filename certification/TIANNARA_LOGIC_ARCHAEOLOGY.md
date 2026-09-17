# Tiannara Logic Archaeology

Campaign: Remediation Architecture & Epistemic Foundation Certification (READ-ONLY)
Baseline commit: `3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6`
Scope: resolve **MC-002** (new numbering; prior register MC-003 "Logic Substrate")
Method: namespace search, contradiction-site enumeration, cross-reference validation. All paths relative to repo root.

---

## 1. Verdict

| Category | Applicable? | Evidence |
|---|---|---|
| (A) Missing entirely | **Partially** — as a *dedicated substrate* yes; as capability, no | No `lib/tiannara/logic/` namespace; no `Tiannara.Logic` module |
| (B) Exists distributed across codebase | **Yes** | ≥11 independent contradiction-detection implementations, 4 transition validators, 3 invariant aggregators, 2 complementarity invariants |
| (E) Theatrical / broken | **Yes** (partial) | One implementation is semantically broken (`BeliefSystem`); one cross-reference points at a nonexistent module |

**Composite verdict:** (B) distributed + partially theatrical. A logic *kernel* must be extracted and made canonical; it does not need to be invented.

## 2. Real logic sites (verified)

| Site | What it actually does | Integrity |
|---|---|---|
| `lib/tiannara/contradiction/engine.ex:38-100` | Pairwise value-conflict detection over claim structures + resolution FSM (suppress/merge/escalate) | **Sound** — best candidate for kernel core |
| `lib/tiannara/sentinel/verification.ex:307-349` | `find_contradictions/1` over supports/contradicts evidence links | Sound, narrow |
| `lib/tiannara/core/world_model/belief_system.ex:284-356` | Negation-pattern string matching to flag contradictions | **Broken semantics** — syntactic negation ≠ logical negation; produces false positives/negatives |
| Transition validators ×4 (governance/ASC/state machines) | Pre/post-condition checks on state transitions | Sound but mutually inconsistent rule syntaxes |
| Invariant aggregation ×3 (constitutional invariant registry, CEL gates, sentinel) | Conjunction of invariant predicates with differing failure semantics (first-fail vs collect-all) | Partially inconsistent |
| Complementarity invariant ×2 (tensegrity field, CIS) | Mutual-constraint satisfaction checks | Duplicated |

## 3. Broken cross-reference (must-fix)

`lib/tiannara/constitution/registry.ex:118` calls `Graph.Audit.find_contradictions/1` — **module does not exist** anywhere in the tree. Any code path reaching that clause crashes. This is direct evidence that a canonical logic module was assumed by the architecture but never built.

## 4. Proposed kernel boundary (~6 functions)

Extract from `Contradiction.Engine` + `Sentinel.Verification`, delete or delegate the rest:

1. `Logic.Contradiction.detect(claim_a, claim_b) :: :contradiction | :consistent | :unknown`
2. `Logic.Contradiction.from_refutations([refutation]) :: [contradiction]`
3. `Logic.Invariant.check(invariant, world_snapshot) :: :ok | {:violation, term}`
4. `Logic.Rule.evaluate(rule, facts) :: :pass | :fail | :undetermined`
5. `Logic.Transition.valid?(transition, pre_state, post_state) :: boolean`
6. `Logic.Complementarity.holds?(pair, context) :: boolean`

Design constraints:
- Claims carry confidence from the Math/Probability layer → **Logic sits ABOVE Math in the stack**, consumes scored claims, never computes its own confidences.
- Failure semantics standardized (collect-all violations, structured terms) — adopted from the strictest of the three existing invariant aggregators.
- The broken `BeliefSystem` negation matcher is replaced by a delegation to kernel `detect/2`; no behavioral contract is preserved for the broken path.

## 5. Consumers to redirect (inventory at remediation time)

- World-model integrity report generation (currently feeds `DiscoveryScheduler.fetch_integrity_report`, scheduler lines 437–469) → route through kernel.
- Constitution registry audit clause (:118) → becomes real call once kernel exists.
- Sentinel verification, ASC transition validators, CEL gate evaluation → thin adapters over kernel.

## 6. Acceptance tests (proposed)

- L-AT-1: `lib/tiannara/logic/` exists; grep shows ≤1 contradiction-detection engine under `lib/` outside deprecated shims.
- L-AT-2: property tests: `detect(a, b)` symmetric; known-refutation corpus maps to expected contradictions (golden set extracted from Contradiction.Engine tests).
- L-AT-3: `constitution/registry.ex:118` call resolves and returns without crash on fixture registry.
- L-AT-4: BeliefSystem contradiction path delegates to kernel; old negation-matcher deleted; regression suite proves false-positive rate drop on labeled fixtures.
- L-AT-5: all three invariant aggregators produce identical verdicts on a shared 20-case fixture matrix.

## 7. Risks

- **Behavioral change in live loops:** Loop B (discovery) derives research questions from world-model contradictions; kernel adoption will change the question stream. Mitigation: shadow-run kernel alongside old analyzer for N cycles, diff reports before cutover (aligns with AE-series adoption pattern).
- **Over-generalization:** temptation to build full theorem proving. Out of scope per bounded certification; kernel is 6 functions.
- **Circular dependency risk:** Logic→Math only; enforce with compile-time dep check (no `Tiannara.Math` reference inside `logic/` beyond numeric helpers... none permitted).
