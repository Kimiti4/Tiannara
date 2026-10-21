# Directory Audit — 11 Requested Paths

**Date:** 2026-10-19 · **Branch:** `local/pr4` · **Mode:** read-only investigation
(no files outside this document were modified as part of this audit).

**Method:**
1. `audit_tiannara_directories.py --root <repo>` scanner → `audit_output/tiannara_file_inventory.csv` (all 11 paths present; exit 0).
2. Three independent code-recon passes (API/audit/core; observatory/small dirs; runtime structure), every claim cited `file:line`.
3. Independent re-verification of the three P0 findings from
   `markdown/Tiannara_Production_Readiness_Audit_2026-10-18.md` (§1 below).
4. Git-tracked status via `git ls-files <dir>` vs filesystem counts.

**Status vocabulary** (per operator ruling): `wired+tested` > `partial` >
`implemented+unwired` > `stubs/simulation-only` > `absent-in-git`.

---

## 0. Summary

| # | Directory | Scanner files | Git tracked | Verdict | Covered by tracked CI? |
|---|-----------|--------------:|-------------|---------|------------------------|
| 1 | `tiannara_api` | 135 | 132 | **partial** | yes (`pytest tests/`, flake8) |
| 2 | `tiannara_audit` | 75 | 9 | **isolated + P0 correctness defects** | **no** |
| 3 | `tiannara_core` | 499 | 440 | **wired+tested** (library; docs overclaim) | partially (root `tests/`) |
| 4 | `tiannara_gui` | 54 | **0** | **absent-in-git** (gitignored) | no |
| 5 | `tiannara_internal_dashboard` | 95 | **0** | **absent-in-git** (never committed) | no |
| 6 | `tiannara_mobile` | 6 | **0** | **absent-in-git + stubs** | no |
| 7 | `tiannara_observatory` | 4890* | 499 | **partial** | **no** (its tests are untracked) |
| 8 | `tiannara_pros` | 44 | 47 | **partial** (zero tests) | no |
| 9 | `tiannara_runtime` | 28966* | — | **partial** | yes (Elixir CI) |
| 10 | `tiannara_runtime/lib` | 1248 | ~1240 | same as #9 | yes |
| 11 | `tiannara_runtime/k8s` | 12 | 12 | **partial/broken kustomize + P0 secrets** | no |

\* scanner counts include vendored `deps/`/`_build`/`node_modules`; observatory's own files ≈ 662.

---

## 1. P0 findings independently re-verified (all CONFIRMED)

### 1.1 `tiannara_audit` — verifiers that cannot fail (P0 claim-control)
- `tiannara_audit/lib/tiannara_audit/graph_verifier.ex:23-37` computes
  `computed_hash` and then **never compares it to anything**; returns
  `match: true`, `failures: 0`, `details: []` unconditionally. Every graph
  sample "passes" by construction.
- `tiannara_audit/lib/tiannara_audit/proof_verifier.ex:21-22` returns
  `match: true` whenever `expected_fingerprint == nil` ("independent
  fingerprint: …") — a sample with **no expected value counts as a pass**.
- Consequence: both committed reports —
  `tiannara_audit/lib/INDEPENDENT_AUDIT_REPORT.md:12-25` and
  `tiannara_runtime/priv/audit/INDEPENDENT_AUDIT_REPORT.md:12-25`
  (2026-07-07, "220/220 PASS", Graph 20/20, Proof 50/50) — were produced by
  the defective verifiers and **cannot establish certification**.
  `HashVerifier` (`hash_verifier.ex:19`) and `RuntimeVerifier`
  (`runtime_verifier.ex:15`) do compare honestly; the defect is isolated to
  the graph/proof verifiers above.
- **Plan:** mark both historical reports superseded (not erased), fix the two
  verifiers to fail on missing/mismatched expected values, regenerate via the
  corrected auditor before any certification claim. *(Not done — repair was
  not in the approved execution scope; proposed under §13.)*

### 1.2 `tiannara_runtime/k8s` — literal production credentials + broken base
- `k8s/phase6/overlays/production/kustomization.yaml:36-37` contained
  literal production secret values (a `release-cookie` and an `nats-auth-token`)
  in a tracked file.
  **Superseded 2026-10-21 (R1/OP-01): the literal values were removed from the
  tracked overlay and the secret generator now reads them from the build
  environment.** The values themselves are deliberately **not reproduced here**;
  see `certification/atlas/ops/OP-01_CREDENTIAL_ROTATION.md` for the rotation
  procedure and the evidence template.
- Same file references `../../base` (`:5`) but `k8s/phase6/base/` had **no
  `kustomization.yaml`** (only one kustomization existed under all of `k8s/`);
  the production overlay could not build from tracked files.
  **Superseded 2026-10-21 (R1/OP-01): a tracked base `kustomization.yaml` was
  added**, so the overlay can now be built (and the secret reference verified)
  from tracked files.
- Repo-wide scan of `k8s/` + `config/` found **no other literal secrets**.
- **Plan (original, 2026-10-19):** rotate both values if ever deployed; switch to deployment-time
  secret injection; add a tracked base `kustomization.yaml`. *(Not done —
  credential rotation is an ops action.)*
  **Status 2026-10-21:** deployment-time secret injection and the base
  kustomization are done; **rotation itself remains an operator action** and is
  not claimed complete.


### 1.3 `tiannara_api` — production entrypoint auth gaps
- `main.py:97-105` installs `ProductionAuthMiddleware`,
  `JWTContextMiddleware`, `SecurityHeadersMiddleware`,
  `InputValidationMiddleware`, `EnhancedRateLimiter`; `main_production.py:46`
  installs **only CORS** — none of the five.
- `middleware/production_auth.py:71-72` — enforcement is skipped unless
  `ENVIRONMENT=production` (default `development` = permissive), and
  `/api/v1/payment` is on the public allowlist (`production_auth.py:21`).
- `routes/payment.py:177-195` — `POST /api/v1/payment/admin/process-downgrades`
  carries `# TODO: Add admin authentication check here` (`:191`) with the
  admin-verifier import commented out.
- Docker/CI launch `uvicorn tiannara_api.main:app` (`docker-compose.yml:51`),
  so the shipped entrypoint is `main.py`, but `main_production.py` remains a
  live footgun for anyone deploying "the production file".
- **Plan:** delete or fold `main_production.py` into `main.py`; implement the
  admin check; move payment prefix off the allowlist or require auth there.
  *(Not done — endpoint-behavior changes need explicit approval.)*

---

## 2. `tiannara_api` — partial

- **Inventory:** 135 files (122 `.py`): `routes/` 48, `middleware/` 12,
  `auth/`, `security/`, `database/`, `engines/`, `gateway/`, `services/`,
  `schemas/`, 1 in-package test file.
- **Startup:** `main.py:92` FastAPI v1.3.0-phase5, ~45 routers
  (`main.py:212-255`); second app `main_production.py:41` v1.4.0-monetization,
  9 routers (`:145-153`). Launch: `docker-compose.yml:51`,
  `docker/api/Dockerfile` → `main:app`.
- **Callers:** root `tests/` (33/36 import it), `ci-cd.yml:49`
  (`pytest tests/ --cov=tiannara_api`), `ci-cd.yml:93` (flake8). One
  test-only import from `tiannara_core`.
- **Security:** see §1.3; JWT secret env-required in prod, random in dev
  (`gateway/auth.py:32-35`); no hardcoded credential literals found.
- **Persistence:** PostgreSQL via SQLAlchemy (`database/__init__.py:10-33`);
  committed dev artifact `runs/cognitive_telemetry.db`.
- **Plan:** resolve the two-entrypoint split (§1.3), admin-auth the
  downgrade endpoint, add in-package tests, keep `ENVIRONMENT=production`
  fail-closed-by-default rather than opt-in.

## 3. `tiannara_audit` — isolated; P0 correctness defects

- **Inventory:** 9 tracked files (5 `.ex`, `mix.exs`, `mix.lock`, committed
  report); no `test/` dir; escript (`mix.exs:11`), no OTP application.
- **Entry point:** `TiannaraAudit.main/1` (`lib/tiannara_audit.ex:16`) reads
  `artifact_data.term`, writes `INDEPENDENT_AUDIT_REPORT.md` (`:164-169`).
- **Callers:** **none** — repo-wide grep for `tiannara_audit`/`TiannaraAudit`
  outside the app found only docs (`docs/capability_ledger.md:157`
  "unbooted application root … invisible to boot, census and CI").
  Not invoked by any workflow (`grep tiannara_audit *.yml` → 0).
- **Tests/CI:** none; never compiled by `elixir_ci.yml`.
- **Security/persistence:** offline CLI; reads a term file, writes one report.
- **Verdict:** tool is feature-complete but unwired **and** two of its four
  verifiers are false-positive by construction (§1.1).
- **Plan:** fix Graph/Proof verifiers → add tests → add a CI job or script
  invocation → regenerate the historical report → only then cite it.

## 4. `tiannara_core` — wired+tested (library), docs overclaim

- **Inventory:** 499 files (455 `.py`), ~70 subfolders, **no `main.py`** —
  it is a Python library, not an app (zero `.ex`/`mix.exs`).
- **Entry/startup:** no entrypoint; instantiated by `tiannara_api/main.py:69-81`
  (Orchestrator, DiscoveryEngine, SafetyGate, …), copied into the API image
  (`docker/api/Dockerfile`). Doc claim `uvicorn tiannara_core.main:app`
  (`markdown/SAAS_REPOSITORY_SEPARATION.md:217`) is **false** (file absent).
- **Callers:** `tiannara_api` (100+ import sites), root ad-hoc scripts.
- **Tests:** CI via root `tests/` (`ci-cd.yml:49`), dedicated lint only for
  `evaluation/` (`test.yml:87`); in-tree `tests/` mixes real tests with
  self-authored "100% COMPLETE" achievement markdown.
- **Security:** domain safety logic (`safety/gate.py`) — no HTTP layer; no
  credential literals; one route imports test infra at runtime
  (`tiannara_api/routes/autonomous_testing.py:161`).
- **Persistence:** several SQLite DBs (`telemetry/cognitive_telemetry.py:133`,
  `interpretability/audit_trail.py:161`, …) and JSONL written **relative to
  CWD** (`memory/discovery_memory.py:16`) — no configuration boundary.
- **Plan:** correct the `uvicorn` doc claim; treat achievement-MD claims as
  non-evidence; make state paths configurable.

## 5. `tiannara_gui` — absent-in-git

- **Inventory:** 54 files on disk (Vite+React 18 SPA, WebGL shader assets).
- **Git:** `git ls-files tiannara_gui` = **0**; `.gitignore:25` ignores it;
  history shows explicit removal (`3f8aacda "Remove tiannara_gui - moving to
  separate repository"`); working tree ≠ that historical content (drift).
- **Entry:** `package.json:7` `vite` dev server :3001, proxying `/api` →
  `:8004` (`vite.config.js:8-11`).
- **Callers:** docs only (`README.md:9`, runtime observability guide:243).
- **Tests:** none; absent from workflows.
- **Security:** browser-side `localStorage.admin_token` gating only
  (`src/pages/AdminDashboard.jsx:56-65`); no server secrets in tree.
- **Plan:** decide explicit ownership (separate repo vs restore) — as-is it
  is invisible to review/CI and cannot be audited from this checkout.

## 6. `tiannara_internal_dashboard` — absent-in-git (never committed)

- **Inventory:** 95 files (Next.js 14 App Router, 23 routes, 59 `.tsx`).
- **Git:** 0 tracked; `.gitignore:26`; `git log --all` **empty** — never in
  history.
- **Entry:** `package.json:6` `next dev`; rewrite `/api/v1/*` → `:8004`
  (`next.config.js:5-11`) while `.env.local.example:2` says `:8000`
  (port conflict).
- **Callers:** cleanup scripts offer to archive it
  (`scripts/cleanup_for_deployment.sh:89-95`); no runtime importer.
- **Security:** client-side demo auth — fixed `local-admin` user,
  `login` **ignores credentials** (`src/lib/AuthContext.tsx:26-35`); no
  `middleware.ts` guard; API-key management UI present
  (`src/app/api-keys/page.tsx`); mock data declared
  (`src/app/demo/observatory/page.tsx:27`).
- **Tests:** none; not in workflows.
- **Plan:** treat as prototype only; never expose; commit or delete
  (deletion needs approval).

## 7. `tiannara_mobile` — absent-in-git + stubs

- **Inventory:** 6 × ~0.5 KB Python files; 0 tracked; `.gitignore:27`;
  never in history; generated by test-harness scripts
  (`tiannara_core/tests/generate_all_remaining.py:33-38`).
- **Entry/callers/tests:** none — `app.py:1-6` self-describes
  "Auto-generated stub module … TODO: Implement full functionality".
- **Plan:** classify as **absent** for any capability claim; do not count in
  inventories of working software.

## 8. `tiannara_observatory` — partial

- **Inventory:** umbrella Elixir (10 of 11 `apps/` in `mix.exs:7-18`;
  `observatory_ui` present on disk but not umbrella-listed) + Next.js UI.
  Own files ≈ 662; scanner's 4890 includes `deps/`/`_build`.
- **Git:** 499 tracked — but **all 20 Elixir test files are untracked** and
  its own CI file is untracked (`tiannara_observatory/.github/…`); only 3 UI
  tests tracked. Not a submodule (contrary to
  `SYSTEM_SCAN_REPORT.md:22,57`).
- **Startup:** `mix phx.server` (README:43, port 4000 per
  `config/runtime.exs:24`); UI `npm run dev`; Dockerfiles exist; **no
  repo-level launcher** (`docker-compose.yml:32-64` = postgres/redis/api/core only).
- **Callers:** `tiannara_api/routes/observatory.py:38` calls
  `http://localhost:4000/api` **with simulation fallback** on failure
  (`:602,:622`).
- **Security:** router-wide Auth+RateLimit plugs
  (`apps/observatory_api/lib/observatory_api/router.ex:6-7`) but **dev
  bypass grants administrator** (`plugs/auth.ex:13-21`); committed dev
  secrets (`config/config.exs:14,48` secret_key_base/jwt_secret; `:22-23`
  postgres/postgres ×6 DBs); **CORS `*`** (`config.exs:9`,
  `observatory_api_web/endpoint.ex:36`).
- **Persistence:** 5-6 Postgres DBs, ETS `observatory_state`; outbound
  `TIANNARA_RUNTIME_URL` default `http://localhost:4000` (`config.exs:65`)
  — self-referential/likely wrong vs runtime's dev `:8004`.
- **CI:** zero references in root workflows; its own CI is untracked →
  effectively **no CI**.
- **Plan:** track the tests (or delete the dir), gate the dev auth bypass,
  remove committed dev secrets from config, fix URL/port config, decide
  umbrella membership of `observatory_ui`.

## 9. `tiannara_pros` — partial (zero tests)

- **Inventory:** 47 tracked (44 source + 3 committed `.pyc`); actuator/EMG
  IO, 18 `orchestrators/orchestrator_day*.py` with `__main__` entrypoints
  (e.g. `orchestrator_day29_run_scenario.py:38`).
- **Wiring:** **yes, into core** — `tiannara_core/integration/pros_adapter.py:3-4`
  imports `motor_controller`; `tiannara_core/autonomous/orchestrator.py:12`
  imports `evaluate_with_pros`.
- **Tests/CI:** none anywhere (grep of `tests/` + `tiannara_core/tests` → 0;
  no workflow mentions); despite `docs/FREEZE_v1.md:1` "stable baseline".
- **Security:** no network/secrets; fault injection disabled
  (`config/limits.json` `"enabled": false`).
- **Persistence:** `runs/<RUN>/packets.jsonl` (`io/run_recorder.py:41,56`).
- **Plan:** add safety-critical tests for actuator/safety paths before any
  hardware claim; remove committed `.pyc`.

## 10. `tiannara_runtime` (+ `lib/`) — partial

- **Startup (real boot tree):** `application.ex:21-24` →
  `StartupSupervisor` (`startup_supervisor.ex:29-42`, `:rest_for_one`):
  ConstitutionalPersistenceLayer (`data/cpl`) → Omega.Supervisor (10 leaves,
  `omega/supervisor.ex:17-30`) → Observatory → Phoenix Endpoint →
  `RootSupervisor` (`runtime_layers/supervisors.ex:199-209`, profile-gated
  `:stable|:research|:minimal`) → DiscoveryRunner (60 s). Boot policy:
  `optional_child` skips missing modules with warning, `required_child`
  raises, `experimental_child` env-gated — NDE/TWP/OSL all `false`
  (`config.exs:8-10`). `Interface.Supervisor` starts `children = []`
  (`supervisors.ex:180`).
- **Layer map (`lib/`):** `tiannara_runtime/` 971 `.ex` (world_model 175,
  cognitive 161, opc 86, civilization 61, os 58, meta 42, …); `tiannara/` 254
  (sentinel 89, oed 33, phase8-19 …); Phoenix 6; **misspelled namespace
  `tiarnara/` (7 files, Phase 18 RRM)**.
- **Persistence:** CPL JSON journal (`data/cpl/…`,
  `constitutional_persistence_layer.ex:390-412`), Omega snapshots
  (`omega/executive_memory.ex:12,144`), ExperimentJournal, Mnesia
  (`meta/causal_data_layer.ex:135-147`, disk schema present), ETS (100+
  sites), raw TCP NATS listener on 4222 (`nats/connection.ex:15-24`).
  No Postgres/Ecto.
- **External:** `nats://localhost:4222` (`config.exs:16`), dev Phoenix
  `:8004` (`dev.exs:5`), k8s image `tiannara-runtime:phase6-6.0.0`.
- **Tests/CI:** 39 tracked `.exs` (166 on disk); `elixir_ci.yml` runs
  root-project `mix compile --force`, lineage test, `mix test
  --max-failures 25` (runs at **repo root**, not `tiannara_runtime/`);
  `phase_5f2_tests.yml` triggers only on `meta/**` and only for
  `main|develop` pushes; `cross_platform_verify.yml` compiles + evidence
  scripts, no ExUnit. **The 166-on-disk vs 39-tracked gap means most tests
  are not in CI.**
- **Config gaps:** `config/config.exs:57` imports `"#{Mix.env()}.exs"` but
  **`config/prod.exs` does not exist** → `MIX_ENV=prod` compile/boot fails;
  `config/layer_boundaries.exs` never imported (dormant); moduledocs of
  `DiversityRegulator`/`CollapseDetector`/`RecoveryOrchestrator` oversell
  (bare counters, `supervisors.ex:64,90,117`).
- **Plan:** add `config/prod.exs` before any prod deploy; track or prune the
  untracked test files; point CI at the runtime project explicitly; fix the
  misspelled `tiarnara` namespace (needs approval — code rename).

## 11. `tiannara_runtime/k8s` — partial/broken

- **Inventory (12 files):** `phase6/base/` (4 manifests, **no
  kustomization**), `phase6/overlays/production/kustomization.yaml` (the
  **only** kustomization in the tree), `phase8-rtl/base/` (3, no
  kustomization), 4 KEDA ScaledObjects (phases 13_14/17/18/19).
- **Defects:** literal secrets + broken base reference (§1.2); KEDA targets
  `tiannara-phase13-14`, `tiannara-ucc`, `tiarnara-rrm` (misspelled ns),
  `tiannara-tcl` deployments that have **no Deployment manifest in `k8s/`**
  (where they live is unknown); phase13_14 ScaledObject sets no min/max.
- **CI:** not exercised by any workflow.
- **Plan:** as §1.2, plus locate/orphan-declare the missing target manifests.

---

## 12. Cross-cutting observations

1. **Three directories (`gui`, `internal_dashboard`, `mobile`) are
   gitignored/never-committed** — invisible to review, CI, and history;
   `mobile` is non-functional stubs. Any "complete system" claim that counts
   them is invalid from this checkout.
2. **The tracked CI surface is narrow:** root `pytest tests/`, root Mix
   project, cross-platform evidence scripts. Not exercised: `tiannara_audit`,
   `tiannara_observatory` (tests untracked), `tiannara_pros`,
   `tiannara_runtime/k8s`, most of the 166 runtime test files, the whole
   `phase_5f2` workflow on non-main branches.
3. **Secrets hygiene:** the only literal production credentials are
   `k8s/phase6/overlays/production/kustomization.yaml:36-37` (confirmed
   repo-wide); dev secrets in `tiannara_observatory/config/config.exs` are
   committed but dev-labeled.
4. **"Production" entrypoints are duplicated and divergent**
   (`main.py` vs `main_production.py`), and prod config for the runtime
   (`config/prod.exs`) is missing entirely.
5. **Documentation systematically overclaims** (5F completion docs — see
   `PHASE_5F_STATUS_CORRECTION.md`; `uvicorn tiannara_core.main:app`;
   submodule claims; achievement-MD "100% complete" markers). Everything in
   this audit is evidence-based; docs were treated as claims to verify, not
   sources.

## 13. Recommended production-readiness order (proposed, not executed)

- **P0:** rotate + de-literalize k8s secrets (§1.2); fix audit verifiers and
  supersede the 220/220 reports (§1.1); admin-auth the payment downgrade
  endpoint (§1.3); add `config/prod.exs` (§10).
- **P1:** collapse the dual API entrypoints; remove observatory dev
  bypass/committed dev secrets; decide ownership of the three
  gitignored front-end dirs.
- **P2:** track or prune untracked test suites (observatory, runtime);
  add CI jobs for `tiannara_audit` + observatory; add pros actuator tests.
- **P3:** namespace/manifest cleanups (`tiarnara` typo, orphan KEDA targets,
  empty `Interface.Supervisor`) — each needs explicit approval as it
  renames or removes things.
