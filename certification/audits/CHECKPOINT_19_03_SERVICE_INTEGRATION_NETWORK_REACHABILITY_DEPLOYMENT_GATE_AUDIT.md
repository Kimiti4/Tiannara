# Checkpoint 19.03 — Independent Service Integration, Network Reachability and Deployment Gate Audit

**Audit status:** OPEN — static cross-service contract review complete for selected deployment paths; no end-to-end environment launched  
**Audit branch:** audit/consolidated-findings-r0a-2026-10-31  
**Source baseline:** 5345ce2cd9874d5ea996975279ed503830874ea3  
**Previous checkpoint:** 19.02 — Artifact Entrypoint, Runtime Startup and Health-Check Contract Audit  
**Finding register continuation:** RL-538 onward

## 1. Objective and scope

Inspect whether the checked-in service clients, routers, reverse proxies, containers, Compose stack, and CI deployment jobs agree on:
- service identity and intended authority;
- URL, path, port, and network target;
- exposed and mounted routes;
- environment-variable contract;
- startup/readiness and deployment success claims.

This is a static source audit supplemented by already completed GitHub Actions run/job evidence. No Docker/Compose cluster, production release, HTTP endpoint, Kubernetes cluster, or browser session was launched. No production files were changed.

## 2. CI evidence inherited from 19.02

The 19.02 report commit is 5345ce2cd9874d5ea996975279ed503830874ea3.
- Elixir CI run 42836815730 completed successfully. Compile, test-placement, lineage regression, required audit suite, required runtime suite, and root suite passed. The quarantined runtime suite failed but is configured non-blocking.
- Cross-platform verification run 42836815905 completed successfully on Ubuntu and macOS; the cross-platform hash comparison passed.

These workflows do not build or run the deployment artifacts or exercise the HTTP/network contracts below.

## 3. Integration surface inventory

| Surface | Declared target/contract | Static result |
|---|---|---|
| Python API image | Uvicorn on 0.0.0.0:8000; health path /api/v1/health | Health path mismatches app route; RL-536 retained |
| Python core image | Python module entrypoint | Module does not start worker; RL-535 retained |
| Root Compose | PostgreSQL, Redis, Python API, Python core | Development-only subset; not a complete Tiannara runtime/Observatory/SaaS deployment |
| Observatory API/UI | API port 4000; UI port 3000; UI calls /api/v1 paths | UI default API target uses localhost; RL-537 retained; client route contract mismatch RL-538 |
| SaaS frontend | Browser API base and Next.js rewrites | NEXT_PUBLIC_API_URL and API_UPSTREAM_URL contracts differ; RL-540 |
| Staging release pipeline | Build, deploy, health check, release | Staging deploy and health-check commands are placeholders; RL-539 |

The root docker-compose.yml contains PostgreSQL, Redis, tiannara-api, and tiannara-core only. It does not start the root Elixir release, the separate tiannara_runtime Mix application, NATS, Observatory API/UI, or SaaS frontend. The Compose file also declares development credentials, development environment values, source mounts, and API reload. This is consistent with a development subset, not an end-to-end production topology. The separation was already recorded in Checkpoint 18.99 and is reaffirmed here, not duplicated as a new finding.

## 4. RL-538 — HIGH — Observatory UI client requests several paths not mounted by the Observatory API router

### Evidence

The Observatory UI's client helper at `tiannara_observatory/apps/observatory_ui/src/lib/api.ts` uses a base path ending in `/api/v1` and declares calls including:
- `/science`
- `/engineering`
- `/knowledge`
- `/planetary`
- `/evolution`
- `/governance`
- `/certification`
- `/metrics/:name/trend`
- `/metrics/:name/forecast`
- `/metrics/query`
- `/replay/compare`
- `/replay/archaeology`
- `/replay/divergence`

The mounted router in `tiannara_observatory/apps/observatory_api/lib/observatory_api/router.ex` explicitly exposes:
- `/health`, `/status`;
- `/runtime/health`, `/runtime/metrics`;
- `/science/discoveries`, `/science/experiments`;
- `/engineering/designs`, `/engineering/trl`;
- `/planet/state`, `/planet/metrics`;
- `/civilization/indices`;
- `/replay`, `/replay/snapshots`, `/replay/timeline`;
- `/certification/status`, `/certification/chain`;
- `/phase-omega/scan`, `/phase-omega/snapshot`;
- `/metrics`, `/metrics/:name`;
- `/events`, `/events/:id`.

There are no corresponding router declarations for the client paths listed above. In particular, the UI's top-level state endpoints do not match the API's more specific route shapes, and metrics trend/forecast/query plus replay compare/archaeology/divergence are absent from the inspected router. The API router has no catch-all route that would supply these requests.

### Impact

The client helper's declared methods cannot be assumed to be implemented by the mounted API. Calls to these unmounted paths are expected to return not-found responses unless routes are added or the client is corrected. This is an API-contract gap independent of container reachability.

### Disposition

**Status:** STATIC_API_CONTRACT_MISMATCH. No HTTP requests were made against a live API. This finding records route declarations, not proof that every helper method is currently called by the UI.

## 5. RL-539 — CRITICAL — Staging deployment job reports success without deploying or checking service health

### Evidence

The audit-branch `.github/workflows/ci-cd.yml` has a job named `Deploy to Staging`, dependent on the build job. Its deployment step currently:
- prints a message that staging deployment is starting;
- contains only commented-out example SSH/deployment commands;
- performs no registry pull, remote command, Compose/Kubernetes update, or rollout.

The following health-check step:
- sleeps for 30 seconds;
- has the `curl` health-check command commented out;
- prints `Staging deployment successful!`.

The job can therefore complete successfully after the image build without deploying anything or probing the staging service. Its configured GitHub Environment URL does not make the deployment operation real.

### Impact

The workflow can produce a green staging-deployment job and a success message without changing staging or establishing service readiness. A consumer of the CI status may interpret a no-op as an actual deployment. This is a false-positive deployment gate, not merely missing end-to-end test coverage.

### Disposition

**Status:** DEPLOYMENT_GATE_PLACEHOLDER / FALSE_SUCCESS. The workflow code proves the absence of deployment and health-check commands; no staging host was contacted.

## 6. RL-540 — HIGH — SaaS frontend uses two different API-upstream variables, while deployment guidance documents only one

### Evidence

The SaaS Next configuration at `tiannara_saas/next.config.ts` sets its rewrite destination using:
- `API_UPSTREAM_URL`;
- default fallback `http://127.0.0.1:8004`.

SaaS client pages use `NEXT_PUBLIC_API_URL` as their direct browser API base, with a localhost fallback. The deployment guidance and configuration examples surfaced in the repository specify `NEXT_PUBLIC_API_URL` for the backend URL. No corresponding documented `API_UPSTREAM_URL` setting was found in those deployment examples.

The `docker/saas/Dockerfile` runs `npm ci` and `npm run build` without declaring a build argument or environment variable for either API target. Next.js public environment variables are embedded during the build, so setting only a container runtime variable is not a substitute for supplying the browser-visible API URL at build time. The Docker image also retains the separate RL-531/RL-532 Node/output blockers.

### Impact

Supplying the documented NEXT_PUBLIC_API_URL does not, by itself, change the server rewrite's API_UPSTREAM_URL destination. Relative /api/v1 requests routed through Next rewrites can continue targeting loopback, while direct client requests use the separately configured public variable. The two routing paths can therefore disagree.

### Disposition

**Status:** STATIC_ENVIRONMENT_CONTRACT_MISMATCH. No SaaS build or network request was executed. This finding is separate from RL-531/RL-532: it concerns the routing variables and proxy contract, not Node compatibility or static output.

## 7. Existing findings retained

No duplicate finding IDs are created for these previously identified issues:
- RL-535 — Python core Docker CMD does not instantiate or run the worker.
- RL-536 — Python API health probe targets a path not registered by the selected app.
- RL-537 — Observatory UI API default points to localhost instead of the separate API container.
- RL-529 — Observatory API image's /app/bin/server command has no checked-in overlay found.
- RL-531/RL-532 — SaaS Node version and static-output configuration issues.
- RL-523 — Runtime production config is missing.
- RL-526 — Python production Dockerfile references absent requirements-production.txt.

## 8. Duplicate and stub directory audit status — explicitly NOT COMPLETE

The latest consolidated system ownership inventory remains Checkpoint 18.97. Its recorded disposition was:
- **4/29** repeated top-level system directory names meaningfully classified;
- **25/29** remained UNKNOWN at the system/API/startup level;
- **12 stub modules** identified and their main caller/behavior risks recorded;
- no exhaustive total number of stub modules/directories established;
- no complete system-by-system mapping from duplicate directory occurrences to production implementation, stub implementation, canonical owner, startup parent, consumers, and tests;
- static source inspection only; runtime ownership/residency remained unverified.

The four meaningfully classified systems were A10, CIS, OCM, and OED. The stub findings included the Stub macro/registry design and stub modules affecting CTL, Sentinel causal traversal/memory, ASC Crucible, GenerationHistory, Graph, LifecycleRegistry, ScientificCapitalLedger, TWP survivability, and REA theory niches.

The register and source inventory must not be described as a completed duplicate/stub audit. The remaining 25 UNKNOWN systems need explicit module occurrence, caller, test, startup and persistence mapping. The 12 stubs are identified findings, not a proven complete stub inventory.

**Checkpoint 19.03 does not close or materially advance the 29-system inventory.** This is retained here to keep remediation readiness visible.

## 9. Remediation readiness and sequencing

### What can be remediated from already established evidence

The following are sufficiently localized for bounded remediation planning, subject to explicit authorization and regression tests:
1. Python core worker entrypoint (RL-535).
2. Python API health endpoint/probe agreement (RL-536).
3. Observatory UI API upstream configuration (RL-537).
4. Observatory UI client/API route contract (RL-538).
5. Staging deployment and health-check workflow implementation (RL-539).
6. SaaS API routing environment contract (RL-540).
7. Previously recorded build blockers and production configuration gaps (RL-523, RL-526, RL-529, RL-531, RL-532).

These are **remediation candidates**, not fixes made or authorized by this report.

### What must wait for the duplicate/stub audit

Do not begin broad duplicate deletion, module renaming, supervisor consolidation, or replacement of stubbed system authorities until the remaining system ownership work establishes:
- every occurrence and module identity across roots;
- which version is loaded in each intended release;
- real startup ancestry and consumers;
- persisted-state/readback semantics;
- which implementation is the canonical authority;
- compatibility callers and migration path;
- tests and rollback procedure.

Otherwise, remediation could remove a live implementation, preserve the wrong stub, create a second authority, or break hidden callers.

### Required pre-remediation gates

| Gate | Requirement | Status |
|---|---|---|
| A. Build/deployment defect inventory | Current artifact build, entrypoint, health, network and route mismatches logged | **PARTIAL — 19.00–19.03** |
| B. Duplicate directory ownership inventory | All 29 repeated system names classified with source paths and ownership | **NOT COMPLETE — 4/29** |
| C. Stub inventory | Exhaustive stub/stub-like scan, caller map, fail-open behavior and production reachability | **PARTIAL — 12 known, total unknown** |
| D. Canonical authority decisions | One owner per overlapping responsibility and approved compatibility boundaries | **NOT COMPLETE** |
| E. Remediation plan | Ordered changes, dependencies, tests, migration and rollback; human approval | **NOT COMPLETE** |
| F. Remediation execution | Code/config fixes with independent verification | **NOT STARTED** |

### How far until remediation?

- **Bounded deployment remediation:** close enough to begin once explicitly authorized; the identified defects have specific files and testable contracts.
- **Broad duplicate/stub structural remediation:** not ready. The duplicate inventory is only 4/29 classified, and the stub inventory has no verified denominator. The full authority/caller map and human-approved plan are still prerequisites.
- **Full remediation completion:** cannot responsibly be expressed as a percentage or number of checkpoints yet. The unknown inventory and runtime reachability must first be measured.

## 10. New finding register

| ID | Severity | Finding | Status |
|---|---|---|---|
| RL-538 | HIGH | Observatory UI API helper declares multiple route paths not mounted by the Observatory API router | STATIC_API_CONTRACT_MISMATCH |
| RL-539 | CRITICAL | Staging workflow performs no deployment and no health probe but prints success | DEPLOYMENT_GATE_PLACEHOLDER / FALSE_SUCCESS |
| RL-540 | HIGH | SaaS uses API_UPSTREAM_URL for rewrites and NEXT_PUBLIC_API_URL for client calls; deployment guidance does not establish both values | STATIC_ENVIRONMENT_CONTRACT_MISMATCH |

## 11. Final disposition

**OPEN — 3 new findings (RL-538–RL-540).** CI for the 19.02 report commit passed its required Elixir and cross-platform jobs; the non-blocking quarantined runtime suite still failed. Integration review found an Observatory UI/API route-contract mismatch, a staging deployment job that reports success without deploying or probing health, and two inconsistent SaaS API-upstream environment variables. The root Compose stack remains a development subset, not the complete runtime/Observatory/SaaS topology.

The duplicate/stub audit remains explicitly incomplete: 4/29 repeated system directories classified; 25 UNKNOWN; 12 stub modules identified but no exhaustive total or complete owner/caller/runtime map. Bounded deployment fixes can be planned independently. Broad duplicate/stub remediation must wait for the full ownership and authority map and human-approved remediation plan.

No production code, Dockerfile, Compose file, CI workflow, or deployment configuration was modified. This checkpoint adds an audit report only.
