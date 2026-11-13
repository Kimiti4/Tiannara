# TCP-001 — Tiannara Completion Programme Charter

**Programme:** Tiannara Completion Programme (TCP)
**Checkpoint:** TCP-001 — Programme establishment and Master Completion Assessment
**Status:** ACTIVE
**Date:** 2026-11-12
**Supersedes:** nothing. Coexists with the CP/RL audit line.

---

## 1. Purpose

Tiannara is transitioning from a continuously-audited system of individually
impressive subsystems to a **single integrated cognitive organism** that
perceives, understands, investigates, reasons, simulates, remembers, learns
under governance, coordinates, and produces independently verifiable
conclusions.

The audit line (CP/RL) produced necessary integrity evidence but is not the
destination. This charter establishes the programme that directs all
subsequent work.

## 2. The two-outcome rule

From TCP-001 onward, **every checkpoint must contribute to at least one of two
outcomes**. A checkpoint that contributes to neither is not started.

| # | Outcome | Meaning |
|---|---------|---------|
| **A** | **Remove a demonstrated blocker to Tiannara's operation** | A defect, duplication, disconnect or hardcode that demonstrably prevents a cognitive capability from functioning, evidenced by repository-grounded analysis and reproduced by a test. |
| **B** | **Deliver or verify a missing cognitive capability** | A capability from the eight-capability model that is absent, partial, stubbed or unverified, brought to a measurable acceptance test. |

Security, governance, testing and architecture remain essential, but they are
now *means*, not ends. A security checkpoint is complete when it removes a
blocker (outcome A); a capability checkpoint is complete when it delivers and
measures a capability (outcome B).

### 2.1 What this does not change

- Implementation is not verification. A disposition of `IMPLEMENTED` is never a
  substitute for `INDEPENDENTLY_VERIFIED`.
- Unresolved findings do not disappear into the programme. RL-565 remains
  `HIGH / OPEN`; RL-564 and `F-ARC-018` remain `OPEN`. TCP does not close them
  and does not block on them, but every TCP checkpoint that touches a governed
  surface must state whether it changes those findings' status.
- No deployment, merge, registry promotion, or physical actuation without
  explicit authorisation.

## 3. The eight capabilities

| ID | Capability | Observable requirement |
|----|------------|--------------------------|
| **C1** | Cognitive core | One reasoning and decision architecture connecting the 20 canonical domains, maintaining context, identifying uncertainty, forming hypotheses, coordinating cognitive processes. |
| **C2** | Autonomous research | Form research questions, find and evaluate evidence, investigate competing explanations, identify knowledge gaps, produce traceable research reports. |
| **C3** | Persistent memory and knowledge | Preserve experiences, knowledge, decisions, discoveries, relationships, provenance and lessons. Distinguish established knowledge from hypotheses and obsolete information. |
| **C4** | Simulation and experimentation | Construct models, simulate systems, test hypotheses, explore alternative futures, compare predictions with observed outcomes. |
| **C5** | Multi-domain coordination | Specialised cognitive systems collaborate, challenge one another, share evidence and coordinate investigations without losing distinct responsibilities. |
| **C6** | Environmental awareness | Connect to approved information sources, instruments, datasets and physical systems. Distinguish observed, inferred, simulated and unknown state. |
| **C7** | Cognitive interface | A unified Observatory and Control Center showing what is known, what is being investigated, what is being done, why a conclusion was reached, and where human authority is required. |
| **C8** | Constitutional self-development | Detect deficiencies, propose improvements, test them in isolation, submit evidence for review, and implement only properly authorised changes. CEL coordinates; it does not replace constitutional authority. |

## 4. The five completion phases

| Phase | Objective | Exit condition |
|-------|-----------|----------------|
| **I. Integrity and trust** | Close critical governance, execution, persistence and false-success vulnerabilities. | Independent verification and reproducible regression evidence. |
| **II. Cognitive integration** | Connect the 20 domains into one functioning cognitive architecture. | End-to-end investigations traverse multiple domains coherently. |
| **III. Research intelligence** | Deliver autonomous research, analysis, hypothesis generation and verification. | Complete research tasks with traceable evidence and reproducible conclusions. |
| **IV. Living knowledge environment** | Integrate memory, simulation, learning, environmental awareness and multi-agent coordination. | Knowledge and investigations persist across sessions and produce measurable improvements. |
| **V. Operational readiness** | Complete Observatory, Control Center, reliability, security and deployment. | Sustained operation with observable, independently verified capabilities. |

## 5. The cognitive cycle — the definition of finished

Tiannara is finished when it demonstrably runs this cycle, with every
significant conclusion and action traceable to evidence:

```
PERCEIVE            receive information and observe the environment
UNDERSTAND          interpret, contextualize and connect knowledge
INVESTIGATE & REASON generate hypotheses, research and challenge conclusions
SIMULATE & VERIFY   test predictions against independent evidence
REMEMBER & LEARN    preserve validated knowledge and update uncertainty
DECIDE & ACT        recommend or execute only within authorized boundaries
```

Compilation, startup, green test suites and impressive simulations are **not**
evidence of completion. Each cycle stage requires its own measurable
acceptance test (see the Master Completion Assessment, §4).

### 5.1 Scope of the "living organism" claim

The architectural and operational ambition is an artificial living organism:
observable cognitive capabilities, self-maintenance under governance,
continuous learning, and self-directed improvement within authorised
boundaries. It is **not** a claim that software has biological life or
consciousness. Tiannara must *demonstrate* cognitive capabilities rather than
assume them, and the acceptance tests are written so that a system which
merely simulates the appearance of cognition fails.

## 6. Programme artefacts

| Artefact | Purpose | Location |
|----------|---------|----------|
| Master Completion Assessment | Repository-grounded map of every subsystem against the eight capabilities, with status classification, evidence pointers, dependencies, implementation order and acceptance tests. | `certification/tcp/TCP-001_MASTER_COMPLETION_ASSESSMENT.md` |
| Completion Register | Single source of truth: blockers, owners, evidence, closure criteria. | `certification/tcp/TCP-001_COMPLETION_REGISTER.csv` |
| This charter | Programme rules, two-outcome rule, phase model, disposition vocabulary. | `certification/tcp/TCP-001_PROGRAMME_CHARTER.md` |

The register is the only place a blocker is tracked. If a defect is not in the
register, it is not on the programme.

## 7. Status classification vocabulary

Every subsystem in the Master Completion Assessment carries exactly one
classification, determined by repository evidence rather than by intent:

| Status | Definition | Evidence test |
|--------|------------|---------------|
| `IMPLEMENTED` | Substantive implementation exists, is wired, and is exercised. | Module has real behaviour, is reachable from a supervision tree or a live call path, and has passing tests. |
| `PARTIAL` | Real implementation exists but is incomplete, unwired at some edge, or measured only by a stub. | Partial behaviour with a named missing piece. |
| `DUPLICATED` | Two or more implementations of the same capability exist and can diverge. | Same module name in two stacks, or two code paths serving one capability. |
| `STUBBED` | Declared capability with no substantive behaviour. | Empty GenServer, `{:stub, ...}` return, canned value, or docstring that contradicts the body. |
| `DISCONNECTED` | Implementation exists but is unreachable from any supervision tree or live call path. | No caller and no supervisor child. |
| `MISSING` | No implementation exists. | Absent from the repository. |

## 8. Disposition vocabulary (carried over from the CP/RL line)

`INDEPENDENTLY_VERIFIED` · `PARTIALLY_VERIFIED` · `VERIFICATION_FAILED` ·
`VERIFICATION_BLOCKED` · `IMPLEMENTED_WITH_PARTIAL_EVIDENCE`

TCP-001's own disposition is stated in §10. It does not close RL-565.

## 9. Checkpoint template (binding)

Every future checkpoint record must contain:

1. **Checkpoint ID** and **outcome claimed** — A or B (or both), with the specific
   blocker removed or capability delivered.
2. **Repository-grounded evidence** — exact file paths and measured counts. No
   claims derived from names or docstrings alone.
3. **Tests** — exact test files, exact counts, seeds used, exact assertions.
   Broad `{:error, _}` / `match?({:error, _})` assertions are prohibited.
4. **Disposition** — from §8, with independent verification explicitly
   separated from self-attestation.
5. **Register update** — rows added, closed or re-scoped.
6. **Non-goals** — what was deliberately not touched, and why.

## 10. TCP-001 outcome and disposition

**Outcome A + B.** TCP-001 both establishes the programme (B: the completion
assessment and register are new deliverables) and removes demonstrated blockers
(A: two capability-8 defects, nine duplicated native boundaries, and a
control-centre API that served fabricated data as measurements — see the Master
Completion Assessment §5).

**Disposition:** `IMPLEMENTED_WITH_PARTIAL_EVIDENCE` / `VERIFICATION_BLOCKED`.

No independent verifier was available for TCP-001. The assessment is
self-attested. RL-565 remains `HIGH / OPEN`; RL-564 and `F-ARC-018` remain
`OPEN`. No merge, deployment, registry promotion or physical actuation was
performed.

**Measurement basis.** The assessment was produced by direct repository
measurement (module and namespace census, hollow-module detection, duplicate
detection, supervision-tree analysis, call-graph reference counting,
hardcoding census), corroborated by two independent deep-scan passes over the
capability surface. Every count in the assessment is reproducible from the
repository at the stated commit.

---

## 11. TCP-002 — W0: Cognitive Capability Activation

**Status:** ACTIVE. TCP-002.1 (activation map) and TCP-002.2 (Cognitive
Execution Spine) delivered. TCP-002.3–002.6 open.

TCP-002 is the first checkpoint governed by the two-outcome rule. Its
substantive finding:

> 336 runtime modules — 24 % of the runtime — contained substantial, implemented
> capability that no process ever called, and a material part of it was
> **broken** rather than merely unwired.

The activation map (`tools/tcp/tcp002_activation_map.py`) showed that **none of
the 336 was a process** — they are stateless libraries and behaviour
contracts. The activation mechanism is therefore *composition*, not
supervision, and the Cognitive Execution Spine was built as a thin sequencing
contract over engines that already exist: **one** process for **339** modules,
with authority and knowledge as fail-closed ports.

Four defects were found by activation that inspection had not found, two of
them (`CognitiveContext.compute_fingerprint/1` and
`ContextBuilder.build_context/3`) fatal to every caller.

Details: `certification/tcp/TCP-002_EXECUTION_SPINE.md`,
`certification/tcp/TCP-002_ACTIVATION_MAP.md` / `.csv`.

**Disposition:** `IMPLEMENTED_WITH_PARTIAL_EVIDENCE` / `VERIFICATION_BLOCKED`.
784 tests and 32 properties, 0 failures, at seeds 0 and 123456. RL-565 remains
`HIGH / OPEN`; RL-564 and `F-ARC-018` remain `OPEN`. No merge, deployment,
registry promotion or physical actuation.

---

## 12. TCP-002.4 — Research-to-Forecast Operational Closure

**Status:** ACTIVE — **PARTIAL**. Stages 0–3 delivered; Stages 4–13 open.

TCP-002.4 is the first checkpoint aimed at a **complete, traceable forecasting
lifecycle** rather than at a boundary or a component. Its central acceptance
target is one research investigation whose forecast survives persistence, whose
outcome is independently resolved, and whose result reaches a genuine score.

**Delivered:**

- **Stage 2 — the Research Director reaches EFDI.** A new adapter
  (`Tiannara.Research.Forecasting`) performs no forecasting mathematics; the
  *supervised* Research Director now requests a probabilistic forecast at the
  hypothesis-evaluation stage and records the forecast id on the hypothesis.
  A hypothesis that is not a forecastable proposition is marked
  `:not_forecastable` — it is **not** given an invented probability.
- **Stage 3 — the durable registry is adversarially verified.** 14 tests against
  an isolated on-disk log. Writing them exposed two real defects, both fixed at
  source: the event log **silently truncated history** at the first unreadable
  frame (corruption was presented as clean history), and `Event.from_binary/1`
  used an **unsafe** `binary_to_term` that could introduce executable terms
  from a tampered log.

**Not delivered, and stated plainly:**

- **No real observed outcome was acquired**, so there is no independent
  resolution, no score and no calibration. Stage 4 is **BLOCKED** by the
  absence of a live external source in this environment — not by a missing
  implementation of the machinery, which exists and is correct.
- The NATS transport remains compiled but unexecuted.
- **No predictive-performance claim of any kind is made.** A single forecast
  cannot establish calibration, and nothing in this checkpoint pretends
  otherwise.

**Disposition:** `IMPLEMENTED_WITH_PARTIAL_EVIDENCE` / `VERIFICATION_BLOCKED`.
RL-565 remains `HIGH / OPEN`; RL-564 and `F-ARC-018` remain `OPEN`. No merge,
deployment, registry promotion or physical actuation.

Details: `certification/tcp/TCP_002_4_IMPLEMENTATION_REPORT.md`,
`certification/tcp/TCP_002_4_BASELINE_AND_INTEGRATION.md`,
`certification/evidence/tcp002_4/`.

---

## 13. TCP-002.5 — Outcome Integrity, Independent Verification, and Durable Forecast Resolution

**Status:** ACTIVE — **PARTIAL**. Stages 0–3 and 9 delivered against real durable
implementations; Stages 4–8 and 10–13 open.

TCP-002.5 is an **outcome-integrity** checkpoint, not a learning checkpoint.
Its success criterion is the first independently verified, durably recorded
forecast score — and, where that is not reachable, the honest closure of the
integrity and contract defects that block it.

**Delivered:**

- **Stage 1 — deterministic ordering (TCP-B-057, RESOLVED).** The durable event
  log now carries a versioned frame envelope with a store-assigned sequence, a
  SHA-256 record digest and the previous record's digest. The first record must
  be sequence `1`; a wrong origin means **no later record can establish one**,
  and nothing is applied. Sequence gaps, duplicates, reordering, removal,
  payload and digest modification and truncation are each proven against real
  files to leave the exact expected state.
- **Stage 2 — record integrity (TCP-B-058, PARTIAL).** Integrity is established
  and verified on append and recovery; `Event.from_binary/1` no longer accepts
  arbitrary terms. **Authenticity is not established and is not claimed** — a
  digest proves that the bytes are the bytes recorded, not who wrote them, and
  the chain has no anchor outside the log's own storage boundary.
- **Stage 3 — typed horizon (TCP-B-059, PARTIAL).** `Contracts.Horizon` is a
  typed, UTC-normalised, validated temporal contract with a closed/open
  publication policy; it is required by the bridge, persisted in the forecast,
  and bound into the forecast's outcome-definition digest. Legacy forecasts
  without one remain readable but are not eligible for normal resolution.
  **The resolution path does not yet read it**, so enforcement at resolution is
  not proven and the finding stays partial.
- **Stage 9 — scoring verified.** The canonical `Calibration.score/2` is
  unchanged and is pinned against **independently calculated** Brier and
  log-loss vectors, with the implementation's binary convention now documented
  rather than assumed.

**Not delivered, and stated plainly.** No observation was acquired, so nothing
was independently verified, resolved or scored. The lifecycle is demonstrated
to `FORECAST_REGISTERED` and no further. **No real-world predictive
performance claim of any kind is made.**

**Disposition:** `IMPLEMENTED_WITH_PARTIAL_EVIDENCE` / `VERIFICATION_BLOCKED`.
Register: 63 rows — 42 open, 18 resolved, 3 partial. RL-565 remains `HIGH /
OPEN`; RL-564 and `F-ARC-018` remain `OPEN`. `ModelUpdateGate` is unchanged
and still forbids production mutation without human review. No merge,
deployment, registry promotion or physical actuation.

Details: `certification/tcp/TCP_002_5_IMPLEMENTATION_REPORT.md`,
`certification/evidence/tcp002_5/`.
