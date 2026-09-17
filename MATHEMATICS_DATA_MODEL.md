# Phase 16.X.0 — Constitutional Mathematics Data Model

document_version: 16.X.0
phase: 16.X
status: Architecture Review (no implementation)
owner: Constitutional Research Council

---

## Purpose

Defines the canonical data model for all mathematical objects in Phase 16.X. Every struct, type, validator, and serialization rule is specified here. No runtime implementation exists — this is the architecture-level data contract.

---

## Entity-Relationship Overview

```
┌──────────────┐     ┌──────────────────┐
│   Axiom      │◄────│   AxiomSet       │
└──────┬───────┘     └──────────────────┘
       │depends_on
       ▼
┌──────────────┐     ┌──────────────────┐
│  Definition  │◄────│   ProofStrategy  │
└──────┬───────┘     └──────────────────┘
       │
       ▼
┌──────────────┐     ┌──────────────────┐
│  Conjecture  │◄────│   ProofEngine    │
└──────┬───────┘     └──────────────────┘
       │proves
       ▼
┌──────────────┐     ┌──────────────────┐
│    Proof     │────►│   ProofStep[]    │
└──────┬───────┘     └──────────────────┘
       │certifies
       ▼
┌──────────────┐     ┌──────────────────┐
│   Theorem    │◄────│   Corollary      │
└──────┬───────┘     └──────────────────┘
       │applies
       ▼
┌──────────────┐     ┌──────────────────┐
│ Application  │     │   Algorithm      │
└──────────────┘     └──────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────┐
│         VerificationEngine              │
│  ┌──────────────────────────────────┐   │
│  │  MathematicalAssertion           │   │
│  │  ├─ property_type                │   │
│  │  ├─ system_model_hash            │   │
│  │  ├─ result (:pass/:fail/:inconcl)│   │
│  │  ├─ proof_hash (if pass)         │   │
│  │  └─ counterexample_hash (if fail)│   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

---

## Entity Specifications

### Axiom
Fields: statement (String, non-empty), status (:active | :deprecated), axiom_set_id (String, optional)
ID: content-addressed SHA-256 of canonical JSON
Validator: statement must be non-empty; status must be one of allowed atoms

### Definition
Fields: name (String, non-empty), body (String), dependencies ([String]), introduced_in (String, optional)
ID: content-addressed SHA-256 of canonical JSON
Validator: name must be non-empty; dependencies must reference existing definitions

### Structure
Fields: name (String, non-empty), fields ([map]), axioms ([String])
ID: content-addressed SHA-256 of canonical JSON
Validator: name must be non-empty

### Conjecture
Fields: statement (String, non-empty), status (:open | :proven | :disproven | :undecidable), confidence (float, 0.0–1.0, optional)
ID: content-addressed SHA-256 of canonical JSON
Validator: statement must be non-empty; confidence must be in [0.0, 1.0] or nil

### Lemma
Fields: statement (String, non-empty), proof_hash (String, non-empty), dependencies ([String])
ID: content-addressed SHA-256 of canonical JSON
Validator: statement and proof_hash must be non-empty

### Theorem
Fields: statement (String, non-empty), proof_hash (String, non-empty), dependencies ([String])
ID: content-addressed SHA-256 of canonical JSON
Validator: statement and proof_hash must be non-empty

### Proof
Fields: conjecture_id (String, non-empty), strategy (:direct | :contradiction | :induction | :constructive | :computational), steps ([ProofStep]), verified (Boolean)
ID: content-addressed SHA-256 of canonical JSON
Validator: conjecture_id must be non-empty; strategy must be one of allowed values

### Corollary
Fields: statement (String, non-empty), parent_theorem_id (String, non-empty)
ID: content-addressed SHA-256 of canonical JSON
Validator: statement and parent_theorem_id must be non-empty

### Algorithm
Fields: name (String, non-empty), theorem_id (String, non-empty), complexity (String, optional)
ID: content-addressed SHA-256 of canonical JSON
Validator: name and theorem_id must be non-empty

### Application
Fields: problem_domain (String, non-empty), theorem_id (String, non-empty), context (map, optional)
ID: content-addressed SHA-256 of canonical JSON
Validator: problem_domain and theorem_id must be non-empty

### MathematicalProgram
Fields: objectives ([String], non-empty), theorems ([String]), status (:active | :complete | :failed)
ID: content-addressed SHA-256 of canonical JSON
Validator: objectives must be non-empty list

### MathematicalExperiment
Fields: program_id (String, non-empty), parameters (map), results (map, optional)
ID: content-addressed SHA-256 of canonical JSON
Validator: program_id must be non-empty

### MathematicalAssertion
Fields: property_type (:correctness | :convergence | :safety | :stability | :consistency | :bounded), system_model (String), result (:pass | :fail | :inconclusive), proof_hash (String, optional), counterexample_hash (String, optional)
ID: content-addressed SHA-256 of canonical JSON
Validator: pass result requires proof_hash; fail result requires counterexample_hash

### ArchaeologyRecord
Fields: origin (String, non-empty), purpose (String, non-empty), owner (String, non-empty), dependencies ([String]), lineage ([String])
ID: derived from contained fields (not independently content-addressed)
Validator: origin, purpose, and owner must be non-empty

---

## Symbolic Data Model

### SymbolicExpression
Fields: type (:constant | :variable | :operator | :function | :quantifier), value (term), children ([SymbolicExpression]), metadata (map)
ID: content-addressed SHA-256 of canonical JSON (recursive)
Validator: value must not be nil

### SymbolicRule
Fields: pattern (String, non-empty), replacement (String, non-empty), domain (atom, optional)
ID: content-addressed SHA-256 of canonical JSON

### RuleSet
Fields: id (String, non-empty), rules ([SymbolicRule]), description (String, optional)
ID: plain string identifier

### DomainRegistration
Fields: domain (atom), rules ([SymbolicRule]), metadata (map)
ID: derived from domain name

### RewriteStep
Fields: step_number (non-neg integer), rule_applied (String), expression_before (SymbolicExpression), expression_after (SymbolicExpression)
ID: derived from step number + expression hashes

### RewriteLog
Fields: steps ([RewriteStep], non-empty), final_expression (SymbolicExpression)
ID: content-addressed SHA-256 of canonical JSON

---

## Proof Data Model

### ProofStep
Fields: step_number (non-neg integer), rule_applied (String, non-empty), derived (String, non-empty), premises ([String])
ID: content-addressed SHA-256 of canonical JSON

### ProofStrategy
Valid values: :direct, :contradiction, :induction, :constructive, :computational

### InferenceRule
Fields: name (String, non-empty), premises (String, non-empty), conclusion (String, non-empty)
ID: content-addressed SHA-256 of canonical JSON

### AxiomSet
Fields: id (String, non-empty), axioms ([String])
ID: plain string identifier

### ProofBundle
Fields: id (String, non-empty), proof_ids ([String])
ID: plain string identifier

---

## Verification Data Model

### VerificationProperty
Valid values: :correctness, :convergence, :safety, :stability, :consistency, :bounded

### VerificationResult
Valid values: :pass, :fail, :inconclusive

### SystemModel
Fields: id (String, non-empty), specification (String, non-empty)
ID: plain string identifier

### BoundedVerificationConfig
Fields: max_steps (pos integer, default 1000), confidence (float, 0.0–1.0, default 1.0)
ID: derived from configuration parameters

---

## Canonical Serialization

All content-addressed IDs use SHA-256 over the canonical JSON representation of the entity. Canonical JSON follows these rules:

1. Map keys sorted lexicographically (Unicode code point order)
2. No whitespace between tokens
3. Atoms serialized as strings (e.g., `:direct` → `"direct"`)
4. Nested entities serialized recursively with same rules
5. Nil/null values excluded from serialization
6. Empty lists serialized as `[]`

---

## Entity Ownership

| Entity | Constitutional Owner |
|--------|---------------------|
| All ontology entities | Constitutional Research Council |
| All symbolic entities | Constitutional Research Council |
| All proof entities | Constitutional Research Council |
| All verification entities | Constitutional Research Council |
| ArchaeologyRecord | Constitutional Research Council |
