# AEO / RAC / AAL Foundation Status

**Scope:** foundational execution and evidence-boundary hardening  
**Status:** implementation proposed in PR #12; CI and end-to-end integration remain pending.

This report supersedes older prose that describes a component as complete merely because a module or interface exists. It records implemented behavior separately from configured integration and certification.

## Implemented in this change

### Adaptive Execution Orchestrator (AEO)

- Translates non-empty text or a goal map into a deterministic, inspectable execution graph.
- Rejects malformed intent and invalid domain weights.
- Submits only through a configured runtime adapter.
- Accepts only structured runtime receipts with an execution ID and an `accepted` or `running` status.
- Returns explicit errors when the adapter is missing, malformed, or fails.
- A planned graph is not represented as executed work.

### Reality Admission Control (RAC)

- Performs a local uncertainty-contract check requiring an explicit statement, bounded confidence and uncertainty, and non-empty evidence.
- Requires configured ACM and OAVL checker modules to return evidence-bearing PASS results.
- Treats missing checkers, exceptions, malformed responses, and absent evidence as UNKNOWN or failure.
- Re-runs checks during admission rather than trusting caller-supplied status flags.
- Requires a configured World Model adapter to actually perform admission; otherwise returns `world_model_unavailable`.

The local UMSC check is a structural uncertainty check, not proof that a claim is true. ACM/OAVL correctness depends on the configured implementations and their independent evidence quality.

### AAL and workspace artifacts

- Command handling returns an observable result instead of immediately acknowledging a background cast.
- Extraction failures and timeouts are retained in the returned error.
- Partial or invalid blueprint sets do not produce workspace artifacts.
- The workspace location is configurable and defaults to a path under the current user's home directory.
- Artifacts receive a SHA-256 manifest.
- Artifact writing no longer initializes a Git repository or creates a commit. Writing files is not source-control approval or deployment.

## Not yet certified

- No local Elixir runtime was available to run ExUnit in the implementation environment.
- CI was queued/in progress when this report was written; a green result must be observed before calling the change verified.
- Production AEO runtime adapter wiring is not yet established by this change.
- Production ACM/OAVL checker implementations and their evidence provenance are not yet established by this change.
- Production World Model admission adapter wiring is not yet established by this change.
- End-to-end replay, failure injection, authorization-boundary testing, and cross-platform runtime verification remain required.
- The remaining phase-document reconciliation and full module-to-test matrix are still in progress.

## Required next gates

1. Obtain passing CI for compilation, focused tests, and cross-platform checks.
2. Wire AEO to the canonical governed execution path; do not use a generic adapter that bypasses Council/CIS or human-approval requirements.
3. Connect RAC to trusted ACM/OAVL implementations and the canonical World Model write API; verify that failed, unknown, or contradictory evidence cannot be admitted.
4. Add end-to-end tests that exercise the real adapters rather than test doubles.
5. Update architecture and phase status documents only after those gates produce evidence.
