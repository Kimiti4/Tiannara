# Checkpoint 19.00 — Independent Artifact Buildability Audit

**Audit status:** OPEN — static artifact-input review complete; selected CI evidence inspected; clean artifact builds not independently executed  
**Source baseline:** `b829254d032f9e0b5cf4c44725c8cf451800dad0` (`main`)  
**Audit branch:** `audit/consolidated-findings-r0a-2026-10-31`  
**Prior checkpoint:** 18.99 — Release Topology and Deployment Authority Audit  
**Finding register continuation:** RL-528 onward

## 1. Objective and method

Determine whether the repository contains the inputs and configuration needed to build each intended deployable artifact, distinguish build-time blockers from container-startup defects, and compare declared build paths with available CI evidence.

This checkpoint is primarily static. Repository contents, Mix project configuration, Dockerfiles, Compose definitions, package manifests, deployment documentation, and GitHub Actions workflow/job records were inspected. GitHub Actions records provide actual evidence for the specific jobs and commits reported below. No local clean checkout was provisioned and no new build was launched by this audit.

Disposition vocabulary:

- **BUILDABLE (CI evidence):** the named command/job completed successfully in the cited workflow run.
- **BLOCKED (static):** a required source/config/build input is absent or the declared command has no corresponding executable input.
- **NOT_VERIFIED:** source inputs appear present, but no successful build of that artifact was observed.
- **PARTIAL:** a narrower compile/test path passed, but the requested release/image/runtime artifact was not exercised.
- **UNKNOWN:** evidence is insufficient to assign another status.

A passing compile or test job is not equivalent to a production release build, Docker image build, or deployed runtime verification.

## 2. Executive result

| Artifact / path | Status | Evidence and limitation |
|---|---|---|
| Root Elixir project, default CI compile | **BUILDABLE (CI evidence)** | `Elixir CI` compile job passed on audit-branch commit `2fce6377d02965a6b4fa7c14dd2adab82e12d80c` (run `42828984197`). |
| Root `:tiannara` production release | **BLOCKED (static)** | Root `config/config.exs` imports `#{config_env()}.exs`; `config/prod.exs` is absent. The explicit release declaration in root `mix.exs` does not supply the missing production config. Existing RL-522 is reaffirmed. |
| Runtime Elixir project, required CI test suite | **BUILDABLE (CI evidence)** | Required `tiannara_runtime suite (quarantine excluded)` passed in run `42828984197`. This is test-environment evidence, not a production release build. |
| Runtime `:tiannara_runtime` production release | **BLOCKED (static)** | `tiannara_runtime/config/config.exs` imports `#{Mix.env()}.exs`; `tiannara_runtime/config/prod.exs` is absent. Existing RL-523 is reaffirmed. |
| Observatory API release/container | **NOT_VERIFIED / startup defect** | Umbrella, lockfile, config, and Dockerfile exist. Dockerfile command is `/app/bin/server`; no checked-in release overlay/server script was found. See RL-529. No image build or container start observed. |
| Python API and core Compose images | **NOT_VERIFIED** | Both Dockerfiles reference the present root `requirements.txt` and source directories; Compose declares these two images. No Docker build was observed. Compose is development-oriented, not production deployment proof. |
| Root Python `Dockerfile.production` image | **BLOCKED (static)** | `requirements-production.txt` is absent while Dockerfile copies and installs it. Existing RL-526 is reaffirmed. |
| SaaS Next.js frontend | **NOT_VERIFIED** | `package.json`, `package-lock.json`, and `build: next build` exist. No npm build job or successful Next.js build evidence was found in the inspected CI workflows. |
| Cross-platform evidence workflow | **BUILDABLE (workflow evidence only)** | Run `42828984147` passed on Linux and macOS. It compiles the root project and runs Phase 14 evidence scripts; it does not assemble the production releases or build the containers listed above. |

## 3. Elixir production configuration — RL-522 and RL-523 reaffirmed

### 3.1 Root project

Evidence:
- `mix.exs` declares app `:tiannara` and an explicit `releases/0` entry for release `tiannara`.
- `config/config.exs` ends with `import_config "#{config_env()}.exs"`.
- `config/dev.exs` and `config/test.exs` exist at the baseline.
- Fetching `config/prod.exs` at the baseline returns NOT_FOUND.
- Fetching `config/runtime.exs` returns NOT_FOUND.

The missing `prod.exs` is the direct production-environment configuration defect. The absence of `runtime.exs` is recorded as a configuration gap, but is not independently asserted to be a Mix release blocker: a runtime config file is not universally mandatory. The root CI compile passed in its configured default environment; it does not clear the production-config defect.

**Disposition:** root normal CI compile = BUILDABLE; root production release = BLOCKED (static) pending a production-environment build.

### 3.2 Runtime project

Evidence:
- `tiannara_runtime/mix.exs` defines a separate Mix project and application.
- `tiannara_runtime/config/config.exs` ends with `import_config "#{Mix.env()}.exs"`.
- Runtime `dev.exs` and `test.exs` exist.
- Runtime `prod.exs` and `runtime.exs` are absent at the baseline.
- The Quick Start says environment-specific config files are to be created as needed; that documentation does not substitute for a committed production config.

The required runtime CI suite passed in run `42828984197`. This establishes the exercised test suite, not a production release build.

**Disposition:** runtime required CI suite = BUILDABLE (CI evidence); runtime production release = BLOCKED (static) pending a production-environment build.

## 4. Python production image and CI pipeline — RL-526 reaffirmed; RL-528 added

Root `Dockerfile.production` contains:
- `COPY requirements-production.txt .`;
- `pip install ... -r requirements-production.txt`;
- application copies for `tiannara_core/`, `tiannara_api/`, `mindcache/`, and `runs/`;
- `COPY docker-entrypoint.sh`.

At the audited baseline, root `requirements-production.txt` is absent. The `runs/` directory does exist, so it is not a missing Docker build input. `requirements.txt` also exists and is used by the separate `docker/api/Dockerfile` and `docker/core/Dockerfile`.

The checked-in `.github/workflows/ci-cd.yml` independently repeats the absent dependency-manifest reference in its test job:

```bash
pip install -r requirements-production.txt
```

The Docker image build job has `needs: [test, lint]`; therefore, on a qualifying main/master push or pull request, the missing requirements file prevents the test job from reaching pytest and prevents the dependent image-build job from running successfully. The workflow's Docker step explicitly targets `Dockerfile.production`, which has the same missing-file defect. This workflow is not the all-branch Elixir workflow and was not the workflow that produced the current audit-branch Elixir CI results.

**RL-528 — HIGH — CI dependency-install step references absent production requirements file**

- **Evidence:** `.github/workflows/ci-cd.yml` installs `requirements-production.txt`; root file is absent at the audited baseline.
- **Impact:** Python test job fails before test execution in a clean checkout; dependent image build cannot proceed through this workflow.
- **Status:** STATIC_CI_BLOCKER.
- **Relationship:** shares the missing source input already recorded in RL-526; this finding records its separate CI-gating consequence rather than creating a second claim about the Dockerfile itself.

## 5. Observatory API container — RL-529 added

Evidence:
- `tiannara_observatory/mix.exs` declares an umbrella containing ten applications.
- The umbrella `mix.lock`, `config/config.exs`, `config/prod.exs`, and `config/runtime.exs` exist.
- `apps/observatory_api/mix.exs` declares dependencies on the nine sibling umbrella apps.
- `tiannara_observatory/Dockerfile.api` installs production dependencies, compiles with warnings-as-errors, runs `mix phx.digest`, then `mix release`.
- The final image copies the release directory and declares `CMD ["/app/bin/server"]`.
- No checked-in `rel/overlays/bin/server` or equivalent `server` script was found in the umbrella or API app paths inspected.

A normal Mix release exposes its release executable; the Dockerfile's `server` command requires an additional server wrapper/overlay. The inspected Dockerfile does not create one, and no matching checked-in overlay was found. Consequently, even if the image build completes, the declared container start command is not supported by the checked-in inputs inspected here.

**RL-529 — HIGH — Observatory API image declares a server executable not supplied by the checked-in build inputs**

- **Evidence:** `tiannara_observatory/Dockerfile.api` uses `CMD ["/app/bin/server"]`; no server overlay/script found in the inspected repository paths.
- **Impact:** container startup is expected to fail with an executable-not-found error unless the build environment supplies an untracked/generated script.
- **Status:** STARTUP_COMMAND_BLOCKER (static); actual image build/start not executed.
- **Qualification:** the actual release directory name and image build result remain NOT_VERIFIED; this finding is limited to the declared server command and missing checked-in wrapper.

## 6. Root Compose API/core images

The root `docker-compose.yml` defines:
- `tiannara-api`, built using `docker/api/Dockerfile`;
- `tiannara-core`, built using `docker/core/Dockerfile`;
- Postgres and Redis dependencies.

Both Dockerfiles use the existing root `requirements.txt`. The API Dockerfile copies `tiannara_api/` and `tiannara_core/`; the core Dockerfile copies `tiannara_core/`. Their source paths exist at the audited baseline. No Compose build or individual Docker build was executed or found in the inspected workflow records.

The Compose file sets `ENVIRONMENT: development`, a literal development JWT secret, source mounts, and an API reload command. It is development topology evidence only. It does not establish production image buildability or production security configuration.

**Disposition:** NOT_VERIFIED. No static missing-input blocker was established for these two Dockerfiles in this pass.

## 7. SaaS frontend

Evidence:
- `tiannara_saas/package.json` declares `build: next build`.
- `tiannara_saas/package-lock.json` exists.
- `tiannara_saas/next.config.ts` exists and defines API and WebSocket rewrites.
- Deployment documentation describes separate Vercel/Netlify deployment and a local `npm run build` step.
- The inspected `ci-cd.yml`, `elixir_ci.yml`, and `cross_platform_verify.yml` do not run `npm ci` or `npm run build`.

A lockfile and build script are necessary inputs, not proof of a successful production build. No frontend build was executed or observed.

**Disposition:** NOT_VERIFIED. No concrete frontend build blocker is asserted from the evidence collected in this checkpoint.

## 8. What the existing CI actually proves

### 8.1 Elixir CI — run 42828984197

Workflow: `.github/workflows/elixir_ci.yml`  
Commit: `2fce6377d02965a6b4fa7c14dd2adab82e12d80c`  
Run URL: https://github.com/Kimiti4/Tiannara/actions/runs/42828984197

At the time this audit inspected the run:
- `compile`: completed successfully, including `mix deps.get`, `mix compile --force --color`, and `mix run -e ":ok"`.
- `test-placement`: passed.
- `tiannara_audit suite (required)`: passed.
- `lineage-regression`: passed.
- `tiannara_runtime suite (required)`: passed.
- `tiannara_runtime quarantine (non-blocking)`: its test step failed; the job is configured as informational/non-blocking.
- `suite`: still in progress; therefore no final result is claimed for the full root test suite.

The workflow runs the normal compile/test commands. It does not call `MIX_ENV=prod mix release`, build a Docker image, or run the SaaS frontend build.

### 8.2 Cross-platform verification — run 42828984147

Workflow: `.github/workflows/cross_platform_verify.yml`  
Commit: `2fce6377d02965a6b4fa7c14dd2adab82e12d80c`  
Run URL: https://github.com/Kimiti4/Tiannara/actions/runs/42828984147

Linux and macOS jobs and the hash comparison completed successfully. The workflow compiles the root project, generates a Phase 14 evidence package, computes a canonical certificate hash, and runs archaeological reconstruction, mutation testing, and an independent audit. This is useful cross-platform evidence for that workflow's scope; it is not proof of root/runtime release assembly, Observatory container build/start, Python image build, or SaaS frontend build.

## 9. RL-528 onward — new finding register

| ID | Severity | Finding | Status |
|---|---|---|---|
| RL-528 | HIGH | `ci-cd.yml` installs absent `requirements-production.txt`, blocking its Python test job and dependent Docker image job in a clean checkout | STATIC_CI_BLOCKER |
| RL-529 | HIGH | Observatory API Dockerfile starts `/app/bin/server`, but no checked-in server overlay/wrapper was found in the inspected release paths | STARTUP_COMMAND_BLOCKER |
| RL-530 | HIGH | Current CI does not exercise the complete declared artifact matrix (production Mix releases, Observatory image, Python Compose/production images, and SaaS Next.js build) | ARTIFACT_CI_COVERAGE_GAP |

RL-522, RL-523, and RL-526 from Checkpoint 18.99 are reaffirmed, not duplicated.

## 10. Required next verification

1. Add or deliberately retire the root production configuration path; then run a clean `MIX_ENV=prod mix release` for `:tiannara`.
2. Add or deliberately retire the runtime production configuration path; then run a clean production release build for `:tiannara_runtime`.
3. Resolve the missing `requirements-production.txt` reference consistently in both `ci-cd.yml` and `Dockerfile.production`; do not silently substitute the development requirements file without dependency/security review.
4. Correct the Observatory release start command or add a tracked server overlay; then build and start the image and verify readiness.
5. Build `docker/api/Dockerfile` and `docker/core/Dockerfile` independently from clean checkout, then start the declared Compose topology and test health checks.
6. Run `npm ci && npm run build` from `tiannara_saas/` in CI.
7. Add CI jobs for each artifact the deployment matrix actually intends to ship. Keep release builds separate from test compilation and record exact artifact digests.
8. Re-run the full root suite and inspect the quarantined runtime failures separately; do not promote a non-blocking failure to PASS.

## 11. Final disposition

**OPEN — 3 new findings (RL-528–RL-530).** Root default-environment compile and required runtime CI suite have positive CI evidence. Root and runtime production releases remain blocked by the missing production config files already recorded as RL-522/RL-523. The Python production image and its associated CI pipeline are blocked by the missing requirements manifest already recorded as RL-526, with the CI consequence recorded in RL-528. Observatory container startup has a static command-path defect (RL-529). Python API/core images and the SaaS frontend remain NOT_VERIFIED. The full root test suite was still running when checked.

No production source, build configuration, or deployment file was modified. This checkpoint adds an audit report only.
