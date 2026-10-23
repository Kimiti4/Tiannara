# Phase R1 Batch 2 — Step 1: Launch Boundary

**Date:** 2026-10-22 (UTC) · **Branch:** `local/pr4` @ `8ff5ec83` · **Mode:** read-only discovery.
**Governing decision:** D-ARC-005 — *interim deployment boundary* (operator, 2026-10-21, resolving OP-04 for the reachability phase): the root Elixir application (`:tiannara`) and `tiannara_runtime` (`:tiannara_runtime`) are operated as **separate releases/processes**. Do **not** load both into one BEAM; do **not** merge the source trees while the 28 duplicate fully-qualified module names remain unresolved (`certification/atlas/decisions_register.md:36`).
**Question answered by this document:** for each project — what real launch paths exist, what do they require, can they be launched in isolation with data redirected to a temporary directory and no external services, what would collide if both ran on one host, and what blocks the reachability step.

---

## 0. Method, evidence vocabulary, and honesty boundaries

### 0.1 Basis labels used on every claim below

| Label | Meaning | How obtained here |
|---|---|---|
| `documented` | The claim exists in a repo file. **Not** treated as truth about behaviour. | Read of a tracked `.md`/`.ex`/`.yaml`. |
| `statically_inferred` | Derived by reading source (boot trees, `defp`, config, call sites). | The primary mode of this document. |
| `dynamically_observed` | Observed running in this pass. **Zero** rows carry this label. | Not available — read-only mandate, no boot, no compile, no test run. |
| `independently_verified` | Re-derived from primary source at a second, different location than the prior audit's citation. | Used where a prior claim (F-ARC-*, architecture.md) was re-read from the cited file. |
| `UNKNOWN` | Could not be established from the repo. **Never** silently promoted to PASS. | §7 + inline. |

> **Unknown is not PASS.** Where a relationship could not be established from source it is marked `UNKNOWN` in place and listed in §7.
> **Historical CI green ≠ boot proof.** No CI result is used here to assert runtime behaviour.

### 0.2 What this pass did NOT do

- No `mix compile`, no `mix run`, no `mix test`, no `mix release`, no `docker build`, no `kustomize build`.
- **No application boot.** (Explicitly out of scope — the operator runs the boot separately.)
- No file outside `certification/atlas/batch2/launch_boundary.md` was created, modified, moved or deleted.
- No git commit / push / checkout. Branch and SHA recorded read-only.

### 0.3 Prior work reused (not rediscovered)

| Asset | Reused for |
|---|---|
| `certification/atlas/architecture.md` | App inventory (A1–A18), boot trees, F-ARC-226..236, explicit unknowns U1–U10. |
| `certification/atlas/problems_G.md` | F-ARC-001 (28 duplicates), F-ARC-008 (k8s), F-ARC-013 (cross-app probes), F-ARC-014 (missing prod config), F-ARC-026..036, F-ARC-229 (no artefacts), F-ARC-232 (launcher's phantom services). |
| `certification/atlas/decisions_register.md` | D-ARC-005 (boundary), D-ARC-007 (kill switch), OP-04 status, BF-05 (separate process ≠ integrated platform). |
| `certification/atlas/baseline.md` | CI facts, workflow inventory, tracked-file distribution. |
| `certification/atlas/capabilities_F_platform.md` | F-PLT-001..016 (entrypoint split, frontends absent-in-git, CI branch filters, k8s overlay, NATS emulation, missing prod config). |
| `certification/atlas/deps_build.json` | Build/test/deploy graph; `mix release` never invoked by any tracked workflow. |
| `certification/audit/PHASE_5F_WIRING_AUDIT.md` | Boot trees for the runtime layers and the W1 CIS chain. |
| `certification/audit/TIANNARA_RUNTIME_TEST_INVENTORY.md` | Runtime test scope, quarantine list, CI-bound evidence. |

### 0.4 Corrections to prior findings (re-verified from primary source)

| Prior claim | Re-read result | Evidence |
|---|---|---|
| F-ARC-008 / F-PLT-005: "phase6/base has no kustomization.yaml" | **Now fixed.** `tiannara_runtime/k8s/phase6/base/kustomization.yaml` exists and lists namespace, gpu-node-selector, runtime-deployment, nats-cluster. | `tiannara_runtime/k8s/phase6/base/kustomization.yaml:1-15` (independently_verified) |
| F-ARC-008: "production overlay contains a literal release cookie + NATS token" | **Now changed.** `secretGenerator` reads `env:` at deploy time; no literal secret value in the file. | `tiannara_runtime/k8s/phase6/overlays/production/kustomization.yaml:33-43` (independently_verified) |
| F-ARC-014: "runtime cannot boot in MIX_ENV=prod (missing config/prod.exs)" | **Still true for the runtime project.** The **root** project's `config/prod.exs` **exists** (and is fail-closed on `SECRET_KEY_BASE`). The two must not be conflated. | `tiannara_runtime/config/` listing (`config.exs`, `dev.exs`, `test.exs`, `opc.ex`, `layer_boundaries.exs`) vs `config/prod.exs:1-43` (independently_verified) |

---

## 1. Launch mechanisms inventory

Legend for the three judgement columns:

- **Starts app?** — does the mechanism actually start the OTP application.
- **Fails closed?** — does a component failure produce a **nonzero exit**, or is it swallowed / downgraded to a warning?

### 1.1 Root Elixir project `:tiannara` (repo root)

| ID | Mechanism | Exact command | Working dir | Starts `:tiannara`? | Starts `:tiannara_runtime`? | Fails closed? | Deciding evidence (path:line) |
|---|---|---|---|---|---|---|---|
| **L1** | Mix task `tiannara.start`, default profile | `mix tiannara.start --profile dev` | repo root | **YES** | **NO** | **NO** — always exits 0 | `lib/mix/tasks/tiannara.start.ex:118` (`Mix.Task.run("app.start")`), `:23` (`@runtime_subsystems [:telemetry, :tiannara]`), `:58-66` (every phase error is rescued), `:304-306` (verdict computed from a `:fail` status that no phase can produce), `:331-336` (`keep_alive` blocks 86 400 000 ms then returns `:ok`) |
| **L2** | `start.bat` | `mix tiannara.start --profile dev` (or `mix tiannara.start %*`) | repo root | YES (via L1) | NO | NO | `start.bat:6-11` |
| **L3** | `start-production.bat` | `mix tiannara.start --profile production` | repo root | YES | NO | NO | `start-production.bat:3` |
| **L4** | `start-safe.bat` | `mix tiannara.start --safe` | repo root | YES | NO | NO | `start-safe.bat:3` → `tiannara.start.ex:11,68-75` |
| **L5** | `start-research.bat` | `mix tiannara.start --profile research` | repo root | YES | NO | NO | `start-research.bat:3` → `tiannara.start.ex:8` |
| **L6** | `start-benchmark.bat` | `mix tiannara.start --profile benchmark` | repo root | YES | NO | NO | `start-benchmark.bat:3` → `tiannara.start.ex:10` |
| **L7** | `mix tiannara.start --profile distributed` (profile exists, no script) | `mix tiannara.start --profile distributed` | repo root | YES | NO | NO | `tiannara.start.ex:12` |
| **L8** | `mix run --no-halt` | `mix run --no-halt` | repo root | YES (`mix run` starts the project app) | NO | **YES** — `mix run` aborts nonzero if `Application.start` returns `{:error, _}` | `mix.exs:58` (`mod: {Tiannara.Application, []}`); `lib/tiannara/application.ex:63-66` returns `{:error, reason}` → app start fails → Mix raises. **Documented only** (no script ships it): `docs/production_completion_baseline.md:23,250`; `markdown/5j.md:1195,1261` |
| **L9** | Release build | `mix release` (release name `tiannara`) | repo root | build artefact only | NO | build-time | `mix.exs:32-44` (`releases: [tiannara: [applications: [tiannara: :permanent, phoenix: :permanent, plug_cowboy: :permanent], steps: [:assemble, :tar]]]`). **No tracked workflow invokes it** (`deps_build.json:147`; re-verified across all 5 workflows, §1.4) |
| **L10** | Mix task `phase_omega_scan` | `mix phase_omega_scan` | repo root | YES, then **terminates** | NO | YES (finite scan) | `lib/mix/tasks/phase_omega_scan.ex:7-10` (`app.start` → `PhaseOmega.Activator.bootstrap()` → `:init.stop()`) |
| **L11** | `mix test` | `mix test` | repo root | **NOT A LAUNCH PATH** — test-only; recorded for completeness | NO | n/a | `mix.exs:108` (`test: ["test"]`); `test/test_helper.exs:9` sets `:test_mode, true`; `lib/tiannara/application.ex:55` makes CEL boot synchronous in `:test` |

**L1 detail — what `mix tiannara.start` actually does (6 phases):**

| Phase | Code | Behaviour | Fail-closed? |
|---|---|---|---|
| `:env` | `tiannara.start.ex:83-97` | Probes `elixir`, `erl`, `mix`, `node`, and TCP ports 5432/6379/4222. Missing service ⇒ status `:warn`. | No (`:warn`) |
| `:infra` | `:99-115` | Same 3 ports; `:stopped` ⇒ `:warn`. | No (`:warn`) |
| `:runtime` | `:117-134` | `Mix.Task.run("app.start")` then `Application.ensure_all_started/1` over `[:telemetry, :tiannara]`. **`:tiannara_runtime` is never in that list** (`-:23`). | No — an exception here is caught by `safe_execute_phase` (`:58-66`) |
| `:api` | `:136-147` | `Application.ensure_all_started(:phoenix)` + `ensure_endpoint_started/0` (`:377-398`, which prefers `TiannaraWeb.Endpoint`, then `TiannaraRuntimeWeb.Endpoint`). | No (`:warn`) |
| `:frontend` | `:149-158` | Only checks that `tiannara_observatory/apps/observatory_ui` **exists**. Never builds or serves it. | No (`:warn`) |
| `:health` | `:160-184` | Liveness of 6 modules + `Tiannara.CRAV.run()` (`lib/tiannara/crav/crav.ex:27`). | No (`:warn` / `:error`) |

> **F-ARC-226 re-verified (independently_verified):** the launcher's declared "required services" (PostgreSQL 5432, Redis 6379, NATS 4222 — `tiannara.start.ex:17-21`) are consumed by **no Elixir code in either project**: neither `mix.exs` declares `ecto`/`postgrex`/`redis`, the root's `:nats`/`:jetstream` config keys have **zero** readers (`config/config.exs:36-63`; grep for `get_env(:tiannara, :nats` → 0 hits in `lib/`), and the runtime's `TiannaraRuntime.NATS.ConnectionManager` config key has **no module** (`tiannara_runtime/config/config.exs:15-18`; `tiannara_runtime/lib/tiannara_runtime/nats/` contains no `connection_manager.ex`). F-ARC-232 stands.

### 1.2 Runtime Elixir project `:tiannara_runtime` (`tiannara_runtime/`)

| ID | Mechanism | Exact command | Working dir | Starts `:tiannara_runtime`? | Fails closed? | Deciding evidence (path:line) |
|---|---|---|---|---|---|---|
| **R1** | `mix run --no-halt` | `mix run --no-halt` | `tiannara_runtime/` | **YES** — `mix run` starts the project app | **YES at OTP level** — `TiannaraRuntime.Application.start/2` returns `{:error, reason}` on supervisor failure ⇒ Mix aborts nonzero. **But** `BootPolicy.optional_child/2` silently skips a module that is not loadable | `tiannara_runtime/mix.exs:23` (`mod: {TiannaraRuntime.Application, []}`); `tiannara_runtime/lib/tiannara_runtime/application.ex:46-54`; `tiannara_runtime/lib/tiannara_runtime/runtime_layers/supervisors.ex:6-12` (`required_child` raises), `:14-21` (`optional_child` warns + skips) |
| **R2** | `mix phx.server` | `mix phx.server` | `tiannara_runtime/` | **YES** (app + endpoint) | YES at OTP level | `tiannara_runtime/config/dev.exs:4-6` (`server: true`, port 8004); invoked by `tiannara_runtime/start_observability.sh:47` and `start_phase4_services.sh:111` |
| **R3** | `start_alpha.ps1` (repo-root script) | `cd tiannara_runtime` → `mix run --no-halt` | `tiannara_runtime/` | **YES** | **YES at script level** — `exit 1` on compile failure and on "not ready in 120 s" | `start_alpha.ps1:35-44` (compile + `mix run --no-halt`), `:46-60` (health wait → `exit 1`), `:29-33` (kills ports 8004 and 3000 first) |
| **R4** | `tiannara_runtime/phase2_quickstart.sh` | `mix run --no-halt &` | **repo root** (script does `cd ..` at `:63` before `:66`) | **NO — it starts the ROOT project, not the runtime.** The script's own success message says `cd tiannara_runtime` for the REPL, contradicting what it launched. Also `cd python_cortex` (`:58`) — the directory exists but the script's `grcc_simulation_cortex.py` step is unverified. | No | `tiannara_runtime/phase2_quickstart.sh:58,63,66`; step 1 starts a Docker NATS on 4222 (`:26-28`) which **conflicts** with the runtime's own raw-TCP listener on 4222 (§2.4) |
| **R5** | `MIX_ENV=prod mix release` (documented) | `MIX_ENV=prod mix release` | `tiannara_runtime/` | — | **CANNOT RUN.** (a) `tiannara_runtime/config/config.exs:57` does `import_config "#{Mix.env()}.exs"` and `config/prod.exs` **does not exist**; (b) `tiannara_runtime/mix.exs` has **no `releases/0`** (the whole file is 184 lines — read in full). The doc claims it produces `_build/prod/rel/tiannara_runtime/` | `tiannara_runtime/QUICK_START.md:239-247` (**documentation only**) vs `tiannara_runtime/config/` listing and `tiannara_runtime/mix.exs:1-184` |
| **R6** | k8s Deployment `tiannara-runtime` | `kubectl apply -k tiannara_runtime/k8s/phase6/overlays/production` | cluster | **NOT A LAUNCH PATH — the image cannot be built from tracked files.** The container spec has **no `command:`/`args:`** and the image `tiannara-runtime:phase6-6.0.0` has **no Dockerfile in the repo**. The only images built anywhere are the four Python/Node Dockerfiles. | n/a | `tiannara_runtime/k8s/phase6/base/runtime-deployment.yaml:41-43` (image, no command), `:66-70` (ports 4000, 9090), `:86-105` (probes `/health/live`, `/health/ready`, `/health/startup` — **none of these paths exist** on the runtime router) vs `tiannara_runtime/lib/tiannara_runtime_web/router.ex:8-63` |
| **R7** | k8s Deployment `tiannara-rtl` | `kubectl apply -k tiannara_runtime/k8s/phase8-rtl/base` | cluster | **NOT A LAUNCH PATH** — same reason (image `tiannara-runtime:phase8-rtl-8.0.0`, no Dockerfile, no command) | n/a | `tiannara_runtime/k8s/phase8-rtl/base/rtl-deployment.yaml:41-42,52-56` |
| **R8** | Mix task `cis.validate_phase5e` | `mix cis.validate_phase5e` | `tiannara_runtime/` | **NOT A LAUNCH PATH** — the only Mix task in the runtime project; it does not start the app | n/a | `tiannara_runtime/lib/mix/tasks/cis.validate_phase5e.ex` (the runtime's **only** Mix task; grep for `app.start`/`ensure_all_started` → 0 hits) |
| **R9** | `mix test` | `mix test` | `tiannara_runtime/` | **NOT A LAUNCH PATH** — test-only; recorded for completeness | n/a | `tiannara_runtime/test/test_helper.exs:1-9` (no isolation wipe, no `:test_mode`); `tiannara_runtime/config/test.exs:42-47` documents the removed, dead `start_app: false` key |

**R1 detail — the runtime boot tree (`statically_inferred`):**

```
TiannaraRuntime.Application.start/2                     tiannara_runtime/lib/tiannara_runtime/application.ex:18
 └─ Supervisor.start_link(strategy: :one_for_one)       :44-46
    ├─ {TiannaraRuntime.StartupSupervisor, []}           :31
    │   └─ Supervisor :rest_for_one                      startup_supervisor.ex:42
    │       1 ConstitutionalPersistenceLayer             :30-34  (checkpoint_interval 30 000, storage_path "data/cpl")
    │       2 TiannaraRuntime.Omega.Supervisor           :35
    │       3 TiannaraRuntime.OS.Observatory             :36
    │       4 TiannaraRuntimeWeb.Endpoint                :37
    │       5 TiannaraRuntime.RootSupervisor             :38
    │       6 TiannaraRuntime.DiscoveryRunner            :39
    └─ BootPolicy.optional_child × 5                    application.ex:33-42
        CIS.Supervisor → MultiWorld.KillSwitch → CIS.ExecutionController
        → Resources.QuotaGovernor → Memory.LineageCompression → Causal.GCK
```

`RootSupervisor` (`:rest_for_one`) resolves a **boot profile** from config:

| Profile | Children | Evidence |
|---|---|---|
| `:minimal` | Infrastructure + Execution + Ecology **only** — Constraint and Meta are **omitted** | `tiannara_runtime/lib/tiannara_runtime/runtime_layers/supervisors.ex:244` |
| `:stable` (default, `config/config.exs:7` `boot_profile: :stable`) | + Constraint + Meta | `:246-249` |
| `:research` | + Constraint + Meta + experimental NDE/TWP/OSL (gated by `:enable_nde` / `:enable_twp` / `:enable_osl`) | `:251-257`; `tiannara_runtime/config/config.exs:8-10` (all three `false`) |
| anything else | falls back to `:stable` | `:259` |

> **This is the single most important reduced-effect lever found in this pass** (see §3.3). `boot_profile: :minimal` is an implemented, config-driven boot-narrowing switch for the runtime.

### 1.3 Repo-root artefacts that do **not** launch either Elixir application

| Artefact | What it actually starts | Evidence | Elixir app started? |
|---|---|---|---|
| `Procfile` | `web: uvicorn tiannara_api.main:app --host 0.0.0.0 --port $PORT` — the **Python** API only | `Procfile:1` | **NO** |
| `docker-compose.yml` | `postgres:15-alpine` (5432), `redis:7-alpine` (6379), `tiannara-api` (Python, 8000), `tiannara-core` (Python worker). **No Elixir service.** | `docker-compose.yml:3-68` | **NO** |
| `Dockerfile.production` | `python:3.11-slim`; `CMD uvicorn tiannara_api.main:app --host 0.0.0.0 --port 8000 --workers 4` | `Dockerfile.production:1-5,20,65-66` | **NO** |
| `docker/api/Dockerfile` | Python API image | `docker/api/Dockerfile` | **NO** |
| `docker/core/Dockerfile` | `CMD python -m tiannara_core.autonomous.loop` | `docker/core/Dockerfile` | **NO** |
| `docker/saas/Dockerfile` | Next.js static image | `docker/saas/Dockerfile` | **NO** |
| `docker-entrypoint.sh` | waits for PostgreSQL, runs migrations, `exec "$@"` | `docker-entrypoint.sh:1-52` | **NO** |
| `start_production.sh` | `uvicorn tiannara_api.main:app` (Python), `PORT` default **8004** | `start_production.sh:1-100` | **NO** |
| `deploy-quickstart.sh` | `docker-compose build` + `docker-compose up -d` | `deploy-quickstart.sh:44-53` | **NO** |
| `start_phase4_services.bat` | Python API (8000) + `tiannara_internal_dashboard` (3000). **No Elixir step at all** | `start_phase4_services.bat:43-88` | **NO** |
| `start_phase4_services.sh` | `cd tiannara_runtime && mix phx.server` (background) + Python API + dashboard | `start_phase4_services.sh:102-116` | **partially — see §4.2** |
| `run_soak72.bat` | `MIX_ENV=dev STORAGE_CONTEXT=soak mix run scripts\soak_test.exs 72` — finite soak, exits with `%ERRORLEVEL%` | `run_soak72.bat:1-5` | YES (root), finite |
| `run_production.exs` | a **campaign script**, not a service: starts `RealityLedger` + `MetaGovernor` by hand, then exits | `run_production.exs:12-51` | no (root app) |

> **`start_alpha.ps1` is the only root-owned launcher that starts `:tiannara_runtime`** (R3). Every other runtime-starting reference is inside `tiannara_runtime/` itself, is a documentation string, or is a k8s manifest with no buildable image.

### 1.4 CI workflows — what builds / starts what, on which branches

| Workflow | Branch triggers | Jobs (build / start) | Starts an Elixir app as a service? | Evidence |
|---|---|---|---|---|
| `.github/workflows/elixir_ci.yml` | `push: branches ["**"]`, `pull_request`, `workflow_dispatch` — **spans `local/pr4`** | `compile` (`mix compile --force`; `MIX_ENV=test mix run -e ":ok"`), `test-placement` (lint gate), `lineage-regression`, `suite` (`mix test`), **`tiannara-runtime-suite`** (`working-directory: tiannara_runtime`, `mix test --exclude quarantine`), `tiannara-runtime-quarantine` (non-blocking), `tiannara-audit-suite` | **NO** — `mix run -e ":ok"` starts the app and exits immediately; `mix test` is not a service launch | `elixir_ci.yml:2-6,30-34,99-102,129-135,160-166,192-198` |
| `.github/workflows/ci-cd.yml` | `push: branches [main, master]`, tags `v*` — **never on `local/pr4`** | `test` (`pytest tests/`), `lint`, `build` (`Dockerfile.production` → ghcr), `deploy-staging` (**echo only — no real deploy**), `release` (GitHub release) | **NO** | `ci-cd.yml:3-8,49,104-151,154-181` |
| `.github/workflows/test.yml` | `push/pull_request: branches [main, master]` | Python `pytest tests/` + flake8/black/isort | **NO** | `test.yml:8-10,45,84-94` |
| `.github/workflows/cross_platform_verify.yml` | `push/pull_request: branches ["**"]` — spans `local/pr4` | `mix deps.get`, `mix compile`, `mix run generate_phase14_evidence_package.exs`, `mix run run_archaeological_reconstruction.exs`, `mix run run_mutation_testing.exs`, `mix run run_independent_audit.exs` — all **finite**, all exit | **NO** | `cross_platform_verify.yml:14,16,71-139` |
| `.github/workflows/phase_5f2_tests.yml` | `push: [main, develop]`, `pull_request: [main]` — **never on `local/pr4`** | `mix compile --warnings-as-errors` + 5 targeted `mix test` in `tiannara_runtime/` | **NO** | `phase_5f2_tests.yml:5,10,46-72` |

> **Consequence:** *no* tracked workflow builds an Elixir release, *no* tracked workflow builds an Elixir image, and *no* tracked workflow starts either Elixir application as a long-running service. The runtime's entire boot wiring is therefore **test-time wiring only** (F-ARC-226 / architecture.md BG-1, independently_verified). `deps_build.json:147` agrees: "No workflow invokes `mix release`."

### 1.5 Kubernetes manifests (all under `tiannara_runtime/k8s/`)

| Manifest | Kind | Target | Ports | Runnable from tracked files? | Evidence |
|---|---|---|---|---|---|
| `phase6/base/namespace.yaml` | Namespace | `tiannara-phase6` | — | yes | `tiannara_runtime/k8s/phase6/base/namespace.yaml` |
| `phase6/base/kustomization.yaml` | Kustomization | namespace + gpu-node-selector + runtime-deployment + nats-cluster | — | **yes** (newly added) | `phase6/base/kustomization.yaml:11-15` |
| `phase6/base/gpu-node-selector.yaml` | NodeSelector | — | — | yes | `phase6/base/gpu-node-selector.yaml` |
| `phase6/base/nats-cluster.yaml` | StatefulSet + headless Service | `nats-cluster` | 4222 (client), 7422 (cluster), 8222 (monitoring) | yes — but **conflicts with the runtime's own listener on 4222** (§2.4) | `phase6/base/nats-cluster.yaml:32-101` |
| `phase6/base/runtime-deployment.yaml` | Deployment + Service | `tiannara-runtime` | container 4000 + 9090; Service 80→4000, 9090 | **NO** — image `tiannara-runtime:phase6-6.0.0` has no Dockerfile in the repo; no `command:`/`args:`; probe paths `/health/live|ready|startup` do not exist on the runtime router; declared port 4000 ≠ runtime dev port 8004 and ≠ runtime prod port (undefined — no prod config) | `phase6/base/runtime-deployment.yaml:41-43,66-70,86-105,136-153` |
| `phase6/overlays/production/kustomization.yaml` | Overlay | patches replicas→5; `configMapGenerator` `runtime-config`; `secretGenerator` `tiannara-secrets` from env | — | base now resolves; **but** the generated ConfigMap is **never mounted** by the base Deployment (no `envFrom:`), so `STABILITY_MODE=production` and the other 5 literals **never reach the container**. And no code reads `STABILITY_MODE` (§3.3). | `phase6/overlays/production/kustomization.yaml:4-5,7-31,33-43` vs `phase6/base/runtime-deployment.yaml:44-65` (env list, no `envFrom`) |
| `phase8-rtl/base/rtl-deployment.yaml` | Deployment | `tiannara-rtl` | container 4000 + 9464; NATS sidecar 4223/8223 | **NO** — image has no Dockerfile; no command; port 9464 has no listener in the repo | `phase8-rtl/base/rtl-deployment.yaml:41-42,52-56` |
| `phase8-rtl/base/rtl-jetstream-streams.yaml` | JetStream streams | — | — | declarative | `phase8-rtl/base/rtl-jetstream-streams.yaml` |
| `phase8-rtl/base/rtl-keda-scaledobject.yaml` | KEDA ScaledObject → `tiannara-rtl` | — | — | target **does** exist (rtl-deployment.yaml) | `phase8-rtl/base/rtl-keda-scaledobject.yaml:7-8` |
| `phase13_14/keda-scaledobject.yaml` | KEDA ScaledObject → `tiannara-phase13-14` | — | — | **ORPHAN** — no Deployment named `tiannara-phase13-14` exists anywhere | `phase13_14/keda-scaledobject.yaml:6-7` |
| `phase17/ucc-keda-scaledobject.yaml` | KEDA ScaledObject → `tiannara-ucc` | — | — | **ORPHAN** | `phase17/ucc-keda-scaledobject.yaml:3,5` |
| `phase18/rrm-keda-scaledobject.yaml` | KEDA ScaledObject → `tiarnara-rrm` (typo namespace `tiarnara-phase18`) | — | — | **ORPHAN** | `phase18/rrm-keda-scaledobject.yaml:3,5` |
| `phase19/tcl-keda-scaledobject.yaml` | KEDA ScaledObject → `tiarnara-tcl` (typo) | — | — | **ORPHAN** | `phase19/tcl-keda-scaledobject.yaml:3,5` |

> **F-ARC-008 partially remediated (independently_verified):** the base kustomization now exists and the literal secrets are gone. The 4 orphan KEDA targets (`tiannara-phase13-14`, `tiannara-ucc`, `tiarnara-rrm`, `tiarnara-tcl`) **remain orphans** — no matching Deployment manifests exist in `k8s/`.

### 1.6 Explicitly NOT launch paths (recorded so they are not mistaken for ones)

| Path | Why it is not a launch path | Evidence |
|---|---|---|
| `mix test` (both projects) | Test-only; in the root it also sets `:test_mode, true` and wipes `test_data/`; in the runtime it has **no** isolation at all | `mix.exs:108`; `test/test_helper.exs:9-16`; `tiannara_runtime/test/test_helper.exs:1-9` |
| `iex -S mix` | REPL; documented in `tiannara_runtime/QUICKSTART.md:71` | doc-only |
| `mix phx.server` **in the repo root** | The root project has a `phoenix` dep and `TiannaraWeb.Endpoint`, so this *does* start `:tiannara` — but it is documented only as `cd tiannara_runtime && mix phx.server` in several docs, i.e. the docs point at the runtime, where it is R2 | `PHASE4_QUICK_REFERENCE.md:153`; `tiannara_observatory/README.md:43` |
| `tiannara_audit` escript | `escript: [main_module: TiannaraAudit]`, **no `mod:`**, `application/0` has no `mod:` ⇒ never an OTP app. It is an audit tool, not a service. | `tiannara_audit/mix.exs:11,15-17` |
| `docker-compose up` | Python/Postgres/Redis only | `docker-compose.yml:3-68` |
| `tiannara_runtime/priv/boot_verification.exs` | A finite harness that boots **only** `Tiannara.P9XEcosystem.Supervisor` in isolation (`:39`) and exits (`:69`). It does **not** boot `:tiannara_runtime`. | `tiannara_runtime/priv/boot_verification.exs:36-69` |

---

## 2. Configuration and dependency requirements per launch

### 2.1 Root project `:tiannara`

| Requirement | Where it is set | MIX_ENV | What breaks if absent |
|---|---|---|---|
| `SECRET_KEY_BASE` env | `config/prod.exs:11-14` — **`raise` if unset** (fail-closed) | `prod` only | Config load raises ⇒ the app cannot start in prod. This is the **only** fail-closed config in either project. |
| `PORT` env | `config/prod.exs:23` (`String.to_integer(System.get_env("PORT", "4000"))`) | `prod` | non-integer ⇒ `ArgumentError` at config load. Default 4000. |
| `PHX_HOST` env | `config/prod.exs:16-20` (builds `check_origin`) | `prod` | absent ⇒ `check_origin: true` (permissive). |
| `LOG_LEVEL` env | `config/prod.exs:30-39` | `prod` | absent ⇒ `:info`. |
| `STORAGE_CONTEXT` env | `config/dev.exs:20`, `config/prod.exs:43` (`System.get_env("STORAGE_CONTEXT", "production")`) | dev/prod | absent ⇒ `"production"`. **The only storage knob with an env override.** |
| `:dets_base_path` | `config/config.exs:11-19` — `./test_data/dets` (test) / `./dev_data/dets` (dev) / `./data/dets` (prod) | all | `:dets_base_path` set ⇒ `Tiannara.Storage.Paths.dets/1` uses `<base>/dets/<context>/<name>.dets`; if `nil` it falls back to `<storage_base>/<context>/dets/…` (`lib/tiannara/storage/paths.ex:70-74`). |
| `:storage_base` | `config/test.exs:51` (`./test_data/storage/<run-id>`); default `"data"` (`paths.ex:18,47`) | test sets it; dev/prod do **not** | dev/prod fall back to `"data"` ⇒ `data/<context>/…` relative to CWD. |
| `:storage_context` | `config/dev.exs:20`, `config/prod.exs:43`, `config/test.exs:45` (`"test"`) | all | default `"production"` (`paths.ex:25`). Must be one of `[:production,:test,:soak,:simulation,:replay,:benchmarks,:harness]` else `ArgumentError` (`paths.ex:41-43`). |
| `TEST_PARTITION` env | `config/test.exs:29-38` (pins the per-run id) | test | absent ⇒ auto-generated per-run id. |
| `:asc, enabled: true` | `config/config.exs:157-159` | all | **`true` by default in every env** ⇒ the 7 ASC supervisors (`lib/tiannara/application.ex:258-281`) start in dev/prod too, not just in ASC campaigns. `project_data_dir: "data/asc_projects"` (`config/config.exs:161`) is **CWD-relative and not env-overridable**. |
| `:llm_mock` | `config/test.exs:20` (`true`) | test | In dev/prod it is unset ⇒ the LLM gateway may attempt real network calls. **UNKNOWN** whether the gateway degrades offline — not read in this pass. |
| External services | **None required by any Elixir code.** The launcher *probes* PostgreSQL 5432 / Redis 6379 / NATS 4222 but only warns | — | Nothing in `:tiannara` breaks if all three are absent. (F-ARC-232.) |

### 2.2 Runtime project `:tiannara_runtime`

| Requirement | Where it is set | MIX_ENV | What breaks if absent |
|---|---|---|---|
| **`config/prod.exs`** | **MISSING.** `tiannara_runtime/config/config.exs:57` does `import_config "#{Mix.env()}.exs"` | `prod` | **Config load raises ⇒ `MIX_ENV=prod mix compile` / `mix release` / boot all fail.** This is F-ARC-014, independently_verified. `tiannara_runtime/_build/` contains `dev`, `test`, `test.ci-sim`, `propcheck.ctex` — **no `prod`**: the runtime has never been built in prod. |
| `NATS_URL` env | `tiannara_runtime/config/config.exs:16`, `dev.exs:20`, `test.exs:16` — `System.get_env("NATS_URL", "nats://localhost:4222")` | all | **Config key is DEAD** — `TiannaraRuntime.NATS.ConnectionManager` **does not exist** (no `connection_manager.ex` under `tiannara_runtime/lib/tiannara_runtime/nats/`). The real boot-wired path is the raw TCP listener, which uses `NATS_PORT` instead. |
| `NATS_PORT` env | `tiannara_runtime/lib/tiannara_runtime/nats/connection.ex:15` — `System.get_env("NATS_PORT", "4222")` | all (hardcoded default, **not** in any config file) | The listener binds 4222. If 4222 is occupied (e.g. by a real `nats-server`, or by `phase2_quickstart.sh`'s Docker NATS) the listen **fails** — but the failure is only a `Logger.warning` and the process **continues** (`connection.ex:28-30`) ⇒ **silent degradation, not fail-closed.** |
| `:boot_profile` | `tiannara_runtime/config/config.exs:7` (`boot_profile: :stable`) — **no env override** | all | `:minimal` / `:stable` / `:research`; any other value falls back to `:stable` (`runtime_layers/supervisors.ex:259`). |
| `:cpl_storage_path` | `tiannara_runtime/config/config.exs:11` (`"data/cpl"`) — **no env override** | all | Read **only** by `resurrection_engine.ex:144-145,149,182,196,210` and `experiment_journal.ex:158-159`. It does **not** control where CPL events/checkpoints are written — see §2.3. |
| `:enable_nde` / `:enable_twp` / `:enable_osl` | `tiannara_runtime/config/config.exs:8-10` (all `false`) | all | Only consulted under `boot_profile: :research` (`runtime_layers/supervisors.ex:254-256`). |
| Endpoint port | `tiannara_runtime/config/dev.exs:5` (`8004`), `test.exs:5` (`4001`, `server: false`); **prod undefined** (no prod.exs) | dev/test | In prod there is **no endpoint configuration at all** — the `TiannanaRuntimeWeb.Endpoint` would use Phoenix defaults (4000). |
| External services | **None required.** NATS is emulated in-VM; no Postgres/Redis/Postgrex/Ecto in `tiannara_runtime/mix.exs:28-69`. | — | Nothing external breaks the runtime's boot. |

### 2.3 Storage / data paths each launch writes to

| Project | Store | Path | Resolved how | Isolatable by config/env? |
|---|---|---|---|---|
| root | DETS `council_audit_log` | `<dets_base>/dets/<context>/council_audit_log.dets` | `Tiannara.Storage.Paths.dets/1` | **YES** — `:dets_base_path` + `:storage_context` + `:storage_base` |
| root | DETS `cel_event_store` | same scheme | `lib/tiannara/cel/services/event_store.ex:50` | YES |
| root | DETS `workflow_engine` | same scheme | `lib/tiannara/cel/services/workflow_engine.ex:157` | YES |
| root | DETS `world_mutations` | same scheme | `lib/tiannara/world/world_mutation_engine.ex:119` | YES |
| root | **DETS `constitution_repository`** | **`./constitution_repository.dets`** (hardcoded, CWD-relative) | `lib/tiannara/council/constitution_repository.ex:8` | **NO** |
| root | **DETS `cel_executive_memory`** | **`./cel_executive_memory.dets`** (hardcoded) | `lib/tiannara/cel/executive_memory.ex:27` | **NO** |
| root | **DETS `cel_memory_v2`** | **`./cel_memory_v2.dets`** (hardcoded) | `lib/tiannara/cel/services/executive_memory.ex:79` | **NO** |
| root | **DETS `cel_event_bus_dlq`** | **`./cel_event_bus_dlq.dets`** (hardcoded) | `lib/tiannara/cel/services/event_bus.ex:70` | **NO** |
| root | **DETS `mission_director_state`** | **`./mission_director_state.dets`** (hardcoded) | `lib/tiannara/cel/services/mission_director.ex:11` | **NO** |
| root | **DETS `ontology_manager`** | **`./ontology_manager.dets`** (hardcoded) | `lib/tiannara/world/ontology_manager.ex:16` | **NO** |
| root | **DETS `conflict_resolution_engine`** | **`./conflict_resolution_engine.dets`** (hardcoded) | `lib/tiannara/world/conflict_resolution_engine.ex:12` | **NO** |
| root | DETS `executive_memory` | `data/executive_memory.dets` (default) | `lib/tiannara/executive_memory.ex:29` | **NO** (no config key) |
| root | DETS `executive_memory` (runtime variant) | `priv/dets/executive_memory.dets` + `_repair` + `_backup` | `lib/tiannara/runtime/executive_memory.ex:191,308-309` | **NO** |
| root | ASC project store | `data/asc_projects` (CWD-relative) | `config/config.exs:161` | **NO** |
| root | ASC law archive | `data/asc_archive/laws.ndjson` | `config/config.exs` + ASC registry | **NO** |
| root | Non-DETS artifacts (checkpoints, reports, logs) | `data/<context>/…` via `Paths.path/1` | `lib/tiannara/storage/paths.ex:34-44`; consumers `lib/tiannara/crav/soak_checkpointer.ex:55-56`, `lib/tiannara/crav/soak_test.ex:93,98,410,878,887,892` | YES via `:storage_base` + `:storage_context` |
| root | ASC autonomous discovery | `:storage_base` (default `./data/storage`) | `lib/tiannara/asc/autonomous_discovery.ex:327` | YES |
| root | Knowledge representation | `:storage_base` (default `./data/storage`) | `lib/tiannara/reasoning/knowledge_representation.ex:69` | YES |
| **runtime** | **CPL events** | **`data/cpl/events/evt_<n>.json`** — hardcoded in `StartupSupervisor` | `tiannara_runtime/lib/tiannara_runtime/startup_supervisor.ex:32` → `.../os/persistence/constitutional_persistence_layer.ex:81,83,391` | **NO** — see §3.2 |
| **runtime** | **CPL checkpoints** | **`data/cpl/checkpoints/<layer>/chk_<layer>_<n>.json`** | `constitutional_persistence_layer.ex:398-400` | **NO** |
| runtime | CPL experiments / stats / shutdown marker | `<:cpl_storage_path>/experiments|stats|shutdown_marker.txt` | `resurrection_engine.ex:144-145,149,182,196,210`; `experiment_journal.ex:158-159` | **PARTIAL** — honours `:cpl_storage_path`, but that key is a literal in `config.exs:11` with no env override |
| runtime | Omega executive memory | `data/omega/executive_memory` | `tiannara_runtime/lib/tiannara_runtime/omega/executive_memory.ex:12,39-40` | **NO** |
| runtime | Mnesia | default Mnesia dir (`Mnesia.nonode@nohost_*`, seen at `tiannara_runtime/` root) | `tiannara_runtime/lib/tiannara_runtime/meta/causal_data_layer.ex:136-147`; `:mnesia` in `extra_applications` (`tiannara_runtime/mix.exs:22`) | **NO** — only via the Mnesia `-mnesia dir` node flag |

> **The runtime's CPL storage path cannot be redirected by config or env.** `StartupSupervisor.init/1` hardcodes `storage_path: "data/cpl"` (`startup_supervisor.ex:32`) and passes it to the CPL, which reads it from `opts` (`constitutional_persistence_layer.ex:81`) — the `:cpl_storage_path` application env is *not* consulted by the CPL. The only redirect is to change the **process working directory**.

### 2.4 External services each launch expects

| Service | Root `:tiannara` | Runtime `:tiannara_runtime` | Notes |
|---|---|---|---|
| PostgreSQL | **none** — no `ecto`/`postgrex` in `mix.exs:63-100` | **none** | Only the Python API (`tiannara_api/database/__init__.py`) and the observatory umbrella use Postgres. |
| Redis | **none** — no redis client in `mix.exs` | **none** | `docker-compose.yml:20-30` runs Redis; **no tracked code reads `REDIS_URL`** (F-ARC-232). |
| NATS (broker) | **none** — the `:nats`/`:jetstream` config keys have zero readers (`config/config.exs:36-63`) | **none required** — but the runtime **binds** 4222 itself | The runtime's "NATS" is an in-VM `Registry` bus (`nats/bus.ex`) plus a **plain `:gen_tcp` listener** on 4222 (`nats/connection.ex:15,22`) that accepts anonymous newline-JSON and republishes it in-VM (`connection.ex:53-68`). The only real `gnat` client, `TiannaraRuntime.EventGateway`, has `connect_nats/0` hard-coded to `{:error, :unavailable}` (F-ARC-228). |
| HTTP server | Phoenix/Cowboy on 4000 (dev) / `PORT` (prod) | Phoenix/Cowboy on 8004 (dev) / 4001 (test, server off) | See §4.2. |
| OpenAI / LLM | `config/test.exs:20` mocks it in test; dev/prod unset | none | **UNKNOWN** — the offline behaviour of the LLM gateway in dev/prod was not read in this pass. |

---

## 3. Isolated-environment feasibility

### 3.1 Root project — feasible, with a named caveat

**Mechanism:** launch with a temporary working directory and set the two storage context keys.

```
# from a scratch dir, with the repo on the path
$env:STORAGE_CONTEXT = "test"                       # config/dev.exs:20, config/prod.exs:43
# :dets_base_path  — set in config/config.exs:11-19; no env override -> override in code:
#   Application.put_env(:tiannara, :dets_base_path, "<tmp>/dets")
#   Application.put_env(:tiannara, :storage_base,  "<tmp>/storage")
```

| Knob | Exact key | Env var? | Effect |
|---|---|---|---|
| storage context | `:tiannara, :storage_context` | **YES** — `STORAGE_CONTEXT` | Selects the sub-tree under `Paths.path/2` (`paths.ex:24-29,37-44`). Valid values: `production, test, soak, simulation, replay, benchmarks, harness`. |
| DETS base | `:tiannara, :dets_base_path` | **NO** | Must be set via `Application.put_env/3` before the app starts (e.g. `mix run --no-start -e "..."`). `config/config.exs:11-19` hardcodes it per env. |
| storage base | `:tiannara, :storage_base` | **NO** | Same mechanism (`paths.ex:47`; `config/test.exs:51` shows the pattern). |
| ASC project dir | `:tiannara, :asc, project_data_dir` | **NO** | `config/config.exs:161` — CWD-relative; only fixable by CWD or `put_env`. |

**Exact config keys and env vars to use** (all four must be set to isolate the root app):

| Key | Value for isolation | How |
|---|---|---|
| `:tiannara, :storage_context` | `"test"` | env `STORAGE_CONTEXT=test` |
| `:tiannara, :dets_base_path` | `"<tmp>/dets"` | `Application.put_env/3` pre-boot (no env hook) |
| `:tiannara, :storage_base` | `"<tmp>/storage"` | `Application.put_env/3` pre-boot (no env hook) |
| `:tiannara, :asc, project_data_dir` | `"<tmp>/asc_projects"` | `Application.put_env/3` pre-boot (no env hook) |

**Caveat (must be stated plainly):** the root app has **7 hardcoded CWD-relative DETS files** (§2.3) that **no config key or env var can redirect**. Isolation therefore requires either (a) launching with a scratch CWD (which is exactly what makes them isolated — they land in the scratch dir), or (b) accepting that they are written into the launch directory. `mix test` proves the intended pattern: the root's `test/test_helper.exs:17-40` **raises** if `:dets_base_path` is missing/empty or is not under `test_data` — i.e. the root project already treats "isolation root not established" as a hard failure.

**External services:** none required — Postgres/Redis/NATS are probed but unused (F-ARC-232). The Python `nats-bin/` at the repo root is not consulted by any Elixir code.

### 3.2 Runtime project — **NOT feasible by configuration alone**

| Attempted knob | Result | Evidence |
|---|---|---|
| `:tiannara_runtime, :cpl_storage_path` | **Does not move CPL events/checkpoints.** The key is read only by `resurrection_engine.ex` and `experiment_journal.ex`; the CPL itself takes `storage_path` from `opts`, hardcoded to `"data/cpl"` by `StartupSupervisor`. | `tiannara_runtime/config/config.exs:11`; `tiannara_runtime/lib/tiannara_runtime/startup_supervisor.ex:24,32`; `.../constitutional_persistence_layer.ex:81,83,391,400` |
| env `CPL_STORAGE_PATH` / `STORAGE_PATH` | **Does not exist.** No `System.get_env` for any CPL path. | grep over `tiannara_runtime/lib` → only `NATS_PORT` and `NATS_URL` are env-read |
| `:tiannara_runtime, :storage_base` / `:dets_base_path` / `:storage_context` | **These keys do not exist for the runtime.** The runtime has **no equivalent of `Tiannara.Storage.Paths`** — no context resolution, no per-context tree, no run-id isolation. | `tiannara_runtime/config/*.exs` (full read); no `paths.ex` under `tiannara_runtime/lib` |
| `:tiannara_runtime, :boot_profile` = `:minimal` | **WORKS.** Narrows `RootSupervisor` to Infrastructure+Execution+Ecology (drops Constraint + Meta). But the CPL, Omega, COP, Endpoint and DiscoveryRunner are **outside** `RootSupervisor` and always start. | `tiannara_runtime/lib/tiannara_runtime/runtime_layers/supervisors.ex:229,244-259`; `tiannara_runtime/lib/tiannara_runtime/startup_supervisor.ex:29-42` |
| Working directory | **The only effective isolation lever.** CPL (`data/cpl`), Omega (`data/omega`) and Mnesia all resolve relative to CWD. Launching from a scratch directory relocates all of them. | `startup_supervisor.ex:32`; `omega/executive_memory.ex:12,39-40`; `meta/causal_data_layer.ex:136-147` |
| Mnesia dir | Only via the BEAM node flag (`-mnesia dir <path>`), not via config. | `meta/causal_data_layer.ex:136` |
| **Runtime test-suite isolation** | **NONE.** `tiannara_runtime/test/test_helper.exs` does **no** wipe and **no** path pinning, and `tiannara_runtime/config/test.exs` does **not** override `:cpl_storage_path`. Consequence: the runtime test suite writes `data/cpl/checkpoints/**` **into the repository tree**. | Confirmed by the working tree at the start of this pass: hundreds of untracked `?? tiannara_runtime/data/cpl/checkpoints/**/*.json` files; `git status --short` |
| External services | **None required.** | `tiannara_runtime/mix.exs:28-69` (no DB/redis client) |

> **Plain statement:** for the runtime, *isolation by configuration/env override alone is not achievable today.* Isolation requires **a different working directory** (plus, for a fully repeatable run, either a scratch Mnesia dir via the node flag, or acceptance that Mnesia follows the node name). This is a **blocker**, not a configuration detail — see §5 B3.

### 3.3 "Safe mode" / reduced-effect launch — what is **actually implemented**

The task asked for *implemented* semantics, not intended ones. Findings:

| Candidate name | Where it appears | **Implemented semantics** | Verdict |
|---|---|---|---|
| `safe-mode` (launcher profile) | `lib/mix/tasks/tiannara.start.ex:11` (`"safe-mode" => [:env, :runtime, :health]`), `:70` (`opts[:safe] -> "safe-mode"`), `start-safe.bat:3` | **Skips the `:infra`, `:api` and `:frontend` phases only.** The `:runtime` phase still runs `Mix.Task.run("app.start")` and starts `:tiannara` with the **full** child tree, including all 7 ASC supervisors (`config/config.exs:157-159` `enabled: true`). | **NOT a safety mode.** It is "skip the infra probe and the Phoenix/frontend checks". No reduced-effect semantics whatsoever. (`documented` name, `statically_inferred` semantics) |
| `STABILITY_MODE` | **only** `tiannara_runtime/k8s/phase6/overlays/production/kustomization.yaml:26` | **Not implemented.** Grep over `tiannara_runtime/lib`, `tiannara_runtime/config` and the root `lib/` finds **no reader** of `STABILITY_MODE`. The ConfigMap that carries it is **never mounted** by the base Deployment (no `envFrom:` in `runtime-deployment.yaml:44-65`). | **UNIMPLEMENTED — a dead knob.** Even if delivered, it would change nothing. |
| `lockdown` (CIS safety mode) | `tiannara_runtime/lib/tiannara_runtime/cis/supervisor.ex:15,53,101-103,242`; legacy copy `tiannara_runtime/lib/tiannara_runtime/legacy/cis/supervisor.ex:28,111-113,276` | **Implemented as a runtime API only.** `TiannaraRuntime.CIS.Supervisor.set_safety_mode(:lockdown)` makes every `authorize_kill/3`, `authorize_resource_termination/3`, `authorize_world_suspension/3` return `:deny` (`supervisor.ex:242`, `:176-180`). Default is `:normal` (`@default_safety_mode :normal`, `:51`); `init/1` (`:128`) reads **no** config key. | **Implemented, but NOT reachable at launch.** There is no env var, no config key, and no CLI flag that sets it. It must be called by another process after boot. |
| `degraded` | `lib/tiannara/cel/services/executive_memory.ex:93` (`status: :degraded`) | A **status label on a DETS-open failure**, not a mode. | Not a launch mode. |
| `:lockdown` in the root | `lib/tiannara/council/council.ex:41` (`policy_applied: :emergency_lockdown`) | A **decision-policy outcome**, not a boot mode. | Not a launch mode. |
| `:boot_profile` (runtime) | `tiannara_runtime/config/config.exs:7`; `runtime_layers/supervisors.ex:229,244-259` | **Implemented and config-driven**: `:minimal` drops the Constraint and Meta layers; `:research` adds the experimental NDE/TWP/OSL supervisors. | **The only genuine reduced-effect launch lever found in either project.** No env override — set via `Application.put_env(:tiannara_runtime, :boot_profile, :minimal)` before boot, or a config edit. |
| `experimental_child` gate | `runtime_layers/supervisors.ex:23-31`; keys `:enable_nde` / `:enable_twp` / `:enable_osl` (`config.exs:8-10`, all `false`) | **Implemented.** Only reachable under `boot_profile: :research`. | Implemented, but gated behind a profile that is not the default. |
| `asc, enabled` (root) | `config/config.exs:157-159` (`true`); `lib/tiannara/application.ex:19,70-72,256-281` | **Implemented**, but defaults to **true** in every env. Setting it `false` removes 7 supervisors. | Implemented — the only root-side reduction lever, and it is **off by default**. |

> **Plain statement:** there is **no** launch-time "safe mode" for the runtime. The runtime's `boot_profile: :minimal` reduces the *supervision tree*, not the *effects* of the subsystems it keeps, and it does not touch the CPL, the Omega layer, the COP, the endpoint, or the DiscoveryRunner. The CIS `:lockdown` safety mode is genuinely implemented but is **not settable at launch** (no env/config/CLI hook). `STABILITY_MODE` is a **dead knob**. The root's `mix tiannara.start --safe` is a **misnomer**: it changes which *checks* run, not what *boots*.

---

## 4. The two projects' shared and conflicting surface

### 4.1 Duplicate fully-qualified module names — 28 (F-ARC-001, independently re-verified)

Recomputed in this pass by scanning every `defmodule` in `lib/**.ex` (1 976 occurrences / 1 971 distinct names) against `tiannara_runtime/lib/**.ex` (1 384 occurrences / 1 375 distinct names). Intersection = **exactly 28** — the F-ARC-001 count is confirmed.

| # | Duplicate fully-qualified name | Root location | Runtime location |
|---|---|---|---|
| 1 | `CivilizationState` | `lib/tiannara/cci/models.ex` | `tiannara_runtime/lib/tiannara_runtime/civilization/kernel.ex` |
| 2 | `Tiannara.A10.AdvisoryEmitter` | `lib/tiannara/a10/supervisor.ex` | `tiannara_runtime/lib/tiannara/a10/advisory_emitter.ex` |
| 3 | `Tiannara.A10.AttractorAnalyzer` | `lib/tiannara/a10/supervisor.ex` | `tiannara_runtime/lib/tiannara/a10/attractor_analyzer.ex` |
| 4 | `Tiannara.A10.AttractorMemory` | `lib/tiannara/a10/supervisor.ex` | `tiannara_runtime/lib/tiannara/a10/attractor_memory.ex` |
| 5 | `Tiannara.A10.DriftTensor` | `lib/tiannara/a10/supervisor.ex` | `tiannara_runtime/lib/tiannara/a10/drift_tensor.ex` |
| 6 | `Tiannara.A10.Sampler` | `lib/tiannara/a10/supervisor.ex` | `tiannara_runtime/lib/tiannara/a10/sampler.ex` |
| 7 | `Tiannara.A10.Supervisor` | `lib/tiannara/a10/supervisor.ex` | `tiannara_runtime/lib/tiannara/a10/supervisor.ex` |
| 8 | `Tiannara.CIS.CollapsePredictor` | `lib/tiannara/cis/supervisor.ex` | `tiannara_runtime/lib/tiannara/cis/collapse_predictor.ex` |
| 9 | `Tiannara.CIS.ImmuneDecisionEngine` | `lib/tiannara/cis/supervisor.ex` | `tiannara_runtime/lib/tiannara/cis/immune_decision_engine.ex` |
| 10 | `Tiannara.CIS.RegulationExecutor` | `lib/tiannara/cis/supervisor.ex` | `tiannara_runtime/lib/tiannara/cis/regulation_executor.ex` |
| 11 | `Tiannara.CIS.Supervisor` | `lib/tiannara/cis/supervisor.ex` | `tiannara_runtime/lib/tiannara/supervisors.ex:114` |
| 12 | `Tiannara.Core.Ontology.Index` | `lib/tiannara/core/ontology/index.ex` | `tiannara_runtime/lib/tiannara/core/ontology/index.ex` |
| 13 | `Tiannara.Meta.CausalTensegrityEngine` | `lib/tiannara/meta/causal_tensegrity_engine.ex` | `tiannara_runtime/lib/tiannara_runtime/meta/causal_tensegrity_engine.ex` |
| 14 | `Tiannara.OED.ACM.CrucibleSupervisor` | `lib/tiannara/oed/supervisor.ex` | `tiannara_runtime/lib/tiannara/oed/acm/crucible_supervisor.ex` |
| 15 | `Tiannara.OED.BudgetController` | `lib/tiannara/oed/supervisor.ex` | `tiannara_runtime/lib/tiannara/oed/budget_controller.ex` |
| 16 | `Tiannara.OED.OAVL.ValidationSupervisor` | `lib/tiannara/oed/supervisor.ex` | `tiannara_runtime/lib/tiannara/oed/oavl/validation_supervisor.ex` |
| 17 | `Tiannara.OED.Quarantine.ContradictionTracker` | `lib/tiannara/oed/supervisor.ex` | `tiannara_runtime/lib/tiannara/oed/quarantine/contradiction_tracker.ex` |
| 18 | `Tiannara.OED.Quarantine.QuarantineRegistry` | `lib/tiannara/oed/supervisor.ex` | `tiannara_runtime/lib/tiannara/oed/quarantine/quarantine_registry.ex` |
| 19 | `Tiannara.OED.Quarantine.SuspendedTheories` | `lib/tiannara/oed/supervisor.ex` | `tiannara_runtime/lib/tiannara/oed/quarantine/suspended_theories.ex` |
| 20 | `Tiannara.OED.Rollback.OntologySnapshots` | `lib/tiannara/oed/supervisor.ex` | `tiannara_runtime/lib/tiannara/oed/rollback/ontology_snapshots.ex` |
| 21 | `Tiannara.OED.Rollback.RollbackController` | `lib/tiannara/oed/supervisor.ex` | `tiannara_runtime/lib/tiannara/oed/rollback/rollback_controller.ex` |
| 22 | `Tiannara.OED.Supervisor` | `lib/tiannara/oed/supervisor.ex` | `tiannara_runtime/lib/tiannara/oed/supervisor.ex` |
| 23 | `Tiannara.OED.UMSC.StabilityController` | `lib/tiannara/oed/supervisor.ex` | `tiannara_runtime/lib/tiannara/oed/umsc/stability_controller.ex` |
| 24 | `Tiannara.P9X.Supervisor` | `lib/tiannara/p9x_ecosystem/supervisor.ex` | `tiannara_runtime/lib/tiannara/supervisors.ex:127` |
| 25 | `Tiannara.P9XEcosystem.Supervisor` | `lib/tiannara/p9x_ecosystem/supervisor.ex` | `tiannara_runtime/lib/tiannara/supervisors.ex:164` |
| 26 | `Tiannara.Sentinel.AnomalyDetector` | `lib/tiannara/sentinel/anomaly_detector.ex` | `tiannara_runtime/lib/tiannara/sentinel/anomaly_detector.ex` |
| 27 | `Tiannara.Sentinel.Supervisor` | `lib/tiannara/sentinel/supervisor.ex` | `tiannara_runtime/lib/tiannara/sentinel/supervisor.ex` |
| 28 | `Tiannara.Sentinel.TelemetryHub` | `lib/tiannara/sentinel/telemetry_hub.ex` | `tiannara_runtime/lib/tiannara/sentinel/telemetry_hub.ex` |

**Which duplicate is actually booted where (the concrete co-residency hazard):**

| Duplicate | Booted by the **root** app? | Booted by the **runtime** app? | Net |
|---|---|---|---|
| `Tiannara.CIS.Supervisor` | **YES** — `lib/tiannara/application.ex:187` | **NO** — the runtime boots `TiannaraRuntime.CIS.Supervisor` (`tiannara_runtime/lib/tiannara_runtime/application.ex:33`). The runtime's `Tiannara.CIS.Supervisor` copy is reachable only via `Tiannara.P9XEcosystem.Supervisor` (`tiannara_runtime/lib/tiannara/supervisors.ex:177`), which is in **no boot tree**. | Same name, **different implementations**, one of them live. A co-VM load makes the root's `:tiannara` app's reference and the runtime's compile-time reference resolve to the **same beam** — one of the two supervisors would be silently shadowed. |
| `Tiannara.Sentinel.Supervisor` | **YES** — `lib/tiannara/application.ex:184` | not in the runtime's boot tree (runtime's copy is at `tiannara_runtime/lib/tiannara/sentinel/supervisor.ex`) | Same hazard. |
| `Tiannara.A10.Supervisor` | root copy is in `lib/tiannara/a10/supervisor.ex`; the root boots `Tiannara.A10.Supervisor`? — **not** in `lib/tiannara/application.ex` | the runtime's `Tiannara.Governance.Supervisor` (`tiannara_runtime/lib/tiannara/supervisors.ex:19`) starts `Tiannara.A10.Supervisor` — but `Tiannara.Governance.Supervisor` itself is only a child of `Tiannara.P9XEcosystem.Supervisor`, which is in no boot tree | Compiled-but-unbooted in both; still a compile-time shadow risk. |
| `Tiannara.OED.Supervisor`, `Tiannara.P9X*`, `Tiannara.Core.Ontology.Index`, `Tiannara.Meta.CausalTensegrityEngine`, `Tiannara.Sentinel.{AnomalyDetector,TelemetryHub}`, `CivilizationState` | mixed | mixed | Compiled in both. |

> **D-ARC-005 is well-founded.** Even a *correct* two-release deployment would be at risk the moment either project is ever added to the other's load path: 28 names would resolve to one beam each. Note also the runtime's own intra-tree duplication (F-ARC-011): `TiannaraRuntime.GRCC.EcologySupervisor` exists at both `tiannara_runtime/lib/tiannara_runtime/supervisors.ex:1` and `tiannara_runtime/lib/tiannara_runtime/grcc/ecology_supervisor.ex:1` — and the runtime sets `elixirc_options: [warnings_as_errors: false]` (`tiannara_runtime/mix.exs:15`), so a redefinition warning cannot fail its build.

### 4.2 Ports each project binds (and the collisions on one host)

| Project / surface | Port | Source | Notes |
|---|---|---|---|
| Root Phoenix endpoint (dev) | **4000** | `config/dev.exs:10` (`ip: {127,0,0,1}`) | The launcher prints `http://localhost:4000/...` (`tiannara.start.ex:320-322`). |
| Root Phoenix endpoint (prod) | **`PORT` env, default 4000** | `config/prod.exs:23` (`ip: {0,0,0,0}`) | |
| Root Phoenix endpoint (test) | 4001, `server: false` | `config/test.exs:9-11` | Not bound. |
| Runtime Phoenix endpoint (dev) | **8004** | `tiannara_runtime/config/dev.exs:5` (`server: true`) | `start_alpha.ps1` probes `http://localhost:8004/api/v1/health` — matches. |
| Runtime Phoenix endpoint (test) | 4001, `server: false` | `tiannara_runtime/config/test.exs:4-6` | Not bound. |
| Runtime Phoenix endpoint (prod) | **undefined** — no `config/prod.exs` | — | Phoenix default would be 4000 — **same as the root app**. |
| **Runtime raw-TCP NATS listener** | **4222** (`NATS_PORT` env, default 4222) | `tiannara_runtime/lib/tiannara_runtime/nats/connection.ex:15,22` | **Binds** 4222; it is a *listener*, not a client. A real `nats-server` on the same host **cannot** also bind 4222. Confirmed by the k8s sidecar using **4223** instead (`phase6/base/runtime-deployment.yaml:110`). |
| Root NATS client (occasional) | 4222 | `lib/tiannara/ucc/trajectory_tensor.ex:41` (hardcoded `Gnat.start_link(%{host: "127.0.0.1", port: 4222})`) | A **client** — would connect to the runtime's raw listener and get JSON garbage back. |
| k8s runtime deployment (declared) | 4000, 9090 | `phase6/base/runtime-deployment.yaml:66-70,147-152` | Declared port ≠ the runtime's actual dev port (8004). Probe paths `/health/live|ready|startup` do not exist on the runtime router. |
| k8s rtl deployment (declared) | 4000, 9464 | `phase8-rtl/base/rtl-deployment.yaml:52-56` | 9464 has **no listener** in the repo. |

**Same-host collisions if both Elixir projects were run together (D-ARC-005 says they will not be co-resident, but they may share a host):**

| Port | Claimed by | Collision? |
|---|---|---|
| 4000 | root app (dev & prod) **and** the runtime's prod endpoint (Phoenix default) **and** the observatory umbrella's prod endpoint (`tiannara_observatory/config/runtime.exs:24`, `PORT` env default 4000) | **YES** — three claimants |
| 8004 | runtime app (dev) **and** Python `restart_backend.bat` (`python -m uvicorn tiannara_api.main:app --reload --port 8004`) **and** `start_production.sh` (`PORT` default 8004) **and** `tiannara_saas` `next.config.ts` `API_UPSTREAM_URL` default `http://127.0.0.1:8004` **and** `.env.example` `API_UPSTREAM_URL` | **YES** — the Python API and the runtime cannot both bind 8004. `start_alpha.ps1:29-31` kills whatever holds 8004 before starting the runtime. |
| 4222 | the runtime's raw listener **and** any real `nats-server` (repo has `nats-bin/`, `nats-server.log`) **and** `phase2_quickstart.sh:26-28` Docker NATS **and** the root's `ucc/trajectory_tensor.ex` client | **YES** — listen-vs-listen conflict |
| 4223 / 8223 | k8s rtl NATS sidecar | sidecar only — OK |
| 5432 / 6379 | `docker-compose.yml:11,23` | Postgres/Redis only — no Elixir claimant |
| 8000 | `docker-compose.yml:37` (Python API), `start_phase4_services.sh:160` | Python only — OK |
| 3000 | dashboard (`start_alpha.ps1:32-34`, `start_phase4_services.sh:193`) | Next.js only — OK |

### 4.3 DETS / file-store collisions

| Store | Root | Runtime | Collision if both share a CWD? |
|---|---|---|---|
| `data/cpl/**` | — | `data/cpl/events`, `data/cpl/checkpoints` | **No** (unique sub-tree) |
| `data/omega/executive_memory` | — | yes | **No** |
| `data/dets/<context>/*.dets` | yes (`:dets_base_path` default `./data/dets`) | — | **No** (root only) |
| `data/<context>/…` (checkpoints, reports, logs) | yes | — | **No** (root only) |
| `data/asc_projects`, `data/asc_archive` | yes | — | **No** (root only) |
| `data/executive_memory.dets` | yes | — | **No** |
| `./constitution_repository.dets`, `./cel_memory_v2.dets`, `./cel_executive_memory.dets`, `./cel_event_bus_dlq.dets`, `./mission_director_state.dets`, `./ontology_manager.dets`, `./conflict_resolution_engine.dets` | yes (CWD-relative, hardcoded) | — | **No** between the two projects — but **the root collides with itself** if two root instances share a CWD, and the runtime's `priv/dets/executive_memory.dets` (`lib/tiannara/runtime/executive_memory.ex:308-309`) is a **different file** from the root's `data/executive_memory.dets` — so **no** collision, but **two different stores with the same logical name**, which is a data-ownership hazard (D-ARC-004). |
| `priv/dets/executive_memory*.dets` | yes | — | **No** |
| Mnesia dir | — | `Mnesia.nonode@nohost_*` in `tiannara_runtime/` | **No** — but node-name-scoped: two runtime instances with the same node name **do** collide. |

### 4.4 ETS table names

ETS tables are **per-BEAM**, so there is **no** cross-process ETS collision. Within one BEAM, the duplicate-module risk (§4.1) is the real hazard. Both projects declare `:named_table` ETS tables — the runtime at 40+ sites (e.g. `:causal_tensegrity_nodes`, `:law_archive`, `:suppressed_observers`, `:chimeras`, `:law_lineages`) and the root at 100+ sites (e.g. `:governance_policies`, `:rate_limits`, `:sandboxes`, `:ontology_index`, `:semantic_vectors`). If the two projects were ever loaded into one BEAM, `:semantic_vectors` (root, `lib/tiannara/core/ontology/vector.ex:44`) and `:ontology_index` (root, `lib/tiannara/core/ontology/index.ex:44`) would collide by name with the runtime's `Tiannara.Core.Ontology.Index` copy — the duplicate module owns `:concept_index`, `:ontology_concepts`, `:search_terms` (`tiannara_runtime/lib/tiannara/core/ontology/index.ex`). **UNKNOWN**: whether any *named* ETS table name is literally identical across the two trees — the two trees were not exhaustively intersected in this pass.

### 4.5 NATS subject namespaces

| Namespace | Owner | Evidence |
|---|---|---|
| `tiannara.ird.interventions`, `tiannara.ird.outcomes.*`, `tiannara.opc.compile_request` | root config only — **the `:jetstream` config block has no reader**; no code publishes these subjects | `config/config.exs:44-63` |
| `tiannara.simulation.{grcc,fitness,niche,evolution}.>` | runtime subscriber (counts only, no consumer logic) | `tiannara_runtime/lib/tiannara_runtime/nats/subscriber.ex:14-19,30-34` |
| `constraint.updated`, `field.pressure_changed` | runtime in-VM bus (`Tiannara.EventBus`, Registry dispatch) | `tiannara_runtime/lib/tiannara/olef/pressure_solver.ex:14,20,28`; `tiannara_runtime/lib/tiannara/event_bus.ex:14-16,31,35-37` |
| `tiannara.*` (OPC bus, mesh, reality bus) | runtime, in-VM only | `tiannara_runtime/lib/tiannara_runtime/nats/{opc_bus,reality_bus,mesh_balancer}.ex` |
| Root-side subject namespaces | **none found** — the root's event buses are in-VM `Registry`/`GenServer` fan-outs (`lib/tiannara/{asc/core,cel/services,cel,executive,runtime,crav}/…event_bus*.ex`) | architecture.md §e.2 |

**Collision assessment:** the two projects' subject namespaces **do not overlap** (`tiannara.*` is runtime-only; the root has no NATS publisher). The real NATS hazard is **not** a subject collision but the **port-4222 listen-vs-listen conflict** (§4.2) and the fact that the runtime's listener accepts **anonymous** JSON from any local client and republishes it into the in-VM bus (`nats/connection.ex:53-68`).

### 4.6 Database schemas

| Project | DB schema | Collision? |
|---|---|---|
| Root `:tiannara` | **none** — no Ecto, no Repo (`config/dev.exs:3-5` and `config/test.exs:3-5` both record that the `Tiannara.Repo` block was removed as dead) | **No** |
| Runtime `:tiannara_runtime` | **none** — no Ecto/Postgrex in `tiannara_runtime/mix.exs:28-69` | **No** |
| (neighbour) Python `tiannara_api` | PostgreSQL via SQLAlchemy, `DATABASE_URL` env | Would be the only DB user; **no Elixir collision** |
| (neighbour) `tiannara_observatory` umbrella | PostgreSQL × 6 DBs (`tiannara_observatory/config/config.exs:22-60`) | **No** Elixir collision |

### 4.7 Same-host neighbours that are **not** the two Elixir projects

Recorded because they share ports with them and would interfere with an isolated launch on a single host:

| Surface | Port | Evidence |
|---|---|---|
| `tiannara_api` (Python FastAPI) | 8000 (compose) / 8004 (`restart_backend.bat`, `start_production.sh`) | `docker-compose.yml:37,51`; `restart_backend.bat`; `start_production.sh:37` |
| `tiannara_saas` (Next.js) | 3000 (dev) / proxies to `API_UPSTREAM_URL` default `http://127.0.0.1:8004` | `tiannara_saas/next.config.ts`; `.env.example` (`API_UPSTREAM_URL=http://127.0.0.1:8004`) |
| `tiannara_observatory` umbrella | 4000 (prod `PORT` default) | `tiannara_observatory/config/runtime.exs:24` |
| `tiannara_gui`, `tiannara_internal_dashboard`, `tiannara_mobile` | 3000 / 5173 | **absent-in-git** (F-PLT-003 / F-ARC-024) — `start_alpha.ps1` and `start_observability.sh` reference them anyway |

---

## 5. Blockers for the reachability step

Ranked by what must be true *before* `:tiannara_runtime` can be launched in isolation under D-ARC-005.

| Rank | Blocker | Why it blocks an isolated launch | Evidence | Severity |
|---|---|---|---|---|
| **B1** | **The runtime has no `config/prod.exs`** ⇒ `MIX_ENV=prod` cannot even load configuration. | The interim boundary says "separate releases/processes". A *release* implies `MIX_ENV=prod`. Without `prod.exs`, `import_config "#{Mix.env()}.exs"` raises ⇒ no prod compile, no prod boot, no release artefact, and **no endpoint port configuration for prod**. The only working env is `dev` (or `test`), which is not a release posture. | `tiannara_runtime/config/config.exs:57`; `tiannara_runtime/config/` listing = `config.exs, dev.exs, test.exs, opc.ex, layer_boundaries.exs`; `tiannara_runtime/_build/` = `dev, test, test.ci-sim, propcheck.ctex` (no `prod`) | critical (F-ARC-014) |
| **B2** | **No launch artefact exists for the runtime** — no `releases/0`, no Dockerfile, no workflow that builds one. | "Separate releases/processes" cannot be satisfied by a release that cannot be produced. `tiannara_runtime/mix.exs` has no `releases/0`; the k8s image `tiannara-runtime:phase6-6.0.0` has no Dockerfile in the repo and the container spec has no `command:`; no tracked workflow invokes `mix release`. The only runtime launch paths that exist are **dev-mode `mix run --no-halt` / `mix phx.server`**. | `tiannara_runtime/mix.exs:1-184` (no `releases/0`); `phase6/base/runtime-deployment.yaml:41-43`; `deps_build.json:147`; §1.4 | critical (F-ARC-229) |
| **B3** | **The runtime's persistent writes cannot be redirected by configuration or env** — CPL path is hardcoded `"data/cpl"`. | A reachability launch that writes into the repository tree is not an *isolated* launch. `:cpl_storage_path` does **not** control the CPL (only `resurrection_engine` and `experiment_journal` read it); `StartupSupervisor` hardcodes `storage_path: "data/cpl"` and the CPL creates it with `File.mkdir_p!`. There is **no** `Tiannara.Storage.Paths` equivalent and **no** storage-context mechanism in the runtime. Isolation therefore requires a **different working directory** (plus a Mnesia dir via the node flag for full isolation). | `tiannara_runtime/lib/tiannara_runtime/startup_supervisor.ex:24,32`; `.../os/persistence/constitutional_persistence_layer.ex:81,83,391,400`; `tiannara_runtime/config/config.exs:11`; `resurrection_engine.ex:144-149`; `meta/causal_data_layer.ex:136-147` | high |
| **B4** | **The runtime's own test suite writes into the repo tree** (`data/cpl/checkpoints/**`), and `tiannara_runtime/test/test_helper.exs` performs **no** isolation wipe. | This is the concrete demonstration that the runtime has no isolation discipline. **961** untracked `?? tiannara_runtime/data/cpl/...` files were present in the working tree at the start of this pass (`tiannara_runtime/data/` holds **26 044** files). A reachability launch will do the same unless the CWD is moved. | working tree `git status --short` at the start of this pass (count reproduced in Appendix A.14); `tiannara_runtime/test/test_helper.exs:1-9`; `tiannara_runtime/config/test.exs` (no `:cpl_storage_path` override) | high (F-ARC-018) |
| **B5** | **No fail-closed launcher exists for the runtime**, and the root launcher cannot fail closed either. | `mix tiannara.start` swallows every phase error and always exits 0 (`:58-66`, `:304-306`, `:331-336`). `start_alpha.ps1` (the only root-owned runtime launcher) does `exit 1` on compile failure / health timeout — but it is a **PowerShell** script that also starts an **absent-in-git** dashboard (`tiannara_internal_dashboard`), and its readiness probe is a single HTTP GET. There is no runtime-native, fail-closed, CI-runnable launch path. | `lib/mix/tasks/tiannara.start.ex:58-66,302-336`; `start_alpha.ps1:35-60` | high |
| **B6** | **The runtime binds 4222 with a plain TCP listener, and the k8s topology deploys a NATS server on the same port.** | On any host where the runtime is launched, port 4222 is occupied by the runtime itself. A real `nats-server` (repo has `nats-bin/`), `phase2_quickstart.sh`'s Docker NATS, or the `phase6/base/nats-cluster.yaml` StatefulSet cannot also bind it. The listener failure is only a `Logger.warning` — **silent degradation**. | `tiannara_runtime/lib/tiannara_runtime/nats/connection.ex:15,22,28-30`; `phase6/base/nats-cluster.yaml:36,93-96`; `tiannara_runtime/phase2_quickstart.sh:26-28` | high (F-ARC-228) |
| **B7** | **No runtime endpoint port exists in prod**, and the declared k8s port/probes do not match the code. | The runtime's prod endpoint has no configuration ⇒ Phoenix default 4000, the **same port as the root app** and the observatory umbrella. The k8s deployment declares 4000 and probes `/health/live`, `/health/ready`, `/health/startup` — **none of which exist** on `TiannaraRuntimeWeb.Router` (which exposes `/api/v1/health`, `/api/v1/system/status`, …). | `tiannara_runtime/config/` (no prod.exs); `tiannara_runtime/lib/tiannara_runtime_web/router.ex:8-63`; `phase6/base/runtime-deployment.yaml:66-70,86-105` | high |
| **B8** | **The "safe mode" lever is not a safety lever, and the runtime's real safety mode is not settable at launch.** | If the reachability step assumes `mix tiannara.start --safe` gives a reduced-effect runtime, that assumption is wrong: `--safe` only skips the `:infra`/`:api`/`:frontend` phases, and the runtime's `:runtime` phase still starts `:tiannara` in full. For the runtime, the only implemented reduction is `:boot_profile` (`:minimal`), which narrows the supervision tree but keeps the CPL, Omega, COP, Endpoint and DiscoveryRunner; and the CIS `:lockdown` mode (the only genuine "deny destructive effects" control) has **no** env/config/CLI hook. | `lib/mix/tasks/tiannara.start.ex:11,68-75,117-134`; `tiannara_runtime/lib/tiannara_runtime/runtime_layers/supervisors.ex:229,244-259`; `tiannara_runtime/lib/tiannara_runtime/cis/supervisor.ex:51,99-103,128` | high |
| **B9** | **The root launcher declares three "required services" that no Elixir code consumes, and its verdict logic can never report failure.** | An operator reading `mix tiannara.start` output ("Status: READY/OPERATIONAL", "Database: ✓") would conclude the stack is ready. In fact Postgres/Redis are unused, NATS is emulated, and the summary can print "OPERATIONAL" even when every phase errored. This will mislead the reachability evidence if the operator's boot uses the launcher. | `lib/mix/tasks/tiannara.start.ex:17-21,89-91,96,113,302-329`; `config/config.exs:36-63` (dead keys); F-ARC-232 | medium |
| **B10** | **28 duplicate fully-qualified module names remain** (F-ARC-001). | Under D-ARC-005 (separate processes) this is currently *contained* — but it is the explicit precondition the decision names for any later co-residency, and one of the two implementations of `Tiannara.CIS.Supervisor` is **live in the root app** while the runtime's copy is compiled and reachable via an unbooted tree. Any accidental shared load path silently shadows one of them. | §4.1; `lib/tiannara/application.ex:187` vs `tiannara_runtime/lib/tiannara/supervisors.ex:114,177` | medium (contained by D-ARC-005) |
| **B11** | **Dead configuration keys create false confidence**: root `:nats`/`:jetstream` have zero readers; runtime `TiannaraRuntime.NATS.ConnectionManager` has no module; runtime `config/layer_boundaries.exs` is never imported (and configures `:tiannara`, not `:tiannara_runtime`); runtime `STABILITY_MODE` has no reader and its ConfigMap is never mounted. | A configuration review that stops at "the key exists" will conclude that NATS, layer boundaries and stability mode are configured. None of them are. | `config/config.exs:36-63`; `tiannara_runtime/config/config.exs:15-18`; `tiannara_runtime/config/layer_boundaries.exs:1-13` (never imported — `config.exs:49,57` import only `opc.ex` and `<env>.exs`); `phase6/overlays/production/kustomization.yaml:26` vs `phase6/base/runtime-deployment.yaml:44-65` | medium |
| **B12** | **No CI job proves either application boots as a service.** | The runtime's whole boot wiring is **test-time** wiring only. A reachability claim needs a CI job that runs the chosen launch path and asserts `TiannaraRuntime.StartupSupervisor.all_running?/0 == true`. No such job exists. | §1.4; `tiannara_runtime/lib/tiannara_runtime/startup_supervisor.ex:62-66`; architecture.md BG-1, L30 | medium |

---

## 6. Answers to the five questions, in one line each

1. **Launch mechanisms inventory** — §1. Root: 11 candidate mechanisms, of which **2 viable** (`mix tiannara.start` variants = L1–L7, and `mix run --no-halt` = L8); runtime: 9 candidate mechanisms, of which **3 viable** (`mix run --no-halt` = R1, `mix phx.server` = R2, `start_alpha.ps1` = R3). **No release artefact, no container image, no k8s-executable path exists for either project.**
2. **Configuration/dependencies per launch** — §2. Root: fail-closed on `SECRET_KEY_BASE` in prod, four storage keys, **no** external services required. Runtime: **`config/prod.exs` missing** ⇒ prod impossible; `NATS_PORT`/`NATS_URL` env vars; **no** external services required; storage paths **not** env-overridable.
3. **Isolated-environment feasibility** — §3. Root: **feasible** with `STORAGE_CONTEXT` + three `Application.put_env/3` calls + a scratch CWD (7 DETS files are hardcoded). Runtime: **not feasible by config/env alone** — requires a different working directory; `:boot_profile` is the only implemented reduced-effect lever; there is **no** safe mode.
4. **Shared/conflicting surface** — §4. **28** duplicate module names; **no** shared DB schema, **no** shared ETS namespace, **no** shared NATS subject namespace; **conflicts on ports 4000, 8004 and 4222**; **no** shared DETS file paths.
5. **Blockers** — §5. Top 5: **B1** missing prod config · **B2** no launch artefact · **B3** unredirectable CPL path · **B4** no test isolation (writes into the repo) · **B5** no fail-closed launcher.

---

## 7. Explicit unknowns

| ID | Unknown | Why it could not be closed here | What would close it |
|---|---|---|---|
| **U-B2-1** | Whether either Elixir application **actually boots end-to-end** in a clean checkout of `8ff5ec83` (and whether the boot reaches `StartupSupervisor.all_running?/0 == true`). | No boot was run (read-only mandate; the operator runs the boot separately). CI-green at a SHA is a *test* signal on a subset, not a boot proof. | The operator's boot + a CI job that asserts `all_running?/0` after the chosen launch path (B12). |
| **U-B2-2** | Whether the runtime's `:tiannara_runtime` app can be started at all in `MIX_ENV=dev` **without** a NATS server on 4222 — i.e. whether `TiannaraRuntime.NATS.Supervisor` (a `required_child`, `runtime_layers/supervisors.ex:80`) survives the raw listener failing to bind. | The listener failure path is a `Logger.warning` + continue (`nats/connection.ex:28-30`); whether the supervisor then crashes was not traced. | A boot trace on a host with 4222 free and again with it occupied. |
| **U-B2-3** | Whether the root app's CEL boot succeeds in `MIX_ENV=dev` with no external services, and what `Tiannara.CRAV.run()` reports. | Not executed. | Operator boot. |
| **U-B2-4** | Whether the root app's LLM gateway (`config/test.exs:20` `:llm_mock` is set only in test) attempts network I/O and how it degrades offline in dev/prod. | The gateway source was not read in this pass. | Read `lib/tiannara/**/llm_gateway.ex` + a boot with egress blocked. |
| **U-B2-5** | Whether any **named ETS table name** is literally identical between the two trees. | The §4.4 ETS intersection was not exhaustively computed (each tree has 40+ / 100+ tables); only the obvious duplicate-module-driven overlap was identified. | A scripted intersection of every `:ets.new(:atom, …)` / `@table` literal in both trees. |
| **U-B2-6** | Whether the runtime's `Mnesia` tables (`meta/causal_data_layer.ex:136-147`) are created on boot, and where Mnesia actually places its dir for a given node name. | Not executed; the `MnesiaCore.nonode@nohost_*` files at `tiannara_runtime/` are artefacts of prior runs, not proof of the current path. | A boot trace + `Application.app_dir`/`mnesia:system_info(:directory)` probe. |
| **U-B2-7** | Whether the 4 orphan KEDA ScaledObjects (`tiannara-phase13-14`, `tiannara-ucc`, `tiarnara-rrm`, `tiarnara-tcl`) ever bound in a cluster outside this checkout. | No cluster access. | Cluster inspection. |
| **U-B2-8** | Whether `tiannara_runtime/priv/boot_verification.exs` still runs (it boots `Tiannara.P9XEcosystem.Supervisor`, whose children include the duplicate `Tiannara.CIS.Supervisor` of the runtime tree). | Not executed. | Run it and read the result. |
| **U-B2-9** | Whether `phase2_quickstart.sh` also breaks at `cd python_cortex` (the directory exists; `grcc_simulation_cortex.py` presence was not verified) and at `cd ..` (which launches the **root** app, §R4). | The script was read, not executed; the Python side was not inspected. | Read `tiannara_runtime/python_cortex/` and run the script in a sandbox. |
| **U-B2-10** | Whether the `tiannara_audit` escript (A5) can be run from a clean checkout and what it exits with. | Not executed; no CI job for it exists except `tiannara-audit-suite` (`mix test` only). | `cd tiannara_audit && mix escript.build && ./tiannara_audit`. |

---

## Appendix A — How to reproduce every check in this document

All commands are PowerShell 5.1, run from the repo root
`C:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic`. Read-only.

**A.0 — Environment / provenance**

```powershell
git status --short
git branch --show-current
git log --oneline -5
elixir --version          # => Erlang/OTP 28 [erts-16.4]; Elixir 1.18.4
(Get-Command elixir).Source
```

**A.1 — Launch mechanism inventory**

```powershell
# Mix tasks in both projects
Get-ChildItem -Path "lib\mix" -Recurse -File | Select-Object -ExpandProperty FullName
Get-ChildItem -Path "tiannara_runtime\lib\mix" -Recurse -File | Select-Object -ExpandProperty FullName

# Root release config and app mod
Select-String -Path "mix.exs" -Pattern "releases|mod:|app:"
Select-String -Path "tiannara_runtime\mix.exs" -Pattern "releases|mod:|app:|extra_applications"

# Procfile / compose / Dockerfile / docker dir
Get-Content Procfile
Get-Content docker-compose.yml
Get-Content Dockerfile.production
Get-ChildItem -Path "docker" -Recurse -File | Select-Object -ExpandProperty FullName

# Root start scripts
Get-ChildItem -Path ".\*" -File | Where-Object { $_.Name -match '^(start|run_production|deploy|run_|probe)' -and $_.Extension -match '^\.(bat|ps1|sh|cmd|exs)$' } | Select-Object Name,Length
Get-Content start.bat, start-production.bat, start-safe.bat, start-research.bat, start-benchmark.bat
Get-Content start_alpha.ps1
Get-Content start_production.sh
Get-Content start_phase4_services.sh
Get-Content start_phase4_services.bat
Get-Content deploy-quickstart.sh
Get-Content run_soak72.bat
Get-Content run_production.exs

# Runtime-side scripts
Get-ChildItem -Path "tiannara_runtime\scripts" -Recurse -File | Select-Object -ExpandProperty FullName
Get-Content tiannara_runtime\phase2_quickstart.sh
Get-Content tiannara_runtime\start_observability.sh
Get-Content tiannara_runtime\priv\boot_verification.exs

# Which mix tasks start the app
Select-String -Path "lib\mix\tasks\*.ex","tiannara_runtime\lib\mix\tasks\*.ex" -Pattern "app\.start|ensure_all_started|Application\.start"

# tiannara_audit escript
Get-Content tiannara_audit\mix.exs
```

**A.2 — CI workflows (branches + what they build/start)**

```powershell
Get-ChildItem -Path ".github\workflows" -File | Select-Object -ExpandProperty Name
foreach ($f in Get-ChildItem ".github\workflows\*.yml") {
  "=== $($f.Name) ==="
  Select-String -LiteralPath $f.FullName -Pattern "branches:|run:|name:|working-directory|mix |pytest|docker"
}
```

**A.3 — Kubernetes**

```powershell
Get-ChildItem -Path "tiannara_runtime\k8s" -Recurse -File | Select-Object -ExpandProperty FullName
Get-Content tiannara_runtime\k8s\phase6\base\kustomization.yaml
Get-Content tiannara_runtime\k8s\phase6\base\runtime-deployment.yaml
Get-Content tiannara_runtime\k8s\phase6\base\nats-cluster.yaml
Get-Content tiannara_runtime\k8s\phase6\overlays\production\kustomization.yaml
Get-Content tiannara_runtime\k8s\phase8-rtl\base\rtl-deployment.yaml
foreach ($f in (Get-ChildItem "tiannara_runtime\k8s" -Recurse -Filter "*keda*.yaml")) {
  "=== $($f.Name) ==="; Select-String -LiteralPath $f.FullName -Pattern "kind:|name:|scaleTargetRef"
}
```

**A.4 — Configuration, MIX_ENV, storage keys**

```powershell
Get-Content config\config.exs, config\dev.exs, config\prod.exs, config\test.exs
Get-Content tiannara_runtime\config\config.exs, tiannara_runtime\config\dev.exs, tiannara_runtime\config\test.exs
Get-Content tiannara_runtime\config\opc.ex
Get-Content tiannara_runtime\config\layer_boundaries.exs
Select-String -Path "tiannara_runtime\config\*.exs" -Pattern "layer_boundaries"
Get-Content lib\tiannara\storage\paths.ex
Select-String -Path "lib\**\*.ex" -Pattern ":storage_base|:storage_context|dets_base_path"
Select-String -Path "tiannara_runtime\lib\**\*.ex" -Pattern "cpl_storage_path|storage_path|dets_base_path|:storage_base"
```

**A.5 — Build artefacts present / absent**

```powershell
Test-Path "_build"; Test-Path "deps"
Test-Path "tiannara_runtime\_build"; Get-ChildItem "tiannara_runtime\_build" | Select-Object -ExpandProperty Name
Test-Path "tiannara_runtime\deps"
Test-Path "tiannara_audit\_build"; Test-Path "tiannara_audit\deps"
Test-Path "forward_provenance\mix.exs"
Test-Path "tiannara_runtime\config\prod.exs"     # => False
Test-Path "config\prod.exs"                      # => True
```

**A.6 — The 28 duplicate module names (recompute from scratch)**

```powershell
function Get-Mods($dir) {
  Get-ChildItem -Path $dir -Recurse -Filter *.ex -File | ForEach-Object {
    $p = $_.FullName
    Select-String -LiteralPath $p -Pattern '^\s*defmodule\s+([A-Z][A-Za-z0-9_.]*)\s+do' -AllMatches |
      ForEach-Object { $_.Matches[0].Groups[1].Value + "|" + ($p -replace [regex]::Escape((Get-Location).Path + "\"), "") }
  }
}
$root = Get-Mods "lib"; $rt = Get-Mods "tiannara_runtime\lib"
$rootNames = ($root | ForEach-Object { ($_ -split '\|')[0] } | Sort-Object -Unique)
$rtNames   = ($rt   | ForEach-Object { ($_ -split '\|')[0] } | Sort-Object -Unique)
"DISTINCT DUPLICATE NAMES: " + ($rootNames | Where-Object { $rtNames -contains $_ }).Count
```
→ `root defmodule count: 1976`, `runtime defmodule count: 1384`, `root unique: 1971`, `runtime unique: 1375`, **`DISTINCT DUPLICATE NAMES: 28`**.

Per-duplicate file locations:

```powershell
function Get-Mods($dir) {
  Get-ChildItem -Path $dir -Recurse -Filter *.ex -File | ForEach-Object {
    $p = $_.FullName
    Select-String -LiteralPath $p -Pattern '^\s*defmodule\s+([A-Z][A-Za-z0-9_.]*)\s+do' -AllMatches |
      ForEach-Object { [PSCustomObject]@{ Name=$_.Matches[0].Groups[1].Value; Path=($p -replace [regex]::Escape((Get-Location).Path + "\"), "") } }
  }
}
$root = Get-Mods "lib"; $rt = Get-Mods "tiannara_runtime\lib"
$rootNames = $root.Name | Sort-Object -Unique; $rtNames = $rt.Name | Sort-Object -Unique
foreach ($d in ($rootNames | Where-Object { $rtNames -contains $_ })) {
  "| ``$d`` | " + (($root | ? { $_.Name -eq $d } | % { $_.Path } | Sort-Object -Unique) -join "; ") +
        " | " + (($rt   | ? { $_.Name -eq $d } | % { $_.Path } | Sort-Object -Unique) -join "; ") + " |"
}
```

**A.7 — Which duplicate is booted where**

```powershell
Select-String -Path "lib\tiannara\application.ex" -Pattern "CIS.Supervisor|Sentinel.Supervisor|A10.Supervisor|OED|P9X"
Select-String -Path "tiannara_runtime\lib\tiannara_runtime\application.ex" -Pattern "optional_child|required_child"
Select-String -Path "tiannara_runtime\lib\tiannara\supervisors.ex" -Pattern "defmodule|CIS.Supervisor|A10.Supervisor|P9X"
Select-String -Path "tiannara_runtime\lib\tiannara_runtime\runtime_layers\supervisors.ex" -Pattern "required_child|optional_child|experimental_child|boot_profile"
```

**A.8 — "Safe mode" / STABILITY_MODE / lockdown / degraded**

```powershell
Select-String -Path "tiannara_runtime\lib\**\*.ex","tiannara_runtime\config\*.ex","tiannara_runtime\k8s\**\*.yaml","lib\**\*.ex","config\*.ex" `
  -Pattern "STABILITY_MODE|safe_mode|SafeMode|lockdown|boot_profile|BootPolicy"
Select-String -Path "tiannara_runtime\lib\tiannara_runtime\cis\supervisor.ex" -Pattern "safety_mode|@default_safety_mode|@valid_safety_modes|def init"
```

**A.9 — Ports, listeners, NATS**

```powershell
Select-String -Path "config\*.exs" -Pattern "port|ip:"
Select-String -Path "tiannara_runtime\config\*.exs" -Pattern "port|server:"
Select-String -Path "tiannara_runtime\lib\tiannara_runtime\nats\connection.ex" -Pattern "NATS_PORT|gen_tcp.listen|Logger.warning"
Select-String -Path "lib\**\*.ex" -Pattern "Gnat.start_link|4222"
Select-String -Path "tiannara_observatory\config\runtime.exs" -Pattern "port"
Select-String -Path "tiannara_runtime\lib\tiannara_runtime_web\router.ex" -Pattern "get \"|post \""
```

**A.10 — Dead configuration keys**

```powershell
Select-String -Path "lib\**\*.ex" -Pattern "get_env\(:tiannara, :nats|get_env\(:tiannara, :jetstream"
Get-ChildItem "tiannara_runtime\lib" -Recurse -Filter "connection_manager.ex"     # => (none)
Get-ChildItem "tiannara_runtime\lib\tiannara_runtime\nats" -File | Select-Object -ExpandProperty Name
Get-ChildItem "tiannara_runtime" -Recurse -Filter "check.layers.ex"              # => (none)
```

**A.11 — DETS paths (hardcoded vs context-resolved)**

```powershell
Select-String -Path "lib\**\*.ex" -Pattern "\.dets""
Select-String -Path "lib\**\*.ex" -Pattern "Paths\.dets|Storage\.Paths"
Select-String -Path "tiannara_runtime\lib\**\*.ex" -Pattern ":dets\.open_file|:mnesia\.create|:ets\.new\("
Select-String -Path "lib\**\*.ex" -Pattern ":ets\.new\("
```

**A.12 — Boot trees**

```powershell
Get-Content lib\tiannara\application.ex
Get-Content tiannara_runtime\lib\tiannara_runtime\application.ex
Get-Content tiannara_runtime\lib\tiannara_runtime\startup_supervisor.ex
Get-Content tiannara_runtime\lib\tiannara_runtime\runtime_layers\supervisors.ex
```

**A.13 — Launcher behaviour (fail-closed analysis)**

```powershell
Select-String -Path "lib\mix\tasks\tiannara.start.ex" -Pattern "safe_execute_phase|status: :fail|any_fail|keep_alive|86_400_000|@required_services|@runtime_subsystems|rescue|catch"
```

**A.14 — Working-tree state (runtime CPL churn)**

```powershell
git status --short | Select-String "tiannara_runtime/data/cpl" | Measure-Object | Select-Object -ExpandProperty Count
# => 961   (reproduced 2026-10-22 at 8ff5ec83)
Get-ChildItem "tiannara_runtime\data" -Recurse -File | Measure-Object | Select-Object -ExpandProperty Count
# => 26044
```

---

*End of report. Written under Phase R1 Batch 2 step 1 (launch boundary). No file other than this one was created or modified; no git operation, no compile, no boot, no test run was performed.*
