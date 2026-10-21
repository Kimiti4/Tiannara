# Tiannara System Atlas — Architecture Reconstruction (Pass 3)

**Date:** 2026-10-21 (UTC) · **Branch:** `local/pr4` @ `521cb7fe513a466302ec3bb398940df3814edf2d`
**Mode:** read-only discovery. No file outside `certification/atlas/` was created, modified, moved or deleted.
No git commit / push / checkout. No compile, no boot, no test run was executed.

---

## 0. Method, evidence vocabulary, and reuse

### 0.1 Basis labels used on every relationship in this document

| Label | Meaning | How it is obtained here |
|---|---|---|
| `documented` | A claim exists in a repo document. **Not** treated as truth about behaviour. | Read of a tracked `.md`/doc file. |
| `statically_inferred` | Derived by reading source (boot trees, `defp`, call sites, imports) with no execution. | The primary mode of this pass. |
| `dynamically_observed` | Observed running. **Zero** edges in this pass carry this label. | Not available (read-only mandate, no boot). |
| `independently_verified` | Re-derived independently from source at a second, different location than the prior audit's citation. | Used where R0 re-checked a prior audit's claim from primary source. |

> **Unknown is not PASS.** Where a relationship could not be established from source, it is recorded in
> §10 (Unknowns) and in `deps_runtime.json.unknowns`, never silently omitted and never asserted.
>
> **Historical CI green ≠ proof.** Every CI statement below is bound to a SHA and a run id; no CI result is
> used to assert runtime behaviour.

### 0.2 Prior evidence reused (not rediscovered)

| Asset | Reused for |
|---|---|
| `certification/audit/PHASE_5F_WIRING_AUDIT.md` | Boot trees for ECR / Sentinel / CEL / kernel / layers; 7 boot paths; orphaned modules; W1/W2/W3 wiring commits. |
| `certification/atlas/baseline.md` | CI facts, run ids, test commands, workflow inventory, tracked-file distribution. |
| `certification/atlas/capabilities_F_platform.md` | F-PLT-001..016 (entrypoint split, frontends absent-in-git, CI branch filters, k8s overlay, NATS emulation, event fragmentation, missing `config/prod.exs`). |
| `certification/atlas/problems_G.md` | F-ARC-001..025 (duplication, kill switch, constitution scatter, event-bus proliferation, audit verifiers, k8s, API auth, orphans, CI blind spots, import cycles, prod config, namespace hygiene, registries, negative tests, frontends, NIFs). |
| `certification/atlas/capabilities_C_governance.md` | F-GOV-001..023 (human approval one-way, RuleEngine cannot approve, kill switch not running, no rollback, audit Merkle root unconsumed, CEL self-authorising). |
| `certification/atlas/capabilities_D_worldmodel.md` | F-WRD-001..010 (world-model stack unwired, `WorldProcess` missing, ControlCenter outside OTP, mock-generated historical scale claim). |
| `certification/audit/DIRECTORY_AUDIT_2026-10-19.md` | Directory-level state, k8s credentials, Python stubs, orphan inventory. |
| `certification/audit/TIANNARA_RUNTIME_TEST_INVENTORY.md` | Test inventory, quarantine table, CI scope evidence, `normalize_checkpoint_keys` origin. |

### 0.3 What this pass did NOT do (scope honesty)

- No `mix compile`, no `mix run`, no `mix test`, no `pytest`, no `docker build`, no `kustomize build`.
- No process was started, therefore **no edge in this document is `dynamically_observed`**.
- No prior artifact was edited; the three new files are additive under `certification/atlas/`.

---

## a. System inventory

### a.1 Application inventory (every deployable unit found)

| # | Application | Kind | Entry point / start mechanism | Tracked? | Basis |
|---|---|---|---|---|---|
| A1 | `:tiannara` | Elixir OTP app (root project) | `mix.exs:58` `mod: {Tiannara.Application, []}` → `lib/tiannara/application.ex:27` `Supervisor.start_link(children, strategy: :one_for_one)` | yes | statically_inferred |
| A2 | `:tiannara_runtime` | Elixir OTP app (2nd project) | `tiannara_runtime/mix.exs:23` `mod: {TiannaraRuntime.Application, []}` → `tiannara_runtime/lib/tiannara_runtime/application.ex:41` `Supervisor.start_link(children, strategy: :one_for_one)` | yes | statically_inferred |
| A3 | `:tiannara_observatory` (umbrella) | Elixir umbrella, 10 apps | `tiannara_observatory/mix.exs:6` `apps_path: "apps"`; **no umbrella-level `mod:`/application** — apps start individually | yes | statically_inferred |
| A4 | `:observatory_api` (umbrella child) | Phoenix 1.8 app | `apps/observatory_api/lib/observatory_api/application.ex` → `ObservatoryApi.Supervisor` (`one_for_one`, 11 children incl. `ObservatoryApi.Repo`, `Endpoint`) | yes | statically_inferred |
| A5 | `:tiannara_audit` | Mix escript project | `tiannara_audit/mix.exs:11` `escript: [main_module: TiannaraAudit]`; **no `mod:`** → never an OTP app; no `application/0` | yes (9 files) | statically_inferred |
| A6 | `:forward_provenance` | Shared contract library | path dep of both root (`mix.exs:67`) and runtime (`tiannara_runtime/mix.exs:32`); has `lib/` + `contracts/` + `spec/` | yes (87) | statically_inferred |
| A7 | `tiannara_api` | Python FastAPI | `tiannara_api/main.py:92` `app = FastAPI(...)`; ASGI entry `tiannara_api.main:app` | yes (132) | statically_inferred |
| A8 | `tiannara_api` (production variant) | Python FastAPI | `tiannara_api/main_production.py:41` — **second, divergent app object** | yes | statically_inferred |
| A9 | `tiannara_core` | Python library (imported by A7/A8) | importable package, no entrypoint | yes (440) | statically_inferred |
| A10 | `tiannara_pros` | Python hardware-IO library | importable package; `tiannara_core/integration/pros_adapter.py` imports it | yes (47) | statically_inferred |
| A11 | `tiannara_api.gateway` | Python in-process routing sub-layer | `tiannara_api/gateway/routing.py` `ROUTE_MAP` + `ENGINE_REGISTRY`; engines registered in `main.py:277-285` startup hook | yes | statically_inferred |
| A12 | `tiannara_saas` | Next.js 16 UI | `tiannara_saas/package.json` `next build` / `next start` | yes (90) | statically_inferred |
| A13 | `observatory_ui` | Next.js 15 UI (umbrella dir) | `tiannara_observatory/apps/observatory_ui/package.json` `next build` | yes (133) | statically_inferred |
| A14 | `tiannara-desktop` | Electron 33 shell | `tiannara-desktop/package.json` `electron .` / `electron-builder` | yes (10) | statically_inferred |
| A15 | `rust_core` | Rust crate | `rust_core/ffi_bindings/Cargo.toml` + `src/lib.rs` | yes (2 files) — **but no `use Rustler`/`crate:` in `tiannara_runtime/mix.exs`** | statically_inferred |
| A16 | `tiannara_gui` | Frontend | present on disk (54 files), **0 tracked** | ✗ absent-in-git | independently_verified |
| A17 | `tiannara_internal_dashboard` | Frontend (Next.js) | present on disk (95 files), **0 tracked** | ✗ absent-in-git | independently_verified |
| A18 | `tiannara_mobile` | Frontend (6 generated stubs) | present on disk, **0 tracked** | ✗ absent-in-git | independently_verified |

**A16–A18 re-verification (quick, as required):** `git ls-files tiannara_gui` → 0;
`git ls-files tiannara_internal_dashboard` → 0; `git ls-files tiannara_mobile` → 0.
`.gitignore:25-27` lists `tiannara_gui/`, `tiannara_internal_dashboard/`, `tiannara_mobile/`.
This **confirms F-PLT-003 / F-ARC-024** at the requested granularity. `tiannara_saas` (90 tracked) and
`observatory_ui` (133 tracked) are the only tracked UIs, plus `tiannara-desktop` (10 tracked).

### a.2 Root Elixir project (`:tiannara`) — how it starts

```
Tiannara.Application.start/2                      lib/tiannara/application.ex:15
 └─ Supervisor.start_link(strategy: :one_for_one)  lib/tiannara/application.ex:25
     ├─ core_children()                            :105-241   (always)
     ├─ loop_children()                            :245-253   (always)
     └─ asc_children(asc_enabled?)                 :256-281   (flag-gated, default OFF)
 └─ register_subsystems()                          :283-425
     ├─ BootSequencer.define_subsystem/1 × 15      :404-406
     └─ BootSequencer.boot()                       :408
 └─ Tiannara.CEL.Kernel.boot()                     :38   (sync in :test, else Task.start)
 └─ Tiannara.Discovery.DiscoverySupervisor.start_link/1  :87  (skipped in :test)
```

- Phoenix endpoint: `TiannaraWeb.Endpoint` (`lib/tiannara/application.ex:209`), `Phoenix.PubSub` `:208`.
- Endpoint port: `config/dev.exs:10` `4000`; `config/prod.exs:23` `PORT` env or `4000`.
- `config/prod.exs` **exists** for the root project (contrast A2 below).
- Release config exists (`mix.exs:32-42`: `tiannara` release incl. `phoenix`, `plug_cowboy`, steps `[:assemble, :tar]`) —
  **but no workflow ever invokes `mix release`** (see §i and `deps_build.json`).

### a.3 Runtime Elixir project (`:tiannara_runtime`) — how it starts

```
TiannaraRuntime.Application.start/2               tiannara_runtime/lib/tiannara_runtime/application.ex:18
 └─ Supervisor.start_link(strategy: :one_for_one)  ...application.ex:39
     ├─ {TiannaraRuntime.StartupSupervisor, []}    :31
     │   └─ Supervisor :rest_for_one                startup_supervisor.ex:42
     │       1 ConstitutionalPersistenceLayer      startup_supervisor.ex:30  (storage_path "data/cpl", 30 000 ms)
     │       2 TiannaraRuntime.Omega.Supervisor     :35
     │       3 TiannaraRuntime.OS.Observatory (COP) :36
     │       4 TiannaraRuntimeWeb.Endpoint          :37
     │       5 TiannaraRuntime.RootSupervisor      :38
     │       6 TiannaraRuntime.DiscoveryRunner     :39  (cycle_interval 60 000)
     └─ BootPolicy.optional_child × 5 (app level, dependency-ordered)  application.ex:33-37
         CIS.Supervisor → CIS.ExecutionController → Resources.QuotaGovernor
         → Memory.LineageCompression → Causal.GCK
```

`RootSupervisor` (`runtime_layers/supervisors.ex:212`, `:rest_for_one`, profile `:stable` from
`config/config.exs:5` `boot_profile: :stable`):

| Layer | Children (source) | Required? |
|---|---|---|
| Infrastructure `:70-81` | `Phoenix.PubSub`(:tiannara_runtime), `Registry`(:tiannara_runtime, unique), `Registry`(**`Tiannara.EventRegistry`**, duplicate), `TiannaraRuntime.SharedMemory`, `TiannaraRuntime.NATS.Supervisor` (required), `TiannaraRuntime.Telemetry.Supervisor` (optional) | mixed |
| Execution `:103-104` | `Tiannara.OPC.CoreSupervisor` (required), `Tiannara.OPC.Supervisor` (optional) | mixed |
| Ecology `:126-135` | `Tiannara.UniverseSupervisor` (required), `TiannaraRuntime.Legacy.Tiannara.OLEF.FieldSupervisor`, `Tiannara.OLEF.Supervisor`, `TiannaraRuntime.OCM.Supervisor`, `Tiannara.RRG.Supervisor` | mixed |
| Constraint `:160-166` | `IRD.Supervisor`, `CCR.Supervisor`, `HSV.Supervisor`, `ACF.Supervisor` (all optional) + `TiannaraRuntime.Cortex.SafetyCortex` (required) | mixed |
| Meta `:189-206` | `Tiannara.MetaSOPL.RateModulationSupervisor` (required), `Tiannara.Meta.ChronogramMatrix`, `Tiannara.NATS.MetaEvolutionStreamManager`, `Tiannara.Meta.MSCL`, `TiannaraRuntime.MCK`, `Tiannara.Meta.ObserverArbitrationLayer`, `Tiannara.Meta.ObserverCollapseGovernor`, `Tiannara.Meta.ObserverMemoryReconciliation` | mixed |

- `BootPolicy.optional_child/2` **skips missing modules with a warning**; `required_child/2` **raises**
  (`runtime_layers/supervisors.ex:6-21`). An optional child that *starts and then fails* still fails the boot.
- Endpoint port: `config/dev.exs` → `8004`; `config/test.exs` → `4001`.
- **`config/prod.exs` does NOT exist** (`tiannara_runtime/config/` = `config.exs`, `dev.exs`, `test.exs`,
  `opc.ex`, `layer_boundaries.exs`), while `config/config.exs:57` does `import_config "#{Mix.env()}.exs"`.
  → `MIX_ENV=prod mix compile`/boot fails. **Confirms F-ARC-014 / F-PLT-008** (independently_verified).

### a.4 Observatory umbrella (`:tiannara_observatory`)

- 11 directories under `apps/`, but `mix.exs:7-18` lists **10** — `observatory_ui` is **not** an umbrella app
  (it has no `mix.exs`; it is a standalone Next.js project living inside the umbrella tree).
- `shared` also has no `application.ex` (library app).
- Each of the 8 OTP apps declares `mod:`; `observatory_api` depends on the other 9 in-umbrella apps plus
  `phoenix 1.8.9`, `ecto_sql`, `postgrex`, `bandit`, `dns_cluster`, `cors_plug`.
- The umbrella root `mix.exs` has `deps: []` and **no `mod:`** → there is no umbrella-level supervision tree;
  the umbrella can be compiled/tested, but "running the umbrella" is undefined.

### a.5 Python packages

| Package | Role | Entry | Basis |
|---|---|---|---|
| `tiannara_api` | FastAPI HTTP surface (A7) | `main.py:92` | statically_inferred |
| `tiannara_api` (prod variant) | FastAPI HTTP surface, divergent (A8) | `main_production.py:41` | statically_inferred |
| `tiannara_core` | domain library: `autonomous`, `discovery`, `evolution`, `memory`, `safety`, `modules`, `mission`, `cognition`, `nlp`, `opc`, `research`, `governance`, … (≈70 sub-packages) | importable | statically_inferred |
| `tiannara_pros` | prosthetic IO: `actuators`, `analytics`, `config`, `io`, `orchestrators`, `scenarios`, `testing`, `utils` | importable | statically_inferred |
| `tiannara_api.gateway` | in-process engine routing (A11) | `gateway/routing.py` | statically_inferred |
| `tiannara_api.middleware` | `ProductionAuthMiddleware`, `JWTContextMiddleware`, `SecurityHeadersMiddleware`, `InputValidationMiddleware`, `EnhancedRateLimiter`, `LoggingMiddleware`, `quota_enforcer` | `main.py:98-105` | statically_inferred |
| `tiannara_api.database` | SQLAlchemy/PostgreSQL | `database/__init__.py:26` `create_engine(DATABASE_URL)`; `DATABASE_URL` env or built from `DB_USER`/`DB_PASSWORD`/`DB_HOST`/`DB_PORT`/`DB_NAME` | statically_inferred |

**Import cycle (confirms F-ARC-012):** `tiannara_core/integration/pros_adapter.py:3-4` imports
`tiannara_pros`; ≥10 `tiannara_pros` files import `tiannara_core`.

### a.6 Frontends

| Frontend | Stack | Build command | Tracked | Notes |
|---|---|---|---|---|
| `tiannara_saas` | Next.js 16.2.6, React 19 | `npm run build` (`next build`) | 90 | `next.config.ts` uses **server-side `rewrites()`** to `API_UPSTREAM_URL` (default `http://127.0.0.1:8004`) |
| `observatory_ui` | Next.js 15, React 19 | `npm run build` | 133 | has `npm test` (vitest), `npm run lint`, `npx tsc --noEmit` |
| `tiannara-desktop` | Electron 33 + electron-builder | `npm run build` → nsis/dmg/AppImage | 10 | `package.json` `name: "tiannara-observatory"` — **name collides with the Observatory umbrella** (F-PLT-014) |
| root `package.json` | — | **no scripts** (only `framer-motion` dep) | 1 | not a buildable frontend |
| `tiannara_gui` / `tiannara_internal_dashboard` / `tiannara_mobile` | on disk only | — | **0** | absent-in-git (A16–A18) |

### a.7 Rust core

`rust_core/ffi_bindings/{Cargo.toml,src/lib.rs}` — 2 tracked files. `tiannara_runtime/mix.exs:67` declares
`{:rustler, "~> 0.36.0"}` but the project has **no `use Rustler` and no `crate:` config**, so **no NIF is
built**. Six `native_bridge.ex` modules load NIFs from
`Application.app_dir(:tiannara_phase14, "priv/native/…")` — `:tiannara_phase14` is **not a project in this
checkout**. → **Confirms F-ARC-025** (independently_verified).

### a.8 Start scripts, Procfile, mise

| Artifact | Content | Notes |
|---|---|---|
| `Procfile` | `web: uvicorn tiannara_api.main:app --host 0.0.0.0 --port $PORT` | Only the Python API is declared as a web process. |
| `mise.toml` | `elixir = "1.18.4-otp-28"`, `erlang = "28"` | Root toolchain pin. |
| `start.bat` / `start-production.bat` / `start-safe.bat` | `mix tiannara.start --profile dev|production` / `--safe` | Root project only. |
| `start_production.sh` | sources `.env.production` / `.env`, then launches the **Python** API | Shell script uses `set -a` (bash) while the file is `.sh` — fine. |
| `restart_backend.bat` | `python -m uvicorn tiannara_api.main:app --reload --port 8004` | ⚠ uses **8004**, the same port the Elixir runtime dev endpoint binds (`tiannara_runtime/config/dev.exs`) → port collision. |
| `restart_frontend.bat` | `cd tiannara_saas && npm run dev` | |
| `start_alpha.ps1` | kills ports 8004 and 3000, starts runtime + `tiannara_internal_dashboard` | Dashboard is absent-in-git (A17). |
| `mix tiannara.start` (`lib/mix/tasks/tiannara.start.ex`) | 6-phase launcher (env → infra → runtime → api → frontend → health) | **Starts only `:telemetry` and `:tiannara`** (`:23`, `:120-134`). Never starts `:tiannara_runtime`. See F-ARC-226. |

### a.9 Docker / Kubernetes / compose

| Artifact | Purpose | State | Basis |
|---|---|---|---|
| `docker-compose.yml` | postgres 15, redis 7, `tiannara-api` (`docker/api/Dockerfile`), `tiannara-core` (`docker/core/Dockerfile`) | compose uses `ENVIRONMENT: development` and `JWT_SECRET_KEY: dev-secret-key-change-in-production` → auth middleware is **opt-out** | statically_inferred |
| `Dockerfile.production` | CI production image for the Python API | `COPY docker-entrypoint.sh` (file **exists**), `CMD uvicorn tiannara_api.main:app` — i.e. the **development** app object, not `main_production` | statically_inferred |
| `docker/api/Dockerfile` | API image | healthcheck probes `http://localhost:8000/api/v1/health` — **that route does not exist** (only `GET /health`, `tiannara_api/main.py:339`) → F-ARC-230 | statically_inferred |
| `docker/core/Dockerfile` | core worker image | `CMD python -m tiannara_core.autonomous.loop` (file exists) | statically_inferred |
| `docker/saas/Dockerfile` | SaaS static image | `COPY --from=builder /app/out` but `next.config.ts` has no `output: "export"` → `/app/out` is never produced → build fails → F-ARC-231 | statically_inferred |
| `tiannara_runtime/k8s/phase6/base/` | namespace, nats-cluster StatefulSet, runtime-deployment, gpu-node-selector | **no `kustomization.yaml`** | statically_inferred |
| `tiannara_runtime/k8s/phase6/overlays/production/kustomization.yaml` | production overlay | `resources: - ../../base` → broken base; `secretGenerator` with **literal** release cookie + NATS token (`:36-37`) → **Confirms F-PLT-005 / F-ARC-008** | independently_verified |
| `tiannara_runtime/k8s/phase8-rtl/base/` | rtl-deployment, rtl-jetstream-streams, rtl-keda-scaledobject | | statically_inferred |
| `tiannara_runtime/k8s/phase13_14,17,18,19` | 4 KEDA ScaledObjects | Targets `tiannara-phase13-14`, `tiannara-ucc`, `tiarnara-rrm` [typo], `tiannara-tcl` — **no matching Deployment manifests exist** → F-ARC-008 | statically_inferred |

---

## b. Request entry points

### b.1 Python API (`tiannara_api/main.py`) — 40 routers mounted

`main.py:212-255` mounts 40 routers. Prefix discipline: most are `/api/v1`; `status`, `modules`, `evolution`,
`autonomous`, `memory`, `autonomy`, `autonomous_testing`, `moderation`, `websocket_metrics`,
`websocket_streaming` are mounted unprefixed. `meta_ecology` is `/api/v1/meta-ecology`.

Route inventory (module → prefix):

| Router | Prefix | Router | Prefix |
|---|---|---|---|
| `status` | (none) | `auth` | `/api/v1` |
| `modules` | (none) | `email_verification` | `/api/v1` |
| `evolution` | (none) | `mfa` | `/api/v1` |
| `autonomous` | (none) | `sso` | `/api/v1` |
| `memory` | (none) | `workspaces` | `/api/v1` |
| `autonomy` | (none) | `audit` | `/api/v1` |
| `autonomous_testing` | (none) | `analytics` | `/api/v1` |
| `websocket_metrics` | (none) | `white_label` | `/api/v1` |
| `websocket_streaming` | (none) | `mapek_security` | `/api/v1` |
| `discovery` | `/api/v1` | `admin` | `/api/v1` |
| `explanations` | `/api/v1` | `usage` | `/api/v1` |
| `payment` | `/api/v1` | `moderation` | (none) |
| `efficiency` | `/api/v1` | `core_proxy` | `/api/v1` |
| `monitoring` | `/api/v1` | `workflows` | `/api/v1` |
| `monitoring_stabilization` | `/api/v1` | `automations` | `/api/v1` |
| `telemetry` | `/api/v1` | `analytics_insights` | `/api/v1` |
| `football_predictions` | `/api/v1` | `team` | `/api/v1` |
| `alert_rules` | `/api/v1` | `gateway_routes` | `/api/v1` |
| `collaboration` | `/api/v1` | `unified_endpoints` | `/api/v1` |
| `api_keys` | `/api/v1` | `domain_tests` | `/api/v1` |
| `observatory` | `/api/v1` | `cognitive_domains` | `/api/v1` |
| | | `cognitive_analysis` | `/api/v1` |

Plus `GET /health` (`main.py:339`) and the in-process gateway route map
(`tiannara_api/gateway/routing.py:19-27`): `/api/predict`, `/api/reason`, `/api/analyze`, `/api/causal`,
`/api/algorithm`, `/api/evolve`, `/api/discovery` → engine registry.

**The `main_production.py` variant mounts only 13 routers** (`main_production.py:145-153`) and **none** of
`auth`, `admin`, `observatory`, `mfa`, `sso`, `audit`, `telemetry`, `gateway_routes`, `core_proxy`,
`meta_ecology`, `webhooks`, `usage`, `moderation`, `api_keys`, `collaboration`, `alert_rules`,
`football_predictions`, `domain_tests`, `cognitive_*`, `email_verification`, `workspace*`, `team`,
`automations`, `analytics_insights`, `monitoring*`, `white_label`, `mapek_security`, `efficiency`,
`unified_endpoints`, `discovery` (prefixed differently: `main_production.py:147` mounts `discovery_router`
**without** the `/api/v1` prefix that `main.py:214` uses). → the two entrypoints are not the same product.

### b.2 Elixir HTTP entry points

| App | Router | Surface |
|---|---|---|
| `:tiannara` (root) | `lib/tiannara/web/router.ex` | `/api/v1` (24 routes, all `CRAVChallengeController`), `/api` (33 routes), `/` + 25 `live` LiveViews (REA Research Workbench) |
| `:tiannara_runtime` | `tiannara_runtime/lib/tiannara_runtime_web/router.ex` | `/api/v1` only, 30 routes, all `TiannaraRuntimeWeb.ObservatoryController` (health, system/status, observatory/*, engines/*, orchestration/*, admin/*, moderation, domains/tests, chat, cpl/stats\|events\|checkpoints) |
| `:observatory_api` | `apps/observatory_api/lib/observatory_api/router.ex` + `.../observatory_api_web/router.ex` (two routers coexist) | REST controllers (certification, civilization, discovery, engineering, events, metrics, planet, replay, runtime, science, status) + `socket "/ws"` (8 channels) + `observatory_api_web` channels (observatory_channel/socket) + 6 `Hub` GenServers |

⚠ **Three distinct Phoenix routers exist across the repo with overlapping route names** — `TiannaraWeb.Router`
(120 lines), `TiannaraRuntimeWeb.Router` (65 lines), `ObservatoryApi.Router` **and**
`ObservatoryApiWeb.Router` (two routers inside the *same* umbrella app).

### b.3 Non-HTTP entry points

- Mix tasks: root has 13 (`asc.adopt|audit|bench.boot|c.run|c.run2|c.run3|c.verify`, `phase_omega_scan`,
  `tiannara.generate_minimal_repro_package`, `tiannara.generate_reproducibility_package`, **`tiannara.start`**);
  runtime has 1 (`cis.validate_phase5e` — references 7 nonexistent `MultiWorld.*` modules).
- ~70 root-level `run_*.exs` scripts (e.g. `run_production.exs`, `run_cold_boot_test.exs`,
  `run_archaeological_reconstruction.exs`, `run_mutation_testing.exs`, `run_independent_audit.exs`) — these are
  the scripts CI actually executes (see §i).
- `docker/api/entrypoint.sh` (image entrypoint).

---

## c. Boot & supervision

### c.1 Boot trees (basis: statically_inferred from source; re-derived from primary source, not copied)

**Path 1 — root application (`:tiannara`)** — `lib/tiannara/application.ex:105-241`
Council.Supervisor → CEL.Kernel.ServiceRegistry → LifecycleRegistry → CTL.CausalRegistry → CEL.Kernel →
Storage.DetsLifecycle → CRAV.SoakCheckpointer → Tiannara.Telemetry → Discovery.PipelineTelemetry →
PhaseOmega.SubsystemRegistry/BootSequencer/RuntimeVerifier → Observatory.ValidationSupervisor/LiveProjection →
ValidationCampaigns → TiannaraOS.CivilizationKernel → LEOC.LatentVault → ROS.Registry/ShardSupervisor/
ShardManager/EvolutionEngine → REL.EconomyEngine/DiscoveryLedger/ProductionEngine → OMCS.Supervisor →
Core/Stabilization/Physics/Topology Supervisors → Domains.CanonicalRegistry → Sentinel.Supervisor →
CIS.Supervisor → Sentinel.D2 × 5 → Task.Supervisor → AAL.CommandLoom → Meta.Hardware.Supervisor →
Phoenix.PubSub → `TiannaraWeb.Endpoint` → Operations.OperationsSupervisor → Domains.ResearchDirector →
ASC.Agency.Sentinel → Executive.Supervisor → Sentinel.SentinelRuntime → Research.ResearchDirector →
Executive.Cognitive.ExecutiveCognitiveRuntime → Interface.CognitiveInterface →
Autonomy.ConstitutionalAutonomy → Omega.OmegaRuntime.
Strategy: `:one_for_one` (`:25`). Plus `loop_children` (5 `Operations.*` children) and
`asc_children` (7 children, flag-gated, default off).

**Path 2 — CEL executive kernel** — `lib/tiannara/cel/kernel.ex`. `Tiannara.CEL.Kernel` is a GenServer that
owns a `DynamicSupervisor` (`Tiannara.CEL.ServiceSupervisor`, `:22`) and boots services through
`BootSequencer.boot/4` (`:46-51`), each with `restart: :temporary` (`:117`).

**Path 3 — Council (constitutional authority)** — `lib/tiannara/council/supervisor.ex:9-16`, `:rest_for_one`:
AuditLog → Omega.MintRegistry → ConstitutionRepository → PolicyRegistry → HumanApprovalQueue →
AmendmentEngine → ConstitutionalMonitor → `Tiannara.Council`.

**Path 4 — PhaseΩ boot sequencer** — `lib/tiannara/phase_omega/boot_sequencer.ex` + `SubsystemRegistry`
(`application.ex:404-416`): **14** subsystems registered via `BootSequencer.define_subsystem/1` (a 15th,
`tool_forge`, is added only when ASC is enabled — `application.ex:389-402`), plus `:ros_registry` registered
directly at `:418-424` outside the sequencer; booted via `BootSequencer.boot/0`.

**Path 5 — runtime application (`:tiannara_runtime`)** — §a.3 above. `StartupSupervisor` `:rest_for_one`;
`RootSupervisor` `:rest_for_one`; app-level `:one_for_one`.

**Path 6 — observatory umbrella `:observatory_api`** — `application.ex:8-21`, `:one_for_one`:
Telemetry → Repo → DNSCluster → PubSub → Hub.EventDispatcher → Hub.LiveStreamEngine →
Hub.SubscriptionRegistry → Hub.AlertEngine → Hub.MissionBroadcast → Hub.COBStreamBridge → Endpoint.

**Path 7 — `Tiannara.ControlCenter` (out-of-tree boot)** — `lib/tiannara/control_center.ex:57-82`:
`init/1` calls `boot_all_subsystems/1` → `start_subsystem/2` (`:189-208`) which calls
`module.start_link([])` **from inside `GenServer.init`**. These ~29 subsystems are therefore **not children
of any Supervisor** — they are linked to the ControlCenter process itself. **Additionally, `Tiannara.ControlCenter`
is not a child of any supervisor in `lib/tiannara/application.ex`** (the only mention is a comment at
`application.ex:75`) and is read (never started) by `lib/tiannara/observability.ex:129,137`.
→ **F-ARC-235** (new).

### c.2 Who supervises what, and restart strategy

| Tree | Strategy | Consequence |
|---|---|---|
| root `Tiannara.Application` | `:one_for_one` | A crashed layer restarts alone; but layers are **not** ordered by dependency on restart, so a restarted `Core.Supervisor` may find its dependencies absent. |
| `Council.Supervisor` | `:rest_for_one` | Correct for a constitution (AuditLog → … → Council). |
| `CEL.Kernel` service supervisor | `DynamicSupervisor`, `one_for_one`, `restart: :temporary` | A crashed CEL service is **not** restarted by the supervisor; only `Kernel.restart_service/2` (Council-gated) re-creates it. |
| `StartupSupervisor` | `:rest_for_one` | CPL → … → RootSupervisor: a CPL crash restarts the *entire* runtime, including the endpoint. |
| `RootSupervisor` | `:rest_for_one` | A Constraint-layer crash restarts Constraint **and Meta**. |
| Layer supervisors | Infrastructure/Execution/Ecology/Constraint = `:rest_for_one`; Meta = `:one_for_one` | Meta children are mutually independent (OMRL↔OCG↔MSCL↔MCK ordering is only guaranteed at first boot). |
| `ObservatoryApi.Supervisor` | `:one_for_one` | |
| `ControlCenter` subsystems | **none** (linked to `GenServer.init`) | Crash semantics undefined (F-WRD-010). |

### c.3 Known boot gaps (verified, not inherited)

| # | Gap | Verification | Basis |
|---|---|---|---|
| BG-1 | **The runtime application is never started by any launcher.** `mix tiannara.start` starts only `:telemetry` and `:tiannara` (`lib/mix/tasks/tiannara.start.ex:23`, `:120-134`); the root release lists only `tiannara`, `phoenix`, `plug_cowboy` (`mix.exs:34-41`); `Procfile` declares only the Python API; `docker-compose.yml` has no Elixir service. | source read | statically_inferred → **F-ARC-226** |
| BG-2 | **The whole world-model / multi-world / civilization stack is absent from every boot tree.** `tiannara_runtime/lib/tiannara_runtime/{world_model,civilization,multi_world,evolution,autonomous_research}` — the `MultiWorld.KillSwitch` GenServer is defined (`multi_world/kill_switch.ex:1`) but **no supervisor references it**; `multi_world/world_supervisor.ex:58` supervises `TiannaraRuntime.MultiWorld.WorldProcess`, which exists **only inside `multi_world/fixes.md:1757`** (markdown, not source); `world_supervisor.ex:111,136,140` call `get_killed_worlds/0`, `request_kill/2`, `confirm_kill/2` — **none of which exist** on the unified `KillSwitch` (`:82-128`). | source read | statically_inferred → confirms **F-WRD-003 / F-WRD-004 / F-GOV-013**, extends with the concrete markdown-only module → **F-ARC-234** |
| BG-3 | `Tiannara.Meta.Supervisor` (`meta/supervisor.ex`) is an orphan — W2 wiring went through `TiannaraRuntime.Meta.Supervisor` instead. | prior audit + source | documented (wiring audit:50) |
| BG-4 | `Tiannara.P9XEcosystem.Supervisor` — defined, **not** in any boot tree; its remaining children (5F.5 MSCL set, CIS, P9X, GRCC) were deliberately not re-parented. | prior audit | documented (wiring audit §4.3) |
| BG-5 | `TiannaraRuntime.Interface.Supervisor` has `children = []`. | prior audit | documented (F-ARC-010) |
| BG-6 | `TiannaraRuntime.EventGateway` — the **only** real (`gnat`) NATS client — is in no boot tree, and its `connect_nats/0` returns `{:error, :unavailable}` unconditionally (`event_gateway.ex:182-185`). | source read | statically_inferred → **F-ARC-228** |
| BG-7 | `Tiannara.ControlCenter` is in no boot tree yet is the documented owner of ~29 subsystems. | source read | statically_inferred → **F-ARC-235** |
| BG-8 | `TiannaraRuntime.MultiWorld.KillSwitch` / `HardenedKillSwitch` / `Tiannara.MultiWorld.KillSwitchCausal` — **three** kill-switch modules, **none started**; `cortex/safety_cortex.ex:393` sends to the unregistered `HardenedKillSwitch` outside any `try/rescue`. | source + prior audit | independently_verified (confirms F-GOV-013) |
| BG-9 | `TiannaraRuntime.MIX_ENV=prod` cannot boot: `config/prod.exs` missing (`tiannara_runtime/config/` listing). | source read | independently_verified (confirms F-ARC-014) |

---

## d. Data ownership & persistence

**No store-ownership map exists in the repo** (F-ARC-018 open). The table below is the Pass-3 reconstruction
from source; it is the proposed Register-4 seed.

| Store | Technology | Owner module | Writers | Format / location | Recovery path |
|---|---|---|---|---|---|
| CPL event log | file JSON, one file per event | `TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayer` (`tiannara_runtime/lib/tiannara_runtime/os/persistence/constitutional_persistence_layer.ex`) | `record_event/2` (`:116`) — called by every runtime operation | `<storage_path>/events/evt_<n>.json`; default `storage_path = "data/cpl"` (`startup_supervisor.ex:32`) — **CWD-relative** | `load_existing_state/1` (`:408`) → `load_events/1` (`:427`) → `normalize_event_keys/1` (`:336`); **whole load is wrapped in `rescue` → logs a warning and returns the empty state** (`:421-425`) — i.e. a malformed event file silently discards the entire event history |
| CPL checkpoints | file JSON, one dir per layer | same | `create_checkpoint/2` (`:124`), auto every 30 000 ms via `checkpoint_all_layers/1` (`:364`) | `<storage_path>/checkpoints/<layer>/chk_<layer>_<n>.json` | `load_checkpoints/2` (`:455`) → `latest_checkpoint/1` (`:477`) → **`normalize_checkpoint_keys/1` (`:497`)** — added in commit `c7214a50` after CI run `39382482185` crashed the process every 30 s with `key :checkpoint_id not found` (`TIANNARA_RUNTIME_TEST_INVENTORY.md:148`). Note: `checkpoint_all_layers/1` writes `state_data = %{}` for every layer (`:376`) — **the checkpoints carry no state**, only a hash of `{}`. |
| CPL hash chain | SHA-256 over `:erlang.term_to_binary/1` | same | `create_event/3` (`:233`) | in-memory `last_event_hash` + `previous_hash` chain, genesis sentinel `"genesis"` | `verify_hash_chain/1` (`:298`) — validates per-event hash, pairwise link, and genesis anchor. `recover/0` (`:192`) returns a report but **does not restore any subsystem state** (`runtime_restored: true` is hard-coded, `:289`). |
| Constitution repository | DETS | `Tiannara.Council.ConstitutionRepository` (`lib/tiannara/council/constitution_repository.ex`) | `commit/3` (`:16`), `rollback/2` (`:20`) | `./constitution_repository.dets` (`:7`, CWD-relative), seeded with `Constitution.v1()` (`:28-31`) | version rollback only; `rollback/2` reverts the *constitution version*, not runtime state |
| Council audit log | DETS | `Tiannara.Council.AuditLog` | `append/3` | `./council_audit_log.dets`; repo contains 470 deleted `council_audit_log.dets.corrupted.*` archives (baseline.md:25) | `repair: false` on open (`:278`), then `repair: true` fallback (`:295`, `:307`). Merkle root computed periodically (`:238-256`) but **has no consumer**; degraded-mode readers return `[]`/`nil` silently (F-GOV-012). |
| CEL executive memory (×2) | DETS | `Tiannara.CEL.ExecutiveMemory` (`cel/executive_memory.ex:27`) and `Tiannara.CEL.Services.ExecutiveMemory` (`cel/services/executive_memory.ex:79`) — **two modules, two files** | — | `./cel_executive_memory.dets`, `./cel_memory_v2.dets` | `repair: true` path in `cel/services/resilient_dets.ex` |
| CEL event-bus DLQ | DETS | `Tiannara.CEL.Services.EventBus` | — | `./cel_event_bus_dlq.dets` (`:70`) | — |
| Mission director state | DETS | `Tiannara.CEL.Services.MissionDirector` | — | `@mission_file` (`:106`) → `mission_director_state.dets` | — |
| Ontology manager | DETS | `Tiannara.World.OntologyManager` | — | `./ontology_manager.dets` (`:96`) | — |
| Workflow engine | DETS | `Tiannara.Executive.WorkflowEngine` | — | `./workflow_engine.dets` | — |
| World conflict / executive stores | DETS | `Tiannara.World.ConflictResolutionEngine` (`:104`), `Tiannara.Executive.DetsStore` (`:11`), `Tiannara.ExecutiveMemory` (`:344`), `Tiannara.Executive.Recovery` (`:238`) | — | `./conflict_resolution_engine.dets`, caller-supplied paths | `Tiannara.Executive.Recovery` (8.6 KB) is the only dedicated recovery module in the root tree |
| Root ETS tables | ETS (named, `public`/`protected`) | ~30 owners (e.g. `Tiannara.LifecycleRegistry` `:lifecycle_*`, `Tiannara.CTL.CausalRegistry`, `Tiannara.PhaseOmega.SubsystemRegistry` `:protected`, `Tiannara.IRD.*` 5 tables, `Tiannara.NDE.*`, `Tiannara.Graph.*`) | — | **in-memory only — no persistence, no owner restart recovery** | lost on restart |
| Runtime Registries | Registry (unique + duplicate) | `TiannaraRuntime.Infrastructure.Supervisor:72-77` | — | in-memory | lost on restart |
| Mnesia | Mnesia | `tiannara_runtime/lib/tiannara_runtime/meta/causal_data_layer.ex` — **the only Mnesia user in the repo**; `:mnesia` is in `extra_applications` (`tiannara_runtime/mix.exs:22`) | — | Mnesia dir (default `Mnesia.nonode@nohost`) | Mnesia's own |
| API database | PostgreSQL (SQLAlchemy) | `tiannara_api/database/__init__.py` | `tiannara_api` routes | `DATABASE_URL` env or `DB_*` env | Postgres |
| Observatory DB | PostgreSQL (Ecto) | `ObservatoryApi.Repo` | `observatory_api` | 6 DBs configured in `tiannara_observatory/config/config.exs:22-60` (all `postgres`/`postgres`) | Postgres |
| Python SQLite | SQLite (4 modules) | `tiannara_core/{autonomy/stagnation_detector,evaluation/episode_logger,interpretability/audit_trail,telemetry/cognitive_telemetry}.py` | those modules | **CWD-relative paths** (e.g. `tiannara_core/memory/discovery_memory.py:16`) — no env-configurable data dir | none |
| Laws / telemetry archives | NDJSON / CSV | `data/asc_archive/laws.ndjson` | ASC archive | append-only text | none |
| Mock reports | CSV | `tiannara_api/routes/observatory.py:655-723` `populate_initial_reports()` | the API itself | `reports/world_health_epoch_*.csv` — **self-described "mock historical hourly reports"** | n/a — **these files are the sole source of the 12-worlds/84-civilizations/23 800-agents historical claim** (F-WRD-001) |

**Store-hygiene facts (F-ARC-018):** 31 tracked `*.dets` files are modified in the working tree at baseline
(baseline.md:24) — runtime DB churn is committed to git; DETS paths are CWD-relative
(`./constitution_repository.dets` etc.), so the store location depends on the launch directory, which differs
between `mix test` (repo root), `cd tiannara_runtime && mix test` (runtime root), and container `/app`.

---

## e. Message flows

### e.1 NATS — two incompatible implementations, and the wrong one is wired

| Implementation | Path | Transport | Wired? | Basis |
|---|---|---|---|---|
| **In-VM bus + raw TCP shim** | `tiannara_runtime/lib/tiannara_runtime/nats/{bus,connection,publisher,subscriber}.ex` | `TiannaraRuntime.NATS.Bus` = a `Registry` broadcast with `*`/`>` subject matching (`bus.ex:18-66`). `TiannaraRuntime.NATS.Connection` opens a **plain `:gen_tcp` listener** on `NATS_PORT` (default `4222`) and parses newline-delimited JSON `{"subject":…,"payload":…}`, republishing into the local Bus (`connection.ex:22`, `:52-68`). | **YES** — `TiannaraRuntime.NATS.Supervisor` (`nats/supervisor.ex:10-15`) starts Bus + Connection + Publisher + Subscriber, and is a `required_child` of the Infrastructure layer (`runtime_layers/supervisors.ex:80`). | statically_inferred |
| **Real `gnat` client** | `tiannara_runtime/lib/tiannara_runtime/event_gateway.ex` | `Gnat.pub/sub` against a NATS server | **NO** — `connect_nats/0` is hard-coded to `{:error, :unavailable}` (`:182-185`); `EventGateway` is in no boot tree; it would retry with exponential backoff (`:320-324`) but can never succeed. | statically_inferred |
| `Tiannara.NATS.MetaEvolutionStreamManager` | `nats/meta_evolution_stream_manager.ex` | `Jason.encode` → `TiannaraRuntime.NATS.Bus.publish/2` (`:70-73`) — **in-VM only** | YES (Meta layer, `optional_child`, `runtime_layers/supervisors.ex:201`) | statically_inferred |

**Consequences (F-ARC-228, new):**
1. The boot-wired "NATS" is a **loopback fan-out**, not a broker. A separate `nats-server` process
   (the launcher checks port 4222, `tiannara.start.ex:91`; `k8s/phase6/base/nats-cluster.yaml` deploys a
   StatefulSet) would conflict with the raw TCP listener bound on the same port.
2. `MetaEvolutionStreamManager.get_status/0` reports **`connected: true` unconditionally**
   (`meta_evolution_stream_manager.ex:17`, `:79-86`) with a hard-coded `url: "nats://127.0.0.1:4222"`,
   so a health dashboard would report a healthy NATS link that does not exist.
3. `TiannaraRuntime.NATS.Subscriber` subscribes to `tiannara.simulation.{grcc,fitness,niche,evolution}.>`
   (`subscriber.ex:14-19`) but only *counts* received messages (`:30-34`) — no consumer logic.
4. `TiannaraRuntime.NATS.ConnectionManager` is configured in `config/config.exs:15-18`
   (`server_url: System.get_env("NATS_URL", …)`) — but **no `ConnectionManager` module exists** in
   `tiannara_runtime/lib/tiannara_runtime/nats/` (the directory lists `bus, chronogram_sync, connection,
   jet_stream_helper, mesh_balancer, mesh_supervisor, meta_evolution_stream_manager, observer_router,
   ocm_bus, opc_bus, pressure_stream, publisher, reality_bus, reality_firewall, subscriber, supervisor,
   world_entanglement_streams, world_event_serializer, world_stream_manager`) → **dead configuration key**
   (same defect class as the removed `start_app` key, `TIANNARA_RUNTIME_TEST_INVENTORY.md:168`).

### e.2 Event bus proliferation (F-ARC-004, re-verified)

| Bus | Module | Tree | Boot-wired? |
|---|---|---|---|
| `TiannaraRuntime.NATS.Bus` | runtime | runtime | yes (Infrastructure) |
| `Tiannara.EventBus` (Registry `Tiannara.EventRegistry`) | runtime | runtime | yes (Infrastructure) |
| `Tiannara.CEL.EventBus` | root | root | module exists; **zero external references** (F-ARC-004) |
| `Tiannara.ASC.Core.EventBus`, `Tiannara.CEL.Services.EventBus`, `Tiannara.Executive.EventBus`, `Tiannara.Runtime.EventBus`, `Tiannara.CRAV.EventBus`, `Tiannara.Omega.*` | root | root | mixed |
| `ObservationBus` | umbrella | observatory | yes (own app) |
| `TiannaraRuntime.Omega.SentinelEventBus` | runtime | runtime | not in a boot tree |

### e.3 In-VM event bus usage (the one real, wired pub/sub path)

`Tiannara.EventBus` (`tiannara_runtime/lib/tiannara/event_bus.ex`):
- `subscribe/1` → `Registry.register(Tiannara.EventRegistry, topic, [])` (`:14-16`)
- `broadcast/3` → (a) `:telemetry.execute([:tiannara, :event_bus | topic_atoms], %{count: 1}, payload)` (`:31`)
  and (b) `Registry.dispatch/3` to subscribers (`:35-37`).

**Producer/consumer pair (the only complete, wired round-trip in the runtime):**
`Tiannara.OLEF.PressureSolver` subscribes to `"constraint.updated"` at init
(`tiannara_runtime/lib/tiannara/olef/pressure_solver.ex:14`) and broadcasts `"field.pressure_changed"`
(`:20`, `:28`). The subscriber side is the `Registry` dispatch — i.e. **the topic is delivered to any
process registered under that exact topic key**. Boot-wired via `Tiannara.OLEF.Supervisor`
(`tiannara_runtime/lib/tiannara/supervisors.ex:102`), added by W3 (`9307d6ed`).
This is the exact round-trip exercised by `test/tiannara/olef/boot_wiring_w3_test.exs` (wiring audit §4.3).

### e.4 Telemetry publisher → consumers

- **Producer:** `TiannaraRuntime.Monitoring.TelemetryPublisher` (`tiannara_runtime/lib/tiannara_runtime/monitoring/telemetry_publisher.ex`),
  started under `TiannaraRuntime.Telemetry.Supervisor` (optional, `runtime_layers/supervisors.ex:45-49`).
  Ticks every **100 ms** (`:9`, `:70`) and executes
  `:telemetry.execute([:tiannara_runtime, :cold_ignition, channel], measurement, %{source: __MODULE__})`
  for channels `:grcc, :mscl, :olef, :cis, :ctl` (`:117-119`).
- **Consumer:** `TiannaraRuntime.Monitoring.ColdIgnitionSupport` attaches a handler to
  `[:tiannara_runtime, :cold_ignition, channel]` (`monitoring/cold_ignition_support.ex:9-10`).
  This is the **only** in-repo consumer of that event name (`git grep cold_ignition`).
- **Metrics source:** `build_metrics/0` reads `Tiannara.UniverseServer.snapshot()` (`:148`) — i.e. the
  telemetry publisher is a **consumer of the Ecology layer** (`Tiannara.UniverseSupervisor`, required child).
  `safe_build_metrics/0` (`:133-145`) rescues **and** catches `:exit` and substitutes
  `empty_metrics/0` (all zeros) — a **fail-open-to-zero** path (a live system and a dead one look identical).
- **Separate root telemetry:** `Tiannara.Telemetry` (root, `application.ex:136`) is a *different* module tree;
  there is no shared event-naming contract between root and runtime telemetry.

### e.5 UEP and payload schemas

**UEP has zero implementation and zero in-repo specification** — F-EPI-001 (`capabilities_B_epistemics.md:150`,
critical, confidence high: repo-wide grep for `UEP|universal_epistemic|Universal Epistemic` over `*.ex` returns
0 hits; no UEP validator or validator-test file exists) and F-ARC-006 / F-GOV-001 (independently re-verified
by the prior pass; R0 adds no new evidence). Consequently:
- The JSON payload schema for every NATS/Bus topic is **defined ad hoc at the call site**
  (`meta_evolution_stream_manager.ex:22-41` maps `:escalation|:regulation|:recovery` to topic strings,
  `event_gateway.ex:54-77` hand-builds `{"type":…, "timestamp":…, "params":…}`).
- `Tiannara.NATS.Bus.publish/2` uses `Jason.encode!` (`bus.ex:19`) — an unencodable payload **raises**;
  `MetaEvolutionStreamManager` was hardened to `Jason.encode` + log-drop (`meta_evolution_stream_manager.ex:69-78`),
  but `TiannaraRuntime.NATS.Publisher` still calls `Bus.publish` directly (`publisher.ex:23`) and
  `Tiannara.EventBus.broadcast/3` passes arbitrary maps with no encoding step at all.
- **Babel** (`meta/singularity_dissolution/babel_protocol.ex`) `encrypt_causal_payload/4` has **zero production
  callers** and its "topological key" is an **unkeyed SHA-256** (wiring audit:48, C-08).

---

## f. State transitions

| State machine | Module | Transitions enforced by | Guarded by constitution? |
|---|---|---|---|
| **CEL executive kernel** | `Tiannara.CEL.Kernel` + `Tiannara.CEL.Kernel.RuntimeStates` (`lib/tiannara/cel/kernel/runtime_states.ex`) | 10 states (`booting, initializing, verifying, learning, operational, adaptive, recovery, emergency, maintenance, shutdown`) with an explicit `@valid_transitions` map (`:14-25`) | **NO.** `Kernel.transition/1` (`cel/kernel.ex:78-84`) consults **only** `RuntimeStates.valid_transition?/2` — no Council decision. → F-GOV-017 (independently re-verified) |
| **CEL service restart / halt** | `cel/kernel.ex:87-114` | `Council.authorize(:architectural_change, …)` | Council policy yields `:require_human` for this decision type (F-GOV-004/F-GOV-006), and `:conditional` is treated as **allow** (`cel/kernel.ex:92-93`) → fail-open. |
| **Council authorization** | `Tiannara.Council` + `PolicyRegistry` + `RuleEngine` + `HumanApprovalQueue` | `Council.authorize/2` → `Authorization` struct; `permitted?/1` accepts `:conditional` (F-GOV-005) | The `RuleEngine` can never return `:approved` for real callers (F-GOV-006); a policy `:approve` (priority 300, `emergency_halt`) **bypasses** the hard invariants and the decision is never re-derived (F-GOV-007). Human approval is a **one-way record** — `approve` writes `status: :approved` and removes the item from `queue`, and **no code resumes** a `:requires_human` authorization (F-GOV-004). |
| **CPL event/checkpoint lifecycle** | `ConstitutionalPersistenceLayer` | `record_event/2` → `create_checkpoint/2`; `recover/0` → `RecoveryReport` | Recovery is **advisory**: `runtime_restored: true` is hard-coded (`constitutional_persistence_layer.ex:289`) and no subsystem is actually restored. |
| **Observatory lifecycle** | `tiannara_observatory/apps/observatory_core/lib/observatory_core/lifecycle/state_machine.ex` — **the only file named `state_machine` in the entire repo** | — | Not in any verified boot path (umbrella has no umbrella-level tree). |
| **Civilization kernel** | `TiannaraOS.CivilizationKernel` (booted root `:153`) | `CivilizationState` | — |
| **Kill-switch lifecycle** | `TiannaraRuntime.MultiWorld.KillSwitch` | `request_termination/3` → `ExecutionController` → CIS → WorldSupervisor | **The chain is never started** (BG-8). |
| **Rollback** | `TiannaraRuntime.Autonomy.RollbackEngine` | — | `rollback/…` **always** returns `{:error, :rollback_unavailable}` (`autonomy/rollback_engine.ex:48`); `institution_adaptation_result.ex:214` defaults `rollback_available: true`. → F-GOV-014 |

---

## g. Security boundaries

*(Paths only; no secret values reproduced.)*

### g.1 API auth boundary — two divergent postures

| | `tiannara_api/main.py` | `tiannara_api/main_production.py` |
|---|---|---|
| Security middlewares | **5** + logging + CORS (`main.py:98-105`) | **0** — CORS only (`main_production.py:46-52`) |
| `ProductionAuthMiddleware` | installed (`:98`) | **absent** |
| `JWTContextMiddleware` | installed (`:99`) | absent |
| `SecurityHeadersMiddleware` | installed (`:100`) | absent |
| `InputValidationMiddleware` | installed (`:101`) | absent |
| `EnhancedRateLimiter` | installed (`:102`) | absent |
| Routers mounted | 40 | 13 |
| CORS default origins | `http://localhost:3000,http://127.0.0.1:3000` (`:111`) | same default (`:43-45`) |
| Version string | `1.3.0-phase5` (`:84`) | `1.4.0-monetization` (`:39`) |
| Admin bootstrap | creates `admin@tiannara.com` with `is_admin: true` on startup; password from `ADMIN_PASSWORD` or `secrets.token_urlsafe(16)` (`:294-336`) | absent |

**`ProductionAuthMiddleware` semantics** (`tiannara_api/middleware/production_auth.py`):
- Enabled **only** when `ENVIRONMENT=production`; default is `development` (`:73-76`) → **fail-open by default**.
- `PUBLIC_PREFIXES` includes `/api/v1/payment` (`:21`) → **the whole payment router is unauthenticated even in production**.
- `PROTECTED_PREFIXES` (`:30-40`) covers only 10 prefixes — e.g. `/api/v1/workflows`, `/api/v1/admin`,
  `/api/v1/auth`-adjacent surfaces, `/api/v1/collaboration`, `/api/v1/team`, `/api/v1/automations`,
  `/api/v1/analytics_insights`, `/api/v1/usage`, `/api/v1/white_label`, `/api/v1/mfa`, `/api/v1/sso`,
  `/api/v1/email_verification`, `/api/v1/mapek_security`, `/api/v1/alert_rules`, `/api/v1/explanations`,
  `/api/v1/efficiency`, `/api/v1/domains`, `/api/v1/unified`, `/api/v1/football`, `/api/v1/gateway_routes`
  are **not** in either list → unprotected in production.
- `tiannara_api/routes/payment.py:177` `@router.post("/admin/process-downgrades")` carries
  `# TODO: Add admin authentication check here` (`:191`) and the whole `/api/v1/payment` prefix is public
  → **unauthenticated admin mutation**. → confirms F-ARC-009 (independently_verified).

### g.2 Observatory auth boundary

- `apps/observatory_api/lib/observatory_api/plugs/auth.ex:13-25`: **dev-mode bypass** — when
  `ObservatoryCore.Config.env() == :dev`, the plug assigns `identity_id: "dev-bypass"`,
  `role: :administrator`, `capabilities: Rbac.Capability.all()`, `authenticated: true`, and **never calls
  the JWT verifier**. The bypass is keyed on a runtime env value with no production guard.
- Committed dev secrets (paths only): `tiannara_observatory/config/config.exs:14` `secret_key_base`,
  `:48` `rbac.jwt_secret`, `:22-23,29-30,36-37,43-44,52-53,59-60` six Postgres `username`/`password` pairs.
- CORS: `config.exs:9` `allow_origins` `*` and `endpoint.ex:36`.

### g.3 Cluster / deployment credential boundary

- `tiannara_runtime/k8s/phase6/overlays/production/kustomization.yaml:36-37` — `secretGenerator` with
  **literal** release cookie and NATS auth token (values redacted here). → F-PLT-005 / F-ARC-008.
- `docker-compose.yml:9` Postgres password literal; `:42` `JWT_SECRET_KEY` literal;
  `:39,58` `DATABASE_URL` with embedded password.
- `tiannara_observatory/config/config.exs` dev secrets (above).
- Root repo-root key-shaped files and a tracked binary (`MediaCreationTool_22H2.exe`, `Tiannara.exe`) → F-PLT-016.
- No secret scanning and no dependency scanning in any workflow → F-PLT-011.

### g.4 Trust boundaries

| Boundary | Mechanism | State |
|---|---|---|
| Browser → FastAPI | JWT (`gateway/auth.py`), API key (`X-API-Key`), cookies (`security/cookies.py`) | Partial; `ENVIRONMENT` gated |
| Browser → Observatory API | JWT via `Rbac.Token.verify/1` | **Dev bypass** |
| Browser → Next.js (`tiannara_saas`) | `next-auth` + Stripe | — |
| FastAPI → Elixir runtime | plain HTTP, **no auth**, `RUNTIME_API_URL = "http://localhost:4000/api"` (`tiannara_api/routes/observatory.py:38`) | Unauthenticated; **and the target path does not exist** → F-ARC-227 |
| Elixir runtime internal | `Registry`/`PubSub` (in-VM) | — |
| NATS boundary | **none** — the raw TCP listener on 4222 accepts anonymous JSON from any client and publishes it into the in-VM bus (`nats/connection.ex:52-68`) → any local process can inject events | → F-ARC-228 |
| Python ↔ Python | `tiannara_core` ↔ `tiannara_pros` import cycle (F-ARC-012) | — |

---

## h. Failure recovery

| Mechanism | Implementation | Verified state |
|---|---|---|
| Supervision restart | `:rest_for_one` (StartupSupervisor, RootSupervisor, Council, Ecology/Constraint layers), `:one_for_one` (root app, Meta, Observatory) | statically_inferred |
| Dynamic service restart | `Tiannara.CEL.Kernel.restart_service/2` — Council-gated; CEL services are `restart: :temporary` (`cel/kernel.ex:117`) so a crashed service **stays dead** until an operator-authorized restart | statically_inferred; F-GOV-017 (`:conditional` treated as allow) |
| Safe mode | `mix tiannara.start --safe` → profile `"safe-mode"` → phases `[:env, :runtime, :health]` (`tiannara.start.ex:11`, `:68-75`). **Safe mode is "skip infra/api/frontend" — no runtime safety semantics whatsoever.** | statically_inferred |
| Kill switch | `TiannaraRuntime.MultiWorld.KillSwitch` (+ `HardenedKillSwitch`, `Tiannara.MultiWorld.KillSwitchCausal`) — **none started**; consumer API `get_killed_worlds/0`/`request_kill/2`/`confirm_kill/2` **does not exist**; `SafetyCortex` `send`s to the unregistered `HardenedKillSwitch` outside any `try/rescue` | independently_verified → F-GOV-013 / BG-2 / F-ARC-234 |
| Rollback | `RollbackEngine` always `{:error, :rollback_unavailable}`; `ConstitutionRepository.rollback/2` rolls back the *constitution version* only; `world_mutation_engine.ex:593-600` flips a record and reverts nothing | F-GOV-014 |
| Audit-chain recovery | Council `AuditLog` DETS with `repair: true` fallback; **Merkle root computed but unconsumed**; degraded-mode reads return `[]`/`nil` silently | F-GOV-012 |
| CPL recovery | `recover/0` → report with `events_replayed` + `hash_verification_passed`; **does not restore subsystem state** (`runtime_restored: true` hard-coded) | statically_inferred |
| Executive recovery | `Tiannara.Executive.Recovery` (8.6 KB) — the only dedicated root recovery module | statically_inferred |
| Clean-shutdown marker | `TiannaraRuntime.OS.Persistence.ResurrectionEngine.mark_clean_shutdown()` called from CPL `terminate/2` (`constitutional_persistence_layer.ex:225`) — distinguishes clean from dirty shutdown | statically_inferred |
| Cron/periodic recovery | `ControlCenter` `run_health_check` + "Recovered #{id}" path (`control_center.ex:228`) — **but ControlCenter is never started** (BG-7) | statically_inferred → F-ARC-235 |
| Container restart | `docker-compose.yml` `restart:` policy — **not set on any service** (no `restart:` key) | statically_inferred |
| k8s recovery | KEDA ScaledObjects reference 4 deployments that **do not exist** → autoscaling never binds | F-ARC-008 |

---

## i. Relationship basis ledger (major flows)

| # | Flow | From → To | Basis | Evidence |
|---|---|---|---|---|
| L1 | Root app boot | `Tiannara.Application` → `Tiannara.Council.Supervisor` | statically_inferred | `lib/tiannara/application.ex:108` |
| L2 | Root app boot → CEL | `Tiannara.Application` → `Tiannara.CEL.Kernel.boot()` | statically_inferred | `lib/tiannara/application.ex:38` |
| L3 | CEL service boot | `CEL.Kernel` → `CEL.ServiceSupervisor` (DynamicSupervisor) | statically_inferred | `lib/tiannara/cel/kernel.ex:22`, `:117-124` |
| L4 | Council boot | `Council.Supervisor` → `AuditLog, MintRegistry, ConstitutionRepository, PolicyRegistry, HumanApprovalQueue, AmendmentEngine, ConstitutionalMonitor, Council` | statically_inferred | `lib/tiannara/council/supervisor.ex:9-16` |
| L5 | Runtime app boot | `TiannaraRuntime.Application` → `StartupSupervisor` | statically_inferred | `tiannara_runtime/lib/tiannara_runtime/application.ex:31` |
| L6 | Runtime boot | `StartupSupervisor` → CPL → Omega → COP → Endpoint → RootSupervisor → DiscoveryRunner | statically_inferred | `tiannara_runtime/lib/tiannara_runtime/startup_supervisor.ex:29-42` |
| L7 | Layer boot | `RootSupervisor` → Infrastructure/Execution/Ecology/Constraint/Meta | statically_inferred | `tiannara_runtime/lib/tiannara_runtime/runtime_layers/supervisors.ex:231-237` |
| L8 | Meta boot order | `Meta.Supervisor` → RateModulationSupervisor → ChronogramMatrix → MetaEvolutionStreamManager → MSCL → MCK → OCAL → OCG → OMRL | statically_inferred | `runtime_layers/supervisors.ex:189-206`; wiring audit §4.2 (W2 `07971bf9`) |
| L9 | App-level CIS chain | `TiannaraRuntime.Application` → `CIS.Supervisor` → `CIS.ExecutionController` → `QuotaGovernor` → `LineageCompression` → `GCK` | statically_inferred | `application.ex:33-37`; wiring audit §4.1 (W1 `3690efbd`) |
| L10 | NATS "bus" | `NATS.Supervisor` → `NATS.Bus` (Registry) + `NATS.Connection` (raw TCP 4222) + Publisher + Subscriber | statically_inferred | `tiannara_runtime/lib/tiannara_runtime/nats/supervisor.ex:10-15` |
| L11 | NATS injection path | TCP client → `NATS.Connection.handle_client/1` → `NATS.Bus.publish/2` | statically_inferred | `nats/connection.ex:52-68` |
| L12 | Real NATS client | `EventGateway` → `Gnat.pub/sub` | **statically_inferred that it CANNOT fire** (hard-coded `{:error, :unavailable}`) | `event_gateway.ex:182-185` |
| L13 | EventBus round-trip | `OLEF.PressureSolver` → `Tiannara.EventBus.broadcast("field.pressure_changed")` → `Registry.dispatch` → subscribers | statically_inferred | `olef/pressure_solver.ex:14,20,28`; `event_bus.ex:35-37` |
| L14 | EventBus → telemetry | `EventBus.broadcast` → `:telemetry.execute([:tiannara, :event_bus, …])` | statically_inferred | `event_bus.ex:31` |
| L15 | Telemetry publisher → consumer | `Monitoring.TelemetryPublisher` → `:telemetry.execute([:tiannara_runtime, :cold_ignition, ch])` → `ColdIgnitionSupport` handler | statically_inferred | `monitoring/telemetry_publisher.ex:119`; `monitoring/cold_ignition_support.ex:9-10` |
| L16 | Telemetry publisher → data source | `TelemetryPublisher.build_metrics` → `Tiannara.UniverseServer.snapshot()` | statically_inferred | `monitoring/telemetry_publisher.ex:148` |
| L17 | OMRL → bus | `Meta.ObserverMemoryReconciliation` → `NATS.MetaEvolutionStreamManager.publish/2` → `NATS.Bus.publish/2` | statically_inferred | wiring audit §4.2; `meta_evolution_stream_manager.ex:69-73` |
| L18 | CPL persistence | `CPL.record_event/2` → `<storage_path>/events/*.json`; `create_checkpoint/2` → `<storage_path>/checkpoints/<layer>/*.json` | statically_inferred | `constitutional_persistence_layer.ex:390-406` |
| L19 | CPL recovery | CPL `init` → `load_existing_state/1` → `load_events/1` + `load_checkpoints/1` → `normalize_event_keys/1` + `normalize_checkpoint_keys/1` | statically_inferred | `constitutional_persistence_layer.ex:103,408-425,497-510` |
| L20 | CPL ↔ telemetry (failure) | CPL checkpoint crash → `TiannaraRuntime.Monitoring.TelemetryPublisher` restart → "no telemetry message loss" test failure | **documented** (CI-bound, not independently re-run) | `TIANNARA_RUNTIME_TEST_INVENTORY.md:148`, CI run `39382482185` @ `d4747586`; fix `c7214a50` |
| L21 | Python → Elixir observatory | `tiannara_api/routes/observatory.py` `call_runtime_api("/calibration/worlds")` → `http://localhost:4000/api/calibration/worlds` → **no such route on any Elixir app** → `except` → `MOCK_WORLDS` | statically_inferred | `observatory.py:38,47,599-605`; runtime router `tiannara_runtime_web/router.ex:8-63`; root router `lib/tiannara/web/router.ex:22-84` → **F-ARC-227** |
| L22 | Python → Elixir (health) | `GET {RUNTIME_API_URL}/health` → `http://localhost:4000/api/health` → root app has `/api/health` (`router.ex:72`) → returns a CRAV health JSON, not the runtime's status | statically_inferred | `observatory.py:483`; `lib/tiannara/web/router.ex:72` |
| L23 | API → gateway engines | `main.py` startup hook → `gateway.routing.register_engine/2` × 5 → `ROUTE_MAP` endpoints | statically_inferred | `main.py:277-285`; `gateway/routing.py:19-27` |
| L24 | API → tiannara_core | `main.py` imports `tiannara_core.{autonomous,discovery,evolution,memory,mission,modules,safety}` | statically_inferred | `main.py:69-80` |
| L25 | tiannara_core ↔ tiannara_pros | `tiannara_core/integration/pros_adapter.py` → `motor_controller` (tiannara_pros); 10+ reverse imports | statically_inferred | confirms F-ARC-012 |
| L26 | Observatory API → Postgres | `ObservatoryApi.Repo` → 6 configured DBs | statically_inferred | `application.ex:8`; `config/config.exs:22-60` |
| L27 | Umbrella app → umbrella app | `observatory_api` → 9 in-umbrella deps | statically_inferred | `apps/observatory_api/mix.exs:35-47` |
| L28 | Launch → runtime app | `mix tiannara.start` → `:telemetry`, `:tiannara` — **NOT** `:tiannara_runtime` | statically_inferred | `lib/mix/tasks/tiannara.start.ex:23,120-134` → **F-ARC-226** |
| L29 | ControlCenter → subsystems | `ControlCenter.init/1` → `module.start_link([])` for ~29 modules, **no supervisor** | statically_inferred | `lib/tiannara/control_center.ex:57-82,189-208` → **F-ARC-235** |
| L30 | CI → runtime suite | `elixir_ci.yml` job `tiannara-runtime-suite` → `mix test --exclude quarantine` in `tiannara_runtime/` | documented (CI-bound) | `.github/workflows/elixir_ci.yml:110-135`; green run `39388434031` @ `c7214a50` |
| L31 | CI → Python suite | `ci-cd.yml` job `test` → `pytest tests/` — **never runs on `local/pr4`** (trigger `[main, master]`) | documented | `.github/workflows/ci-cd.yml:5,49` → F-PLT-004 |
| L32 | CI → Docker image | `ci-cd.yml` job `build` → `Dockerfile.production` → ghcr — **never runs on `local/pr4`** | documented | `.github/workflows/ci-cd.yml:104-151` |
| L33 | k8s overlay → base | `overlays/production/kustomization.yaml` → `../../base` (no `kustomization.yaml`) → **build fails** | statically_inferred | `tiannara_runtime/k8s/phase6/overlays/production/kustomization.yaml:5`; `base/` listing → F-PLT-005 |

> Baseline note: `certification/atlas/baseline.md:48` records that `ci-cd.yml` "runs on pushes to `local/pr5`,
> `local/pr6` only". The file itself declares `branches: [main, master]` (`.github/workflows/ci-cd.yml:5`).
> The file is authoritative; **the baseline line is wrong**. F-PLT-004 already flagged this; R0 re-verified it.

---

## Draft findings (F-ARC-226 .. F-ARC-236)

> These are **drafts**, not ratified. Each cites primary source. Severity uses the problems_G.md scale
> (critical > high > medium > low). "Confirm" = a single re-read of the cited file.

### F-ARC-226 — The launcher never starts the runtime application: the entire second OTP root is unreachable
- **Severity:** high · **Confidence:** confirmed (static)
- **Category:** boot gap / undocumented interface
- **Evidence:** `lib/mix/tasks/tiannara.start.ex:23` `@runtime_subsystems [:telemetry, :tiannara]` and
  `:120-134` (`Mix.Task.run("app.start")` then `Application.ensure_all_started/1` over that list) —
  `:tiannara_runtime` is **not** started. The root release lists only `tiannara`, `phoenix`, `plug_cowboy`
  (`mix.exs:34-41`). `Procfile` declares only `uvicorn tiannara_api.main:app`. `docker-compose.yml` has no
  Elixir service. `start.bat`/`start-production.bat` call `mix tiannara.start` (root project).
  The runtime project is reachable only by `cd tiannara_runtime && mix …` (as `elixir_ci.yml` does for
  tests) — a path with **no** launcher, script, Dockerfile, k8s manifest, or release.
- **Consequence:** the whole `StartupSupervisor` tree (CPL, Omega, COP, Endpoint, RootSupervisor,
  DiscoveryRunner) **and** the application-level CIS safety stack (W1 `3690efbd`) are boot-verified only
  by unit/boot tests, never by a runnable product path. Every "wired" claim in the wiring audit is
  therefore a *test-time* wiring claim, not a *deployment* wiring claim.
- **Affected caps:** all runtime caps; the entire W1/W2/W3 wiring workstream.
- **Minimal remediation:** decide the deployment topology (one release with both apps vs two services),
  then add the runtime app to the release/launcher/compose and prove it with a boot smoke test.
- **Acceptance criteria:** a documented start path boots `:tiannara_runtime`; a CI job asserts
  `StartupSupervisor.all_running?/0 == true` after that path runs.

### F-ARC-227 — The Python → Elixir observatory edge is permanently on the mock path
- **Severity:** high · **Confidence:** confirmed (static)
- **Category:** flow break / test-vs-production mismatch
- **Evidence:** `tiannara_api/routes/observatory.py:38` `RUNTIME_API_URL = "http://localhost:4000/api"`.
  (a) Port 4000 is the **root** app's Phoenix endpoint (`config/dev.exs:10`); the runtime endpoint is
  **8004** in dev / **4001** in test (`tiannara_runtime/config/{dev,test}.exs`). (b) The path
  `/api/calibration/worlds` **does not exist** in either Elixir app: the runtime router exposes
  `/api/v1/observatory/worlds` and `/api/v1/observatory/worlds/:id/intervene`
  (`tiannara_runtime/lib/tiannara_runtime_web/router.ex:28-29`), and the root router's `/api` scope has no
  `calibration` entry (`lib/tiannara/web/router.ex:49-84`). (c) `git grep "calibration/worlds"` over `*.ex`/`*.exs`
  returns **zero** hits.
  Therefore `call_runtime_api("/calibration/worlds")` (`:599`) always raises, and the `except` branch
  (`:601-605`) always serves `MOCK_WORLDS`; the same applies to `POST /calibration/intervene` (`:619-643`),
  which mutates in-memory mock worlds and reports `"applied in-memory"`.
- **Consequence:** the API never reaches the runtime; the "high-fidelity simulation" is the **only** behaviour.
  This resolves F-WRD-001's open "unknown" (whether the Elixir endpoint exists) — **it does not** — and
  upgrades it to a confirmed flow break. It also means every committed
  `reports/world_health_epoch_*.csv` is doubly orphaned: generated by the mock, and the mock is the only path.
- **Affected caps:** observatory/observability, world-model reporting, the 12-worlds/84-civ/23 800-agent claim.
- **Minimal remediation:** point `RUNTIME_API_URL` at the correct app/port and use the existing
  `/api/v1/observatory/worlds` route; delete the mock fallback (fail loudly) per F-ARC-016(c).
- **Acceptance criteria:** a route test asserts a live response from the runtime and asserts **no**
  `MOCK_WORLDS` on backend outage (the request must fail, not fabricate).

### F-ARC-228 — The boot-wired "NATS" is an in-VM loopback with an anonymous TCP injector; the real client is hard-disabled
- **Severity:** high · **Confidence:** confirmed (static)
- **Category:** conflicting authority / security boundary / undocumented interface
- **Evidence:** `tiannara_runtime/lib/tiannara_runtime/nats/bus.ex:4-31` — `TiannaraRuntime.NATS.Bus` is a
  `Registry` broadcast with `*`/`>` subject matching; `nats/connection.ex:15-30` opens a **plain `:gen_tcp`
  listener** on `NATS_PORT` (default 4222) and `nats/connection.ex:52-68` accepts **anonymous** newline-JSON
  `{"subject":…,"payload":…}` from any client and republishes it into the in-VM bus with **no auth, no
  validation, no allow-list**. `nats/supervisor.ex:10-15` starts it as a **required** Infrastructure child
  (`runtime_layers/supervisors.ex:80`). The only `gnat`-based client, `TiannaraRuntime.EventGateway`,
  has `connect_nats/0` hard-coded to `{:error, :unavailable}` (`event_gateway.ex:182-185`) and is in no
  boot tree. `Tiannara.NATS.MetaEvolutionStreamManager.get_status/0` reports **`connected: true`**
  unconditionally (`nats/meta_evolution_stream_manager.ex:17`, `:79-86`). Finally,
  `config/config.exs:15-18` configures `TiannaraRuntime.NATS.ConnectionManager` — **no such module exists**
  in `tiannara_runtime/lib/tiannara_runtime/nats/` (directory listing has no `connection_manager.ex`) →
  dead configuration key.
- **Consequence:** (i) a local process can inject arbitrary events into the runtime's event fabric;
  (ii) the deployed `nats-cluster` StatefulSet (`k8s/phase6/base/nats-cluster.yaml`) would **conflict on
  port 4222** with the in-VM listener; (iii) health dashboards report a healthy NATS link that does not exist.
- **Affected caps:** messaging, mesh/reality bus, OLEF pressure stream, OPC bus, observer stack.
- **Minimal remediation:** choose one transport per app (real `gnat` client, or an explicitly-named in-VM bus
  with the TCP listener removed or authenticated); delete the dead `ConnectionManager` config or implement it.
- **Acceptance criteria:** no plaintext TCP listener in the runtime boot path; `get_status/0` reflects the
  real connection state; the config file has no key without a consuming module.

### F-ARC-229 — No artifact is produced for any deployable unit, and the runtime cannot be packaged at all
- **Severity:** high · **Confidence:** confirmed (static)
- **Category:** build/deployment gap
- **Evidence:** the root `mix.exs:32-42` defines a `tiannara` release (steps `[:assemble, :tar]`) but **no
  workflow invokes `mix release`** (the 5 tracked workflows contain no `mix release`); `tiannara_runtime/mix.exs`
  has **no `releases/0`**, so it cannot be packaged at all, and `tiannara_runtime/config/prod.exs` is missing
  while `config/config.exs:57` does `import_config "#{Mix.env()}.exs"` → `MIX_ENV=prod` fails at compile.
  `tiannara_observatory/mix.exs` has no `releases/0` either. The only images built anywhere are the four
  Dockerfiles (all Python / Node) — **no image contains an Elixir runtime**.
- **Consequence:** the "production" artefacts in this repository are the Python API image and two broken
  static/Node images. Neither Elixir application has a deployable artefact, and the runtime app cannot
  even compile in prod.
- **Affected caps:** deployment/ops, all Elixir caps.
- **Minimal remediation:** add `config/prod.exs` (fail-closed, env-required) for `tiannara_runtime`, add
  `releases/0` to both Elixir projects, and add a CI job that produces the release tarball.
- **Acceptance criteria:** `MIX_ENV=prod mix compile` succeeds from a clean checkout in `tiannara_runtime`;
  `mix release` produces a tarball in CI; the k8s runtime image references that artefact.

### F-ARC-230 — The API container health check probes a route that does not exist
- **Severity:** medium · **Confidence:** confirmed (static)
- **Category:** build/deployment defect
- **Evidence:** `docker/api/Dockerfile:26-27`
  `HEALTHCHECK … CMD curl -f http://localhost:8000/api/v1/health || exit 1`.
  The FastAPI app exposes `GET /health` at the **root** (`tiannara_api/main.py:339`); no router defines
  `/api/v1/health` (`git grep` over `tiannara_api` finds no such path). The `status` router defines
  `/status` (`tiannara_api/routes/status.py:8`). `Dockerfile.production:55-56` probes
  `http://localhost:8000/health` — **correct**.
- **Consequence:** every container built from `docker/api/Dockerfile` (which is what `docker-compose.yml`
  builds, `docker-compose.yml:33-35`) reports **unhealthy** forever; any orchestrator that gates on
  health will never route traffic.
- **Affected caps:** deployment/ops, API availability.
- **Minimal remediation:** change the probe to `/health`, or add an `/api/v1/health` alias; add a smoke step
  that builds the image and asserts the healthcheck passes.
- **Acceptance criteria:** `docker build -f docker/api/Dockerfile` + `docker run` reports healthy.

### F-ARC-231 — The SaaS container image cannot be built (static-export assumption vs server-rewrite reality)
- **Severity:** medium · **Confidence:** confirmed (static)
- **Category:** build/deployment defect
- **Evidence:** `docker/saas/Dockerfile:26` `COPY --from=builder /app/out /usr/share/nginx/html`, but
  `tiannara_saas/next.config.ts` uses **server-side `rewrites()`** to `API_UPSTREAM_URL`
  (default `http://127.0.0.1:8004`) and declares **no `output: "export"`**. `next build` therefore writes
  to `.next/`, and `/app/out` is never created → the `COPY` fails at image-build time.
- **Consequence:** sharpens F-PLT-010 — the SaaS image is not merely "incompatible with server rewrites",
  it **cannot be produced at all**; and even if it could, a static nginx image cannot serve `/api/v1/*`
  rewrites.
- **Affected caps:** SaaS UI, deployment.
- **Minimal remediation:** use `output: "export"` and remove rewrites (client-side fetch), or run
  `next start` in the image instead of nginx.
- **Acceptance criteria:** `docker build -f docker/saas/Dockerfile .` succeeds and the served app can reach
  the API through the documented path.

### F-ARC-232 — The launcher's "required services" (Postgres, Redis) are not consumed by any Elixir code
- **Severity:** medium · **Confidence:** confirmed (static)
- **Category:** documented-vs-implementation gap / hidden dependency
- **Evidence:** `lib/mix/tasks/tiannara.start.ex:17-21` declares PostgreSQL (5432), Redis (6379), NATS (4222)
  as *required* services and `:89-91` probes them; neither `mix.exs` nor `tiannara_runtime/mix.exs` declares
  `ecto`, `postgrex`, `redis`, or any DB client (dependency lists inspected). The only Postgres consumer in
  the repo is the Python API (`tiannara_api/database/__init__.py:26`) and the umbrella (`ecto_sql`,
  `postgrex` in `apps/observatory_api/mix.exs:35-36`). The only Redis consumer anywhere is
  `docker-compose.yml:20-30` (a service no image reads `REDIS_URL` from except `tiannara-api`/`tiannara-core`,
  which set it but do not use it in tracked code — `git grep REDIS_URL` returns only compose + Dockerfile).
- **Consequence:** the launcher's env check can report "ready" for infrastructure that the Elixir stack
  never touches, and the `ENVIRONMENT`/`REDIS_URL` variables in compose create the impression of a
  Redis-backed session/rate-limit store that does not exist (rate limiting is in-process
  `EnhancedRateLimiter`).
- **Affected caps:** platform, deployment.
- **Minimal remediation:** either wire Postgres/Redis into the Elixir stack or remove them from the
  launcher's required set and from compose.
- **Acceptance criteria:** every service in `@required_services` has a tracked consumer in the process the
  launcher starts, or is removed from the list.

### F-ARC-233 — The Observatory umbrella is outside every build and CI path
- **Severity:** medium · **Confidence:** confirmed (static)
- **Category:** CI blind spot / build gap
- **Evidence:** `tiannara_observatory/.github/workflows/ci.yml` exists on disk (Elixir compile+test with
  `--warnings-as-errors`, `mix format --check-formatted`, Node lint/tsc/vitest/build, and two Docker builds)
  but is **untracked** — `git ls-files tiannara_observatory/.github` returns **0** files. The umbrella is
  therefore never built or tested by any workflow in this repository. Additionally
  `tiannara_observatory/mix.exs:7-18` lists 10 apps and **omits `observatory_ui`**, which has no
  `mix.exs` — so `mix` never compiles the Next.js UI even locally.
- **Consequence:** 499 tracked umbrella files (10 apps, incl. `observatory_api` with 11 controllers,
  8 channels, 6 Hub GenServers, a dev auth bypass and committed secrets) have **zero** CI coverage in this
  repo, and their own CI file is not even version-controlled. → sharpens F-ARC-019 / F-ARC-015.
- **Affected caps:** observatory API, RBAC, telemetry gateway, event/replay/state stores.
- **Minimal remediation:** track `tiannara_observatory/.github/workflows/ci.yml` and add an umbrella job to
  the branch-spanning workflow (or move the umbrella to its own repository with a pinned SHA).
- **Acceptance criteria:** every push compiles and tests the umbrella; `observatory_ui` is either an
  umbrella app or has its own CI job.

### F-ARC-234 — The multi-world runtime surface is unreachable: the supervised module exists only in Markdown
- **Severity:** critical · **Confidence:** confirmed (static)
- **Category:** boot gap / flow break
- **Evidence:** `tiannara_runtime/lib/tiannara_runtime/multi_world/world_supervisor.ex:58` supervises
  `TiannaraRuntime.MultiWorld.WorldProcess`; the only occurrence of that module name in the whole repo is
  `tiannara_runtime/lib/tiannara_runtime/multi_world/fixes.md:1757` — **a Markdown file**, not source.
  `world_supervisor.ex:111,136,140` call `KillSwitch.get_killed_worlds/0`, `request_kill/2`, `confirm_kill/2`;
  the unified module `multi_world/kill_switch.ex:82-128` exposes `request_termination/3`,
  `emergency_kill/2`, `get_kill_status/1` — **none of the three called functions exist**. No supervisor in
  either Elixir project starts `TiannaraRuntime.MultiWorld.KillSwitch`,
  `multi_world/hardened_kill_switch.ex` or `multi_world/kill_switch_causal.ex`.
  `tiannara_runtime/lib/tiannara_runtime/cortex/safety_cortex.ex:393` `send`s to the unregistered
  `HardenedKillSwitch` outside any `try/rescue` (contrast `:396-400`).
- **Consequence:** the multi-world control plane cannot start, cannot be killed, and its safety-cortex
  emergency path raises. This is F-WRD-004 + F-GOV-013 with the concrete markdown-only module proven.
- **Affected caps:** world management, safety chain, Safe Mode, CAP-WRD-004.
- **Minimal remediation:** implement or delete `WorldProcess`; reconcile the KillSwitch API; wire the
  kill switch under a supervisor; guard the SafetyCortex send.
- **Acceptance criteria:** a boot test starts the multi-world tree; a contract test covers
  request→confirm→get_killed; `mix compile` emits no undefined-function warnings.

### F-ARC-235 — `Tiannara.ControlCenter` — the documented owner of ~29 subsystems — is in no boot tree
- **Severity:** high · **Confidence:** confirmed (static)
- **Category:** boot gap / undocumented interface
- **Evidence:** `lib/tiannara/control_center.ex:1` defines `Tiannara.ControlCenter`; `init/1` (`:57-82`)
  calls `boot_all_subsystems/1` → `start_subsystem/2` (`:189-208`), which calls `module.start_link([])`
  from inside `GenServer.init` — so those subsystems are **linked to the ControlCenter process, not to any
  Supervisor** (restating F-WRD-010). **New in this pass:** `Tiannara.ControlCenter` is **not a child of
  any supervisor** — `lib/tiannara/application.ex` mentions it only in a comment (`:75`); `git grep
  ControlCenter -- lib` returns only `control_center.ex` itself, `architecture/reconciliation.ex:30`
  (a string map), `observability.ex:129,137` (reads `ControlCenter.uptime/0` and `ControlCenter.status/0`
  — **never started**), and comments in `discovery_scheduler.ex:33` and `discovery/steps/provider_seeder.ex:18`
  that *depend on* ControlCenter's boot ordering ("CapabilityGraph is booted before this scheduler by
  ControlCenter").
- **Consequence:** the modules that other code explicitly documents as "booted by ControlCenter"
  (`CapabilityGraph`, `DiscoveryScheduler` ordering) are **not booted at all** in the current root
  application; the ordering contract is documentation-only. The periodic health-check / recovery /
  constitutional-audit loop (`control_center.ex:210-256, 300, 334`) that would be the root project's
  **only** self-healing mechanism never runs.
- **Affected caps:** discovery pipeline, capability graph, operations self-healing, Section D research.
- **Minimal remediation:** decide whether ControlCenter is the Section D boot authority; if yes, add it as
  a supervised child and move its subsystem boot into a `Supervisor` (or a `DynamicSupervisor`) so restart
  semantics are defined; if no, correct the ordering comments and `observability.ex` to not depend on it.
- **Acceptance criteria:** either ControlCenter is a supervised child with a boot test asserting its
  subsystems are alive, or all references to it as a boot authority are removed and the dependent modules
  are given real owners.

### F-ARC-236 — `Phoenix.PubSub` and `Registry` ownership is duplicated across two Elixir applications with colliding intent
- **Severity:** low · **Confidence:** confirmed (static)
- **Category:** duplicate implementation
- **Evidence:** the root app starts `{Phoenix.PubSub, name: Tiannara.PubSub}` (`lib/tiannara/application.ex:208`)
  and the runtime starts `{Phoenix.PubSub, name: TiannaraRuntime.PubSub}` plus two `Registry`s
  (`runtime_layers/supervisors.ex:72-77`). Both projects also depend on `forward_provenance`
  (`mix.exs:67`, `tiannara_runtime/mix.exs:32`) — the **only** shared contract library between them
  (F-ARC-020). The root project additionally declares 28 module names that the runtime also compiles
  (F-ARC-001), so a future co-deployment in one VM would have two `Tiannara.*` namespaces and two
  `Phoenix.PubSub` instances with different names but overlapping purpose.
- **Consequence:** low today (separate VMs), but it is the concrete mechanism by which the 28 duplicate
  modules would shadow each other, and it is the reason the co-VM intent implied by
  `lib/tiannara/crav/runtime_atlas.ex:582` / `crav/runtime_census.ex:246`
  (`Process.whereis(TiannaraRuntime.StartupSupervisor)`) is dangerous.
- **Affected caps:** messaging, cross-project coupling (F-ARC-013).
- **Minimal remediation:** fold the PubSub/Registry ownership into the decision register together with
  F-ARC-001's per-namespace owner table.
- **Acceptance criteria:** one PubSub owner per deployed app recorded; the co-VM probe list is configurable
  (F-ARC-013 acceptance).

---

## Explicit unknowns (k)

| ID | Unknown | Why it could not be closed here |
|---|---|---|
| U1 | Whether any Elixir application **actually boots** end-to-end in a clean checkout of `521cb7fe`. | No compile/boot was run (read-only mandate). CI-green at the same SHA is a *test* signal on a subset, not a boot proof. |
| U2 | Whether `tiannara_runtime` compiles at all at `521cb7fe` (≈700 warning lines were measured at an earlier SHA; `elixirc_options: [warnings_as_errors: false]` in `tiannara_runtime/mix.exs:15` means warnings do not fail the build — but `phase_5f2_tests.yml:52` compiles with `--warnings-as-errors`, which would fail). | No compile run. |
| U3 | Runtime behaviour of the NATS raw TCP listener under concurrency, and whether the deployed `nats-cluster` StatefulSet actually conflicts on port 4222. | No environment; no boot. |
| U4 | Whether the `observatory_ui` Next.js app is served by anything in production (`tiannara.start` only *checks that the directory exists*, `tiannara.start.ex:150-157`; it never builds or starts it). | Static read only; no deployment evidence exists in-repo. |
| U5 | Whether the root `mix.exs` release (`:32-42`) has ever been produced. No artifact, log, or workflow invocation exists in-repo. | No CI history access in this pass (no network); baseline records only workflow runs. |
| U6 | The real content of the `data/cpl/**` checkpoint and event files (i.e. whether the hash chain currently verifies) and the current state of the 31 modified tracked `*.dets` files. | Files are dirty and uncommitted; reading them is safe but interpreting "expected" content requires the runtime's own verification, which was not run. |
| U7 | Whether `tiannara_core`'s ~70 sub-packages are all importable and whether `tiannara_pros` hardware IO is exercised anywhere. F-ARC-012 (import cycle) is confirmed statically but its runtime effect is untested. | No import/pytest run. |
| U8 | The exact composition of the umbrella's `shared` and `observatory_core` apps (both have no `application.ex`); their boot semantics are undefined because the umbrella has no root `mod:`. | Static read of `mix.exs` files only. |
| U9 | Whether the 4 orphan KEDA ScaledObjects ever bound to live workloads in a cluster outside this checkout. | No cluster access. |
| U10 | Whether the `tiannara_gui` / `tiannara_internal_dashboard` / `tiannara_mobile` directories correspond to any released artefact (they are absent-in-git and may live in another repository). | Out of this checkout. |

---

## Cross-references (l)

- `certification/atlas/deps_runtime.json` — machine-readable runtime/data-flow graph produced by this pass.
- `certification/atlas/deps_build.json` — machine-readable build/test/deploy graph produced by this pass.
- `certification/atlas/problems_G.md` — F-ARC-001..025 (this pass adds drafts F-ARC-226..236).
- `certification/audit/PHASE_5F_WIRING_AUDIT.md` — the boot-tree source of truth this pass re-derived.
- `certification/atlas/capabilities_C_governance.md` — F-GOV-001..023 (governance flows).
