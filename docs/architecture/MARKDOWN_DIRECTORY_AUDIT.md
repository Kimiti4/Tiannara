# Tiannara AI — `markdown/` Directory Audit (Pass 1)

**Branch:** `hardening/aeo-rac-truthful-execution`  
**Audit date:** 2026-10-11  
**Purpose:** Reconcile the design and historical-report directory with current source, tests, and governance constraints.  
**Status:** First-pass triage; not a line-by-line certification of every document.

## Inventory correction

The direct GitHub contents listing for `markdown/` on this branch returns **248 entries**. The initial implementation audit's earlier `markdown/` bucket of 19 was incomplete and has been corrected in `INTENDED_SYSTEMS_IMPLEMENTATION_AUDIT.md`.

The directory is not a single specification. It contains:
- architectural/design documents and phase plans;
- implementation and integration roadmaps;
- test predictions, experiment outputs, and parameter-tuning reports;
- audit/security/testing guidance;
- “complete”, “production-ready”, or “100%” status reports;
- product/dashboard/SaaS setup documents and session summaries.

These categories have different evidentiary weight. A plan is a requirement candidate, a prediction is not a result, a report is a claim to verify, and a passing test only proves the behavior actually exercised.

## High-signal document findings

| Document family / representative files | What it contributes | Audit finding / disposition |
|---|---|---|
| AAL/Jarvis concepts: `5j.md`, `jarv.md`, `AEO2.md` | Context continuity, anticipation, completion awareness, cross-domain synthesis, dialogue state, and user-facing interaction. | Preserve the capability goals, not the theatrical examples. `5j.md` includes hard-coded sample outputs, invented precision/confidence examples, a GNN-like proposal without an implementation contract, and an explicit LLM call for cross-domain bridge statements. Rewrite as evidence-bound, deterministic interfaces with uncertainty and user control; no external LLM dependency. |
| Phase and control-plane designs: `5.md`, `5E.md`, `5F.md`, `5F4.md`, `5F5.md`–`5F12.md`, `5G.md`, `5final5.md` | World/runtime control, CIS/GCK/Council authority, causal/observer models, memory, replay, and phase sequencing. | Treat as proposals and historical design history until requirements map to current source and tests. The documents use evolving phase boundaries and sometimes describe modules as mandatory/complete without linked current evidence. Reconcile authority, lifecycle, and dependency rules before implementing more phase systems. |
| AEO review and architecture plans: `AEO.md`, `AEO2.md`, `AEO_REVIEW_AND_INTEGRATION_PLAN.md`, `AEO_COMPLETE_REVIEW_SUMMARY.md`, `COGNITIVE_ARCHITECTURE_INTEGRATION_PLAN.md` | Cognitive immune system, metacognition, orchestration and integration roadmaps. | The filename `AEO.md` contains substantial CIS material rather than being a narrow AEO specification. Some “implemented/fully implemented” statements are not supported by the current AEO source: the current PR still has an adapter boundary, not a proven governed runtime integration. Split requirements by subsystem and replace broad completion labels with source/test/runtime evidence. |
| Experiment reports: `1000_STEP_TEST_PREDICTION.md`, `500_STEP_TEST_*.md`, `TEST_1000_STEPS_STATUS.md`, `TEST_500_EPISODE_RESULTS.md` | Parameter tuning, cognitive-mode distribution, long-horizon and episode experiments. | `1000_STEP_TEST_PREDICTION.md` is explicitly predictive, not observed evidence. The 500-step reports show changing and sometimes contradictory mode distributions across variants; several report 99–100% reflex dominance or explicitly partial success. Keep raw run provenance, code revision, seeds, configuration and machine-readable outputs together. Do not count each report as an independent successful certification campaign. |
| Validation / capability claims: `COMPREHENSIVE_VALIDATION_RESULTS.md`, `ENHANCED_FALSE_EVIDENCE_AUDIT_COMPLETE.md`, `COGNITIVE_DOMAINS_IMPLEMENTATION_COMPLETE.md`, `TIANNARA_INTELLIGENCE_ASSESSMENT.md`, `DOMAIN_VALIDATION_AUDIT.md`, `VALIDATION_EXECUTION_RESULTS.md` | Belief resilience, domain coverage, cognition and validation status. | These documents make strong pass-rate and production-readiness claims, while some explicitly describe simulated tests, incomplete criteria, or failures. Revalidate each claim against the exact source revision, test command, raw result and acceptance threshold. Simulation-only evidence must remain labelled simulation-only. |
| Product / operations: `README.md`, `architecture.md`, `DEPLOYMENT_GUIDE.md`, `DEPLOYMENT_CHECKLIST.md`, `PRODUCTION_DEPLOYMENT_COMPLETE.md`, `TESTING_GUIDE.md`, `WORKSPACE_AND_API_GATEWAY_SETUP.md` | API gateway, SaaS dashboard, deployment, WebSocket and testing instructions. | These are a separate product/operations stream, not proof of cognitive runtime readiness. Some include local Windows paths and “ready/complete” claims. Validate instructions against current workflows and repository layout before treating them as canonical. |
| Security / epistemic governance: `SECURITY_AUDIT.md`, `audit.md`, `6audit.md`, `ENHANCED_FALSE_EVIDENCE_AUDIT_COMPLETE.md` | Secret handling, adversarial evaluation, epistemic integrity, phase governance. | Keep security and epistemic integrity as gates. Historical vulnerability findings need current-source verification; a report saying a fix was implemented is not proof the current branch is safe. Any claimed PASS needs reproducible tests and evidence provenance. |

## Cross-document contradictions and design risks

1. **Specification vs implementation:** architecture plans frequently describe capabilities as already complete. The current source audit instead finds AEO/RAC integration adapters not yet wired to a proven canonical runtime path, fragmented context implementations, no general task-completion contract demonstrated end-to-end, and cross-domain modules whose evidence path is not yet established.
2. **LLM independence:** some illustrative design examples call an external LLM for synthesis. That is not an acceptable core dependency for Tiannara AI; use retrieval, explicit typed relations, deterministic synthesis rules, and evidence-linked hypotheses.
3. **Completion semantics:** a dispatch, a generated blueprint, a simulation, or a log entry is not task completion. Completion requires task-specific acceptance criteria and independent postcondition evidence.
4. **Authority-chain ambiguity:** phase documents sometimes use fire-and-forget casts for operations while describing a single authoritative execution spine. Destructive or state-changing work must have a result-bearing, governed authorization path; no caller should be able to bypass CIS/Council/human-approval boundaries.
5. **Overlapping names and duplicated architecture:** AEO/CIS, ContextGraph/context managers, completion evaluators, memory/lineage, and cross-domain reasoning appear in multiple documents and modules. Map existing source and ownership before adding parallel modules.
6. **Evidence duplication:** multiple parameter reports and “complete” summaries may derive from the same experiment family. Count independent runs by reproducible run IDs/configurations, not by Markdown filenames.
7. **Stale machine-local links:** multiple documents use `file://c:/Users/...` links and old local project names. Replace them with repository-relative links where the target exists, or mark them historical.
8. **Security report freshness:** the directory's security audit lists serious classes of issue (including hard-coded credentials/secrets and weak password hashing). Those findings must be checked against current code and current configuration; do not infer either that they remain exploitable or that they were fixed solely from the report.

## Implementation priorities derived from the documentation

### P0 — Trustworthy request-to-outcome path
- CI must pass on the exact PR head.
- Keep unknown and ambiguous intent explicit; no silent engineering/synthesis default.
- Connect AEO to the governed runtime and RAC to trusted checkers/World Model admission with real receipts.
- Preserve truthful failures and prevent partial output from being described as completion.

### P1 — Continuity and task completion
- Map existing executive/context/memory modules and identify the canonical owner.
- Establish persistent context with provenance, scope, expiry, contradiction handling and restart semantics.
- Add task-specific acceptance criteria and independent postcondition checks.

### P2 — Bounded anticipation and cross-domain synthesis
- Derive suggestions only from observed state and evidence-backed dependencies.
- Make suggestions advisory, explainable, rate-limited, dismissible and user-controlled.
- Reuse existing cross-domain discovery/analogical reasoning if sound; emit hypotheses with evidence and counter-evidence.

### P3 — Reconcile phase architecture
- Build a requirement-to-source-to-test matrix for Phase 5E/5F and the runtime/governance contracts.
- Resolve contradictory phase boundaries, authority ownership, and completion claims.
- Defer civilization-scale/self-modification expansion until the foundational interaction path passes.

## Review status and next pass

This pass inspected representative architecture, AEO/Jarvis, phase/control-plane, validation, experiment, product/operations, and security documents. It is a triage, not a claim that all 248 entries have been read line-by-line.

Next pass should enumerate all directory entries into a manifest, group exact/near-duplicate reports, extract each document's stated status/date/revision/test evidence, and cross-reference the highest-priority canonical requirements to source and tests. Large files such as `55.md` require section-level review rather than treating a truncated excerpt as a complete read.

No architecture claim in this report is a certification result.


## Phase-document reconciliation (second pass)

The following phase documents were read beyond their filenames and headings. This is a design-conflict review, not a certification of the proposed physics/runtime systems.

| Document | Document-level claim or design | Source-of-truth decision |
|---|---|---|
| `5.md` | Declares a required pre-5F stack: runtime/resource governance, CIS, Safety Cortex, KillSwitch, GCK, observer and collapse components. | Convert the list into a requirement matrix; do not assume that listed modules exist or are integrated. Single-owner authority and resource bounds are prerequisites, not phase-completion prose. |
| `5E.md` | Says Phase 5E is “completed but still evolving,” then specifies additional CTN production architecture and a transition gate. | The completion label is internally ambiguous. Define a finite Phase 5E exit contract, source/test evidence and explicit transition conditions before declaring it complete. |
| `5F.md` | Proposes GPU/VRAM-centric causal-knot computation, NATS feedback, Mnesia/Amnesia graph storage and at one point says the new design “replaces GCK completely.” | This is a proposal, not evidence of deployed capability. The claim to replace GCK conflicts with the separate phase docs' global consistency/authority role. Do not remove or bypass a governance/consistency gate based on a speculative subsystem proposal. Treat GPU, NATS and data-layer choices as implementation options requiring measured need, bounded fallback and tests—not constitutional requirements. |
| `5F4.md` | Describes ExecutionController as the sole execution spine, CIS Supervisor as policy-only, and KillSwitch as an execution tool, while also discussing observer-relative/holographic memory. | The single authority spine is a candidate invariant to reconcile with the current canonical runtime. Separate grounded execution control from speculative observer-memory models; no parallel path may bypass authorization or the kill switch. |
| `5F5.md` | Defines MSCL resource/contradiction budgets and says duplicate authority modules must be consolidated. | Resource budgets and one-owner rules are testable requirements. The ontology/thermodynamic framing is metaphor unless mapped to measurable resource counters, invariants, admission/rejection behavior and failure recovery. |
| `5F6.md` and `5F7.md` | Propose observer-physics compilation, epsilon shims, decoy ontologies/honeypots and an observer revelation governor. | High complexity and significant adversarial semantics. Defer operational implementation until provenance, sandbox isolation, bounded compute, auditability and noninterference are specified. Any decoy or escape behavior must remain inside explicitly isolated research simulations and must not weaken Tiannara's real authorization boundaries. |
| `5F8.md` and `5F9.md` | Propose inter-sandbox resonance/jailbreak dynamics and a recursive compiler defense that can shift compute load to observer manifolds. | Do not treat this as an operational roadmap. “Escape” and hidden transfer of computational work are threat-model scenarios to test safely, not desired runtime powers. Never offload work onto users/observers without explicit consent and resource accounting. Keep sandbox boundaries enforceable by external controls. |
| `5G.md` | Proposes a singularity vent/latent archive to handle runaway complexity and preserve state. | The useful requirement is bounded overload handling with durable provenance and recoverability. Archive/restore must preserve integrity, ownership, access controls, quotas and tested restore semantics; “reality must never fully converge” is not an acceptance criterion. |
| `5final5.md` | Combines multiple future subsystems and describes a complete Phase 5 stack, including OPC/DFG and many governance/phase schedulers. | This is a synthesis of proposals, not a stable normative specification. It combines multiple overlapping authorities and modules. Extract only measurable invariants and define one canonical owner for each responsibility before implementation. |
| `55.md` | A very large document mixes OSS computation, APIs/callbacks/validation, placeholder symbolic analysis, WebGL/GPU proposals, and later Phase 5D/physics compiler material. | This document is too heterogeneous to serve as a single actionable specification. Split or index by subsystem; distinguish real code snippets from pseudocode, aspirational claims, and examples that depend on browser/GPU features not guaranteed by the backend runtime. Its 414 KB size makes section-level tracing essential. |
| `5j.md` | Defines a Jarvis-style AAL with anticipation, cross-domain bridges, proactive events, task completion and dialogue style. It also contains sample outputs and an LLM bridge call. | Keep AAL as an interaction layer above governed cognition. Implement only evidence-grounded suggestions and completion reports. Do not add external LLM dependencies, invent confidence, or allow proactive actions to mutate state without authorization. |

### Phase-document contradictions that block declaring a phase complete

- **Completion vs ongoing requirements:** Phase 5E is described as completed and still evolving, with additional required architecture in the same document.
- **Consistency authority replacement:** Phase 5F proposes replacing GCK, while other phase documents make global consistency a required barrier. No replacement can be accepted without a formal authority review, migration plan, and regression proof.
- **One control plane vs proliferating components:** the docs repeatedly call for a single execution authority while proposing multiple governors, schedulers, hypervisors, councils, and feedback loops. Component count is not proof of a coherent control plane.
- **Simulation semantics vs operational semantics:** observer-relative truths and ontological escape dynamics are research-simulation concepts. They must not be allowed to alter real system permissions, evidence provenance, or isolation boundaries.
- **Phase numbering is not a dependency graph:** numbered documents overlap and sometimes reintroduce earlier architecture. Derive dependencies from explicit contracts and code ownership rather than filenames alone.

## CI failure triage recorded for the latest observed head

On commit `76fe16152584dc6992db610c52972307f86f0c4a`, GitHub Actions reported:
- Elixir CI: success.
- Python Tests: failures on Ubuntu and Windows across Python 3.10, 3.11 and 3.12; lint passed.
- CI/CD Pipeline: test matrix failed, so image build and staging deploy were skipped.
- Cross-Platform Verification: Ubuntu and macOS verification steps passed, but the final certificate/hash comparison failed.

This is not a green PR. The current evidence establishes the failing job/step, but not the underlying failure messages. Do not guess a cause or edit tests to make the gate green without retrieving the relevant logs/annotations. Next step: inspect the failing test output and hash-comparison report, classify failures as regression/environment/flakiness/invariant mismatch, fix the root cause, and rerun on the exact new head. A successful compile and local platform checks do not override the failed aggregate gate.

## Revised order of work

1. Retrieve and diagnose the failed Python test logs and cross-platform hash comparison; fix causes, not thresholds or comparison semantics.
2. Validate the new LTF and CommandLoom behavior with the exact branch source, including extractor return-shape compatibility and domain-vector behavior. Unknown/ambiguous intent must not create artifacts.
3. Verify AEO runtime receipts and RAC evidence admission with real canonical adapters; missing/unknown evidence stays non-PASS.
4. Create a canonical responsibility map for CIS, SafetyCortex, KillSwitch, GCK, ExecutionController, AEO, RAC and the runtime adapter. Resolve any authority duplication before further phase work.
5. Continue full 248-entry inventory using metadata/content hashes and grouped document families. For each remaining document, record requirement-bearing sections, claimed status, linked source/test, contradictions and disposition. The current document remains a partial audit, not a claim of complete line-by-line review.


## CI root-cause evidence update

The failed Python collection log was retrieved. The matrix fails before executing the suite because `tests/test_prometheus_metrics.py` imports `tiannara_api.main`, which imports `tiannara_api.routes.mfa`, and that module imports `pyotp`. `pyotp` was absent from `requirements.txt`. Added the missing declared dependency `pyotp>=2.9.0` in the branch commit; the next workflow run must confirm whether collection and the full matrix now pass.

The cross-platform hash report was also retrieved:
- Linux canonical hash: `e38c759303ef53a7e9ce8bb71f00aa88e076215c61458f620d5a2c374dba9f00`
- macOS canonical hash: `da89a433c5246b601803694324753aaaaceef938fdfce283dec0385224669bf6`
- Result: mismatch; both platform verification jobs completed, but the comparison correctly failed.

The comparison must not be weakened to accept divergent hashes. The workflow's environment advertises `TIANNARA_DETERMINISTIC_TIMESTAMP`, but the evidence generator script does not itself read that environment variable; it also creates several wall-clock timestamps in secondary evidence artifacts. The compared `certificate.json` is canonicalized by removing only a small set of top-level timestamp keys. Nested timestamp fields or nondeterministic campaign outputs are plausible causes, not yet proven as the sole cause. Next diagnostic: preserve and compare both platform evidence artifacts at the JSON-path level, identify the first differing fields, then make the producer deterministic (or explicitly define and justify a canonical projection) and rerun the same comparison.

A further CI integrity issue was identified: `.github/workflows/elixir_ci.yml` had `continue-on-error: true` on the full ExUnit suite. The run log showed the suite hit the max-failure cap with 25 failures, even though the workflow's headline was successful. That flag has been removed so a failing full suite cannot be represented as a successful workflow. The next run may therefore report Elixir CI as failed until those test failures are resolved; that is the intended truthful gate, not a regression in the verification standard.


## Security and domain-validation claims cross-checked against source

### Security audit

The historical `markdown/SECURITY_AUDIT.md` is useful as a threat checklist, but its summary says all findings were fixed. Source checks show a mixed result:
- `tiannara_api/gateway/auth.py` requires `JWT_SECRET_KEY` when `ENVIRONMENT=production` and generates a random secret in non-production mode; this is stronger than the historical hard-coded-secret example.
- `tiannara_api/security/password.py` now exposes bcrypt password hashing and a legacy `sha256:` prefix path, so migration/legacy verification still deserves tests.
- `setup_sample_users.py` still contains a salted SHA-256 password helper. Establish whether this is test/demo-only and ensure it cannot create production credentials or be reused by live authentication.
- The `pyotp` import used by the MFA route was missing from `requirements.txt` and caused the observed test-collection failure. It has now been added as a declared dependency; the new CI run must verify it resolves the collection error.

Disposition: do not repeat the historical report's “all fixed” conclusion as current fact. Maintain a live security matrix linking each finding to production call paths, configuration mode, test coverage and remediation evidence.

### Domain validation audit

`markdown/DOMAIN_VALIDATION_AUDIT.md` itself records material gaps that conflict with broad “domain mastery”/“100% operational” summaries elsewhere in the directory:
- Its logic-domain table reports contradiction recovery failing, with 51% accuracy (49% failure) for the tested semantic contradictions.
- It reports dynamic-programming integration at 0/150 until integration is complete.
- It labels the causal-intelligence examples as a risk of spurious causal inference without intervention simulation.
- It explicitly marks several domains as infrastructure-present but not integrated or not yet validated.

Disposition: treat the document as a gap backlog, not as evidence that 14 domains are mastered. Re-run each domain's test suite against the current source, publish exact datasets/seeds/thresholds and classify each capability as implemented, integrated, verified, or unknown. Do not roll simulated or infrastructure-only status into an operational success rate.
