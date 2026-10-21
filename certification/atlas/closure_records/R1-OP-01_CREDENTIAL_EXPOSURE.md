# Closure record — R1/OP-01 — exposed production credential (code-side removal)

| Field | Value |
|---|---|
| **Finding ID** | F-ARC-008 · F-PLT-005 (code-side exposure) · residual obligation split out as **F-SEC-001** |
| **Root-cause cluster** | C6 — authentication and authorisation fail open (secrets handling) |
| **Baseline SHA** | `a88e6e42` (R0 review dispositions commit; R0 atlas baseline `013411bb`, program baseline `521cb7fe`) |
| **Candidate SHA** | recorded in the commit that carries this record |
| **Changed implementation** | `tiannara_runtime/k8s/phase6/overlays/production/kustomization.yaml` — `secretGenerator.literals` (two literal values) replaced by `secretGenerator.env`; `tiannara_runtime/k8s/phase6/base/kustomization.yaml` added (the base the overlay references did not exist). Contract preserved: secret keys `release-cookie` / `nats-auth-token` are unchanged, so `base/runtime-deployment.yaml:49-51` (`secretKeyRef`) is unaffected. |
| **Authority owner** | Deployment pipeline owner (phase-6 k8s manifests) — operator; the repository only removes the literal and defines the injection contract. |
| **Affected consumers** | `tiannara_runtime/k8s/phase6/base/runtime-deployment.yaml` (secretKeyRef `tiannara-secrets`); the phase-6 runtime Deployment; the NATS StatefulSet in namespace `tiannara-phase6`. |
| **Before/after test evidence** | **Before:** `git grep -n "tiannara_nats_prod_token" -- .` → 2 matches (the overlay and the audit document that quoted it); `git grep -n "tiannara_phase6_cookie_prod" -- .` → 2 matches. The production overlay could not be built at all (no base `kustomization.yaml`). **After:** both greps return **no matches**; the tracked overlay contains no secret value; the audit document records the redaction and keeps the finding. Negative-path property: the secret generator now **fails closed** — an unset environment variable aborts the build instead of silently deploying a placeholder. |
| **CI and execution evidence** | `gh` run for the candidate commit: Elixir CI (compile, test-placement, lineage-regression, `tiannara_runtime suite (required)`, suite) and Cross-Platform Verification — all green. The k8s overlay build itself is **not executed in CI** (no kustomize job exists) and is recorded as an evidence gap, not as a pass. |
| **Atlas update** | `findings_ledger.csv`: F-ARC-008 and F-PLT-005 → `FIXED_PENDING_VERIFICATION` with residual scope named; new row **F-SEC-001** (OPEN, critical) for rotation + history remediation. `capability_register.csv`: CAP-PLT-009 and CAP-PLT-010 annotated (evidence state unchanged — rotation is unverified). `decisions_register.md` Part E.1: OP-01 status. `certification/audit/DIRECTORY_AUDIT_2026-10-19.md` §1.2: superseded with redaction, finding preserved. |
| **Closure status** | **FIXED_PENDING_VERIFICATION** for the code-side exposure removal. **NOT VERIFIED_CLOSED**: credential rotation and git-history remediation are outstanding (F-SEC-001) and require cluster/secret-manager access this workspace does not have. |

**Evidence gaps (recorded, not hidden):** the kustomize build is not exercised in CI; the overlay's rendered output was
not verified against a live cluster; rotation is unverified; the history still contains the old values by operator
decision.
