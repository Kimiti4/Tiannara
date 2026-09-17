# Phase 16.X.3 — Symbolic Computation Engine Architecture

document_version: 16.X.3

phase: 16.X

status: Architecture Review (no implementation)

owner: Constitutional Research Council

depends_on:
  - MATHEMATICS_ARCHITECTURE.md
  - MATHEMATICAL_DISCOVERY_STACK.md

supersedes: null

---

## Purpose

This document defines the architecture for the **Symbolic Computation Engine** — Tiannara's deterministic symbolic reasoning substrate.

The engine provides exact symbolic computation across 10 mathematical domains. No numerical approximations are produced unless explicitly requested by the caller. Every symbolic operation is deterministic, replayable, and archaeologically recorded.

---

## Constitutional Role

The Symbolic Engine is the **primitive layer** of the mathematics substrate. It supplies:

- Algebraic manipulation for the Proof Engine (X.4) — proofs need symbolic reduction
- Expression simplification for the Conjecture Engine (X.5) — conjectures need invariant detection
- Symbolic differentiation/integration for World Modeling (Phase 17) — physics simulation needs calculus
- Tensor algebra for Engineering Intelligence (Phase 18) — engineering systems need linear algebra
- Topological computation for Civilizational Intelligence (Phase 19) — coordination needs graph theory
- Information-theoretic measures for Constitutional OS (Phase 20) — governance needs entropy and mutual information

---

## Iterative Build Strategy

The symbolic engine is built in **two iterations** to resolve the bidirectional dependency with the Proof Engine:

### Iteration 1 (Phase 16.X.3 — initial)

Minimal symbolic kernel covering:

| Domain | Operations | Primitives |
|--------|------------|------------|
| **Algebra** | Polynomial manipulation, factorization, GCD, resultants | `SymbolicExpr` tree, pattern matching, rewriting rules |
| **Calculus** | Symbolic differentiation, elementary integration, limits | `D`, `Integrate`, `Limit` with exact symbolic results |
| **Linear algebra** | Matrix operations, determinants, eigenvalues (symbolic) | `Matrix`, `Vector`, symbolic Gaussian elimination |
| **Basic simplification** | Constant folding, identity elimination, normalization | Canonical form for every expression class |

No approximate methods. No floating point. No iterative solvers.

### Iteration 2 (after Phase 16.X.4 — Proof Engine)

Expanded to full 10-domain coverage:

| Domain | Added Operations |
|--------|-----------------|
| **Tensor algebra** | Tensor contraction, index gymnastics, Einstein summation |
| **Graph theory** | Path finding, isomorphism detection, spectral graph measures |
| **Topology** | Simplicial complexes, homology groups, homotopy (discrete) |
| **Probability** | Symbolic probability distributions, moments, entropy |
| **Optimization** | Symbolic Lagrangian, KKT conditions, convexity detection |
| **Differential equations** | Symbolic ODE/PDE solving, symmetry reduction |
| **Information theory** | Entropy, mutual information, KL divergence (symbolic forms) |

All iteration-2 operations are verified for correctness by the Proof Engine.

---

## Core Architecture

```
SymbolicExpression (content-addressed AST)
        │
        ├─── SymbolicRuleSet (pattern → replacement)
        │
        ├─── SymbolicDomain (algebra, calculus, tensor, ...)
        │
        ├─── SymbolicRewriter (deterministic rewriting engine)
        │
        └─── SymbolicCache (content-addressed memoization)
```

### SymbolicExpression

Every expression is an immutable, content-addressed tree:

```elixir
defstruct [
  :id,             # blake3 hash of canonical serialization
  :type,           # :constant | :variable | :function | :operator
  :value,          # atom | number | function name
  :children,       # list of SymbolicExpression
  :metadata        # map containing at least: origin (String), purpose (String), owner (String), domain (atom)
]
```

Canonical serialization: sorted children, normalized operators, explicit parentheses.

### SymbolicRuleSet

Rule sets are ordered lists of `{pattern, guard, replacement}` tuples. Rules are applied deterministically: leftmost innermost, first match wins. Tie-breaking by rule hash.

### SymbolicDomain

Each domain (algebra, calculus, etc.) is a module that registers rules and normalization functions with the kernel. Domain registration is deterministic and frozen.

### SymbolicRewriter

The core rewriting engine applies rules to expressions until fixed point (no rule applies) or budget exhaustion. Budget is a deterministic parameter (max rewrite steps, max depth).

### SymbolicCache

Content-addressed memoization: `hash(input_expression + rule_set_hash) → output_expression`. Cache is deterministic and replayable.

---

## Determinism Guarantees

1. **Rule ordering is frozen** — Rule sets are compiled to a canonical order at engine initialization (sorted by rule hash).
2. **No randomness** — All decisions (match order, tie-breaking, budget) are deterministically derived from content-addressed seeds.
3. **No environment dependence** — The engine has no access to wall clock, network, or system state.
4. **Cache is deterministic** — Cache keys include the full expression and rule context.
5. **Timeout** — If symbolic computation exceeds budget, the engine returns `{:error, :budget_exhausted}` (fail-closed) rather than falling through to an approximation.

---

## Absorption of Existing Modules

| Existing Module | Absorption Strategy |
|----------------|-------------------|
| `SymbolicSimplifier` (OPC) | Primitives absorb into core rule set. `simplify/1` becomes `SymbolicEngine.simplify/2`. |
| `DoCalculusEngine` (Python) | Pearl's do-calculus rules become a `:causal` domain in the symbolic engine. |
| `ConstraintSolver` (Python) | CSP solving becomes a proof strategy in Proof Engine (X.4), not a symbolic primitive. |
| `SymbolicValidator` (OPC) | Stability validation is replaced by type checking in the symbolic engine's normalization pass. |
| `TensorConstraintSolver` (OPC + Meta) | Both are deprecated. Tensor operations are native to the symbolic engine's tensor domain. |
| `PersistentHomology` (topology) | Homology computation becomes a `:topology` domain module. |

---

## Replay Contract

```
input:  SymbolicExpression + Domain + RuleSet hash
steps:  deterministic rewrite sequence (log every Nth step)
output: SymbolicExpression + RuleSequence hash
replay: identical inputs → identical outputs
```

Every symbolic computation produces a replay bundle: input hash, rule set hash, step log, output hash. The independent auditor (X.96) replays a random sample and verifies hash equality.

---

## Frozen Interfaces Appendix

### Frozen Schemas

SymbolicExpression, SymbolicRule, RuleSet, DomainRegistration, RewriteStep, RewriteLog

### Frozen APIs

SymbolicEngine.eval/2, SymbolicEngine.simplify/2, SymbolicEngine.differentiate/2, SymbolicEngine.integrate/2, SymbolicEngine.rewrite/3, SymbolicEngine.domain_registered?/1

### Frozen Behaviours

SymbolicDomain (callbacks: rules/0, normalize/1, type_check/1)

---

## Status

Architecture Review — no implementation.

Iteration 1 (algebra + calculus kernel) will be implemented in Phase 16.X.3 after the ontology (X.1) and knowledge graph (X.2) are in place. Iteration 2 (full 10-domain coverage) begins after Proof Engine (X.4) is operational.
