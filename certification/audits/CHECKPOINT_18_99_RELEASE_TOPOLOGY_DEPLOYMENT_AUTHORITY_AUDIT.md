# Checkpoint 18.99 — Release Topology and Deployment Authority Audit

**Disposition:** OPEN — project/release boundaries statically mapped; no deployable artifact was built or executed. Production bootability is not established.

**Source baseline:** `b829254d032f9e0b5cf4c44725c8cf451800dad0`  
**Repository:** `Kimiti4/Tiannara`  
**Audit branch:** `audit/consolidated-findings-r0a-2026-10-31`  
**Method:** Read-only inspection of Mix projects, application callbacks, release declarations, container definitions, and deployment documentation. No production code, configuration, tests, or runtime processes were changed or executed.

## 1. Executive determination

The repository contains multiple independent application/build products, not one unified Tiannara release:

1. **Root Elixir application — `:tiannara`**. Root `mix.exs` defines a release named `tiannara`, with `Tiannara.Application` as its OTP callback. Its compile paths are root `lib`; its declared dependencies do not include `:tiannara_runtime`.
2. **Runtime Elixir application — `:tiannara_runtime`**. `tiannara_runtime/mix.exs` defines a separate Mix project and `TiannaraRuntime.Application` callback. Its own startup supervisor starts CPL, Omega, Observatory, Endpoint, RootSupervisor, and DiscoveryRunner. Its Quick Start documents a separate `tiannara_runtime` release build.
3. **Observatory umbrella — `:observatory_api` plus nine umbrella apps**. `tiannara_observatory/mix.exs` declares its own umbrella app set. `tiannara_observatory/Dockerfile.api` builds and packages `observatory_api` as its own release.
4. **Python API/core containers**. Root `docker-compose.yml` orchestrates Python API and core containers with Postgres and Redis. It does not start either Elixir application or the Observatory umbrella.
5. **SaaS frontend**. `tiannara_saas/package.json` defines a separate Next.js app. The root Compose file does not include it.

These boundaries materially qualify Checkpoint 18.98's duplicate module findings: the root and runtime definitions of `Tiannara.OED.Supervisor` and `Tiannara.Sentinel.Supervisor` are in separate Mix projects with separate compile roots. They are **not automatically co-loaded into the root `:tiannara` release**. A module-name collision is only a deployment risk if a future/custom artifact compiles both source roots or loads both BEAM sets into one VM. No such combined artifact is established by the inspected release declarations.

However, the repository does not supply a verified deployment manifest connecting the separate releases, their authority boundaries, their NATS/API interfaces, and their lifecycle. There are also missing environment-specific production config files referenced by both Elixir config roots, and a Python production Dockerfile references a missing requirements file.

## 2. Build and release inventory

| Product | Build root / application | Entry point | Deployment evidence | Status |
|---|---|---|---|---|
| Root Elixir | repository root; app `:tiannara` | `Tiannara.Application` | Explicit `releases/0` declaration; release name `tiannara` | RELEASE_DECLARED; PROD_CONFIG_MISSING |
| Runtime Elixir | `tiannara_runtime/`; app `:tiannara_runtime` | `TiannaraRuntime.Application` | Separate Quick Start documents `MIX_ENV=prod mix release` and `tiannara_runtime/bin/tiannara_runtime start` | SEPARATE_PROJECT; PROD_CONFIG_MISSING |
| Observatory | `tiannara_observatory/`; umbrella app `:observatory_api` + nine apps | `ObservatoryApi.Application` | Dedicated `Dockerfile.api` runs `mix release` and copies `observatory_api` release | SEPARATE_RELEASE |
| Python API | root Docker context; `tiannara_api` | Uvicorn `tiannara_api.main:app` | `docker/api/Dockerfile`, root Compose service | CONTAINER_DEFINED |
| Python core | root Docker context; `tiannara_core` | `python -m tiannara_core.autonomous.loop` | `docker/core/Dockerfile`, root Compose service | CONTAINER_DEFINED |
| Python legacy image | root context; API | Uvicorn `tiannara_api.main:app` | `Dockerfile.production` | BUILD_INPUT_MISSING |
| SaaS frontend | `tiannara_saas/`; Next.js | Next.js scripts | package manifest and deployment guide; no root Compose service | SEPARATE_APP; DEPLOYMENT_UNVERIFIED |

### Root Elixir release

Root `mix.exs` declares:
- `app: :tiannara`;
- `elixir: ~> 1.15`;
- `elixirc_paths(:test) = ["lib", "test/support"]` and otherwise only `["lib"]`;
- a release named `tiannara`;
- release applications `:tiannara`, `:phoenix`, and `:plug_cowboy`;
- OTP callback `Tiannara.Application`;
- path dependency `forward_provenance`.

It does not declare `:tiannara_runtime`, `tiannara_observatory`, or the Python services as dependencies. The root release therefore does not compile the runtime Mix project's `lib` tree by virtue of the repository layout alone.

Root `Tiannara.Application` starts the root application tree, including Council, CEL, root Core, Stabilization, Sentinel, CIS, and other root subsystems. This is a different application tree from `TiannaraRuntime.StartupSupervisor`.

### Runtime Elixir project

`tiannara_runtime/mix.exs` declares `app: :tiannara_runtime`, `TiannaraRuntime.Application`, Elixir `~> 1.14`, and a separate dependency set. Its path dependency to `forward_provenance` resolves to `../forward_provenance`.

`TiannaraRuntime.Application` starts `TiannaraRuntime.StartupSupervisor`. That supervisor starts:
1. ConstitutionalPersistenceLayer;
2. Omega.Supervisor;
3. OS.Observatory;
4. Runtime Phoenix Endpoint;
5. RootSupervisor;
6. DiscoveryRunner.

The runtime's Quick Start explicitly documents a separate release build under `tiannara_runtime/_build/prod/rel/tiannara_runtime/`. The Mix file does not declare a custom `releases/0` block; the documentation is evidence of intended default Mix release usage, not evidence that a release was successfully built.

### Observatory umbrella

`tiannara_observatory/mix.exs` declares an umbrella with ten apps:
`:shared`, `:observatory_core`, `:telemetry_gateway`, `:event_store`, `:metrics_engine`, `:replay_store`, `:observatory_state`, `:observatory_api`, `:rbac`, and `:observation_bus`.

`observatory_api/mix.exs` depends on the nine sibling apps with `in_umbrella: true`; its application callback starts the Repo, PubSub, event dispatcher, stream engine, subscription registry, alert engine, mission broadcaster, COB bridge, and Endpoint.

`tiannara_observatory/Dockerfile.api` is a separate Elixir release build: it copies umbrella `mix.exs`, `mix.lock`, `config/`, and `apps/`, runs `mix deps.get --only prod`, `mix compile --warnings-as-errors`, `mix phx.digest`, and `mix release`, then copies `_build/prod/rel/observatory_api` into a runtime image. It is not the root `:tiannara` release or the `:tiannara_runtime` project.

## 3. Production configuration and build blockers

### Root Elixir config

Root `config/config.exs` ends with `import_config "#{config_env()}.exs"`. The expected production import is therefore `config/prod.exs`. That file was not present at the audited baseline (repository path lookup returned NOT_FOUND). No root `config/runtime.exs` was found either.

**Impact:** the checked-in root configuration does not provide its referenced production environment file. A production config evaluation/build is not established and is expected to fail at the missing import unless that file is generated or supplied outside the repository. No build was run to validate the exact Mix failure.

### Runtime Elixir config

`tiannara_runtime/config/config.exs` likewise imports `#{Mix.env()}.exs`; `tiannara_runtime/config/prod.exs` and `runtime.exs` were not present at the audited baseline. The runtime Quick Start says to create environment-specific files as needed and documents a production release command, but does not provide the required production config in the inspected tree.

**Impact:** runtime production release/boot is not reproducible from the committed configuration alone. Treat production release readiness as UNKNOWN/blocked until the production config and required secrets/endpoints are versioned or securely injected through a verified runtime configuration mechanism.

### Python production Dockerfile

Root `Dockerfile.production` contains:
- `COPY requirements-production.txt .`;
- `RUN pip install ... -r requirements-production.txt`;
- copies of `tiannara_core/`, `tiannara_api/`, `mindcache/`, and `runs/`;
- `COPY docker-entrypoint.sh`;
- Uvicorn API command.

The referenced root `requirements-production.txt` was not present at the audited baseline. The entrypoint script does exist. The missing requirements file is a direct static build-context defect for this Dockerfile. This does not affect the separate `docker/api/Dockerfile`, which uses the present root `requirements.txt`.

No Docker build was run.

## 4. Container and service topology

The checked-in root `docker-compose.yml` defines four services:
- Postgres 15;
- Redis 7;
- `tiannara-api`, built from `docker/api/Dockerfile`;
- `tiannara-core`, built from `docker/core/Dockerfile`.

It does not define:
- the root Elixir `:tiannara` release;
- the `:tiannara_runtime` application;
- the Observatory umbrella/API release;
- the Next.js SaaS frontend;
- NATS.

The runtime Elixir configuration defaults NATS to `nats://localhost:4222`, and runtime Quick Start describes Python-to-Elixir integration over NATS. But the root Compose file does not provide a NATS service or a runtime Elixir service. Therefore this Compose topology cannot, by itself, demonstrate the documented hybrid Python/Elixir runtime being deployed together.

The root Compose file also sets development-oriented values (including `ENVIRONMENT: development` and a literal development JWT secret) and mounts Python source directories. It should not be treated as the production deployment authority.

The deployment guide describes a broader frontend/API/core/infra architecture and several proposed deployment options. Those are documentation plans, not evidence of a checked-in, complete production orchestration manifest.

## 5. Reclassification of Checkpoint 18.98 duplicate-module risks

| Earlier finding | Checkpoint 18.99 topology evidence | Revised interpretation |
|---|---|---|
| RL-515 — root/runtime OED same module identity | Separate Mix projects, separate compile roots; root dependency graph excludes runtime app | PROJECT_LEVEL_DUPLICATE; no co-loading established in root release |
| RL-516 — root/runtime Sentinel same module identity | Same separation evidence | PROJECT_LEVEL_DUPLICATE; no co-loading established in root release |
| RL-507 — root/runtime Core authority split | Root and runtime are independently bootable applications with separate OTP callbacks | CONFIRMED_SEPARATE_APPLICATIONS; cross-process authority contract still UNKNOWN |
| RL-513 — OCM duplicate functional authority | Separate root/runtime app trees | SEPARATE_OWNERSHIP_DOMAINS; shared state/reconciliation still UNKNOWN |

This reclassification does not close the underlying behavior findings from 18.98. It narrows the collision claim: there is no source evidence that the root release combines the root and runtime source roots. A custom deployment that starts both separate releases on one host or connects them over NATS/API must define authority and data ownership explicitly, but that is not equivalent to loading both module definitions into one BEAM.

## 6. New finding register

| ID | Severity | Finding | Status |
|---|---|---|---|
| RL-520 | HIGH | Root `:tiannara` release excludes the separate `:tiannara_runtime` Mix project and its source tree | CONFIRMED_RELEASE_BOUNDARY |
| RL-521 | HIGH | Runtime Elixir is a separate application/release target; no checked-in deployment manifest composes it with root Tiannara | DEPLOYMENT_TOPOLOGY_UNKNOWN |
| RL-522 | CRITICAL | Root config imports environment-specific config but audited `config/prod.exs` is absent | PROD_BUILD_BLOCKER |
| RL-523 | CRITICAL | Runtime config imports environment-specific config but audited `tiannara_runtime/config/prod.exs` is absent | PROD_BUILD_BLOCKER |
| RL-524 | HIGH | Observatory is a third independent Elixir umbrella/release product with its own Docker build path | SEPARATE_RELEASE |
| RL-525 | HIGH | Root Compose topology omits both Elixir apps, Observatory, SaaS frontend, and NATS; it cannot establish the documented hybrid deployment | INCOMPLETE_COMPOSITION |
| RL-526 | HIGH | `Dockerfile.production` references absent `requirements-production.txt` | STATIC_BUILD_BLOCKER |
| RL-527 | HIGH | No checked-in deployment authority maps versioned artifacts, endpoints, trust boundaries, startup dependencies, and shutdown/recovery across all products | UNKNOWN |

## 7. Evidence not established

No compilation, release assembly, Docker build, container start, network test, health check, or runtime integration test was executed.

This checkpoint does not establish:
- that any of the documented releases currently build;
- that the root and runtime applications are deployed together;
- that the Observatory umbrella is deployed or connected to either Tiannara application;
- that Python and Elixir share a working NATS deployment;
- that API credentials, NATS credentials, secrets, database migrations, or durable stores are production-ready;
- that the deployment guides accurately describe the currently deployed infrastructure.

## 8. Required next verification

1. Obtain or define the actual deployment target matrix: which product is deployed where, artifact/version, environment, process owner, and network links.
2. Add and validate root and runtime production configuration; ensure secrets are injected without committing secret values.
3. Build each intended release independently from a clean checkout: root `:tiannara`, runtime `:tiannara_runtime`, Observatory `:observatory_api`.
4. Build every intended container from its declared context; repair the missing `requirements-production.txt` reference or retire the obsolete Dockerfile.
5. Create one deployment manifest (or explicitly versioned per-environment manifests) for Python API/core, Elixir root/runtime, Observatory, SaaS, Postgres, Redis, and NATS. Do not assume they are all required in one environment.
6. Define process-to-process contracts and canonical data owners for root/runtime/Observatory/Python boundaries. NATS subjects, schemas, authorization, replay, idempotency, and failure behavior need explicit evidence.
7. Verify startup dependency ordering, health/readiness gates, shutdown, restart, backup/restore, and recovery across the chosen topology.
8. Add CI gates that build all intended artifacts from clean checkout and fail when a deployment references a missing project, config, Docker build input, or undeclared service.

## 9. Final disposition

**OPEN — 8 new findings (RL-520–RL-527). Four earlier duplicate-module/authority findings are reclassified with the newly established project boundaries. Static release topology mapped; production buildability and deployed topology NOT VERIFIED.**

No production code or configuration was changed. This checkpoint adds an audit report only.
