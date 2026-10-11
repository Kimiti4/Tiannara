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
