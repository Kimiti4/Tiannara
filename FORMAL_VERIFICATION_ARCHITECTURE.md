# Phase 16.X.6 — Formal Verification Architecture

document_version: 16.X.6

phase: 16.X

status: Architecture Review (no implementation)

owner: Constitutional Research Council

depends_on:
  - MATHEMATICS_ARCHITECTURE.md
  - PROOF_ENGINE_ARCHITECTURE.md
  - SYMBOLIC_REASONING_ARCHITECTURE.md

supersedes: null

---

## Purpose

This document defines the architecture for **Formal Verification** — the component that consumes theorems from the Proof Engine (X.4) and applies them to verify properties of engineering, scientific, and governance systems.

Formal Verification is the bridge between pure mathematics and applied systems. It provides proof infrastructure for correctness, convergence, safety, stability, consistency, and bounded behavior.

---

## Constitutional Role

Phase 16.X.6 is the **applied layer** of the mathematics substrate. While the Proof Engine (X.4) proves mathematical statements, the Verification Engine (X.6) uses those theorems to verify real-world properties of:

- **Phase 17 (World Modeling):** convergence of simulation algorithms, stability of world representations, consistency of multi-world state
- **Phase 18 (Engineering Intelligence):** correctness of engineering designs, safety bounds, resource constraint satisfaction
- **Phase 19 (Civilizational Intelligence):** fairness of coordination protocols, stability of governance dynamics, bounded inequality
- **Phase 20 (Constitutional OS):** consistency of constitutional rules, safety of automated governance actions, non-contradiction of legal frameworks

The Verification Engine does **not** replace testing. It **complements** it. Verified properties are mathematical guarantees; tested properties are empirical observations. Both are required.

---

## Verification Properties

### 1. Correctness

A system produces the intended output for all valid inputs.

```text
∀input ∈ ValidInputs. system(input) = spec(input)
```

Verification strategy: symbolic execution of the system against a formal specification. Uses the Proof Engine's `:direct` and `:induction` strategies.

### 2. Convergence

An iterative process terminates at a fixed point.

```text
∃k < max_iterations. state(k+1) = state(k)
```

Verification strategy: construct a Lyapunov function (potential function) that strictly decreases each iteration and is bounded below. Uses the Symbolic Engine's calculus domain (differentiation, inequality checking).

### 3. Safety

A system never enters an unsafe state.

```text
∀t. system(t) ∈ SafeStates
```

Verification strategy: invariant induction. Find an invariant I such that: (a) initial state satisfies I, (b) every transition preserves I, (c) I implies safety. Uses the Proof Engine's `:induction` strategy.

### 4. Stability

A system returns to equilibrium after perturbation.

```text
∀ε > 0. ∃δ > 0. ‖initial - equilibrium‖ < δ → ∀t. ‖system(t) - equilibrium‖ < ε
```

Verification strategy: Lyapunov stability analysis using symbolic differentiation and inequality proving. Uses the Symbolic Engine (gradients, norms) and Proof Engine (inequality chains).

### 5. Consistency

No contradictory statements are derivable from the system's axioms.

```text
¬∃P. system ⊢ P ∧ system ⊢ ¬P
```

Verification strategy: encode the system's axioms in the Proof Engine and attempt to derive a contradiction. If no contradiction is found within budget, the system is provisionally consistent (not proven consistent — Gödelian limits apply).

### 6. Bounded Behavior

All system outputs stay within specified bounds.

```text
∀t. lower_bound ≤ system_output(t) ≤ upper_bound
```

Verification strategy: induct on time steps, using monotonicity and conservation properties. Uses the Proof Engine's `:induction` strategy.

---

## Verification Pipeline

```
System Model (formal specification)
        │
        ▼
Property Encoding (correctness, safety, convergence, ...)
        │
        ▼
Proof Construction (Proof Engine X.4)
        │
        ▼
Symbolic Checking (Symbolic Engine X.3)
        │
        ▼
Verification Certificate (MathematicalAssertion)
        │
        ├── PASS     → Property is mathematically guaranteed
        ├── FAIL     → Counterexample exists (counterexample artifact produced)
        └── BOUNDED  → Property verified within budget; stronger verification deferred
```

### Counterexample Artifacts

When verification fails, a counterexample artifact is constructed:

```elixir
%Counterexample{
  id: String,                    # blake3 hash
  property: String,              # the property being verified
  system_model_hash: String,     # the system model used
  witness: SymbolicExpression,   # the counterexample value/state
  proof_hash: String,            # proof that this witness violates the property
  metadata: ArchaeologyRecord
}
```

Counterexamples are stored in the Mathematics KG. They are **not** errors — they are mathematical facts that inform engineering decisions.

---

## Bounded Verification

For properties that cannot be fully verified (undecidable, budget-exhausted, or requiring unbounded quantification), the Verification Engine supports bounded verification:

- **Bounded model checking:** verify the property for all states reachable within K steps
- **Bounded safety:** verify safety for all trajectories of length ≤ T
- **Statistical bounds:** verify with probability ≥ 1-δ that the property holds (requires explicit confidence parameters)

Bounded verification results are marked `BOUNDED` (not `PASS`). Downstream systems must treat bounded results as provisional.

---

## Absorption of Existing Modules

The Verification Engine has fewer existing modules to absorb than the Symbolic or Proof engines, because formal verification is currently underdeveloped in the codebase. The primary absorptions are:

| Existing Module | Absorption Strategy |
|----------------|-------------------|
| `EquilibriumEngine` (RRG) | The Ψ metric computation becomes a `:stability` verification primitive. |
| `LoopAnalyzer` (OPC) | Loop termination analysis becomes a `:convergence` verification tactic. |
| `SingularityDetector` (OPC) | Singularity detection becomes a `:safety` verification constraint. |
| `CategoryTheoreticValidator` (kernel) | Functorial homomorphism verification becomes a `:correctness` tactic for structure-preserving transformations. |

New modules will need to be built for the verification pipeline — this is the sub-phase with the most greenfield work.

---

## Verification Certificate (MathematicalAssertion)

The Verification Engine produces **assertions**, not certificates. Per the constitutional constraint (MATHEMATICS_ARCHITECTURE.md §5), the term `MathematicalAssertion` is used in all auditor-facing interfaces to avoid conflating verification with certification.

```elixir
%MathematicalAssertion{
  id: String,
  property_type: :correctness | :convergence | :safety | :stability | :consistency | :bounded,
  system_hash: String,
  result: :pass | :fail | :bounded,
  proof_hash: String | nil,      # nil for :fail
  counterexample_hash: String | nil,  # nil for :pass
  bound: Integer | nil,          # K or T for :bounded
  metadata: ArchaeologyRecord
}
```

Assertions are **not** used for certification. They are mathematical statements of fact, subject to the same replay and audit requirements as proofs (X.4).

---

## Replay Contract

```
input:  System Model Hash + Property + Assertion Hash
steps:  reconstruct proof from Proof Engine, re-check symbolic constraints
output: {:ok, :verified} | {:error, :replay_mismatch} | {:error, :proof_not_found}
replay: identical inputs → identical assertion outcomes
```

---

## Frozen Interfaces Appendix

### Frozen Schemas

VerificationProperty, VerificationResult, MathematicalAssertion, Counterexample, SystemModel, BoundedVerificationConfig

### Frozen APIs

VerificationEngine.verify/3, VerificationEngine.assert/2, VerificationEngine.replay/2, VerificationEngine.supported_properties/0, VerificationEngine.register_verifier/2

### Frozen Behaviours

VerificationStrategy (callbacks: can_verify?/2, verify/2, bound/2)

---

## Status

Architecture Review — no implementation.

Formal Verification (Phase 16.X.6) is the **last core sub-phase** before the validation/audit/certification tail. It depends on:
- Phase 16.X.3 (Symbolic Engine) — symbolic expression evaluation and differentiation
- Phase 16.X.4 (Proof Engine) — proof construction and self-verification
- Phase 16.X.5 (Conjecture Engine) — invariant candidate generation (for safety induction)

The first consuming phase (Phase 17 — World Modeling) will be the first external client of the Verification Engine's stability and convergence verifiers.
