# Phase 18.6 — Decision Certification

## Validation Stages

### Stage 1: Structural Validation
- All required replay and evidence artifacts exist.
- Artifact schemas conform to the decision data model.
- Artifact hash chains are intact.
- Producer signatures are verifiable.

### Stage 2: Pipeline Validation
- Decision pipeline stages are complete and in order.
- Each stage's inputs match the previous stage's outputs.
- No stage is skipped or duplicated.
- Policy hierarchy precedence is respected.

### Stage 3: Policy Validation
- All policies in the active set were evaluated.
- No unauthorised policies were injected.
- Policy evaluation functions produced valid scores.
- Veto conditions were correctly applied.

### Stage 4: Authorization Validation
- Authorization threshold logic is correct.
- Risk assessment was completed before authorization.
- Authorization was performed by an authorised entity.
- Authorization constraints are internally consistent.

### Stage 5: Intent Validation
- ExecutionIntent is fully materialised.
- Intent references a valid ExecutionAuthorization.
- Resource budget is internally consistent.
- Safety constraints are well-formed.

## Audit

Every certification produces a signed audit record containing:
- Certification session ID
- Decision session ID
- Validation results for each stage (pass/fail per check)
- List of all artifacts examined (with hashes)
- Certification timestamp
- Certifier identity

Audit records are stored in the archaeology subsystem and are immutable.

## Freeze Conditions

A decision is frozen (irreversible) when **all** of the following hold:

1. **Pipeline complete** — All 9 stages of the policy pipeline executed successfully.
2. **Intent issued** — An `ExecutionIntent` was produced and accepted by the downstream executor.
3. **Replay complete** — The replay subsystem successfully reconstructed the full decision graph with no inconsistencies.
4. **All artifacts archived** — Every replay, evidence, and archaeology artifact has been committed to the archaeology store.
5. **Certification passed** — All five validation stages in this document passed.

Once frozen, the decision cannot be altered. Corrections require a new decision session.
