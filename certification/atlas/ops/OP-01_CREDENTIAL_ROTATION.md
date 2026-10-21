# OP-01 — exposed credential: removal record, rotation procedure and evidence template

**Finding:** F-ARC-008 / F-PLT-005 (critical) — tracked production overlay contained literal secret values.
**Operator disposition (2026-10-21):** rotate the credential and move runtime configuration to a secret-manager
reference; handle history remediation under the repository's secret-handling procedure; record evidence of rotation
**without reproducing the secret**.
**Hard condition HC-1:** the exposed credential must be dealt with before remediation proceeds.

**This record contains no secret value.** Locations are given as paths and key names only.

---

## 1. What was removed (code-side, executed in this repository)

| # | Location (before) | Action | State now |
|---|---|---|---|
| 1 | `tiannara_runtime/k8s/phase6/overlays/production/kustomization.yaml:35-37` — `secretGenerator.literals` with two literal values | Replaced with `secretGenerator.env`, so both values are read from the **build environment** at deploy time. The generated secret keys (`release-cookie`, `nats-auth-token`) are unchanged, so `base/runtime-deployment.yaml:49-51` (`secretKeyRef`) keeps working. | **No literal value remains in the tracked tree.** The build now **fails closed** if a variable is unset. |
| 2 | `tiannara_runtime/k8s/phase6/base/` had **no `kustomization.yaml`**, while the overlay references `../../base` | Added a tracked base `kustomization.yaml` listing the four base resources (`namespace.yaml`, `gpu-node-selector.yaml`, `runtime-deployment.yaml`, `nats-cluster.yaml`). | The overlay can now be built from tracked files, so the secret reference is verifiable rather than theoretical. |
| 3 | `certification/audit/DIRECTORY_AUDIT_2026-10-19.md` §1.2 — the finding quoted the literal values inline | Values replaced with a redaction marker; the finding, its supersession and the open rotation obligation are preserved. | The tracked audit trail no longer contains the secret. |

**Verification (reproducible):**

```
git grep -n "tiannara_nats_prod_token" -- .          # expect: no matches
git grep -n "tiannara_phase6_cookie_prod" -- .       # expect: no matches
```

Both were run after the change and returned no matches. The earlier scan that found them also confirmed
**no other literal secret exists under `tiannara_runtime/k8s/` or `config/`**; a repository-wide scan for AWS keys,
Slack tokens and PEM private-key headers in tracked files also returned no matches. The `tiannara_api` database URL
helper flagged by the earlier scanner is a false positive — it builds the URL from environment variables with an empty
password default and contains no credential.

## 2. What was NOT done (and is not claimed)

| Item | Status | Why |
|---|---|---|
| **Rotating the credential in the running environment** | **NOT DONE — operator action** | Rotation requires cluster and secret-manager access, which this workspace does not have. The operator's disposition explicitly distinguishes *handling* from *claiming rotation*. |
| **Git history remediation** | **NOT DONE — operator action** | The literal values remain in the repository's history. Remediation (filter-repo / history rewrite / force-push) is a destructive, operator-owned procedure under the repository's secret-handling policy. **No history rewrite was performed and none should be performed without explicit operator approval.** |
| Deleting the dangling `nats-auth-token` key | Not done | The key is not consumed by any tracked manifest today; removing it is a deployment-contract decision for the operator, not a security fix. It is now inert (never a literal). |
| Untracked key-shaped files in the workspace root (`pem*.txt`, `key_h.txt`, `MediaCreationTool_*.exe`, `Tiannara.exe`) | Reported, not modified | Untracked working-tree artifacts, outside the repository's tracked scope. They are not in git and therefore not exposed through the repository, but they should be reviewed by the operator. |

## 3. Rotation procedure (operator, with cluster access)

1. **Generate** new values for both keys (`release-cookie`, `nats-auth-token`) in the secret manager — do not derive
   them from the old ones, and do not paste them into any ticket, commit, or chat.
2. **Store** them under the secret-manager path that the deployment pipeline reads (the `secretGenerator.env` contract
   expects the environment variable names to match the secret keys: `release-cookie`, `nats-auth-token`).
3. **Roll** the affected workloads: the phase-6 runtime deployment and the NATS StatefulSet in the
   `tiannara-phase6` namespace. The rollout must be ordered so that the NATS cluster accepts the new token before the
   runtime starts using it, and the old value must be invalidated in the NATS configuration at the same time.
4. **Confirm** the rotation by observing the running deployment's secret references and the NATS server's auth
   configuration — not by reading the value into a log.
5. **Record** the evidence using the template in §4, then update this record's status line to `ROTATION VERIFIED`.

**Ordering note:** step 1–2 may happen at any time; step 3 must not precede step 2. Because the overlay now reads the
values from the environment, a rotation is delivered by re-running the deploy with the new environment — no repository
change is required, and no repository change should be made to carry a rotated value.

## 4. Evidence template (to be completed by the operator; do not include secret values)

```
OP-01 rotation evidence
  date (UTC):            <YYYY-MM-DDTHH:MM:SSZ>
  operator / approver:   <identity>
  environment:           <cluster / namespace>
  secret-manager path:   <reference, no value>
  keys rotated:          release-cookie, nats-auth-token
  previous values:       <revoked — reference only, no value>
  rollout:               <workload, strategy, start/end timestamps>
  negative check:        <evidence that the previous value no longer authenticates>
  verification:          <how the running deployment was observed to use the new reference>
  history remediation:   <procedure applied or "deferred with reason", operator decision>
```

## 5. Atlas update

| Register | Change |
|---|---|
| `findings_ledger.csv` | F-ARC-008 and F-PLT-005 move to `FIXED_PENDING_VERIFICATION` for the *exposure-removal* portion only, with this record as the evidence reference. The **rotation** and **history remediation** remain OPEN obligations recorded here. |
| `capability_register.csv` | CAP-PLT-009 (storage/secrets) and CAP-PLT-010 (deployment/CI) note that deployment-time secret injection is implemented and that the overlay now builds from tracked files; their evidence state is unchanged because rotation is unverified. |
| `decisions_register.md` | OP-01 disposition status confirmed (Part E.1). |

**Nothing in this record asserts that a credential was rotated.** The exposure is removed from the tracked repository;
the rotation is an operator action with an evidence template ready.
