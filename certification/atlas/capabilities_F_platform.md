# Section F — Platform, Interfaces, and Operations (Phase R0 discovery)

Date: 2026-10-20 · Branch `local/pr4` @ `521cb7fe` · Mode: read-only (no files outside `certification/atlas/` modified).
Companion data file: `certification/atlas/capabilities_F_platform.csv` (14 rows). Interface inventory: `certification/atlas/interfaces_schemas.md`.

Evidence rules applied: unknown ≠ PASS; documentation ≠ implementation; test definition ≠ test run; historical CI green ≠ proof (bound to baseline SHA where cited). Every claim below carries `path:line` or a reused-audit reference.

Reuse register: `DIRECTORY_AUDIT_2026-10-19.md`, `PHASE_5F_WIRING_AUDIT.md`, `EXECUTION_CONTRACTS.md`, `TIANNARA_RUNTIME_TEST_INVENTORY.md`, `certification/atlas/baseline.md`. Directory names from `R0_SOURCE_PLAN.txt:391` are treated as discovery boundaries only.

---

## CAP-PLT-001 — API and communication layer · `partially_connected` / PARTIAL

Authoritative implementation is the FastAPI app `tiannara_api/main.py:92` (`v1.3.0-phase5`, ~45 routers `main.py:212-255`, full security middleware stack `main.py:97-102`), launched by `docker-compose.yml:55`, `Procfile`, `docker/api/Dockerfile`. Serialization: two proto3 schemas `lib/tiannara/telemetry/world_state.proto` and `report_slice.proto` with generated Elixir modules `lib/tiannara/protobuf/*.pb.ex`, consumed by Phoenix channels `lib/tiannara/web/telemetry_channel.ex:43` and `report_channel.ex:25`.

The canonical contract set named by the plan — **ISD v2.0 and IF-001..IF-004 — does not exist anywhere in the repository** (repo-wide grep across md/txt/ex/exs/py/proto/json: the only hits are the plan text itself, `R0_SOURCE_PLAN.txt:186`). Therefore interface compatibility for the API layer cannot be reconciled against its own specification (F-PLT-001).

Competing implementations: `main_production.py:44` (`v1.4.0-monetization`, only CORS — `main_production.py:46-53`) and a third app `tiannara_api/gateway/main.py:16`. Tests: root `pytest tests/` exists (`ci-cd.yml:49`) but that workflow only fires on `main`/`master` (F-PLT-004). No proto round-trip or contract tests found.

## CAP-PLT-002 — Event infrastructure · `implemented_incompletely_verified` / PARTIAL

Three coexisting transports:
1. **CEL `Tiannara.CEL.Services.EventBus` v2** (`lib/tiannara/cel/services/event_bus.ex:1-108`): durable — EventStore append with offsets, DETS-backed DLQ (`:70-97`), replay (`:26-28`), retry, `:telemetry` emission (`:100`). Booted through `Tiannara.CEL.Kernel.boot` from `lib/tiannara/application.ex:37-59`. 40+ publish/subscribe sites in `lib/tiannara/world/*`.
2. **Runtime `Tiannara.EventBus`** (`tiannara_runtime/lib/tiannara/event_bus.ex:1-41`): Registry (`Tiannara.EventRegistry`) pub/sub + telemetry; EventRegistry is a booted Infrastructure-layer `optional_child` prerequisite added in W3 (`PHASE_5F_WIRING_AUDIT.md:21,151-165`).
3. **NATS**: gnat is a real dep (`tiannara_runtime/mix.exs` gnat `~> 1.0`) and is used by phase8–19 supervisors and `event_gateway.ex:117,188`; but `TiannaraRuntime.NATS.Connection` is a **bespoke raw TCP listener on :4222** (`nats/connection.ex:14-30`) that publishes JSON into `NATS.Bus` — an emulated/fallback transport, not a NATS client (F-PLT-006). `Tiannara.UCC.NATSConsumer` is a self-declared stub (`ucc/nats_consumer.ex:1-10`, commented out of supervision `ucc_supervisor.ex:16-17`).

Delivery/ordering/recovery: CEL bus gives monotonic offsets + DLQ + replay; ordering across subscribers and at-least-once semantics are **untested as failure modes** (UNKNOWN). Verified-fallback semantics (when gnat vs raw TCP listener is used) are undocumented. Tests that did run in CI: boot round-trip `tiannara_runtime/test/tiannara/olef/boot_wiring_w3_test.exs:17-34` (EventBus pressure_update through live PressureSolver) inside the CI-required runtime suite (`baseline.md:46`). No unified event registry/schema (no UEP artifact found).

## CAP-PLT-003 — Runtime supervision · `implemented_incompletely_verified` / MATCHED

Reused, not re-derived: boot tree and integration truth table from `PHASE_5F_WIRING_AUDIT.md:10-57` (StartupSupervisor `:rest_for_one` → CPL → Omega (10 leaves) → Observatory → Phoenix → RootSupervisor profile-gated `:stable|:research|:minimal` → DiscoveryRunner; BootPolicy `required/optional/experimental_child` at `supervisors.ex:6-21`). W1/W2/W3 wiring commits `3690efbd`/`07971bf9`/`9307d6ed` are part of the CI-required runtime suite (1854 tests green at baseline SHA, `baseline.md:38,46`), so boot wiring is dynamically observed in CI — but only for the test environment.

Gaps keeping this from `verified_operational`: `config/prod.exs` missing → `MIX_ENV=prod` boot cannot succeed (`DIRECTORY_AUDIT:272-274`); failure isolation/restart behaviour spot-tested only (CIS terminate/restart); 23 orphaned modules + `Tiannara.Meta.Supervisor` orphan remain unwired (`PHASE_5F_WIRING_AUDIT.md:50`); `Interface.Supervisor` starts `children = []` (`supervisors.ex:180`).

## CAP-PLT-004 — Python services · `partially_connected` / PARTIAL

- **tiannara_api**: FastAPI confirmed (`main.py:92`), `/health` at `main.py:339`, Prometheus init `main.py:95`. Divergent `main_production.py` (CORS only) and third app `gateway/main.py` (F-PLT-002).
- **tiannara_core**: library, no entrypoint; instantiated by `main.py:80-81`; doc claim `uvicorn tiannara_core.main:app` is false (file absent, `DIRECTORY_AUDIT:136-137`); CWD-relative state writes (`DIRECTORY_AUDIT:145-147`).
- **tiannara_pros**: 47 tracked files, orchestrator `__main__` entrypoints, wired into core (`pros_adapter.py:3-4`), **zero tests anywhere** (`DIRECTORY_AUDIT:233-234`).
- **tiannara_saas** (plan brief lists it as a Python service): **not Python** — Next.js 16 app (`tiannara_saas/package.json:2`, `next` 16.2.6 `:21`), reclassified to CAP-PLT-005/010 (F-PLT-010).
- Health: `/health` plus router-level healths (`routes/monitoring.py:351`, `routes/efficiency.py:357`, `routes/observatory.py:477` proxying runtime health). Python CI matrix exists but never runs on this branch (F-PLT-004).

## CAP-PLT-005 — Frontend platform · `partially_connected` / CONTRADICTED

Five frontends, four of them unverifiable from this checkout:

| Frontend | Stack | Git | CI |
|---|---|---|---|
| `tiannara_gui` | Vite + React 18 + three.js/WebGL2 (`src/components/CognitiveFieldRenderer.jsx:2,48`; `src/5f/causal_manifold.ts:5`) | **0 tracked**, `.gitignore:25` | none |
| `tiannara_internal_dashboard` | Next.js 14 App Router | **0 tracked**, never in history (`DIRECTORY_AUDIT:169`) | none |
| `tiannara_saas` | Next.js 16 (+ Stripe/Flutterwave/socket.io) | 90 tracked | none (docker/saas build only) |
| `tiannara_observatory/apps/observatory_ui` | Next.js (+vitest) | partially tracked (133 files) | none in root workflows |
| `tiannara-desktop` | Electron (`package.json:3-8`, productName "Tiannara Observatory") | 10 tracked | none |

The **WebGL Observatory lives inside gitignored `tiannara_gui`** — the capability the plan names (`R0_SOURCE_PLAN.txt:373`) is invisible to review and CI (F-PLT-003). `tiannara_internal_dashboard` login ignores credentials (`DIRECTORY_AUDIT:177-179`). The saas Docker build statically exports to `/app/out` (`docker/saas/Dockerfile:22`) while `next.config.ts:5-17` defines server-side rewrites — statically inferred incompatibility (F-PLT-010).

## CAP-PLT-006 — Mobile · `missing_or_unresolved` / CONTRADICTED

`tiannara_mobile`: 6 auto-generated stub files (~0.5 KB), `app.py:1-6` "Auto-generated stub … TODO", 0 tracked, never in history, generated by `tiannara_core/tests/generate_all_remaining.py:33-38` (`DIRECTORY_AUDIT:185-193`). **No API connectivity code exists.** Capability = absent.

## CAP-PLT-007 — Observability · `implemented_incompletely_verified` / PARTIAL

Present: cognitive health telemetry (`tiannara_core/telemetry/cognitive_telemetry.py:94,186,490` — SQLite; `dashboard.py:98-126,350`); API Prometheus middleware (`main.py:95`) + Prometheus/Grafana/alerts configs tracked (`monitoring/prometheus.yml`, `monitoring/alerts.yml`, 3 Grafana dashboards); runtime `:telemetry` emission from both event buses (`cel/services/event_bus.ex:100`, `tiannara/event_bus.ex:31`) and runtime `observability/stream_processor.ex` (gnat); alert/health HTTP surface (`routes/monitoring_stabilization.py:413-664`).

Missing/unknown: **distributed traces — no OTel/Jaeger/OpenTelemetry artifact found (UNKNOWN)**; monitoring stack deployment state unknown (configs exist, no compose/k8s service wiring found); audit correlation rests on `tiannara_audit`, whose graph/proof verifiers "cannot fail" (`graph_verifier.ex:23-37`, `proof_verifier.ex:21-22` — reports superseded, `DIRECTORY_AUDIT:40-59`) and which has no CI job (F-PLT-012).

## CAP-PLT-008 — Storage · `implemented_incompletely_verified` / PARTIAL

Actual mechanisms: root DETS (lifecycle-managed, `application.ex:124-126`; DLQ opened CWD-relative `event_bus.ex:70`) + 100+ ETS sites; runtime CPL JSON journal (`lib/tiannara_runtime/os/persistence/constitutional_persistence_layer.ex`), Omega snapshots, Mnesia (`meta/causal_data_layer.ex:3,49-99`, disk schema per `DIRECTORY_AUDIT:259-260`); PostgreSQL/SQLAlchemy in API (`database/__init__.py:10-33`) and 5–6 DBs in observatory (committed dev creds `config/config.exs:22-23`); SQLite in core (`telemetry/cognitive_telemetry.py:133`, `interpretability/audit_trail.py:161`).

Ownership/migrations/backup: no single ownership registry (competing: CPL vs Omega vs ExperimentJournal vs observatory event_store/replay_store); migrations = 7 ad hoc root `migrate_*.py` scripts, no alembic found; backup/restore = manual archive dirs (`council_dets_archive_20260816`, `dev_data_archive_20260816`) + snapshots, no automated path evidenced. Hygiene: **16 `*.dets` files tracked in git** incl. 6.9 MB `cel_memory_v2.dets` (F-PLT-009); `tiannara_runtime/data/**` untracked runtime churn (baseline: untracked 1318 entries). Runtime has no Postgres/Ecto (`DIRECTORY_AUDIT:262`).

## CAP-PLT-009 — Security · `partially_connected` / CONTRADICTED

Real: full middleware stack on `main.py:97-102`; JWT secret env-required in prod (`gateway/auth.py:32-35`); websocket auth fail-closed `close(1008)` (`security/websocket_auth.py:44-48`); rate limiting/quota (`middleware/enhanced_rate_limiter.py:91`, `quota_enforcer.py:51`).

Contradictions: enforcement skipped unless `ENVIRONMENT=production`, default `development` = permissive (`production_auth.py:71-72`); `/api/v1/payment` on public allowlist (`production_auth.py:21`); payment admin endpoint has `# TODO: Add admin authentication check` (`routes/payment.py:191`); `main_production.py` ships none of the five middleware; k8s production overlay holds literal release-cookie/nats-auth-token values (`tiannara_runtime/k8s/phase6/overlays/production/kustomization.yaml:36-37` — path cited, values redacted) and cannot build (missing base kustomization, `:5`); observatory dev bypass grants administrator (`plugs/auth.ex:13-21`) + committed dev secrets + CORS `*` (`config/config.exs:9`).

Dependency security: **no dependabot/safety/pip-audit/npm audit/codeql/trivy in any workflow or `.github` config (grep = 0 hits)** (F-PLT-011). Signature/key material: key-shaped `pem*.txt` files at repo root are **untracked** (paths only — `pem1.txt`..`pem_h.txt`; never staged); `Tiannara.exe` **is tracked** (binary in git). Root `.env` is untracked BEAM tuning only (`ELIXIR_ERL_OPTIONS`), no secrets. Babel crypto still uses an unkeyed SHA-256 "topological key" with zero production callers (`PHASE_5F_WIRING_AUDIT.md:48`).

## CAP-PLT-010 — Deployment and CI/CD · `partially_connected` / PARTIAL

Five workflows: `elixir_ci.yml` (branches `**`, `:2-4` — required root suite + required `tiannara_runtime suite`, green at baseline `baseline.md:38,46`), `cross_platform_verify.yml` (branches `**`, evidence scripts, green `baseline.md:39`), `ci-cd.yml` (**`[main, master]`**, `:3-8` — pytest matrix, flake8, Docker build/push ghcr, deploy-staging, release), `test.yml` (`[main, master]`, `:6-10`), `phase_5f2_tests.yml` (`[main, develop]` + path filter, `:3-12`).

**Reconciliation defect:** `baseline.md:48` claims `ci-cd.yml` "runs on pushes to `local/pr5`, `local/pr6`" — the actual file says `[main, master]` (`ci-cd.yml:5,8`). Both claims agree it never runs on `local/pr4`; the branch list itself is CONTRADICTED (F-PLT-004).

Deploy artifacts: `docker-compose.yml` (postgres/redis/api/core only), `Dockerfile.production`, `docker/{api,core,saas}`, `Procfile` (single web process), `start*.bat/ps1/sh` scripts, `tiannara_runtime/k8s/` (12 manifests; production overlay broken + plaintext creds; KEDA targets deployments with no tracked manifests — `DIRECTORY_AUDIT:281-292`). Rollback/release promotion: no automated rollback path found; release job only creates a GitHub Release (`ci-cd.yml` release job). Artifact integrity: image digest logged in build job; cross_platform cert-hash artifacts — but nothing gates promotion on them.

## CAP-PLT-011 — Resource management · `implemented_incompletely_verified` / UNKNOWN

Many local budget mechanisms, no system-level governor: IRD compute budget (`ird/budget_controller.ex:11-59`), SafetyCortex stability credits (`cortex/safety_cortex.ex:21,55`), constitutional stabilization budget (`constitution/stabilization.ex:17-19`), OPC causal shear budget (`opc/tier3/causal_budget_controller.ex:11`), RewriteEngine rewrite budget (`mathematics/rewrite_engine.ex:18,64-80`), legacy MSCL budget tracker, OSE thermodynamic budgets, API rate/quota middleware, CEL EventBus `backpressure` option (`event_bus.ex:89`). IRD + SafetyCortex are boot-wired (Constraint layer); the rest vary.

Unknowns: memory/CPU ceilings (only `Optimize-WindowsBEAM.ps1` helper); queue-depth backpressure end-to-end; safe-degradation contracts (degradation atoms exist, e.g. `evaporation_engine.ex:120`, but no e2e exhaustion test found). Reconciliation UNKNOWN because no spec defines expected resource behaviour to compare against.

## CAP-PLT-012 — Documentation and developer tooling · `implemented_incompletely_verified` / CONTRADICTED

Docs exist in volume (461 files under `docs/`, 100s of root `PHASE*.md`), plus `AGENT.md`, `README.md`, `docs/capability_ledger.md:157` (admits `tiannara_audit` invisible to boot/census/CI). But no single authority: `DIRECTORY_AUDIT:314-318` records systematic overclaims (`uvicorn tiannara_core.main:app`, submodule claims despite `baseline.md:15` "Submodules: none", achievement-MD "100% COMPLETE" markers inside `tiannara_core/tests`). Ownership: no CODEOWNERS found. Reproducible workflow: `mise.toml` + start scripts exist; `cross_platform_verify.yml` runs reconstruction/mutation/independent-audit evidence scripts — but their generator (`run_independent_audit.exs`) feeds the same audit lineage whose reports are superseded (F-PLT-012). The evidence layer under `certification/audit/` is the de-facto authoritative source (used by this R0).

## CAP-PLT-013 — (extra) Electron desktop shell · `implemented_incompletely_verified` / UNKNOWN

Discovered: `tiannara-desktop/` — Electron app, 10 tracked files (`main.js`, `preload.js`, `renderer/{app.js,index.html,splash.html,styles.css,coa-bridge.css}`, `package.json`, `assets/icon.png`), `electron-builder` win/mac/linux targets, productName "Tiannara Observatory" (`package.json` build block) — name collision with `tiannara_observatory`. Not in plan Section F; no CI, no tests, backend connectivity UNKNOWN.

## CAP-PLT-014 — (extra) tiannara_observatory umbrella · `partially_connected` / PARTIAL

10-app umbrella listed in `tiannara_observatory/mix.exs:7-18` (+ `observatory_ui` present on disk, not umbrella-listed). Real router-level auth+rate-limit plugs exist but dev bypass grants administrator (`plugs/auth.ex:13-21`). Tracked contract docs (`docs/06_DATA_CONTRACT.md`, `08_EVENT_TAXONOMY.md`, `09_METRIC_REGISTRY.md`, `11_API_CONSTITUTION.md`) are candidate interface authorities (see `interfaces_schemas.md`). Consumed by `tiannara_api/routes/observatory.py:38` with **simulation fallback on failure** (`:602,:622`) — the API degrades to fabricated observatory data rather than failing closed. No root CI references; its own CI file untracked (`DIRECTORY_AUDIT:201,219-220`).

---

## Draft findings

### F-PLT-001 — Interface contracts ISD v2.0 / IF-001..IF-004 do not exist in the repository
- **Severity:** High (blocks interface-certification claims) · **Confidence:** high
- **Evidence:** `certification/atlas/R0_SOURCE_PLAN.txt:186` is the *only* occurrence of `ISD v2.0` or `IF-001..IF-004` (repo-wide grep over md/txt/ex/exs/py/proto/json = 1 hit); no file matching `*ISD*`/`*interface*contract*` found.
- **Affected caps:** CAP-PLT-001, CAP-PLT-012 (also reported in `interfaces_schemas.md`).
- **Root cause/HYPOTHESIS:** the interface contract set was specified in program documents but never landed in this repo (may live in ESAP or another repo — UNKNOWN).
- **Minimal remediation:** locate the authoritative ISD/IF artifacts and import them into `certification/atlas/` with provenance, or re-derive them from the implemented APIs and mark them as inferred.
- **Acceptance criteria:** ISD/IF documents with version+producers+consumers exist in-repo; each IF-00n maps to at least one implemented boundary with a compatibility test.

### F-PLT-002 — Divergent/duplicated API entrypoints with divergent security posture
- **Severity:** High · **Confidence:** high
- **Evidence:** `tiannara_api/main.py:84,92,97-102` (5 security middleware, v1.3.0) vs `main_production.py:40-53` (CORS only, v1.4.0) vs `gateway/main.py:16` (third app); `middleware/production_auth.py:71-72` skips enforcement unless `ENVIRONMENT=production` (default development); `routes/payment.py:191` admin-auth TODO; `production_auth.py:21` payment allowlist. Reused: `DIRECTORY_AUDIT:73-89`.
- **Affected caps:** CAP-PLT-001, CAP-PLT-004, CAP-PLT-009.
- **Root cause/HYPOTHESIS:** monetization workstream forked `main_production.py` instead of extending `main.py`; auth is opt-in by env rather than fail-closed default.
- **Minimal remediation:** retire/fold `main_production.py` (or make it a wrapper importing `main`), make production auth fail-closed by default, implement the payment admin check, re-evaluate the payment allowlist entry.
- **Acceptance criteria:** exactly one production entrypoint; a test proves auth middleware rejects an unauthenticated admin call in default env; flake8/pytest suite runs green under CI on this branch (see F-PLT-004).

### F-PLT-003 — Frontend platform is mostly absent-in-git (WebGL Observatory unauditable)
- **Severity:** High · **Confidence:** high
- **Evidence:** `git ls-files tiannara_gui|tiannara_internal_dashboard|tiannara_mobile` = 0; `.gitignore:25-27`; WebGL lives in `tiannara_gui/src/5f/causal_manifold.ts:5` and `src/components/CognitiveFieldRenderer.jsx:2,48`; `DIRECTORY_AUDIT:151-193`.
- **Affected caps:** CAP-PLT-005, CAP-PLT-006 (and interface report — `causal_manifold.ts` claims a shared Elixir/TS/WebGL/NATS schema that cannot be reviewed).
- **Root cause/HYPOTHESIS:** deliberate "move to separate repository" (commit `3f8aacda`) executed without vendoring/pointer; dashboard/mobile never committed by oversight.
- **Minimal remediation:** decide ownership per dir (restore to git, convert to submodule, or formally declare external and record the boundary + interface pinning).
- **Acceptance criteria:** each frontend dir is either tracked in this repo (with at least one build job) or listed in an ownership register with its canonical repo URL and a pinned interface contract.

### F-PLT-004 — Python/Docker/release pipeline never executes on this branch (and baseline records the branch filter incorrectly)
- **Severity:** High · **Confidence:** high
- **Evidence:** `.github/workflows/ci-cd.yml:3-8` (`push`/`pull_request` → `[main, master]`), `test.yml:6-10` (same), `phase_5f2_tests.yml:3-12` (`[main, develop]` + path filter) vs `baseline.md:48` claiming `ci-cd.yml` runs on `local/pr5|pr6` — CONTRADICTED. Running branch is `local/pr4` (git). `baseline.md:38-43` confirms only Elixir CI + Cross-Platform ran at baseline SHA.
- **Affected caps:** CAP-PLT-010, CAP-PLT-001/004/009 (no pytest/lint/security coverage on candidate branches).
- **Root cause/HYPOTHESIS:** workflow branch filters written for mainline; candidate-branch work never widened them; baseline discovery transcribed an incorrect branch list.
- **Minimal remediation:** correct `baseline.md:48`; decide policy — either widen `ci-cd.yml`/`test.yml` triggers to candidate branches or document that Python CI is mainline-only with an explicit promotion gate.
- **Acceptance criteria:** either a CI run of `ci-cd.yml` on a non-main branch is recorded, or a signed-off exclusion note exists in the certification record; baseline text matches workflow files.

### F-PLT-005 — Kubernetes production overlay contains plaintext credentials and cannot build
- **Severity:** High (security + deployability) · **Confidence:** high (reused, paths re-verified)
- **Evidence:** `tiannara_runtime/k8s/phase6/overlays/production/kustomization.yaml:36-37` literal `release-cookie`/`nats-auth-token` values (values redacted here; see `DIRECTORY_AUDIT:61-71`); same file references `../../base` at `:5` but `k8s/phase6/base/` has no `kustomization.yaml` (only kustomization in tree is the overlay itself); KEDA targets deployments with no tracked manifests (`DIRECTORY_AUDIT:287-290`); `k8s` not exercised by any workflow (`DIRECTORY_AUDIT:291`).
- **Affected caps:** CAP-PLT-009, CAP-PLT-010, CAP-PLT-002 (nats auth token).
- **Root cause/HYPOTHESIS:** secrets hand-written into the overlay; kustomize base never completed.
- **Minimal remediation:** rotate both values (ops action), switch to secret-manager/`secretGenerator` + `--load-restrictor` pattern, add tracked base kustomization, orphan-declare missing KEDA targets.
- **Acceptance criteria:** `kubectl kustomize` succeeds from tracked files; secret scan of `k8s/` returns zero literal credentials; rotation recorded out-of-band.

### F-PLT-006 — "NATS integration" includes an emulated TCP transport with ambiguous fallback semantics
- **Severity:** Medium · **Confidence:** high (code), medium (impact)
- **Evidence:** `tiannara_runtime/lib/tiannara_runtime/nats/connection.ex:14-30` opens a raw `:gen_tcp.listen` on port 4222 and feeds `NATS.Bus` — competes with a real NATS server on the same port (root `nats-server.log` exists); gnat usage is real elsewhere (`event_gateway.ex:117,188`, phase8-19 `Gnat.start_link`); `ucc/nats_consumer.ex:1-10` stub + commented out (`ucc_supervisor.ex:16-17`); `config.exs:16` `nats://localhost:4222` default (`DIRECTORY_AUDIT:263`).
- **Affected caps:** CAP-PLT-002, CAP-PLT-004 (Python↔Elixir bridge), CAP-PLT-011 (degradation path).
- **Root cause/HYPOTHESIS:** the listener is a dev/test fallback that hardened into "integration"; nothing documents when it is active vs gnat.
- **Minimal remediation:** document and gate the fallback (explicit config flag + boot warning), verify port-conflict behaviour, remove or implement `UCC.NATSConsumer`.
- **Acceptance criteria:** a written transport matrix (component → transport → fallback) with a test per row; no process silently binds 4222 while a NATS server expects it.

### F-PLT-007 — Event infrastructure fragmented across ≥4 transports with no registry/schema authority
- **Severity:** Medium · **Confidence:** high
- **Evidence:** CEL EventBus v2 (`cel/services/event_bus.ex:1-108`), runtime Registry bus (`tiannara/event_bus.ex`), `TiannaraRuntime.NATS.Bus` + Connection/Publisher/Subscriber, gnat per-phase supervisors (phase8-19), plus JSON ad hoc subjects (`nats/world_event_serializer.ex` free-text subject list); no UEP/event-registry artifact found (grep = 0); observatory's `docs/08_EVENT_TAXONOMY.md` covers only its own umbrella.
- **Affected caps:** CAP-PLT-002, CAP-PLT-007, CAP-PLT-011.
- **Root cause/HYPOTHESIS:** organic phase-by-phase growth; each phase added a bus instead of extending one.
- **Minimal remediation:** publish a single event registry (name/version/payload schema/producers/consumers) and classify every existing transport as registered, bridged, or legacy.
- **Acceptance criteria:** registry file exists with ≥ the top 20 live topics mapped; delivery/ordering/recovery semantics documented per transport with at least one failure-mode test each.

### F-PLT-008 — Runtime production boot impossible: `config/prod.exs` missing
- **Severity:** Medium (blocks deployment claims) · **Confidence:** high (reused)
- **Evidence:** `DIRECTORY_AUDIT:272-274` — `config/config.exs:57` imports `"#{Mix.env()}.exs"`; no `tiannara_runtime/config/prod.exs` → `MIX_ENV=prod` compile/boot fails; k8s image `tiannara-runtime:phase6-6.0.0` implies prod runs were attempted elsewhere (UNKNOWN).
- **Affected caps:** CAP-PLT-003, CAP-PLT-008, CAP-PLT-010.
- **Root cause/HYPOTHESIS:** dev/test-only runtime configuration history.
- **Minimal remediation:** add a reviewed `config/prod.exs` (fail-closed defaults), compile under `MIX_ENV=prod` in a workflow.
- **Acceptance criteria:** `MIX_ENV=prod mix compile` (or a dry-run boot) succeeds in CI, and prod config contains no committed secrets.

### F-PLT-009 — Runtime state databases and binaries committed to git
- **Severity:** Medium · **Confidence:** high
- **Evidence:** `git ls-files "*.dets"` → 16 files incl. `cel_memory_v2.dets` (6.9 MB), `conflict_resolution_engine.dets` (19 MB), `council_audit_log.dets`, `dev_data/dets/**`, `tmp/test_executive_memory/primary.dets`; `Tiannara.exe` tracked; `baseline.md:24` records ` M` churn from test runs on tracked `.dets`.
- **Affected caps:** CAP-PLT-008, CAP-PLT-010 (dirty-tree noise, diff/PR hygiene), CAP-PLT-009 (audit-log state committed).
- **Root cause/HYPOTHESIS:** runtime writes opened tables in repo root before ignore rules were written.
- **Minimal remediation:** untrack (not delete) runtime DBs after archiving contents, add `.gitignore` entries, keep only schema/seed fixtures tracked.
- **Acceptance criteria:** `git ls-files '*.dets'` returns only intentional fixtures; `git status` churn from test runs stops modifying tracked files.

### F-PLT-010 — `tiannara_saas` misclassified as Python service; static-export Docker build incompatible with server rewrites
- **Severity:** Medium · **Confidence:** high (classification), medium (build break — statically inferred, not executed)
- **Evidence:** `tiannara_saas/package.json:2,21` (Next.js 16.2.6, React 19); `docker/saas/Dockerfile:13,22` (`npm run build` → copy `/app/out`) vs `tiannara_saas/next.config.ts:5-17` (async `rewrites` require a Node server; no `output: 'export'` found); saas absent from `docker-compose.yml` service list.
- **Affected caps:** CAP-PLT-004, CAP-PLT-005, CAP-PLT-010.
- **Root cause/HYPOTHESIS:** Dockerfile written for a static-export variant; config later switched to rewrites (or vice versa).
- **Minimal remediation:** either set `output: 'export'` and replace rewrites with absolute API URLs, or serve via `next start`/Node runtime image; reconcile compose to include (or explicitly exclude) saas.
- **Acceptance criteria:** `docker build docker/saas` produces an image that serves a working app (or build job in CI proves it); plan/docs list saas under frontend, not Python services.

### F-PLT-011 — No dependency or secret scanning in CI
- **Severity:** Medium · **Confidence:** high
- **Evidence:** grep of `.github/workflows/*.yml` for `dependabot|safety|pip-audit|npm audit|trivy|codeql` = 0 hits; `.github/dependabot.yml` absent; existing pipelines cover pytest/flake8/mix only.
- **Affected caps:** CAP-PLT-009, CAP-PLT-010.
- **Root cause/HYPOTHESIS:** CI scope historically limited to test suites; security left to manual audit.
- **Minimal remediation:** add dependabot + one SAST/secret-scan step (even as non-blocking first), wire results into the certification evidence stream.
- **Acceptance criteria:** a workflow run on the candidate branch shows a dependency/secret-scan job with recorded results.

### F-PLT-012 — Audit-correlation component cannot fail (verifiers return success unconditionally)
- **Severity:** Medium (claim-control) · **Confidence:** high (reused, code refs)
- **Evidence:** `tiannara_audit/lib/tiannara_audit/graph_verifier.ex:23-37` computes a hash, never compares it, returns `match: true`; `proof_verifier.ex:21-22` passes when expected fingerprint is `nil`; the "220/220 PASS" reports (`INDEPENDENT_AUDIT_REPORT.md` in two locations) are therefore invalid (`DIRECTORY_AUDIT:40-59`); `tiannara_audit` has no CI job or tests (`DIRECTORY_AUDIT:113-128`).
- **Affected caps:** CAP-PLT-007, CAP-PLT-012 (and any evidence stream that cited those reports, incl. cross_platform `run_independent_audit.exs` lineage — verify before reuse).
- **Root cause/HYPOTHESIS:** verifier implemented as report generator; missing-failure path never tested.
- **Minimal remediation:** make both verifiers fail-closed on nil/mismatch, regenerate the reports with the fixed auditor, mark historical ones superseded, add a CI job.
- **Acceptance criteria:** a deliberately corrupted sample makes the auditor exit non-zero; both historical reports are annotated superseded; auditor runs in CI.

### F-PLT-013 — Protobuf schemas unversioned, minimal, and disconnected from the runtime bus
- **Severity:** Low · **Confidence:** medium
- **Evidence:** `lib/tiannara/telemetry/world_state.proto` and `report_slice.proto` are proto3 with **no version field/compat policy**; consumers are only the two root-app Phoenix channels (`telemetry_channel.ex:43`, `report_channel.ex:25`); runtime messaging uses JSON ad hoc (`nats/world_event_serializer.ex`, `Jason.encode` sites) — the protos do not cover event-bus payloads.
- **Affected caps:** CAP-PLT-001, CAP-PLT-002.
- **Root cause/HYPOTHESIS:** protos are a viz-channel artifact, not a platform contract.
- **Minimal remediation:** declare ownership (which messages are contractual), add version/compat notes, add a round-trip encode/decode test.
- **Acceptance criteria:** each proto has a documented producer/consumer and a test that fails on breaking changes (or an explicit "not contractual" label in the interface register).

### F-PLT-014 — Desktop shell naming collides with Observatory; zero verification
- **Severity:** Low · **Confidence:** high
- **Evidence:** `tiannara-desktop/package.json` productName "Tiannara Observatory" / appId `com.tiannara.observatory` while `tiannara_observatory` is the umbrella; 10 tracked files, no tests/CI/docs referencing it.
- **Affected caps:** CAP-PLT-013, CAP-PLT-014.
- **Root cause/HYPOTHESIS:** parallel prototype; ownership never assigned.
- **Minimal remediation:** rename or register ownership; decide whether it consumes runtime/API endpoints (document them) or is a dead prototype.
- **Acceptance criteria:** ownership record + at least a smoke build job, or formal retirement.

### F-PLT-015 — Observatory security posture: dev bypass + committed dev secrets + fail-open API fallback
- **Severity:** Medium · **Confidence:** high (reused)
- **Evidence:** `tiannara_observatory/apps/observatory_api/lib/observatory_api/plugs/auth.ex:13-21` (dev bypass grants administrator); `config/config.exs:14,48` secret_key_base/jwt_secret and `:22-23` postgres/postgres committed; CORS `*` (`config.exs:9`, `observatory_api_web/endpoint.ex:36`); `tiannara_api/routes/observatory.py:602,622` simulation fallback; self-referential `TIANNARA_RUNTIME_URL` default (`config.exs:65`).
- **Affected caps:** CAP-PLT-014, CAP-PLT-009, CAP-PLT-007, CAP-PLT-005.
- **Root cause/HYPOTHESIS:** dev ergonomics shipped as defaults.
- **Minimal remediation:** gate bypass behind explicit env with fail-closed default, move secrets to env, restrict CORS, make the API path fail closed instead of simulating, fix the runtime URL default.
- **Acceptance criteria:** boot with no env set rejects unauthenticated admin requests; config holds no literal secrets (scan clean); observatory health failure surfaces as an error, not simulated data.

### F-PLT-016 — Key-shaped files at repo root and tracked binary (secret hygiene risk)
- **Severity:** Low (currently untracked) · **Confidence:** high
- **Evidence:** `pem1.txt`, `pem2.txt`, `pem3.txt`, `pem_3b.txt`, `pem_h.txt` exist at repo root and begin with private-key-style headers — **not tracked** (`git ls-files --error-unmatch` fails); `Tiannara.exe` **is tracked**; root `.env` untracked and contains only `ELIXIR_ERL_OPTIONS` (no secrets).
- **Affected caps:** CAP-PLT-009.
- **Root cause/HYPOTHESIS:** local key material placed in workspace root where a future `git add -A` would stage it.
- **Minimal remediation:** move key material outside the repo or to a gitignored `secrets/` dir; add `pem*`/`*.pem` to `.gitignore`; consider untracking `Tiannara.exe`.
- **Acceptance criteria:** `.gitignore` covers key-material patterns; a pre-commit/CI secret scan confirms zero staged key material.

---

## Explicit unknowns (Section F)

1. ISD v2.0 / IF-001..IF-004 content, location, and whether they exist outside this checkout (ESAP repo not examined in R0).
2. Distributed tracing (OTel/Jaeger): no artifacts found — capability presence UNKNOWN, not absent-proof.
3. Ordering/at-least-once/replay semantics of CEL EventBus under failure — no failure-mode tests located; only happy-path boot tests ran in CI.
4. Whether Prometheus/Grafana/alerting stack has ever been deployed (configs tracked; no compose/k8s wiring found).
5. Whether any `pem*.txt` file contains a real private key (content not read beyond header shape; paths recorded only).
6. Phase8–19 gnat supervisors: are they booted in any environment (not in the Section-0 boot tree tables; wiring status UNKNOWN beyond local tests).
7. Mobile API connectivity: no code exists to inspect; historical claims (if any) unverifiable here.
8. Whether `main_production.py`/`gateway/main.py` are referenced by any deployment outside this checkout.
9. tiannara-desktop renderer backend endpoints (not analyzed beyond entry files).
10. Backup/restore actuality: archive dirs exist; whether restore was ever exercised is UNKNOWN.
