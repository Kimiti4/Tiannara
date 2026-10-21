# Proposed target architecture (Phase R0 deliverable 9)

**Status:** proposal for review. Nothing here is implemented, and no decision in this document has been taken.
Each rule below is traceable to a root-cause cluster in `findings_ledger.md` and to the cluster's upstream fix.

This document states the *shape* the platform must reach to make closure decidable: one capability, one authoritative implementation, explicit dependencies, independently verified evidence, one closure decision (operator §central rule). It deliberately does not choose between options where the evidence does not decide it — those are recorded as open decisions in `decisions_register.md`.

---

## 1. Ownership rules (normative)

| Rule | Statement | Replaces |
|---|---|---|
| O-1 | Every capability has exactly one named **authoritative implementation** and one named **state owner**. Where two implementations exist, one is canonical and the other is an adapter, a compatibility shim, a test fixture, or retired. | ≥4 Executive Memory stores, ≥5 constitution modules, ≥6 CIS authorities, ≥4 knowledge-graph namespaces, 3 event-bus families, 3 world models, 28 duplicate module names (C2) |
| O-2 | Ownership is recorded per **deployed application**, not per repository. Two applications may legitimately implement the same capability when each has an explicit contract and the boundary between them is written down. | Root `lib/` vs `tiannara_runtime/lib/` ambiguity (F-ARC-001, F-ARC-011) |
| O-3 | A module that is not reachable from a launcher, a supervision tree, or a documented standalone-tool contract is **not a capability**; it is unowned code with a scheduled disposition. | Test-only wiring (C9), 35 zero-evidence GenServers, 23 orphaned modules |
| O-4 | A store (ETS/DETS/Mnesia/DB/file) has exactly one owner module, one path source (configuration, never a hard-coded path or the working directory), one format version, and one documented restore procedure. | 16 committed DETS files, whole-file rewrites without locking, hard-coded `/tmp` paths (C7) |
| O-5 | Policy, protocol, schema and metric definitions have a single owning document *and* a single owning module, and the module reads the document where the document is normative. | `rules.md` unread by any code; hard-coded structs treated as authority; three competing gate families (F-GOV-002, F-GOV-009) |
| O-6 | A capability is **specification-only** until its specification is inside the repository (or a pinned external reference is recorded). It is never counted as implemented. | CAE v1.1, CAP v1.0, ISD v2.0, IF-001..004, UEP, Context Graph, Completion Evaluator, POMDP, Ontological Bridge (C8) |

## 2. Dependency rules (normative)

| Rule | Statement | Replaces |
|---|---|---|
| D-1 | Every dependency edge is recorded in one of the four graphs (`deps_code.json`, `deps_runtime.json`, `deps_governance.json`, `deps_build.json`) with a basis label: `documented`, `statically_inferred`, `dynamically_observed`, `independently_verified`. An edge with no basis is not usable as evidence. | Ad-hoc wiring discovered only by reading code |
| D-2 | A **documented** edge without an implementation is a defect, not an aspiration. A **runtime** edge absent from the architecture documentation is an architectural discovery and must be added to the atlas. | The operator's graph rule, applied in `deps_*.json` discrepancies |
| D-3 | A subsystem that no launcher starts is unreachable. Reachability is asserted by a boot check, not by a unit test. | `F-ARC-226`: the entire second OTP root is test-time-only |
| D-4 | A published interface (event subject, payload schema, replay package, API contract) is registered with a version, producers, consumers, and a compatibility test. Unregistered subjects are a CI failure. | No event registry; namespace drift `tiarnara.*` vs `tiannara.*` (C12) |
| D-5 | A verifier or gate must be able to fail. *Missing expectation, mismatch, or absent input is FAIL.* A verifier that cannot fail may not produce a report, a certificate, or a PASS. | `tiannara_audit` verifiers always PASS; "220/220 PASS" reports (C4) |
| D-6 | Generated or synthetic data is tagged at write time with its generator and a synthetic flag, and the tag survives to every consumer. A consumer may not present synthetic data as measured. | Mock worlds, stub forecasts, fabricated observatory payloads (C5) |
| D-7 | Every store write path has a corresponding recovery path; availability-only checkpointing is never counted as rollback. | Flip-a-record rollback; no real restoration (C7) |
| D-8 | Every CI job that claims coverage of a subsystem runs on the branch under remediation. | Python/Docker/release workflows gated on `main`/`master` only (C9) |

## 3. Target runtime topology (proposal)

```
Launcher (single entry point, explicit in Procfile / release / compose)
├── tiannara_api            (FastAPI — one application, one auth library, fail-closed)
│   └── observatory client  →  tiannara_runtime HTTP API   (no mock fallback; D-6)
├── tiannara_runtime        (Elixir/OTP — one supervision root, reachable from the launcher)
│   ├── ControlCenter / startup order contract   (must be in the tree, not a comment)
│   ├── Constitutional layer  (policy authority: single module, single registry)
│   │   ├── Council.authorize  (hard invariants authoritative; policy advisory)
│   │   ├── RuleEngine         (built-in scorer can reach :approved; plugin path supervised)
│   │   ├── HumanApprovalQueue (park → approve → resume)
│   │   ├── CAP gates          (single gate family, mapped to the CAP contract)
│   │   ├── Certificates       (subject-version + validity binding, keyed signature)
│   │   └── Kill switch        (one module, started, with the consumer API that exists)
│   ├── Cognitive layer       (one orchestrator; Context Graph / Anticipation / Completion
│   │                          Evaluator implemented or formally deferred)
│   ├── Epistemic layer       (UEP schema owned here; evidence ageing applied; trust scored
│   │                          from observed outcomes)
│   ├── Research/simulation   (world model, ASC, cross-domain — booted, not test-only)
│   └── Telemetry/observability (publisher → consumers, real event registry)
├── Event fabric             (one registered transport contract; real NATS or honestly named
│                            in-VM broadcast; anonymous TCP injector removed)
├── State layer              (one owner per store: CPL, KG, audit log, checkpoints; paths from
│                            configuration; restore procedure per store)
└── Frontends                (5 surfaces: root console, GUI, dashboard, observatory UI, mobile —
                             each with an owner repository and an API contract)
```

**Non-goals of the target topology** (deliberately unchanged): the cognitive capability set, the constitutional vocabulary, the Elixir/Python/TypeScript technology split, and the existing module names of canonical implementations. The target changes *reachability, ownership, and evidence discipline*, not the science.

## 4. Verification layer (one framework)

Constitutionally required suites per capability: unit, property, interface/schema compatibility, component integration, end-to-end through the real entry point, adversarial/negative authorization, deterministic replay and lineage integrity, fault injection and recovery, regression, and production-like execution. The harness reports what it verified, what it could not verify, and what it skipped. It must never convert missing evidence into a successful certification (operator §R4).

This is the direct answer to the five recurring failure patterns: a capability is not closed because a module exists, because its isolated tests pass, or because its interface is defined (patterns 3, 4, and 7).

## 5. Governance chain (proposal)

`rules.md` (or its successor document, owner named) → Policy registry → Council.authorize (invariants authoritative) → human approval (with resume) → CAP gates → certificate (bound to subject version, validity, evidence set) → state-machine transition (authorized by the certificate, enforced by the executor) → audit chain (hash-linked, with a consumer and a recovery path) → rollback (real restoration).

Each arrow is an edge in `deps_governance.json` with a basis label. Any arrow that is currently documentation-only is a finding, not an assumption.

## 6. Migration path (aligned to operator phases)

| Operator phase | Target-architecture work |
|---|---|
| R1 Stabilize foundations | Batch 1 (enforcement integrity, fail-closed claim control) + Batch 2 (reachability) — no architecture change, no moves |
| R2 Canonical ownership | Batch 4 (per-concept Register-4 decisions and enforcement) + Batch 5 (security defaults) |
| R3 Connect capabilities | Batch 3 (real data, real verifiers) + Batch 6 (event registry, interface contracts, deferred-capability dispositions) |
| R4 Verify and certify | Verification layer above; conformance, adversarial, replay, recovery suites per capability |
| R5 Release and maintain closure | Atlas updated in the same change as any code change; a closed finding cannot silently reopen |

## 7. What this proposal deliberately does not decide

- Whether the root Elixir project and `tiannara_runtime` remain two applications or merge (OP-04).
- Whether `rules.md` remains the normative policy document or is retired in favour of a machine-readable policy (D-5 record, open decision D-ARC-002).
- Whether the event fabric is real NATS or a named in-VM broadcast (D-ARC-004).
- Whether the three absent frontends are re-vendored, submodule-linked, or recorded as external boundaries (OP-03).
- The cryptographic scheme for certificates (deferred to the operator's Babel/C-08 decision).
- Any ESAP-internal structure — the ESAP repository keeps its own architecture and its own decision register.
