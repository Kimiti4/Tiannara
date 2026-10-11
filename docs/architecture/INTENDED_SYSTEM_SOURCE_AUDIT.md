# Tiannara AI — Intended-System Source Audit (Initial Slice)

**Audit basis:** repository `main` source tree and the named documents listed below, inspected on 2026-10-11.  
**Purpose:** distinguish documented intent from source presence, exercised behavior, and certified capability.  
**Scope warning:** this is an initial targeted slice, not a claim that all 1,812 Markdown paths containing “phase” have been individually reviewed. The repository contains 2,993 Markdown files in total; many phase-named files are nested experiment reports or generated evidence.

## Status vocabulary

- **IMPLEMENTED-VERIFIED** — behavior is exercised by relevant tests and the current CI/runtime evidence is available.
- **IMPLEMENTED-UNVERIFIED** — source exists, but relevant tests or current runtime evidence are missing/not yet confirmed.
- **PARTIAL** — a narrow mechanism exists, but the documented end-to-end capability does not.
- **MISSING** — no corresponding implementation was found in the inspected source tree.
- **STALE/CONFLICTING CLAIM** — documentation claims more than source/evidence currently supports.
- **DEFER** — intentionally outside the first practical interaction/continuity milestones.

A filename, module declaration, documentation checkmark, or unit test alone does not establish end-to-end certification.

## Initial source-to-intent matrix

| Intended system / claim | Source observed on `main` | Test / evidence observed | Initial status | Gap / consequence |
|---|---|---|---|---|
| Adaptive Execution Orchestrator (AEO) translates intent into an execution graph | `lib/tiannara/aeo.ex` returns `:execution_graph_placeholder` from `translate_intent/1`; `submit_to_runtime/1` returns `:submitted_to_runtime` without a runtime receipt | No matching AEO test was established in this initial source review | **STALE/CONFLICTING CLAIM** | Main's API reports planning/submission without a real graph or observed runtime acceptance. The hardening PR replaces this with a deterministic graph and fail-closed configured adapter, but the adapter is not yet wired/certified. |
| Reality Admission Control (RAC) challenges claims before World Model admission | `lib/tiannara/reality_admission_control.ex` returns descriptive tuples and unconditionally reports successful admission from `admit_to_world_model/1` | No evidence-bearing adversarial checker or canonical World Model adapter found in the main implementation reviewed | **STALE/CONFLICTING CLAIM** | Main's methods are placeholders, not adversarial validation. The hardening PR requires evidence-bearing checker adapters and fails closed if they are absent; adapters remain an integration gate. |
| Lexical Tensegrity Field maps language to domain(s) | `lib/tiannara/aal/lexical_tensegrity_field.ex`; `lib/tiannara/aal/semantic_encoder.ex` | Main file has no corresponding test located in the initial review; hardening branch adds a no-match regression test | **PARTIAL** | Only seven domain vectors are present despite a “20 domains” comment; hashing-trick lexical overlap is not a semantic model; core action is always `:synthesis`. No-match behavior must remain explicit instead of silently falling back to Engineering. |
| AAL Command Loom returns a truthful command outcome | `lib/tiannara/aal/command_loom.ex` | Hardening branch has source changes and related tests are still subject to CI | **STALE/CONFLICTING CLAIM on main; PARTIAL on PR branch** | Main uses fire-and-forget `GenServer.cast`, drops failed/timeout results, writes filtered outputs, and logs a confirmation claiming a commit occurred. PR branch switches to a call/observed result, refuses empty domain matches, reports incomplete extraction, and separates artifact writing from Git/hardware actions. |
| Blueprint validation proves generated hardware is safe | `lib/tiannara/aal/blueprint_validator.ex` | Structural validator tests exist on the PR branch; CI result pending | **PARTIAL** | Current validation checks fields, confidence range and Verilog module delimiters. It does not prove semantic correctness, successful synthesis, simulation, or hardware safety. The PR documentation correctly narrows the claim. |
| Base Reality workspace output is version-controlled and committed | `lib/tiannara/base_reality/workspace.ex` on main historically called Git commit operations via the Command Loom path | Hardening branch tests exercise workspace writes; CI result pending | **PARTIAL** | File output, Git commit, build, deploy, and hardware action are distinct. PR branch writes into a configurable workspace with hashes and explicitly reports `source_control: :not_committed`. |
| Unsupported domains are routed to the correct extractor | `lib/tiannara/domains/extruder.ex` | PR branch includes unsupported-domain tests; CI result pending | **PARTIAL** | Only Engineering, Energy, and Computation have explicit dispatch in the reviewed dispatcher. Placeholder world context/discoveries are not live state; unsupported domains must fail rather than be mislabeled as Engineering. |
| ContextGraph / contextual anticipation | No dedicated `ContextGraph` implementation path found. Adjacent modules exist: `lib/tiannara/executive/cognitive/context_manager.ex`, `tiannara_runtime/lib/tiannara_runtime/cognitive/engines/context_assembler.ex`, `context_builder.ex`, `context_snapshot.ex`, and `context_replay.ex`. | No dedicated ContextGraph test path found in the initial search. The inspected executive ContextManager explicitly labels its interpretation as mock. ContextSnapshot uses a fingerprint, but `ContextReplay.reconstruct/1` returns only the snapshot ID rather than reconstructing the state. | **PARTIAL (adjacent scaffolds); ContextGraph itself MISSING** | Existing context-related files must not be conflated with a live, event-linked, replayable graph of user goals, task state, system signals, and temporal patterns. Audit focused tests and canonical integration before reusing these modules. |
| Dedicated anticipation engine | No matching anticipation engine source path found in the current recursive source-tree search | No matching test path found | **MISSING** | No evidence of ranked next-step predictions evaluated against later outcomes. |
| Executive situational context interpretation | `lib/tiannara/executive/cognitive/context_manager.ex` | Source itself records `confidence: 0.85`, fixed urgency heuristics, and assumptions stating "Mock interpretation"; no focused test path established in this initial pass | **PARTIAL / MOCK** | Fixed confidence and category-based urgency must not be presented as learned inference or causal understanding. Replace with evidence-derived confidence and explicit unknowns before using it for autonomous decisions. |
| Completion evaluation / goal-closure monitor | No matching completion-evaluation source path found in the current recursive source-tree search | No matching test path found | **MISSING** | The system cannot claim it independently knows a requested task is complete without explicit acceptance criteria and observed evidence. |
| Proactive notification | `lib/tiannara/interface/proactive_notifier.ex` | `test/tiannara/interface/proactive_notifier_test.exs` exists on main; PR branch adds a regression test that high confidence alone does not bypass the ordinary rate limit | **PARTIAL** | It rate-limits, deduplicates, tracks acknowledgements, and logs delivery. The reviewed delivery path is a log/telemetry event, not proof of a live human-facing channel. The emergency/critical bypass still relies on the supplied severity field and needs trusted provenance/authorization before it can be treated as a secure emergency path. It is not itself a ContextGraph or anticipation engine. |
| Ontology bridge / cross-domain synthesis | No matching ontology-bridge source path found in the current recursive source-tree search | No matching test path found | **MISSING** | The proposal in `markdown/5j.md` references an LLM-based bridge. For Tiannara's independence requirement, implement a bounded, evidence-linked non-LLM candidate-mapping mechanism; do not pretend lexical similarity establishes a valid scientific analogy. |
| Phase 16.1 research/replay modules are certified | The 23 source paths referenced by `MODULE_IMPLEMENTATION_MATRIX.md` resolve in the current tree, including question generation, hypothesis/experiment/theory engines, knowledge graph, replay engine, and archaeology modules. | `REPLAY_IMPLEMENTATION_REPORT.md`, `tiannara_runtime/RUNTIME_IMPLEMENTATION_REPORT.md`, and `ARCHAEOLOGY_IMPLEMENTATION_REPORT.md` explicitly describe implementation/infrastructure rather than certification. The Phase 16.1-named module paths have no corresponding focused test files in the inspected `tiannara_runtime/test/` tree; `PHASE16_PRE_IMPLEMENTATION_AUDIT.md` lists certification-time outputs as absent at spec stage. | **IMPLEMENTED-UNVERIFIED / STALE CLAIM RISK** | Module presence is supported; focused behavioral verification and certification are not established. Treat the matrix's “complete” label as implementation status only. Add focused tests, execute replay/campaign gates, and generate signed evidence only after gates pass. |
| Phase 5E self-regulating runtime is production-certified | `PHASE5E_COMPLETE.md` and `PHASE5E_BOOT_VALIDATION_COMPLETE.md` report broad completion/boot validation | Historical report-level evidence; current independent production gate not established by this review | **STALE/CONFLICTING CLAIM RISK** | A historical boot validation does not prove present production readiness or certify all described behaviors. Re-run applicable tests and runtime checks on current source. |

## Confirmed high-priority defects on `main`

1. **False execution success:** AEO's main-branch implementation returns placeholder success-shaped values.
2. **False epistemic admission:** RAC's main-branch admission function returns success without running evidence-backed checks.
3. **False command completion:** AAL's main-branch command handler is asynchronous/fire-and-forget and logs that artifacts were committed even though its workspace path does not establish a real Git commit.
4. **Domain misrouting:** LTF describes 20 domains while defining seven, always chooses `:synthesis`, and main silently falls back to Engineering on no match.
5. **Overstated safety:** structural Verilog checks cannot certify hardware correctness or safety.
6. **Unwired proactive channel:** notifier logging is not the same as an independently verified notification delivery channel.

The current draft PR `hardening/aeo-rac-truthful-execution` addresses items 1–5 in part by making outcomes observable and failure states explicit. It does **not** yet wire the trusted AEO runtime adapter, ACM/OAVL checkers, canonical World Model adapter, or certify real generated artifacts. Those are explicit remaining gates.

### Additional continuity/context finding
The repository does contain several context and continuity components; therefore, the right conclusion is not that all context work is absent. However, the inspected executive ContextManager labels its interpretation as mock, the CCOS ContextBuilder deterministically sorts caller-supplied artifacts without retrieving missing context, and ContextReplay's `reconstruct/1` returns a snapshot ID rather than reconstructing context state. The AE-006 protocol specifies stronger continuity/recovery expectations, but the presence of that protocol does not itself prove the gates passed. These components need a contract-and-test audit before any is promoted to the assistant's canonical continuity layer.

## Implementation order recommended by this audit

### Gate 0 — Establish truthful execution boundaries
- Keep the AEO/RAC/AAL hardening changes.
- Obtain green CI on the exact PR head.
- Add or retain regression tests proving missing adapters, unsupported domains, extraction failures, malformed outputs, and workspace errors never become success.
- Do not merge while required CI is queued or failing.

### Gate 1 — Reliable interaction and continuity
- Define a canonical interaction record: user goal, normalized intent, constraints, relevant context references, expected result, and evidence references.
- Add bounded, inspectable conversation/task continuity with explicit retention and provenance.
- Do not infer durable memory or live world state from empty/default placeholder maps.

### Gate 2 — Completion awareness
- Define per-task acceptance criteria before execution.
- Track planned, running, blocked, failed, completed-with-evidence, and unknown states.
- Require observed artifacts/tests/results for completion; a generated response or successful file write is not automatically task completion.

### Gate 3 — Contextual anticipation
- Implement a small, deterministic ContextGraph over explicit interaction/task/system events.
- Produce ranked suggestions with reasons, confidence/uncertainty, and a no-action option.
- Evaluate predictions against subsequent user choices and outcomes before raising autonomy.

### Gate 4 — Governed proactivity
- Route suggestions through notification policy, deduplication, rate limits, operator acknowledgement, and observable delivery receipts.
- Do not allow confidence alone to override all ordinary rate limits; emergency bypass must be tied to a separately authenticated severity source.

### Gate 5 — Evidence-linked cross-domain synthesis
- Start with candidate relationships derived from shared concepts, units, causal structure, and explicit mappings.
- Preserve source evidence and state where an analogy is merely proposed.
- Require domain-specific validation before translating an insight into an executable blueprint.

### Gate 6 — Adaptive refinement
- Compare predictions to observed outcomes, record misses and corrections, and update bounded parameters only through reviewed changes.
- Any self-improvement remains subject to the established human-authority and governance gates.

## Audit limits and next review

This initial pass intentionally prioritizes systems on the direct path to a reliable assistant. The full phase-document review remains open. Next, reconcile the Phase 13–16 specifications and certification reports with actual module/test paths, then audit the runtime/OTP integration and replay evidence. No system should be marked certified based solely on a completion-report heading.
