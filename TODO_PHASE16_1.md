# TODO — Phase 16.1 Implementation (Runtime Orchestrator + Artifacts Only)

## Step 1 — Derive exact contract inputs/outputs from spec docs
- [x] Read `AUTONOMOUS_RESEARCH_VALIDATION.md` (campaigns, gates, expected artifacts)
- [x] Read `INDEPENDENT_RESEARCH_AUDIT.md` (evidence-only constraints, input/output semantic contracts)
- [x] Read `LONG_HORIZON_RESEARCH.md` (horizon scenarios, metrics, replay/archaeology coverage)
- [x] Read `RESEARCH_READINESS.md` (RRI levels/dimensions/gating mapping)

## Step 2 — Inspect existing Phase 16.1 runtime modules (to avoid duplication)
- [x] Inspect `tiannara_runtime/lib/tiannara_runtime/autonomous_research/observation.ex`
- [x] Inspect `tiannara_runtime/lib/tiannara_runtime/autonomous_research/observation_id.ex`
- [ ] Inspect existing replay/divergence helpers (if any) under `tiannara_runtime/lib/tiannara_runtime/` (optional)

## Step 3 — Implement Phase 16.1 runtime orchestration (fail-closed, contract-aligned)
- [ ] Create `tiannara_runtime/lib/tiannara_runtime/phase16_1/orchestrator.ex`
- [ ] Create `tiannara_runtime/lib/tiannara_runtime/phase16_1/validation_campaign_runner.ex`
- [ ] Create `tiannara_runtime/lib/tiannara_runtime/phase16_1/long_horizon_runner.ex`
- [ ] Create `tiannara_runtime/lib/tiannara_runtime/phase16_1/readiness_runner.ex`

## Step 4 — Implement immutable artifact writers (deterministic serialization + content addressing)
- [ ] Create `tiannara_runtime/lib/tiannara_runtime/phase16_1/artifacts/artifact_store.ex`
- [ ] Create artifact writers for:
  - [ ] research ledger / observation records
  - [ ] validation/replay manifests + divergence reports
  - [ ] lineage manifests / archaeology metadata
  - [ ] audit input packages (evidence-only)
  - [ ] long-horizon research metrics artifact
  - [ ] RRI computation output artifact(s)

## Step 5 — Implement evidence-only independent audit boundary (no runtime imports)
- [ ] Create `tiannara_runtime/lib/tiannara_runtime/phase16_1/independent_audit/audit_runner.ex`
- [ ] Ensure audit runner only consumes exported immutable artifacts and does not import runtime orchestrator/engine modules.

## Step 6 — Implement replay determinism infrastructure
- [ ] Create `tiannara_runtime/lib/tiannara_runtime/phase16_1/replay/divergence.ex`
- [ ] Create replay hash comparison + divergence report artifacts.

## Step 7 — Tests (Phase 16.1 isolated test suite)
- [ ] Create `tiannara_runtime/test/tiannara_runtime/phase16_1/` tests:
  - [ ] determinism: identical inputs => identical artifact hashes
  - [ ] replay mismatch: divergence report emitted + fail-closed behavior
  - [ ] fail-closed gating: if evidence closure fails, audit/readiness steps don’t run
  - [ ] independent audit boundary: audit runner doesn’t depend on runtime modules
  - [ ] serialization/canonicalization determinism

## Step 8 — Verification commands
- [ ] Run `mix test` (scoped to phase16_1 tests if possible)
- [ ] Run `python phase16_verify.py` to ensure Phase 16 doc reference integrity checks pass

## Hard Constraints (must never violate)
- [ ] Do NOT implement or emit issued certification artifacts:
  - RESEARCH_CERTIFICATE.json
  - RESEARCH_PROOF.json
  - RESEARCH_FINAL_REPORT.md
  - RESEARCH_ARCHAEOLOGY.md
- [ ] Independent audit must remain evidence-only and must not import runtime state/engine modules.
