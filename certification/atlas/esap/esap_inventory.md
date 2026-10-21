# ESAP R0 Inventory — Kimiti4/autonomous-API-Gen (Tiannara ESAP / Full-Stack Autonomous Software Compiler)

Phase R0 read-only discovery. This inventory is **separate from** the Tiannara AI platform inventory; no merged counts, no shared rows.

Evidence rules applied: Unknown is not PASS; documentation is not implementation; every claim carries a source ref. Clone is at `C:\Users\user\AppData\Local\Temp\opencode\esap` (read-only after clone; no tests executed).

## 1. Repo identity

| Field | Value |
| --- | --- |
| URL | https://github.com/Kimiti4/autonomous-API-Gen.git |
| Default branch | `main` |
| HEAD SHA | `062cbeb449bf646044d93ab423b2939160229889` |
| HEAD date | 2026-10-20T12:21:51+03:00 (merge of PR #139 `feature/buildable-react-frontend-v1`) |
| Cloned depth | 100 commits (871 total reachable from HEAD in shallow clone rev-list — see unknowns) |
| Total tracked files | 3,386 |
| Languages (by extension) | Python 2,666 (.py); Markdown 280; JSON 101; TypeScript/TSX 120 (.ts 69, .tsx 51); YAML 51; Elixir 36 (.ex/.exs — all under `generated/`); HTML 30; shell 13; JS 10; Go 7 (all under `out/calibration-baseline-6/`); CSS 6 |
| Self-description | README.md:3 "experimental autonomous software compiler for discovering, evaluating, lowering, generating, and verifying API architectures" |

## 2. Top-level layout (all 67 top-level entries classified)

**Compiler / pipeline core (source):** `compiler/` (49 files: kernel, registry, validation, backends incl. 47 KB python_fastapi + 62 KB rust_axum emitters), `isr/` (15: graph/behavior/invariants/identity), `reqgraph/` (5), `constitutional_architecture/` (564: its own `isr/`, `compiler/` with pipeline + source_binding + intent_entrypoint + passes, `compilers/`, `deployment/`, `eir/irr/ckb`, 21 subdirs), `tiannara/` (335: hexagonal app/domain/infrastructure/interfaces + CLI), `autonomous-api/` (730: FastAPI repository engine, `app/engine/` ~230 modules incl. `source_bound_full_stack.py` 104 KB).

**Vertical slice / evidence runs:** `vertical_slice/` (90, D19–D29 step scripts + paired `*_evidence.json`), `certification/` (44: campaign, stages, payroll, remediation register W01–W22 + defects D01–D08), `golden-projects/taskflow/` (19), `generated/` (61: materialized testshop/monolithshop apps incl. Elixir), `out/` (122: calibration-baseline-6 materialized Go/Rust/etc. bundles), `evidence/` (2 JSONL run ledgers).

**Support / platform:** `docs/` (113), `tests/` (453, canonical suite), `observatory/` (95), `dashboard/` (55, TS/React), `observation-client/` (41), `reasoning-ui/` (23), `evolution/`, `learning/`, `knowledge/`, `civilization/`, `product_factory/`, `distributed_evolution/`, `ecosystem/`, `marketplace*/`, `identity/`, `genesis/`, `experiments/`, `scripts/`, `config/`, `release/`, `folder/` (129 — misc non-core content).

**Meta:** `.github/` (32, incl. 32 workflow files), `AGENTS.md`, `CAPABILITY_CONSTITUTION.md`, `FRONTEND_CONSTITUTION.md`, `pyproject.toml`, `uv.lock`, startup scripts.

## 3. Pipeline reconstruction (intent → ISR → code → build → verify)

```
intent statement (CLI: tiannara/interfaces/cli/main.py create/factory)
  │ tiannara/application/intent/compiler.py  (+ LLM: recorded/live provider, hermetic default)
  ▼
Requirement graph + typed SystemModel (tiannara/application/intent/graph_builder.py)
  │ constitutional_architecture/isr/semantics/intent_projection.py  [loss-aware projection]
  ▼ (blockers fail closed: "projection_blocked")
ISR candidate + source SHA-256 binding
  │ constitutional_architecture/compiler/source_binding.py:verify_constitutional_source_binding
  │ autonomous-api/app/engine/source_bound_full_stack.py (full-stack projection, mapping digests, provenance)
  ▼ (incomplete binding fails closed: "binding_blocked")
Compiler pipeline (constitutional_architecture/compiler/pipeline.py:compile_source_bound)
  │ passes: validation_pass (binding gate) → code_generation_pass (source_bound_codegen_certified gate)
  ▼
Emitters (3 stacks): compiler/backends/* ; tiannara/application/compiler/* (14 backends + 9 frontends);
  │                 constitutional_architecture/compilers/*
  ▼
Materialization (tiannara/materializer, engine backends:materialize, factory)
  │ artifacts observed in-repo: out/calibration-baseline-6/, generated/
  ▼
Independent verification (certification/stages/independent_verify.py, compiler/sdk/testing.py)
  │ CI: cbc1-campaign-a.yml (register cites artifact 78/78 CERTIFIED @ d8f2a88e)
  ▼
Deployment (constitutional_architecture/deployment/targets/*, deployment_handoff, docker/cicd emitters)
    FAIL-CLOSED: targets require injected TargetExecutor (D04 fixed); no shipped runtime executor
```

**断裂 points (fractures) identified:**

1. **Source intent → ISR semantics (historical R0 issue):** the fail-closed *binding* machinery exists (step 2–3, CI-covered by `source-binding-integration-focused.yml`), but typed behavioral semantics merged in PR #137 are, per the repo's own register, "not consumed by the certified emitters" (register.py:201-204, W02). **Partially closed, not fully closed.**
2. **ISR → architecture selection:** candidate scores "analyst-assigned rather than derived from candidate content" (register.py:253-255, W04).
3. **ISR → events:** retries/DLQ/ordering not generated; no async e2e tests (register.py:420-424, W10).
4. **ISR → security:** RBAC/ABAC engine not wired into generated enforcement points; generated routes = API-key only (register.py:445-447, W11).
5. **Frontend → runtime:** no npm build / browser-level tests in CI (register.py:500-505, W13).
6. **Full stack:** no generated UI→API→persistence journey; union draft #140 reported red (register.py:526-529, W14).
7. **Verify → deploy:** no runtime executor; generated CI/deploy workflows never executed (register.py:644-647, W18).

## 4. Per-capability table (CAP-ESP-001..016, Section E, R0_SOURCE_PLAN.txt:315-349)

| ID | Capability | evidence_state | Key impl (authoritative) | Execution evidence | Primary gap |
| --- | --- | --- | --- | --- | --- |
| 001 | Intent ingestion & compilation | partially_connected | `tiannara/application/intent/compiler.py`; `constitutional_architecture/compiler/intent_entrypoint.py` | tests/test_intent_compiler.py, test_intent_entrypoint.py; source-binding CI workflow | TOR extraction draft-only (W01) |
| 002 | ISR | implemented_incompletely_verified | `isr/core/*`; `constitutional_architecture/isr/*`; `tiannara/domain/models/isr.py` | test_isr_substrate_v12, typed-isr-content-hash CI | 3 competing ISRs; typed behavioral payload not consumed by emitters (W02) |
| 003 | Source-bound intent projection | implemented_incompletely_verified | `source_bound_full_stack.py`; `source_binding.py` | tests/cbc1/*; source-binding-integration-focused.yml | source-mutation invalidation lacks enforced canonical test (W01) |
| 004 | Architecture selection | partially_connected | `vertical_slice/architecture_selection_d24.py`; `engine/architecture_selection.py` | tests/vs1/test_architecture_selection_d24.py; evidence JSON | scores not derived from content (W04) |
| 005 | Autonomous code generation | partially_connected | `compiler/backends/*`; 14 tiannara backend emitters | materialized `out/`, `generated/`; test_backend_compiler.py | run evidence weak (factory.jsonl: 1 test/scan skipped) |
| 006 | Multi-stack orchestration | implemented_incompletely_verified | `tiannara/.../compiler/registry.py`; `campaign/backend_matrix.py` | calibration-baseline-6 ledger + artifacts; AGENTS.md Tier C claim (40/40, 33 min — historical claim) | equivalence is contract-level |
| 007 | Frontend generation | partially_connected | `react_frontend.py`; `react_typescript_compiler.py` | PR #139 merged at HEAD; generated-frontend-certification.yml | no npm/browser verification in CI (W13) |
| 008 | API generation | partially_connected | `production/openapi_backend.py`; `engine/api_ir.py` | autonomous-api API IR tests | versioning/pagination/idempotency not ISR-driven (W09) |
| 009 | Backend generation | implemented_incompletely_verified | 14+ emitters (fastapi_hexagonal, rust_axum typed, go, spring, nest, ktor…) | out/calibration-baseline-6, generated/testshop, factory ledger | thin runtime execution evidence |
| 010 | Events & async | partially_connected | `fastapi_hexagonal_backend.py:async_resolution_module` | tests/test_r24_async_resolution_codegen.py | no retries/DLQ/ordering generation; no e2e async tests (W10) |
| 011 | Security & authorization | partially_connected | `enterprise/authorization.py` (PR#125); `security_policy_compiler.py`; `compiler/governance/enforcer.py` | test_authorization_policy_engine.py; codeql/secret-scan/dependency-review CI | RBAC not wired into generated routes (W11); no real DAST adapter (W17) |
| 012 | Full-stack integration | partially_connected | `source_bound_full_stack.py`; `hardening/fullstack_gates.py` | taskflow-golden.yml (backend+frontend+docker smoke) | no generated e2e journey; #140 red (W14) |
| 013 | Independent verification | implemented_incompletely_verified | `certification/stages/independent_verify.py`; `compiler/sdk/testing.py` | cbc1-a-evidence artifact (78/78 CERTIFIED @ d8f2a88e, per register); fail-closed D01–D08 regression tests | own status = IMPLEMENTED_UNVERIFIED (W16) |
| 014 | Deployment & operations | partially_connected | `deployment/targets/*`; `deployment_d26.py`; docker/cicd emitters | taskflow docker health smoke in CI; fail-closed target tests | no shipped runtime executor; generated workflows not executed (W18) |
| 015 | Legacy repair & evolution | partially_connected | `existing_codebase_workflow.py`; factory repair providers | bucket-4-x CI workflows; test_phase18_repair_port.py | analysis regex-only (W21) |
| 016 | Autonomous improvement | partially_connected | `tiannara/application/evolution/*`; `self_improvement/*` | governance/safety-control test files; evolution entries in factory ledger | fitness quality not independently audited (R0) |

Companion machine-readable table: `capabilities_ESAP.csv` (16 rows, section `E-ESAP`).

## 5. Tests + CI reality

- **32 workflow files** in `.github/workflows/` (no workflow under glob check by name of full pipeline; they are per-concern).
- `root-canonical-suite.yml`: authoritative Tier A — full `tests/` (~4538 tests claimed in comment; ~2786 passed claimed in AGENTS.md:45 — two different numbers in repo, treat both as claims), excludes `-m docker_integration -m certification`; plus a Postgres-backed `autonomous-api/tests` job (D08 fix).
- `final-13-software-certification.yml`: 13 named suites in `autonomous-api/`, Python 3.11+3.13 matrix — unit/contract scope.
- `source-binding-integration-focused.yml`, `typed-isr-content-hash.yml`: cover the historical source→ISR connection path.
- `cbc1-campaign-a.yml`, `execution-evidence-truthfulness.yml`, `final-hardening-closure.yml`, release gates v1.1–v1.4: certification-tier jobs.
- `taskflow-golden.yml`: closest to full-pipeline CI — backend pytest + frontend `tsc`/`npm run build` + Docker build/run/health-check of a **committed golden project** (not regenerated from intent in CI).
- **Scope verdict:** CI exercises units/contracts heavily and some candidate-bound gates; the *generative* pipeline (intent → ISR → code → build → verify for a fresh intent) is not run end-to-end by any workflow read in this pass. Docker-integration and certification tiers are opt-in/excluded from the canonical default (AGENTS.md:27-55).

## 6. Shared contracts with Tiannara AI platform (recorded WITHOUT merging)

- **Cross-repo imports:** none found. No reference to `MindCache`, `Tiannara-MindCache`, `UEP`, `ISD v2.0`, or protobuf schemas (only `protobufjs` transitive npm dependency and a `data_format` enum pattern containing "protobuf"). Confirmed by repo-wide grep.
- **Shared principles (conceptual, not wired):** ISR/requirement-graph idea; cryptographic hash-chained evidence ledger (`tiannara/infrastructure/ledger/jsonl_evidence_ledger.py` pattern vs platform evidence ledger); constitutional/governance + fail-closed gates; hermetic recorded-LLM mode; certification tiers (structural/build/behavioural/security/operational/release).
- **Naming overlap without coupling:** both sides use "Tiannara", "ISR", "governance", "campaign" terminology; ESAP's Elixir appears only in `generated/` output (36 files), not as a platform runtime dependency.

## 7. Findings F-ESP-nnn

| ID | Severity | Confidence | Finding | Evidence | Remediation | Acceptance criteria |
| --- | --- | --- | --- | --- | --- | --- |
| F-ESP-001 | high | high | Historical R0 issue (source intent → ISR → downstream derivation) only **partially closed**: binding/projection fail-closed + CI exist, but typed behavioral ISR semantics are not consumed by the certified emitters | `certification/remediation/register.py:179-205` (W02 limitations), `:151-177` (W01 limitations); `intent_entrypoint.py:50-126` | Merge + wire PR#137 typed behavioral payloads into certified emitters; enforce source-mutation invalidation test | A canonical test proves mutating source invalidates every derived binding; representative requirements produce typed ISR semantics consumed end-to-end with no lost mandatory element (W01/W02 closure gates) |
| F-ESP-002 | high | high | RBAC/ABAC engine (PR#125, deny-by-default) is not wired into generated route/service/data enforcement; generated routes = API-key auth only | `register.py:426-448` (W11) | Wire policy engine into emitter templates; add per-operation allow/deny + tenant-isolation tests | Independent tests prove allow and deny for every protected operation incl. escalation attempts (W11 gate) |
| F-ESP-003 | high | high | Event/async generation incomplete: no retries, dead-letter queues, or ordering generated; no e2e asynchronous delivery tests; API versioning/pagination/idempotency not ISR-driven | `register.py:401-425` (W10), `:373-399` (W09) | Emit retry/DLQ/ordering from ISR behaviour; add delivery/duplicate/failure/recovery e2e tests | End-to-end event tests prove payload conformance, retry, duplicate handling, consumer failure and recovery (W10 gate) |
| F-ESP-004 | high | high | No generated UI→API→persistence end-to-end journey; frontend builds/browser verification absent from CI; union draft #140 reported failing Campaign A + React certification | `register.py:477-529` (W13/W14); `root-canonical-suite.yml` (no npm jobs) | Run npm install/build/tsc/browser tests on generated frontends in CI; repair #140 | Clean-environment build + deployment exercises real user journeys incl. failures and denials (W14 gate) |
| F-ESP-005 | medium | high | Remediation register is stale vs HEAD: W13 says "PR#139 unmerged"/"Draft #139 unverified", W02 says PR#137 draft — but HEAD `062cbeb` **is** the merge of #139 and `9803760` merges #137 | `register.py:194,493,519` vs `git log` | Re-derive register dispositions from merged state; keep evidence refs SHA-pinned | Every register evidence reference resolves to a merged commit/workflow run at current HEAD |
| F-ESP-006 | medium | high | Deployment capability fails closed with no shipped runtime executor; generated CI/deploy workflows are never executed by the system | `register.py:622-648` (W18); `tests/test_deployment_targets_fail_closed.py` (D04) | Provide a real container/cluster TargetExecutor adapter + execute generated workflows in a runner | Clean runner builds, deploys, probes, captures logs, tears down (W18 gate) |
| F-ESP-007 | medium | medium | Architecture selection scores are analyst-assigned, not derived from candidate content; legacy-repo analysis is regex-only | `register.py:232-256` (W04), `:700-723` (W21) | Derive scores from measurable candidate properties; replace regex analysis with structural parsing | Identical inputs+toolchain reproduce identical candidates/scores with reasons for exclusions (W04) |
| F-ESP-008 | positive | high | Eight historical fail-open defects D01–D08 (verification fail-open, dry-run gateway default, fake deploy handoff/targets, vacuous assert-True tests, simulated DAST, assert-True smoke, canonical-testpath gap) now VERIFIED with regression tests | `register.py:755-851` | Maintain regression suite | Each D-item keeps its named regression test green in root-canonical-suite |
| F-ESP-009 | medium | medium | Run evidence in `evidence/factory.jsonl` is thin: entries show `total_tests: 1`, `security_scan_performed: false`, `tests: []` while marking verdict pass | `evidence/factory.jsonl` records 2026-08-09…09-05 | Require non-trivial candidate-bound test counts + security scan before verdict=pass | Ledger entries with pass verdict carry real test inventories and scan results |
| F-ESP-010 | medium | high | Three parallel ISR representations and three emitter stacks coexist (`isr/`, `constitutional_architecture/isr`, `tiannara/domain/models/isr.py`; `compiler/backends`, `tiannara/application/compiler`, `constitutional_architecture/compilers`) with unclear single authority | file inventory (section 2) | Declare one authoritative ISR/stack per capability; demote others to adapters | Register/atlas maps each capability to one authoritative_impl; competing impls explicitly scoped |

## 8. Unknowns

- GitHub Actions **actual run status** (green/red) for the 32 workflows was not fetched; workflow definitions only. The register's "78/78 CERTIFIED @ d8f2a88e" and AGENTS.md "40/40 in 33 min" are historical claims, not re-verified.
- State of open PRs #138 (TOR extraction) and #140 (union; "currently red") — not fetched from GitHub.
- Shallow clone depth 100 vs reported 871 reachable commits — full history not scanned; cross-repo references older than the clone window cannot be excluded by grep alone.
- No pipeline execution performed (governing rule: no long runs, no mutations) — every evidence_state is repository-static; no fresh e2e run exists from this R0 pass.
- Whether `generated/` and `out/` artifacts are reproducible from current HEAD emitters was not tested.
- Browser-level verification existence (W13 claims absent in CI) checked only against workflow files, not against local developer runbooks.
- Tier C certification (`-m certification`, 40/40 claim) and Docker tier not executed; their current pass/fail state is unknown.
