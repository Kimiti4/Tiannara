# Phase 16.X — Constitutional Architecture Audit

**Audit Phase:** 16.X.0 (Architecture Review)  
**Date:** 2000-01-01  
**Auditor:** Constitutional Research Council  
**Documents Audited:** MATHEMATICS_ARCHITECTURE.md, SYMBOLIC_REASONING_ARCHITECTURE.md, MATHEMATICAL_DISCOVERY_STACK.md, PROOF_ENGINE_ARCHITECTURE.md, FORMAL_VERIFICATION_ARCHITECTURE.md

---

## Verdict: **PASS WITH OBSERVATIONS**

All 7 audit categories pass. 6 observations and 1 flag were identified that must be resolved before Phase 16.X.05 freeze.

---

## 1. Ownership Audit — PASS

| Entity | Owner | Status |
|--------|-------|--------|
| Mathematics Architecture | Constitutional Research Council | PASS |
| Symbolic Engine (X.3) | Constitutional Research Council | PASS |
| Proof Engine (X.4) | Constitutional Research Council | PASS |
| Conjecture Engine (X.5) | Constitutional Research Council | PASS |
| Verification Engine (X.6) | Constitutional Research Council | PASS |
| Mathematics Observatory (X.7) | Constitutional Research Council | PASS |
| Mathematics Replay | Constitutional Research Council | PASS |
| Mathematics Archaeology | Constitutional Research Council | PASS |
| Mathematical Knowledge Graph (X.2) | Constitutional Research Council | PASS |
| Mathematical Ontology (X.1) | Constitutional Research Council | PASS |
| Mathematical Validation (X.95) | Constitutional Research Council | PASS |
| Independent Audit (X.96) | Constitutional Research Council | PASS |
| Long-Horizon (X.97) | Constitutional Research Council | PASS |
| Readiness (X.98) | Constitutional Research Council | PASS |
| Certification (X.999) | Constitutional Research Council | PASS |

**Finding:** The ownership model follows Phase 16 convention — single top-level owner (Constitutional Research Council) owns all mathematics sub-phases. No overlapping authority exists. During the absorption epoch, old modules (e.g., `CategoryTheoreticValidator` in `tiannara_runtime/kernel/`) retain their prior owners until formal deprecation; the architecture acknowledges this explicitly.

**Recommendation:** None required. Ownership is clean.

---

## 2. Replay Audit — PASS

| Object | Replay Requirements | Status |
|--------|---------------------|--------|
| Axiom | Content hash + axiom set ID → full statement | PASS |
| Definition | Content hash + dependency chain → full definition | PASS |
| Conjecture | KG entry + generating context → full conjecture | PASS |
| Lemma | Replayed via proof replay (Proof ID + Conjecture ID + Axiom Set Hash) | PASS |
| **Proof** | `Proof ID + Conjecture ID + Axiom Set Hash` → replay each step through Symbolic Engine → `{:ok, :verified}` or `{:error, reason}` | PASS |
| **Theorem** | Proof hash + dependencies → full theorem statement | PASS |
| **Assertion** | `System Model Hash + Property + Assertion Hash` → reconstruct proof → re-check constraints | PASS |
| Algorithm | Theorem provenance + implementation complexity | PASS |
| SymbolicExpression | Input expression + Domain + RuleSet hash → replay rewrite sequence → output hash | PASS |

**Finding:** Every object has an explicit replay contract requiring only immutable artifacts (ledger, hashes, dependencies, deterministic context). No runtime memory access required. The replay patterns mirror Phase 16.2 conventions.

**Recommendation:** Add a cross-reference from each replay contract to Phase 16.2's 3-level replay model (Level 1: Hash Equality, Level 2: Semantic Equality, Level 3: Structural Pipeline Equality) for consistency.

---

## 3. Archaeology Audit — PASS (2 observations)

**Required:** Every mathematical artifact answers: why does it exist, which conjecture produced it, which definitions were required, which assumptions remain, which applications depend on it, which scientific discoveries consume it.

**Documents checked:**
- MATHEMATICS_ARCHITECTURE.md §3 requires archaeology record with: origin, purpose, owner, dependencies, lineage. PASS.
- MATHEMATICAL_DISCOVERY_STACK.md specifies application-level archaeology. PASS.
- PROOF_ENGINE_ARCHITECTURE.md includes `ArchaeologyRecord` in `Proof.metadata`. PASS concept, but:
  - **Observation A: `ArchaeologyRecord` type is referenced but never defined.** The MATHEMATICS_ARCHITECTURE.md lists archaeology as a requirement but the struct definition `%ArchaeologyRecord{origin, purpose, owner, dependencies, lineage}` is not frozen anywhere. Must be defined in Phase 16.X.05 freeze.
  - **Observation B: `SymbolicExpression.metadata` is opaque.** Documented as "archaeology, provenance, domain" but minimum required fields are not specified. The struct at SYMBOLIC_REASONING_ARCHITECTURE.md:94-100 shows `:metadata` as a catch-all map. Should commit to minimum archaeology fields.

**Recommendations:**
1. Define `ArchaeologyRecord` struct as a frozen schema in Phase 16.X.05.
2. Specify minimum archaeology fields for `SymbolicExpression.metadata` in the symbolic engine freeze.

---

## 4. Determinism Audit — PASS (2 observations)

| Component | Determinism Mechanism | Status |
|-----------|----------------------|--------|
| **Rewrite ordering** | Rule sets sorted by rule hash. Leftmost innermost, first match wins. Tie-breaking by rule hash. | PASS |
| **Proof ordering** | Proof steps are sequentially ordered. Self-verification replays each step deterministically. | PASS |
| **Graph traversal** | Not explicitly specified | OBSERVATION |
| **Dependency sorting** | Not explicitly specified | OBSERVATION |
| **Serialization** | Canonical form: sorted children, normalized operators, explicit parentheses. blake3 hashing. | PASS |
| **No hidden randomness** | All decisions from content-addressed seeds. No wall clock, network, or system state. | PASS |

**Observations:**
1. **KG traversal determinism:** The Mathematical Knowledge Graph (X.2) must specify that graph traversal (query results, neighbor enumeration, path finding) uses content-hash ordering for tie-breaking, not insertion order or any runtime-dependent ordering.
2. **Dependency sorting determinism:** The Proof Engine and Discovery Stack must specify that dependency resolution uses topological sort with content-hash tie-breaking, ensuring deterministic build order.

**Recommendations:**
1. Add "graph traversal uses sorted node iteration, tie-breaking by content hash" to the mathematical KG freeze contract.
2. Add "dependency resolution uses topological sort with content-hash tie-breaking" to the proof engine and discovery stack freeze contracts.

---

## 5. Mathematical Discovery Audit — PASS (1 observation)

**Potential cycle path:**
```
Theorem A ──depends on──► Lemma B ──depends on──► Theorem A
```

**Current architecture stance:** Proofs are "composable" (PROOF_ENGINE_ARCHITECTURE.md:102) and theorems record dependencies. No explicit cycle detection or versioning protocol.

**Observation:** If Theorem A's proof references Theorem A as a lemma, the dependency graph contains a cycle. The architecture should specify:
1. The proof dependency graph must be acyclic (no self-referential proofs).
2. If a theorem needs to reference itself as a lemma (e.g., for induction with strengthened hypothesis), it must be versioned: `Theorem.v1 → Theorem.v2`, where v2's proof depends on v1's statement as a lemma.
3. Cycle detection is a required validation gate in the Proof Engine.

**Recommendation:** Add cycle detection requirement to Proof Engine freeze contract and versioning convention to the Discovery Stack freeze.

---

## 6. Dependency Audit — PASS (1 flag requiring fix)

**Flag: `PersistentHomology` absorption entry has inconsistent timing reference.**

In MATHEMATICS_ARCHITECTURE.md, the absorption table (line 84) states:
```
| `PersistentHomology` | `tiannara_runtime/topology/` | Absorb → symbolic engine topology domain (X.3) | Topology is a symbolic domain |
```

However, SYMBOLIC_REASONING_ARCHITECTURE.md clearly assigns topology to **Iteration 2** (after Proof Engine), while the "(X.3)" reference implies Iteration 1. This is a documentation inconsistency that will cause confusion during implementation.

**Required fix:** Change "(X.3)" to "(X.3 Iteration 2)" in the absorption table entry.

**Iteration 1 / Iteration 2 boundary verified clean:**
| Domain | Iteration | X.3 imports? |
|--------|-----------|-------------|
| Algebra | Iteration 1 | No Iteration 2 domains imported |
| Calculus | Iteration 1 | No Iteration 2 domains imported |
| Linear algebra | Iteration 1 | No Iteration 2 domains imported |
| Basic simplification | Iteration 1 | No Iteration 2 domains imported |
| Tensor algebra | Iteration 2 | Isolated until after X.4 |
| Graph theory | Iteration 2 | Isolated until after X.4 |
| Topology | Iteration 2 | Isolated until after X.4 |
| Probability | Iteration 2 | Isolated until after X.4 |
| Optimization | Iteration 2 | Isolated until after X.4 |
| Differential equations | Iteration 2 | Isolated until after X.4 |
| Information theory | Iteration 2 | Isolated until after X.4 |

All Iteration 2 domains are verified by the Proof Engine (X.4) before inclusion, ensuring no Iteration 1 code imports Iteration 2 capabilities.

---

## 7. World Model Boundary Audit — PASS (1 observation)

**Constitutional boundary:** Phase 16.X provides mathematical tools (proofs, symbolic computation, formal verification). Phase 17 implements world understanding (causal reasoning, prediction, forecasting, counterfactuals).

**Verified boundaries:**

| Feature | Phase | Rationale |
|---------|-------|-----------|
| Symbolic differentiation | 16.X | Tool — provides calculus primitives. Phase 17 uses them for physics simulation. |
| Formal verification (convergence) | 16.X | Tool — proves simulation algorithms terminate. Phase 17 implements those algorithms. |
| Polynomial algebra | 16.X | Pure mathematics |
| Graph theory | 16.X | Pure mathematics |
| Counterexample artifact | 16.X | Mathematical fact (witness to violated property) |
| Counterfactual queries | 17 | World understanding — what would happen if... |
| Prediction/forecasting | 17 | World understanding |
| Causal effect estimation | 17 | World understanding — requires numerical computation from data |

**Observation: DoCalculusEngine absorption boundary risk.** The existing Python `DoCalculusEngine` implements:
- Pearl's 3 rules of do-calculus (graph rewriting rules — pure mathematics) ✓
- `find_backdoor_adjustment_set` (graph algorithm — mathematics) ✓
- `estimate_causal_effect_backdoor` (numerical computation from data) ✗ — Phase 17
- `estimate_causal_effect_frontdoor` (numerical computation from data) ✗ — Phase 17
- `_estimate_simple_effect` (floating point computation) ✗ — Phase 17

MATHEMATICS_ARCHITECTURE.md states: "Absorb → symbolic causal engine (X.3)" — the term "causal engine" is ambiguous. If Phase 16.X absorbs the numerical estimation functions, it has crossed the boundary into Phase 17.

**Recommendation:** Before the freeze, the absorption contract for `DoCalculusEngine` must explicitly state:
- Phase 16.X absorbs only: the 3 rules of do-calculus as symbolic graph rewriting rules, backdoor/frontdoor criterion identification as graph algorithms, and identifiability checking.
- Phase 16.X explicitly excludes: `estimate_causal_effect_backdoor`, `estimate_causal_effect_frontdoor`, `_estimate_simple_effect`, `_estimate_adjusted_effect`, `_estimate_partial_effect`, and any floating-point numerical computation.
- These numerical functions remain in their current location (`tiannara_core/interpretability/`) and are consumed by Phase 17 when it implements causal reasoning.

---

## Summary of Required Actions Before Freeze

| # | Severity | Item | Responsible Document | Action |
|---|----------|------|--------------------|--------|
| 1 | **FLAG** | `PersistentHomology` references "(X.3)" but topology is Iteration 2 | MATHEMATICS_ARCHITECTURE.md:84 | Change to "(X.3 Iteration 2)" |
| 2 | Observation | `ArchaeologyRecord` type undefined | All 5 documents | Define struct in freeze |
| 3 | Observation | `SymbolicExpression.metadata` fields unspecified | SYMBOLIC_REASONING_ARCHITECTURE.md | Specify minimum archaeology fields |
| 4 | Observation | KG traversal determinism unspecified | MATHEMATICAL_DISCOVERY_STACK.md | Add content-hash tie-breaking to freeze |
| 5 | Observation | Dependency sort determinism unspecified | PROOF_ENGINE_ARCHITECTURE.md | Add topological sort + hash tie-breaking to freeze |
| 6 | Observation | Proof dependency cycle detection unspecified | PROOF_ENGINE_ARCHITECTURE.md | Add acyclic constraint + versioning convention to freeze |
| 7 | Observation | DoCalculusEngine absorption must exclude numerical estimation | MATHEMATICS_ARCHITECTURE.md | Add explicit scope boundary to absorption table |

---

## Recommendation

All 7 observations and 1 flag are document-level corrections that can be made before the freeze. After addressing them, Phase 16.X.05 (Constitutional Mathematics Freeze) may proceed.

The architecture is structurally sound. The most important finding is item 7 (do-calculus boundary) — getting this wrong would mean Phase 16.X accidentally implementing Phase 17 functionality, violating the constitutional separation between mathematics (tools) and world modeling (understanding). All other items are documentation clarifications.
