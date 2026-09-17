# Phase 16.X.0 — Constitutional Mathematics Replay Model

document_version: 16.X.0
phase: 16.X
status: Architecture Review (no implementation)
owner: Constitutional Research Council

---

## Purpose

Defines the replay model for all Phase 16.X mathematical operations. Every mathematical artifact must be deterministically reconstructable from immutable inputs. Replay is the cornerstone of constitutional auditability — no runtime state, ETS, database, or network may be required.

---

## Replay Levels

Following the Phase 16.2 replay model, three levels of replay are defined:

### Level 1 — Hash Equality
Same canonical inputs → same content-addressed ID.
Verification: recompute ID from canonical JSON; compare to stored ID.
Scope: all ontology entities (Axiom, Definition, Theorem, etc.)

### Level 2 — Semantic Equality  
Same conceptual inputs → same semantic output (modulo canonicalization).
Verification: re-run operation on canonicalized inputs; compare output hash.
Scope: SymbolicExpression simplification, Proof verification, VerificationEngine assertions

### Level 3 — Structural Pipeline Equality
Same sequence of inputs → same sequence of intermediate and final states.
Verification: replay full pipeline; compare every step hash.
Scope: multi-step symbolic rewrites, proof construction, verification campaigns

---

## Replay-Critical Artifacts

Every artifact type below is replay-critical. Each must include sufficient metadata for all three replay levels:

| Artifact | Level | Replay Inputs |
|----------|-------|---------------|
| Axiom | L1 | statement, status, axiom_set_id |
| Definition | L1 | name, body, dependencies |
| Conjecture | L1 | statement, confidence |
| Lemma | L1 | statement, proof_hash, dependencies |
| Theorem | L1 | statement, proof_hash, dependencies |
| Proof | L2 | conjecture_id, strategy, axiom_set_hash |
| Corollary | L1 | statement, parent_theorem_id |
| Algorithm | L1 | name, theorem_id |
| Application | L1 | problem_domain, theorem_id |
| MathematicalAssertion | L2 | property_type, system_model, proof_hash |
| SymbolicExpression | L2 | type, value, children (recursive) |
| RewriteStep | L3 | step_number, rule_applied, expression_before, expression_after |
| ProofStep | L1 | step_number, rule_applied, derived, premises |
| Counterexample | L1 | property, witness |
| SystemModel | L1 | id, specification |

---

## Replay Protocol

For any replay request on artifact A:

```
1. Load A's canonical inputs from the Mathematics Registry
2. Canonicalize inputs (sorted keys, no nil, recursive)
3. Execute the replay function for A's type
4. Compute output hash
5. Compare to A's stored ID hash
   - Match → replay verified (Level 1)
   - Mismatch → replay divergence → emit REPLAY_DIVERGENCE error
6. For Level 2/3: compare semantic output or step sequence
```

---

## Divergence Handling

When replay diverges:
- The replay module must emit a `REPLAY_DIVERGENCE` error artifact
- The divergence must be recorded in the artifact's ArchaeologyRecord lineage
- The runtime may not silently correct the divergence
- An independent auditor (Phase 16.X.8) must be able to detect and report the divergence

---

## Replay API (Architecture)

```
MathematicsReplay.replay(artifact_id) → {:ok, :verified} | {:error, :replay_divergence, details}
MathematicsReplay.replay_level(artifact_id, level) → {:ok, result} | {:error, reason}
MathematicsReplay.batch_replay(artifact_ids) → {:ok, %{id => result}}
MathematicsReplay.verify_pipeline(stage, inputs, expected_outputs) → {:ok, :verified} | {:error, details}
```

---

## Determinism Guarantees

| Operation | Determinism Rule |
|-----------|-----------------|
| ID derivation | SHA-256 over canonical JSON; same inputs → same ID always |
| KG traversal | Results sorted by content hash lexicographically |
| Symbolic rewrite | Leftmost innermost; first match by rule hash ordering |
| Proof construction | Sequential; tie-breaking by content hash |
| Verification | Deterministic bounded steps; fail-closed on budget |
| List operations | Always sorted by content hash before any enumeration |
| Randomness | Content-addressed seeds only; no wall-clock or entropy sources |

---

## Boundary

- Replay consumes only the Mathematics Registry and exported immutable artifacts
- No runtime imports (ETS, database, network, GenServer state)
- No dependency on Phase 15 (scientific) or Phase 17 (world model) artifacts
- The replay model is constitutionally separate from the Scientific Replay Model

---

## Audit References

- Replay Audit: see CONSTITUTIONAL_ARCHITECTURE_AUDIT.md §Replay
- Determinism Audit: see MATHEMATICS_ARCHITECTURE.md §Constitutional Requirements
- Archaeology Audit: see MATHEMATICS_ARCHITECTURE.md §Archaeology
