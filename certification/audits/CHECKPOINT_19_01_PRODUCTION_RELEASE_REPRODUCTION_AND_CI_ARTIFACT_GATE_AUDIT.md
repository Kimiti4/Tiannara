# Checkpoint 19.01 — Production Release Reproduction and CI Artifact-Gate Audit

**Audit status:** OPEN — production release commands not executable in this audit environment; GitHub Actions evidence and artifact gates inspected  
**Audit branch:** audit/consolidated-findings-r0a-2026-10-31  
**Branch source head before this report:** 5976b93867eefbff1400f1d4a9aab42fdb8e7081  
**Historical main baseline used by Checkpoint 19.00:** b829254d032f9e0b5cf4c44725c8cf451800dad0  
**Previous checkpoint:** 19.00 — Independent Artifact Buildability Audit  
**Finding register continuation:** RL-531 onward

## 1. Objective and scope

This checkpoint rechecks the current audit-branch source, reproduces available build-gate failures from existing GitHub Actions logs, evaluates production-release prerequisites, and maps which deployable artifacts are actually exercised by CI.

The source branch has diverged from the historical main baseline used by Checkpoint 19.00. This report distinguishes:
- Current audit-branch state at 5976b93867eefbff1400f1d4a9aab42fdb8e7081;
- Historical main-branch CI evidence at b829254d032f9e0b5cf4c44725c8cf451800dad0;
- Observed CI outcomes from specific workflow run/job logs; and
- Static build assessments where no build command was executed.

No production source or build configuration was modified in this checkpoint.

## 2. Execution limitations and reproduction boundary

A local execution attempt was not possible:
- mix, elixir, and docker are not installed in the available execution environment.
- A shallow Git clone of the audit branch was attempted but failed because the environment could not resolve github.com.
- The available GitHub integration can inspect repository files, workflow runs, job summaries, and logs, and can rerun failed jobs. It does not expose a workflow-dispatch or arbitrary shell-execution action.
- The existing Elixir CI workflow has a workflow_dispatch trigger, but no dispatch action was available to invoke it.

Consequently, this report does not claim to have executed MIX_ENV=prod mix release, docker build, docker compose build, or npm run build against a clean checkout. It uses actual CI logs where available and marks unexecuted production artifacts NOT_VERIFIED or BLOCKED (static).

## 3. Correction and reclassification of Checkpoint 19.00 findings

Checkpoint 19.00 inspected the historical main baseline b829254d..., then committed its report to an audit branch whose source tree was already ahead of that baseline. The following branch-specific corrections are required.

| Prior finding | State at historical main b829254d | State at audit branch 5976b938 | 19.01 disposition |
|---|---|---|---|
| RL-522 — root config/prod.exs absent | Absent | Present since at least parent commit 2fce6377d02965a6b4fa7c14dd2adab82e12d80c; unchanged at 5976b938 | RECLASSIFIED — CONFIG PRESENT; RELEASE NOT_VERIFIED |
| RL-523 — runtime tiannara_runtime/config/prod.exs absent | Absent | Still absent | RETAINED — STATIC PRODUCTION-CONFIG BLOCKER |
| RL-526 — root requirements-production.txt absent | Absent | Still absent | RETAINED — DOCKER BUILD INPUT BLOCKER |
| RL-528 — CI test step installs absent requirements-production.txt | Workflow at b829254d used missing file and failed | Audit-branch ci-cd.yml now installs the present requirements.txt | RECLASSIFIED — HISTORICAL MAIN-BRANCH FAILURE; AUDIT-BRANCH TEST-INSTALL CHANGE NOT YET RUN BY THIS WORKFLOW |
| RL-529 — Observatory API container calls missing /app/bin/server | Command present; no overlay found | Still present; no checked-in server overlay found | RETAINED — STARTUP-COMMAND BLOCKER (STATIC) |
| RL-530 — CI does not cover all release artifacts | Confirmed | Still confirmed; scope is now more precise | RETAINED / EXPANDED |

### Root production config correction

The audit branch contains config/prod.exs. It requires SECRET_KEY_BASE when the prod config is loaded and defines production endpoint settings. This corrects the prior report's statement for the current audit branch. The historical main baseline b829254d still lacks that file.

The presence of this config file does not prove the root release assembles. No production release command was executed, and the root elixir_ci.yml still does not run MIX_ENV=prod mix release. The config also obtains SECRET_KEY_BASE at config-load/build time; a production build that does not supply it will stop with the explicit missing-secret error.

### Python CI dependency-install correction

The audit-branch .github/workflows/ci-cd.yml changed its test dependency installation to pip install -r requirements.txt, which exists. However, the same workflow's image-build job still targets root Dockerfile.production, which still contains COPY requirements-production.txt . and tries to install that absent file. Thus the old test-stage failure is not the current audit-branch test-install condition, but the production image still has a missing build input.

## 4. Production release and image status matrix

| Artifact | Current audit-branch status | Evidence |
|---|---|---|
| Root :tiannara production release | NOT_VERIFIED | config/prod.exs exists, but no MIX_ENV=prod mix release job or run was found. SECRET_KEY_BASE must be provided when loading production config. |
| Runtime :tiannara_runtime production release | BLOCKED (static) | Runtime config imports "#{Mix.env()}.exs"; tiannara_runtime/config/prod.exs is still absent. Quick Start documents MIX_ENV=prod mix release. |
| Observatory API image/release | NOT_VERIFIED; startup defect retained | Production config and Dockerfile exist. Dockerfile invokes mix release, but starts /app/bin/server; no checked-in server overlay/script exists in the Observatory tree inspected. |
| Observatory UI image | NOT_VERIFIED | Dockerfile.ui, lockfile, Next config, and public/ exist. It has no matching active build gate in the repository's checked-in workflows. |
| Python production image (Dockerfile.production) | BLOCKED (static) | Its required requirements-production.txt input is absent. |
| Python API image (docker/api/Dockerfile) | NOT_VERIFIED | Uses present requirements.txt and source paths; no image build evidence found. |
| Python core image (docker/core/Dockerfile) | NOT_VERIFIED | Uses present requirements.txt and tiannara_core/; no image build evidence found. |
| SaaS Next.js Docker image (docker/saas/Dockerfile) | BLOCKED (static) | Node 18 image is incompatible with Next.js 16; Dockerfile also copies an out/ directory not configured by the current Next.js config. |
| SaaS Next.js direct build | NOT_VERIFIED | package.json and lockfile exist; no npm ci && npm run build CI job or successful build run was found. |

## 5. Reproduced CI evidence

### 5.1 Historical main Python CI/CD run — confirmed dependency-install failure

Run: https://github.com/Kimiti4/Tiannara/actions/runs/37443655186  
Commit: b829254d032f9e0b5cf4c44725c8cf451800dad0  
Workflow: .github/workflows/ci-cd.yml

Observed job outcomes:
- Python 3.10 dependency installation: failed.
- Python 3.11 dependency installation: failed.
- Python 3.12 dependency installation: failed.
- Code Quality / flake8: failed independently.
- Docker image build: skipped.
- Staging deployment: skipped.
- GitHub Release job: skipped.

The Python job logs show the exact error for each tested version:

    ERROR: Could not open requirements file:
    [Errno 2] No such file or directory: 'requirements-production.txt'

This is an actual reproduced CI failure for the historical main commit, not merely a static inference. Because the test/lint prerequisites failed, that run did not execute the Docker build and therefore did not reproduce the Dockerfile's own missing-file failure at the builder stage.

### 5.2 Current audit-branch Elixir CI — required gates pass, quarantine remains red

Run: https://github.com/Kimiti4/Tiannara/actions/runs/42830034541  
Commit: 5976b93867eefbff1400f1d4a9aab42fdb8e7081

Job outcomes:
- compile: PASS.
- test-placement: PASS.
- tiannara_audit suite (required): PASS.
- Root suite: PASS.
- lineage-regression: PASS.
- tiannara_runtime suite (required): PASS.
- tiannara_runtime quarantine (non-blocking): FAIL; the workflow marks this job continue-on-error: true.

The quarantined run log records 40 properties, 1,863 tests, 4 failures, 1,897 excluded. The four failures include:
1. Passive-mode test observed a changed fingerprint and reported mutations during passive mode.
2. Reactivity test observed constraint load unchanged at 0.0 -> 0.0 after perturbation.
3. CPL reload test could not start a process because the named CPL process was already started.
4. Omega supervisor readiness test hit the same already_started child-start condition.

The required suite passing is valid for the tests it runs (--exclude quarantine). It must not be represented as an all-tests-pass result. The four quarantined failures remain visible but do not change the overall workflow conclusion because the job is explicitly non-blocking.

### 5.3 Current audit-branch cross-platform workflow

Run: https://github.com/Kimiti4/Tiannara/actions/runs/42830034683  
Commit: 5976b93867eefbff1400f1d4a9aab42fdb8e7081

Linux, macOS, and the cross-platform hash comparison passed. This workflow compiles the root project and runs its evidence-package/reconstruction/mutation/audit scripts. It does not build the root or runtime production releases, Python production image, Observatory images, or Next.js applications.

### 5.4 Historical main Elixir failures are not current audit-branch failures

The main-branch Elixir CI run at b829254d failed test-placement because an ExUnit module was under lib/, and root compilation failed on invalid syntax in lib/tiannara/math/optimization.ex. The audit branch contains corrected versions, and the current audit-branch CI run above passes the required root and runtime suites. These older failures are retained as source-history context, not carried forward as current audit-branch failures.

## 6. SaaS Docker build blockers — RL-531 and RL-532

### RL-531 — HIGH — Node 18 build image is below the Next.js 16 runtime requirement

Evidence:
- docker/saas/Dockerfile uses FROM node:18-alpine AS builder.
- tiannara_saas/package.json pins next to 16.2.6.
- Next.js 16's official system requirements specify Node.js 20.9 or later. The official upgrade guide states that Node.js 18 is no longer supported.

Expected consequence: the npm run build step runs Next.js 16 under an unsupported Node 18 runtime and is expected to terminate before producing the application build.

**Status:** STATIC_BUILD_BLOCKER. No Docker build was run.

Official reference: https://nextjs.org/docs/app/getting-started/installation

### RL-532 — HIGH — SaaS Dockerfile copies static-export output without configuring static export

Evidence:
- docker/saas/Dockerfile runs npm run build, then copies /app/out from the builder into Nginx.
- tiannara_saas/next.config.ts defines rewrites() but does not set output: "export".
- The current package script is plain next build.
- Next.js documents that the default build output is .next; the out/ directory is generated when static export is configured using output: "export".

Expected consequence: after resolving RL-531, the Nginx stage still expects an out/ directory that the present configuration does not request.

A simple addition of output: "export" is not sufficient as a blind fix: Next.js static export does not apply custom rewrites. The current SaaS Next config defines both API and WebSocket rewrites, while the Nginx config proxies /api/ but does not define a /ws proxy. The deployment design must choose a Node/Next server output or explicitly move all required proxy behavior into the reverse proxy and verify the static-export feature constraints.

**Status:** STATIC_OUTPUT_MISMATCH. No Docker build was run.

Official references:
- https://nextjs.org/docs/app/guides/static-exports
- https://nextjs.org/docs/app/api-reference/config/next-config-js/output

## 7. Observatory release/container gate

### API container — RL-529 reaffirmed

tiannara_observatory/Dockerfile.api:
- builds with MIX_ENV=prod;
- runs mix deps.get --only prod, mix compile --warnings-as-errors, mix phx.digest, and mix release;
- copies the expected release directory; and
- declares CMD ["/app/bin/server"].

The checked-in Observatory config/runtime.exs documents that a bin/server helper is generated by mix phx.gen.release; alternatively it shows starting the release with PHX_SERVER=true bin/observatory_api start. The Dockerfile does not invoke mix phx.gen.release, and the inspected Observatory tree contains no rel/overlays/bin/server or other tracked bin/server script.

**Disposition:** RL-529 remains a static startup-command blocker. The build and container start were not executed. The expected release directory and command must be verified together; correcting the command to the actual release executable or adding a tracked/generated server overlay are alternative designs, not a change made by this audit.

### UI container exists, but has no CI gate

The previously unaccounted-for tiannara_observatory/Dockerfile.ui does exist. It uses Node 22, runs npm ci and npm run build, copies .next, public/, package metadata and dependencies, then runs npm start. The required public/ directory exists. No static missing-input blocker was established for this Dockerfile in the present inspection.

This only means the Dockerfile's declared inputs are present; it does not prove the image builds or starts. Neither the API nor UI image is built by the workflows found in .github/workflows/.

## 8. CI artifact-gate coverage and documentation

The current audit-branch .github/workflows/ci-cd.yml:
- runs the Python test job using requirements.txt;
- runs Python lint;
- builds only root Dockerfile.production after test and lint pass;
- has staging and GitHub Release jobs downstream of that build;
- triggers push events only for main and master, plus pull requests targeting those branches.

It does not build or test:
- root :tiannara production release;
- runtime :tiannara_runtime production release;
- Observatory API Docker image or UI Docker image;
- root Python API/core images from docker/api/Dockerfile and docker/core/Dockerfile;
- SaaS Next.js application or its Docker image;
- Observatory UI Next.js application independently.

The branch-wide elixir_ci.yml performs compile and test gates, but it does not run a production release assembly. The cross-platform workflow validates the specified Phase 14 evidence process and likewise does not create deployable artifacts.

### RL-533 — MEDIUM — Observatory README documents a CI workflow file that is absent

tiannara_observatory/README.md states that GitHub Actions workflows in .github/workflows/ci.yml include Elixir CI, Node CI, and Docker builds for API and UI. At the audited branch tree, .github/workflows/ci.yml is absent. The checked-in workflow directory contains only:
- ci-cd.yml;
- cross_platform_verify.yml;
- elixir_ci.yml;
- phase_5f2_tests.yml;
- test.yml.

No actual Observatory Node CI or Observatory API/UI Docker build gate was found. The README's CI description is therefore not supported by the checked-in workflow set.

**Status:** DOCUMENTATION_CI_MISMATCH / ARTIFACT_GATE_ABSENT.

### RL-534 — MEDIUM — Green Elixir workflow outcome tolerates four quarantined runtime test failures

The audit-branch workflow marks the quarantined runtime suite continue-on-error: true. The actual run at commit 5976b938 records four test failures but the overall workflow succeeds because the required suite excludes the quarantined tests and the quarantine job is non-blocking.

The workflow is transparent about the separate quarantine job, which is preferable to hiding its status. However, a green overall workflow is not an all-tests-pass signal and must not be used as a release criterion without explicitly accepting the quarantined failures.

**Status:** KNOWN_NONBLOCKING_TEST_FAILURES. This finding does not invalidate the successful required-suite jobs; it qualifies their scope.

## 9. Consolidated status and required reproduction matrix

| Build command / gate | Evidence now available | Next required evidence |
|---|---|---|
| Root MIX_ENV=prod mix release | Production config exists on audit branch; no release job/run | Clean production release log with required env supplied; record artifact path/hash |
| Runtime MIX_ENV=prod mix release | Required prod.exs missing; production config import present | Add/restore correct production config under authorized change, then clean release log |
| Observatory API Docker build/start | Dockerfile and config exist; /app/bin/server not supplied by inspected tree | Build log, release file listing, container startup log and readiness response |
| Observatory UI Docker build/start | Dockerfile and declared local inputs exist | Build log, image digest, server start and /mission-control check |
| Python production Docker image | Required manifest missing | Resolve manifest; build log and image digest |
| Python API/core Compose images | Dockerfiles use existing requirements/source; no build evidence | Independent clean builds; Compose service health and integration logs |
| SaaS direct Next build | Manifest/lockfile exist, no build CI | Node >=20.9 clean npm ci && npm run build log |
| SaaS Nginx image | Two static blockers in Dockerfile/config | Resolve Node version and output mode/proxy architecture; build and smoke test |

## 10. New finding register

| ID | Severity | Finding | Status |
|---|---|---|---|
| RL-531 | HIGH | SaaS Docker builder uses Node 18 with Next.js 16.2.6, below Next.js 16's Node 20.9 minimum | STATIC_BUILD_BLOCKER |
| RL-532 | HIGH | SaaS Dockerfile copies out/ while current Next config does not enable static export; static export also requires a rewrite/proxy design review | STATIC_OUTPUT_MISMATCH |
| RL-533 | MEDIUM | Observatory README names .github/workflows/ci.yml, which is absent; no checked-in Observatory API/UI build workflow found | DOCUMENTATION_CI_MISMATCH |
| RL-534 | MEDIUM | Elixir CI overall can pass with four quarantined runtime test failures because the quarantine job is non-blocking | KNOWN_NONBLOCKING_TEST_FAILURES |

RL-522 is reclassified to current-branch config present / production release not verified. RL-528 is reclassified as a historical main-branch test-install failure; the audit-branch test-install command now uses requirements.txt, while the image Dockerfile still references the missing production requirements file. RL-523, RL-526, RL-529, and RL-530 remain open.

## 11. Final disposition

**OPEN — 4 new findings (RL-531–RL-534).** The historical main-branch Python CI dependency-install failure is reproduced in job logs. The current audit-branch Elixir required compile/test gates and cross-platform verification pass, but the optional quarantine job records four failures. The root production config has been added on the audit branch and is no longer a current-branch missing-file blocker; actual root release assembly remains NOT_VERIFIED. The runtime production config remains absent. The Python production Docker image remains statically blocked by its missing requirements manifest. The SaaS Docker image has two independent static blockers (Node version and output directory). Observatory API startup still has the unresolved /app/bin/server command mismatch. Observatory API/UI, Python API/core, SaaS frontend, and all production Elixir releases still lack successful artifact-build evidence in the inspected CI.

No production code, configuration, Dockerfile, or workflow was modified. This checkpoint adds an audit report only.
