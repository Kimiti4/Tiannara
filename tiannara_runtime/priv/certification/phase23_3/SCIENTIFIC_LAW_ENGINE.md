# Scientific Law Engine

## Purpose

Formulate, store, and manage scientific laws as constitutional entities.
Every law references supporting evidence and remains traceable to its
originating discoveries.

## Law Types

| Type | Description |
|------|-------------|
| Empirical | Laws derived directly from observation |
| Derived | Laws derived mathematically from other laws |
| Probabilistic | Laws expressed as probability distributions |
| Deterministic | Laws with exact functional relationships |
| Approximate | Laws valid within specified tolerance |
| Domain-Specific | Laws applicable to a single domain |
| Cross-Domain | Laws that generalize across multiple domains |

## Law Structure

Each law records:
- Law type
- Formal statement (mathematical/logical)
- Variables and their domains
- Parameters and their uncertainties
- Supporting evidence IDs
- Supporting mechanism IDs
- Boundary conditions
- Known counterexamples
- Derivation history
- Uncertainty quantification
- Fingerprint (content hash)

## Constitutional Requirements

- Every law must reference at least one supporting evidence
- All derived laws must preserve their proof chain
- Approximate laws must specify their error bounds
- Cross-domain laws must cite evidence from each domain
