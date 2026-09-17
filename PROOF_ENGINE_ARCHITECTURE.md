# Phase 16.X.4 — Proof Engine Architecture

document_version: 16.X.4

phase: 16.X

status: Architecture Review (no implementation)

owner: Constitutional Research Council

depends_on:
  - MATHEMATICS_ARCHITECTURE.md
  - SYMBOLIC_REASONING_ARCHITECTURE.md
  - MATHEMATICAL_DISCOVERY_STACK.md

supersedes: null

---

## Purpose

This document defines the architecture for the **Proof Engine** — the component responsible for constructing, verifying, storing, and replaying mathematical proofs.

Every proof is an immutable, content-addressed, replayable artifact. Proofs are the mechanism by which conjectures (X.5) become theorems, and theorems become the foundation for formal verification (X.6).

---

## Constitutional Role

The Proof Engine sits between the Symbolic Engine (X.3) and the Conjecture Engine (X.5):

```
Symbolic Engine (X.3) ──provides symbolic reduction──► Proof Engine (X.4)
                                                              │
                                                              ▼
                                                    Conjecture Engine (X.5)
                                                              │
                                                              ▼
                                                    Formal Verification (X.6)
```

The Proof Engine depends on the Symbolic Engine for:
- Expression normalization (canonical forms for proof steps)
- Substitution and rewriting (applying rules during proofs)
- Term evaluation (computing concrete instances for computational proofs)

The Proof Engine provides to downstream consumers:
- Verified theorem artifacts (for the mathematics KG)
- Proof replay bundles (for the independent auditor)
- Justification chains (for formal verification)

---

## Supported Proof Strategies

### 1. Direct Proof

Forward chain from premises to conclusion using inference rules.

```text
Given:  A, B, C
Rule:   A ∧ B → D
Rule:   D ∧ C → E
Conclusion: E
```

Implementation: forward chaining with configurable rule set and depth limit. The `TheoremEngine.forward_chain` (existing Python module) provides a reference implementation that will be absorbed.

### 2. Proof by Contradiction

Assume the negation of the conclusion and derive a contradiction.

```text
Goal:   P → Q
Assume: P ∧ ¬Q
Derive: contradiction (⊥)
Conclusion: P → Q
```

Implementation: the assumption engine adds negated goal to the premise set, then runs forward chaining until a contradiction (A ∧ ¬A) is detected. The existing `ContradictionDetector` module is absorbed.

### 3. Induction

Prove base case + inductive step.

```text
Base:    P(0)
Step:    P(k) → P(k+1)
Conclusion: ∀n. P(n)
```

Implementation: structural induction on well-founded term orderings. The engine detects recursive structure in definitions and generates base/step subgoals automatically.

### 4. Constructive Proof

Build an explicit object satisfying the conclusion.

```text
Goal:    ∃x. P(x)
Proof:   x := f(a, b, c)  where P(f(a,b,c))

Goal:    ∀x. ∃y. R(x, y)
Proof:   y := g(x)  where R(x, g(x))
```

Implementation: uses the Symbolic Engine to construct witness terms. The proof is the witness plus a verification that the witness satisfies the condition.

### 5. Computational Proof

Enumerate a finite domain and verify the conclusion for every case.

```text
Goal:    ∀x ∈ D. P(x)
Proof:   for each x ∈ D, compute P(x) symbolically and verify truth
```

Implementation: bounded exhaustive enumeration with symbolic evaluation. The domain must be finite and explicitly enumerated. For infinite domains, computational proof is not applicable.

---

## Proof Artifact Structure

Every proof produces an immutable artifact:

```elixir
%Proof{
  id: String,                    # blake3 hash of canonical serialization
  conjecture_id: String,         # the conjecture being proved
  strategy: :direct | :contradiction | :induction | :constructive | :computational,
  premises: [String],            # IDs of axioms, definitions, lemmas used
  steps: [ProofStep],
  conclusion: SymbolicExpression,
  verified: boolean,             # true if self-verification passed
  metadata: %{
    engine_version: String,
    symbolic_engine_version: String,
    rule_set_hash: String,
    timestamp: String,
    archaeology: ArchaeologyRecord
  }
}

%ProofStep{
  step_number: Integer,
  rule_applied: String,          # name of inference rule
  premises: [String],            # IDs of previous steps or axioms used
  conclusion: SymbolicExpression,
  justification: String          # human-readable explanation
}
```

---

## Self-Verification

Every proof, upon construction, is **self-verified** by the engine:

1. Replay each step: given the premises and rule, symbolically derive the step's conclusion.
2. Verify the chain: confirm that each step's conclusion is a valid consequence of its premises and the inference rule.
3. Verify the final step: confirm that the final step's conclusion matches the target theorem statement.

Self-verification must complete in bounded time (deterministic budget). If self-verification fails, the proof is rejected (`{:error, :verification_failed}`).

---

## Proof Replay Contract

```
input:  Proof ID + Conjecture ID + Axiom Set Hash
steps:  replay each proof step through the symbolic engine
output: {:ok, :verified} | {:error, reason}
replay: identical inputs → identical outputs
```

The independent auditor (X.96) replays a random sample of proofs using only the exported artifacts (proof bundle, axiom set, symbolic engine freeze hash). No runtime access to the Proof Engine is permitted during audit.

---

## Absorption of Existing Modules

| Existing Module | Absorption Strategy |
|----------------|-------------------|
| `TheoremEngine` (`tiannara_core/logic/`) | Forward chaining becomes the `:direct` proof strategy. Backward chaining becomes a search strategy for proof construction. |
| `ConstraintSolver` (`tiannara_core/logic/`) | CSP solving becomes a tactic within `:computational` proofs. |
| `ProofSystem` (`tiannara_runtime/eid/`) | Emergence validation becomes a `:constructive` proof strategy with domain-specific rules. |
| `CategoryTheoreticValidator` (`tiannara_runtime/kernel/`) | Functoriality verification becomes a built-in proof tactic for the `:category_theory` domain. |
| `ContradictionDetector` (`tiannara_core/logic/`) | Absorbed as the contradiction detection primitive for `:contradiction` proofs. |

---

## Dependency Resolution Determinism

All dependency resolution in the Proof Engine and Discovery Stack uses **topological sort with content-hash tie-breaking**.

1. The dependency graph (theorems depending on lemmas, lemmas depending on axioms) must be acyclic. Cycle detection is a required validation gate in the Proof Engine.
2. If a theorem needs to refer to itself (e.g., induction with strengthened hypothesis), it must be versioned: `Theorem.v1 → Theorem.v2`, where v2's proof depends on v1's statement.
3. When two nodes have equal topological rank, the node with the lexicographically smaller content hash is resolved first.
4. This guarantees deterministic build order: same axiom set → same proof construction → same theorem IDs, every time.

### Proof Dependency Cycle Rule

No proof may contain a cycle in its dependency graph. The Proof Engine MUST reject any proof attempt whose dependency graph contains a cycle. This applies to all five proof strategies (direct, contradiction, induction, constructive, computational).

Rationale: A cyclic dependency would mean a theorem is used to prove itself, which violates the constitutional requirement that every theorem has a verifiable, replayable proof chain back to axioms.

---

## Frozen Interfaces Appendix

### Frozen Schemas

Proof, ProofStep, ProofStrategy, InferenceRule, AxiomSet, ProofBundle

### Frozen APIs

ProofEngine.prove/3, ProofEngine.verify/1, ProofEngine.replay/2, ProofEngine.supported_strategies/0, ProofEngine.register_rule/2

### Frozen Behaviours

ProofStrategy (callbacks: can_prove?/2, construct/2, verify/1)

---

## Status

Architecture Review — no implementation.

Proof Engine implementation (Phase 16.X.4) depends on:
- Phase 16.X.1 (Ontology) — Proof and ProofStep structs must exist
- Phase 16.X.2 (Mathematics KG) — Theorems, lemmas, and axioms must be addressable
- Phase 16.X.3 Iteration 1 (Symbolic kernel) — Expression normalization and substitution must be available
