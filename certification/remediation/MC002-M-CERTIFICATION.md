# MC-002-M: Logic Substrate Mutation Certification

**Gate:** MC-002-M
**Campaign:** Tiannara Remediation + Substrate Integration
**Verdict:** CERTIFIED (BOUNDED)
**Scope:** L4 (kernel) + L1 (delegation) + L2 (theatrical decommission) + L3
(fabricated metrics removal) — L5 (proof/inference) excluded per authorization.
**Date:** 2026-08-29
**Authority:** C14 (`c14_ac`), authorization GRANTED
(`priv/tiannara/authorization/ASC-MC-002-M-LOGIC-MUTATION.human.yaml`)

---

## 1. What was done

1. **L4 — Kernel (`lib/tiannara/logic/`)** — created the six-function canonical
   engine that the entire contradiction/invariant/rule/transition/
   complementarity surface now reduces to: `Logic.Contradiction.{detect/2,
   from_refutations/1}`, `Logic.Invariant.check/2` (+collect-all `check_all/2`),
   `Logic.Rule.evaluate/2`, `Logic.Transition.valid?/3`,
   `Logic.Complementarity.holds?/2`. The kernel sits ABOVE Math: it never
   computes confidence, only reasons over subject/value/timestamp structure
   (`:contradiction | :consistent | :unknown`).
2. **L1 — Delegation to a single engine:**
   - `Contradiction.Engine.detect/1` became a thin shim delegating each pair
     verdict to `Logic.Contradiction.detect/2` (classification/severity/
     confidence/lifecycle stay in Engine — Logic above Math).
   - `Graph.Audit.find_contradictions/1` implemented over the kernel; the
     constitutional probe `registry.ex:118` now resolves (`:ok`).
   - BeliefSystem's fabricated negation/topic matcher deleted; verdicts
     delegated to the kernel (free-text beliefs → `:unknown`, false-positive
     drop).
   - Discovery scheduler `contradiction_pairs/1` rerouted through the kernel.
   - Sentinel `Verification.find_contradictions/3` preserved (real
     evidence-link mechanism; `from_refutations/1` is its map adapter).
3. **L2 — Theatrical decommission:**
   - `CTL.ParadoxResolver.resolve/2` → `{:error, :paradox_resolver_unavailable}`.
   - Nine `Substrate.*` families deleted from disk (+ their untracked scratch
     gauntlet scripts). Only `runtime_atlas.ex` documentation strings remain
     (deferred: `TD-MC002-M-RUNTIME_ATLAS`).
4. **L3 — Fabricated metrics removed:** aggregator no-op clauses for
   `:euf,:gck,:hsv,:mcal,:opc,:oed,:ose,:osk,:cof` deleted; real-emitter
   clauses (`:coherence`, `:iv`) retained.

## 2. Acceptance tests (L-AT)

| Test | Result |
|------|--------|
| L-AT-1 kernel exists; 6 functions; kernel is THE engine (≤1 engine under lib outside deprecated shims) | PASS |
| L-AT-2 `detect/2` symmetric + golden corpus | PASS |
| L-AT-3 `registry.ex:118` resolves; `Audit.find_contradictions/1` non-empty for fixture; probe `:ok` | PASS |
| L-AT-4 BeliefSystem delegates to kernel; false-positive drop | PASS (ros/omcs 7 tests) |
| L-AT-5 kernel `Invariant.check_all/2` collect-all semantics + status invariants (arity-0/arity-1 normalization) | PASS |

**Targeted suites:** `test/tiannara/logic/` (22), `test/tiannara/contradiction/`
(11), `test/tiannara/ctl/`, `test/tiannara/graph/`, `test/tiannara/discovery/`
(39 properties, 181 tests), `test/tiannara/metrics/` — **all PASS**.

## 3. Compile / boot

`mix compile` → "Generated tiannara app" (clean of new warnings).
Deletion of the substrate modules caused no compile error (no live consumer).

## 4. Regression status

- **Full cross-repo suite regression: NOT_EXECUTED** (environment/time) —
  recorded as NOT_EXECUTED, never as PASS. This is the basis for the BOUNDED
  verdict, mirroring MC-001-M.
- Known pre-existing failures NOT attributed to this mutation:
  `constitutional_invariant_suite_test.exs` (untracked test calls nonexistent
  `Sentinel.Authority` / `Research.Authority` modules — infrastructure debt)
  and the documented MC-001-M asc baseline.

## 5. Constraints honored

- L5 (proof/inference) **NOT** mutated.
- No replacement substrate/logic implementation beyond the authorized 6-fn
  kernel.
- No symbolic math / theorem proving introduced.
- REAL contracts preserved: Engine API+lifecycle, Sentinel evidence links,
  Debugger queries, aggregator `push_event/2` interface, Discovery output maps.
- Canonical 20-domain ontology, CanonicalRegistry, AC-001 boundaries untouched.
- `unavailable` ≠ failed ≠ success — always an explicit distinguishable return.

## 6. Certification boundary

Certifies the authorized L4+L1+L2+L3 logic truthfulness mutation based on
static verification (verifier), compile, and passing targeted acceptance tests.
The full-suite regression gap is recorded as NOT_EXECUTED and bounds the
verdict. This gate certifies no new logical capability beyond the six kernel
functions; proof/inference capability remains explicitly out of scope (L5).

## 7. Artifacts

- `priv/tiannara/remediation/contracts/MC002_M_logic_mutation.contract.yaml`
- `priv/tiannara/authorization/ASC-MC-002-M-LOGIC-MUTATION.human.yaml`
- `priv/tiannara/remediation/results/MC002_M_result.json`
- `priv/tiannara/remediation/verifiers/MC002_M_logic_mutation.py`
- `certification/remediation/MC002-M3-THEATRICAL-DECOMMISSION.md`
- `certification/remediation/MC002-M5-METRICS-DECOMMISSION.md`
- `certification/remediation/MC002-M-EVIDENCE-MATRIX.md`
- `certification/remediation/MC002-M-CONSUMER-CONTRACTS.md`
- `certification/remediation/MC002-M-CERTIFICATION.md` (this file)