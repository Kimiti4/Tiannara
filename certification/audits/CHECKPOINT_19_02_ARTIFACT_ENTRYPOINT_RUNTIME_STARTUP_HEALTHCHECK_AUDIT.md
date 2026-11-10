# Checkpoint 19.02 — Artifact Entrypoint, Runtime Startup and Health-Check Contract Audit

**Audit status:** OPEN — static startup-contract review complete; no new container or service was launched  
**Audit branch:** audit/consolidated-findings-r0a-2026-10-31  
**Source baseline:** 6f8ac8a6d69e663f552ee6bfcb5bc6c8b8d21d43  
**Previous checkpoint:** 19.01 — Production Release Reproduction and CI Artifact-Gate Audit  
**Finding register continuation:** RL-535 onward

## 1. Objective and method

Trace intended deployable artifacts from their configured process entrypoint through their effective service behavior: process lifetime, listen address/port, health-check URL, upstream routing, and required runtime environment.

Inspected the current audit-branch Dockerfiles, Compose configuration, Python entrypoint modules and FastAPI route registration, Observatory API/UI configuration, and deployment documentation. Rechecked the 19.01 commit's CI outcomes.

This checkpoint is static. No containers, releases, Python services, or Next.js services were started. The dispositions below distinguish deterministic consequences of the checked-in command/source from unobserved runtime behavior.

## 2. CI status inherited from 19.01

For source commit `6f8ac8a6d69e663f552ee6bfcb5bc6c8b8d21d43`:
- Elixir CI run `42833650625` completed successfully.
- Cross-Platform Verification run `42833650518` completed successfully.
- These workflows still do not build/start the Python API/core containers, Observatory API/UI images, or SaaS image. They do not run production release assemblies.

The passing runs establish the jobs in those workflows only. They do not close the startup defects in this checkpoint.

## 3. Artifact entrypoint matrix

| Artifact | Declared process entrypoint | Health/readiness contract | Checkpoint disposition |
|---|---|---|---|
| Python API image | `uvicorn tiannara_api.main:app` | Dockerfile probes `/api/v1/health`; FastAPI app defines `/health` | **HEALTH-CHECK PATH MISMATCH — RL-536** |
| Python core image | `python -m tiannara_core.autonomous.loop` | No Docker health check; module only defines a class and methods | **NO WORKER MAIN — RL-535** |
| Root Python production image | `docker-entrypoint.sh` then Uvicorn | Probes `/health`; this route exists in `tiannara_api.main` | **PATH MATCH; IMAGE BUILD STILL BLOCKED BY RL-526** |
| Observatory API image | `/app/bin/server` | API health route is `/api/v1/health`; runtime config requires DB URL and secret | **START COMMAND ISSUE — RL-529 reaffirmed** |
| Observatory UI image | `npm start` | UI calls API at `NEXT_PUBLIC_API_URL` or localhost fallback; rewrite points at localhost:4000 | **CROSS-CONTAINER UPSTREAM ISSUE — RL-537** |
| SaaS Docker image | Nginx serving copied `out/` | Node 18 / Next 16 and static-export issues remain | **RL-531 / RL-532 reaffirmed** |
| Runtime Elixir release | Release executable documented in runtime Quick Start | Runtime imports `prod.exs`, which is absent | **RL-523 reaffirmed; no production release verified** |

## 4. RL-535 — HIGH — Python core container command does not start a worker

### Evidence

`docker/core/Dockerfile` ends with:

```dockerfile
CMD ["python", "-m", "tiannara_core.autonomous.loop"]
```

The referenced module `tiannara_core/autonomous/loop.py`:
- imports time/dataclass/typing and `Orchestrator`;
- defines `AutonomousLoop`;
- defines `step()`, `run()`, and `stop()`;
- does not instantiate `AutonomousLoop`;
- does not construct an `Orchestrator`;
- does not call `run()`; and
- contains no `if __name__ == "__main__"` execution block or other module-level worker startup.

The class is a callable library component, not a runnable module entrypoint. Running the exact Docker CMD executes the imports and class definitions and then exits; it does not begin a background worker loop. The Dockerfile comment describes it as a background worker, but the command does not implement that behavior.

Root `docker-compose.yml` builds `tiannara-core` from this Dockerfile and does not override its command. Thus the same command is used by the declared Compose core service.

**Impact:** the core container is expected to exit normally after module import, leaving the Compose service without a running worker. A successful image build would not establish a working core service.

**Status:** STATIC_ENTRYPOINT_DEFECT. No container was started.

## 5. RL-536 — HIGH — Python API image health check probes a route not registered by its application

### Evidence

`docker/api/Dockerfile` declares:

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/api/v1/health || exit 1

CMD ["uvicorn", "tiannara_api.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

The selected module is `tiannara_api/main.py`. It registers the FastAPI health handler at:

```python
@app.get("/health")
async def health_check():
    ...
```

The same module includes `status_router` without a prefix. That router exposes `GET /status`; it does not define `/api/v1/health`. No `/api/v1/health` registration was found in the selected application module or its included status router.

The distinct root `Dockerfile.production` health check uses `/health`, which matches the route in `tiannara_api.main`. This finding is limited to `docker/api/Dockerfile`.

**Impact:** the API process may answer requests successfully while Docker's health probe receives a not-found response at `/api/v1/health` and marks the container unhealthy. Any orchestration or operator relying on container health will receive a false-negative health state.

**Status:** STATIC_HEALTHCHECK_MISMATCH. No HTTP request was sent to a running container.

## 6. RL-537 — HIGH — Observatory UI container's default API target resolves to itself/client localhost, not the separately deployed API

### Evidence

The Observatory deployment documentation describes two separate containers:
- `tiannara/observatory-api`, published on port 4000;
- `tiannara/observatory-ui`, published on port 3000.

Its `Dockerfile.ui` builds a separate Next.js server image and starts it with `npm start`.

The UI helper `apps/observatory_ui/src/lib/api.ts` defines:

```typescript
const BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api/v1'
```

Its API calls use `fetch(`${BASE}${path}`)`.

The Next.js configuration separately defines:

```typescript
destination: "http://localhost:4000/api/:path*"
```

The Dockerfile does not supply an `ARG` or `ENV` for `NEXT_PUBLIC_API_URL` during the frontend build. The README's Docker run examples start the API and UI containers separately and do not pass a usable API URL to the UI container.

With the default configuration:
- Inside the UI container, `localhost:4000` refers to the UI container itself, not the API container.
- For browser-side calls using the compiled `NEXT_PUBLIC_API_URL` fallback, `localhost:4000` refers to the browser user's own machine.
- The Next rewrite also targets the UI container's loopback address when it executes from the UI server.

The UI README lists `NEXT_PUBLIC_API_URL` as a production variable, but the Dockerfile does not define a build argument or otherwise inject it into the build. A runtime-only environment variable is not sufficient for a variable already embedded in the Next.js client bundle during build.

**Impact:** the separately deployed Observatory UI cannot reliably reach the API using the image's default configuration. A successful UI image build and Next.js process start would not prove that dashboard data calls reach the API.

**Status:** STATIC_UPSTREAM_CONFIGURATION_DEFECT. No API/UI containers were started.

## 7. Existing Observatory API startup issue — RL-529 reaffirmed

`tiannara_observatory/Dockerfile.api` builds the Mix release and copies it into the final image, but declares:

```dockerfile
CMD ["/app/bin/server"]
```

The Observatory runtime config comments show the generated `bin/server` helper as an optional output of `mix phx.gen.release`; its direct release-start example is `PHX_SERVER=true bin/observatory_api start`. The Dockerfile runs `mix release`, not `mix phx.gen.release`, and the inspected tree contains no tracked `rel/overlays/bin/server`.

The production runtime config also raises when `DATABASE_URL` or `SECRET_KEY_BASE` is missing. The Dockerfile sets `PHX_SERVER=true`, but it does not provide those two runtime values; a deployment must inject them.

**Disposition:** RL-529 remains a static command-path issue. The required environment variables must also be supplied at runtime. No image or release was built or started.

## 8. SaaS and production-image startup issues carried forward

The current branch retains the following already-recorded issues:
- RL-526: root `Dockerfile.production` references absent `requirements-production.txt`; its health path `/health` itself matches the Python API handler.
- RL-531: `docker/saas/Dockerfile` uses Node 18 while the app pins Next.js 16.2.6.
- RL-532: the SaaS Dockerfile copies `/app/out` but the current Next config does not configure static export. Static-export mode also needs a proxy/routing design because the app declares API and WebSocket rewrites.
- RL-523: runtime Elixir production config is absent.

No repeated findings were created for these issues.

## 9. New finding register

| ID | Severity | Finding | Status |
|---|---|---|---|
| RL-535 | HIGH | Python core Docker CMD executes a module with class definitions only; it never constructs or runs the worker | STATIC_ENTRYPOINT_DEFECT |
| RL-536 | HIGH | Python API Docker health check calls `/api/v1/health`, but the selected FastAPI app registers `/health` | STATIC_HEALTHCHECK_MISMATCH |
| RL-537 | HIGH | Observatory UI image defaults API calls and rewrites to localhost:4000 although API and UI are separate containers; image does not inject the documented API URL at build time | STATIC_UPSTREAM_CONFIGURATION_DEFECT |

## 10. Required next verification

1. Give the Python core image a real process entrypoint that constructs its dependencies, runs an explicit worker lifecycle, handles termination, and reports failure if initialization fails. Then build and run the image and inspect its process lifetime.
2. Align the Python API Docker health check with the route actually registered by `tiannara_api.main`, then verify the health probe against a running image.
3. Define one explicit Observatory deployment network and a build/runtime configuration contract for the UI API target. Verify browser requests and server rewrites across the separate API/UI containers.
4. Resolve the Observatory API release executable path and supply its required database URL and Phoenix secret; test the image's actual start command and readiness route.
5. Add an artifact matrix CI gate that builds each Dockerfile, starts each container, waits on the declared health/readiness endpoint, and records image digests plus logs.
6. Keep unit/test success, image build success, container start success, and application readiness as separate statuses.

## 11. Final disposition

**OPEN — 3 new findings (RL-535–RL-537).** The Python core image's configured command does not start the declared worker. The Python API image's Docker health check targets a path not registered by the FastAPI app it starts. The Observatory UI's default upstream points to localhost rather than the separately deployed API, and the declared UI Docker build does not inject its documented API URL. RL-529 and the existing SaaS/runtime release blockers remain open. Current audit-branch Elixir CI and cross-platform verification passed, but those workflows do not exercise these containers or prove their runtime contracts.

No production source, Dockerfile, Compose file, or deployment configuration was modified. This checkpoint adds an audit report only.
