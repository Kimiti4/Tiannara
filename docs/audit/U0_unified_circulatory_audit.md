# U0 Unified Substrate & Circulatory Audit

**Status:** INITIALIZING  
**Predecessor:** AE-003 CLOSED (HEALTHY)  
**Next Milestone:** AE-004 Gate Fidelity (queued post-U0 validation)  
**Guiding Principle:** "Prove coherence under continuous operation, not feature accumulation."

## 1. Epistemic Status Key
- `✓` = Demonstrated (runtime evidence exists)
- `~` = Documented (structurally present, runtime integration incomplete)
- `?` = Unassessed (no runtime observation yet)
- `✗` = Empirically failed (observed contract violation)

## 2. The 16-Capability Causal Matrix
| ID | Capability | Target State | Current Status | Primary Blocker / Next Step |
|----|------------|--------------|----------------|-----------------------------|
| C1 | Perception / Reality Ingestion | R/I | `?` | U1 Probe: Ingest external observation |
| C2 | Unified World / Reality Model | R/I | `?` | U1 Probe: Verify canonical state mutation |
| C3 | Knowledge / Memory | I/V | `~` | Prove boundedness + continuity under load |
| C4 | Epistemic Reasoning | I/V | `~` | Link explicitly to C2 state mutations |
| C5 | Mathematical / Logical Reasoning| I/V | `~` | Validate as shared substrate across domains |
| C6 | Planning / Research | I/V | `~` | End-to-end runtime proof of autonomous prioritization |
| C7 | Engineering / Synthesis (ASC) | I/V | `✓` | Strong evidence; operating slice validated |
| C8 | Execution | I/V | `?` | U5/U6 Probe: Governed action to external reality |
| C9 | Learning / Discovery | I/V | `✓` | Integrated slice demonstrated (AE-001 to AE-003) |
| C10| Continuity / Archaeology | I/V | `~` | Universal trace coverage required |
| C11| External Reality Interface | I/V | `✗` | CRITICAL GAP: Requires read-only first, then governed writes |
| C12| Homeostasis / Cognitive Immune | I/V | `?` | Runtime integration evidence needed |
| C13| Adaptation / Evolution | V | `✓` | VALIDATED (AE-003 longitudinal evidence) |
| C14| Constitutional Governance | V | `✓` | Strong evidence (two-key adoption pattern) |
| C15| Observability / Truthfulness | V | `~` | Trace Envelope must become universal primitive |
| C16| Human Collaboration | V | `✓` | Demonstrated through controlled adoption |

---

## 3. Core Integration Probes (The Circulatory Tests)

These probes do not test isolated modules. They test the **causal arrows** between capabilities. Every transition must emit a conformant `trace_envelope`.

### Probe U1: Reality → Knowledge (Metabolism)
**Objective:** Prove that an external observation produces a traceable state mutation in the canonical reality representation, without creating shadow state.
- **Input:** Synthetic external observation (e.g., mocked repository commit or telemetry event).
- **Path:** C1 (Ingestion) → C2 (Canonical Mutation) → C3 (Knowledge Storage) → C4 (Epistemic Tagging).
- **Success Criteria:** 
  1. Single `trace_id` spans all phases.
  2. Read-back from C2 yields the exact payload hash of the input.
  3. No competing "World Model" or "Event Store" diverges from this canonical state.

### Probe U4: Governance → Engineering (Constitutional Alignment)
**Objective:** Prove that ASC (C7) is a citizen of Tiannara, not an isolated island, and consumes constitutional constraints *before* candidate generation.
- **Input:** Engineering objective with explicit constitutional constraints (e.g., "max 50MB memory footprint").
- **Path:** C14 (Governance Gate) → C6 (Research/Planning) → C7 (ASC Proposal Generation) → C14 (Certification).
- **Success Criteria:** 
  1. Trace envelope shows `authorization_state.required = true` at C14.
  2. ASC candidate metadata explicitly references the C14 constraint in its `evidence_ref`.
  3. Rejection occurs if constraint is violated pre-generation.

### Probe U5/U6: Tiannara → Reality → Tiannara (Purpose)
**Objective:** Prove the system can safely affect external reality, observe the consequence, and update its knowledge. *(Note: C11 is currently a critical gap; this probe will initially use a strictly controlled, read-only or sandboxed mock external interface).*
- **Input:** Approved, governed action payload.
- **Path:** C8 (Execution) → C11 (External Gateway) → [External State Change] → C1 (Observation) → C2 (Reality Model Update) → C9 (Learning).
- **Success Criteria:** 
  1. Action is blocked without C14 authorization.
  2. Post-action C1 observation detects the state change.
  3. C9 updates future decision weights based on the outcome (success/failure).

---

## 4. Execution Protocol & Guardrails

1. **No Feature Creep:** If a probe fails, the output is a diagnostic hypothesis, not a new feature request.
2. **Trace Envelope Mandatory:** Any script or tool executing these probes must output the `trace_envelope` schema defined in `priv/tiannara/trace_envelope_schema.yaml`.
3. **Epistemic Honesty:** If a capability is `?` (unassessed), it remains `?` until the probe provides `✓` or `✗` evidence. We do not guess.
4. **Human-in-the-Loop:** Probe U4 and U5/U6 require explicit human authorization artifacts (e.g., `ASC-U0.human`) before execution, maintaining the two-key pattern.

---

## 5. Next Decision Point

Upon completion of U0 (specifically U1 and U4), the system will have proven baseline circulatory integrity. Only then will **AE-004 Gate Fidelity** be authorized to test the quality of the evolutionary instrument itself, followed by the Long-Horizon Real-World Pilot.