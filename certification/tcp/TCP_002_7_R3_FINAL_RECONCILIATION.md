# TCP-002.7-R3 Final Reconciliation

**Purpose:** Superseding documentation for the TCP-002.7-R3 checkpoint sequence.
**Workstream:** W0 — Activate Existing Capabilities
**Baseline:** `fd7babafc42cccf7d290b6f6af59fb6a6fc63bf4` (TCP-002.7-R2)
**Baseline parent:** `05ee148e88d4ba066a9c3c085363eced9d0b5872` (TCP-002.7-R1)
**Branch:** `feat/tcp-002-7-r3-transactional-recovery`

This document reconciles the commit history, evidence artifacts and test
results for the TCP-002.7-R3 checkpoint sequence without rewriting prior
records.

## Commit sequence

| Commit | SHA | Purpose |
|---|---|---|
| A — implementation | `37acceb53f6c177bc91ebee05ccd69bb5be3b033` | EventStore fail-closed recovery, write poisoning, transactional ResolutionRegistry recovery, 42-test isolated suite, implementation report, manifest generator |
| B — evidence | `96155353fa22de6cbca5650ae423977a383ce93a` | Evidence manifest (SHA-256 digests verified against the working tree), register row TCP-B-064 → RESOLVED, master assessment §13 |
| C — CI record | `500730e40b84cf947ff2abce66e6404e89fcd033` | Elixir CI and Cross-Platform Verification outcomes recorded; the two unused-`ctx` warnings identified by the B push's CI logs renamed to `_ctx`; manifest regenerated with a `ci_record` and `FAIL_PREEXISTING_ONLY` stage 8 |
| D — reconciliation | `df9231a73497d8303a446b31e20a2f2e22431ddd` | CI record for the C push added to the report, master assessment and manifest; report header/plan wording corrected; this document. D's SHA was verified against the remote after the push (`git ls-remote` = local HEAD) |
| E — review addendum | this commit | Independent-review outcome recorded; legacy `stream/2`/`since/2` compatibility-reader caveat documented in the report, this document and the manifest; D push's CI record (§12.3 of the report) added; documentation-only — no code, no tests, no disposition change |

Commit E's own SHA is **not embedded** in this file or in the manifest — a
commit cannot contain its own SHA. It is recorded as the branch HEAD at push
time. Commit D's SHA (previously not embedded) is now committed in this file,
and was likewise verified against the remote (`git ls-remote` = local HEAD at
the time of the D push).

Commit D's own SHA is **not embedded** in this file or in the manifest — a
commit cannot contain its own SHA. It is recorded as the branch HEAD at push
time and can be read with

```
git rev-parse HEAD
```

on `feat/tcp-002-7-r3-transactional-recovery` after the push that carries
this document.

## Parent relationships

- A parent: `fd7babaf` (TCP-002.7-R2)
- B parent: `37acceb5` (A)
- C parent: `96155353` (B)
- D parent: `500730e4` (C)
- E parent: `df9231a7` (D)

All are linear descendants on one branch. No force-push or history rewrite
was performed at any stage. The branch is 5 commits ahead of the baseline and
0 behind it.

## Evidence artifacts

| Artifact | Path |
|---|---|
| Implementation report (§12 CI record for all three pushes) | `certification/tcp/TCP_002_7_R3_IMPLEMENTATION_REPORT.md` |
| Evidence manifest | `certification/tcp/TCP_002_7_R3_EVIDENCE_MANIFEST.json` |
| Evidence manifest (same bytes, evidence tree) | `certification/evidence/tcp002_7_r3/TCP_002_7_R3_EVIDENCE_MANIFEST.json` |
| Manifest generator | `tools/tcp/tcp0027r3_evidence_manifest.py` |
| Append-only register | `certification/tcp/TCP-001_COMPLETION_REGISTER.csv` |
| Master assessment | `certification/tcp/TCP-001_MASTER_COMPLETION_ASSESSMENT.md` |
| This reconciliation document | `certification/tcp/TCP_002_7_R3_FINAL_RECONCILIATION.md` |

The manifest is generated, never hand-edited. Its `artifacts` list carries
SHA-256 digests for the five report/evidence documents above (excluding the
manifest's own digest, which would change on every regeneration, and excluding
this reconciliation document, which is created after the manifest). All five
digests were verified against the on-disk files after the final regeneration
(`ALL_MATCH`). `implementation_commit` resolves to commit A; `evidence_commit`
is deliberately `null` with an explanatory `evidence_commit_note`.

## Test evidence

Executed on the final source state (after commit C's `_ctx` fix):

- Dedicated adversarial suite
  (`test/tiannara/forecasting/resolution_registry_test.exs`): **42 tests, 0 failures**,
  exit 0, at seeds 0, 1, 2, 3, 4, 5, 123456.
- Application forecasting + research: **617 tests, 0 failures** (2 seeds,
  0 and 123456).
- Executive set: **88 tests, 0 failures** (2 skipped), seed 0.
- Runtime regression (`tiannara_runtime`, cwd): **792 tests, 32 properties, 0 failures**, seed 0.

All isolated instances used temp files; the application-wide log was never
touched. Exit code was 0 for every executed command.

What is proven (adversarially, in isolation): incomplete history is never
treated as complete; a failed durable step is never reported as success; a
replay that cannot be trusted publishes nothing; a stale index does not
outlive an integrity failure; exact retries are idempotent; conflicting
records are refused.

What is **not** proven: behavior under real disk corruption, real power loss,
real filesystem `fsync` semantics or a real second writer; performance on long
logs (full re-read on every append and replay is deliberate, O(n) and
unmeasured); independent verification; calibration; model mutation.

## CI record

The branch was pushed three times and each push triggered `Elixir CI` (all-branch
workflow) and `Cross-Platform Verification` (all-branch workflow):

| Push | Workflow | Run ID | Conclusion |
|---|---|---|---|
| B (`96155353…`) | Elixir CI | `43700070002` | **failure** |
| B | Cross-Platform Verification | `43700069993` | **success** |
| C (`500730e4…`) | Elixir CI | `43702102210` | **failure** |
| C | Cross-Platform Verification | `43702102197` | **success** |
| D (`df9231a7…`) | Elixir CI | `43703627182` | **failure** |
| D | Cross-Platform Verification | `43703627228` | **success** |

Elixir CI job-by-job on all three pushes: `compile` success, `test-placement`
success, `tiannara_audit suite (required)` success, `lineage-regression`
success, `tiannara_runtime suite (required)` success; `suite` **failure** and
`tiannara_runtime quarantine (non-blocking)` **failure**.

On all three pushes the `suite` failure is exactly the ten pre-existing
`ResearchForecastingIntegrationTest` failures
(`research_forecasting_integration_test.exs` lines 89, 104, 116, 131, 143,
153, 166, 182, 191, 208 — the D run logs its first failure at line 88, a
line-ending offset; the same tests, the same set) and the quarantine failure
is exactly the four pre-existing non-blocking failures
(`passive_mode_test.exs:38`, `reactivity_test.exs:69`,
`omega_robustness_test.exs:25` and `:48`). **Zero new failures attributable to
this work.**

The only R3-related lines in the first push's logs were two compile warnings
(unused `ctx` in `resolution_registry_test.exs`); those were renamed to `_ctx`
in commit C. The C and D pushes' failed-job logs contain no lines from
`resolution_registry_test.exs` — only the five pre-existing warnings for the
unrelated `Tiannara.CEL.Services.EventStore` module (D: zero R3-related lines
whatsoever). The dedicated suite was re-executed after the change at seeds
0/1/2/3/4/5/123456 (42 tests, 0 failures).

The disposition `IMPLEMENTED_WITH_PARTIAL_EVIDENCE / VERIFICATION_BLOCKED`
is unchanged by CI; the checkpoint is not independently verified and is not
claimed as passing CI (the `suite` job fails for pre-existing reasons that
long predate this branch).

## Preservation of tracked runtime state

- Tracked checkpoints under `tiannara_runtime/data/cpl/checkpoints/`: **13,596** files,
  all preserved, **0 deletions** across `fd7babaf..HEAD`.
- The three pre-existing untracked files
  (`certification/atlas/r0_refresh_2026-10-24.json`,
  `certification/audit/GENSERVER_OWNERSHIP_INVENTORY.csv`,
  `certification/audit/GENSERVER_OWNERSHIP_INVENTORY.md`) remain untracked and
  were never staged.
- `cel_memory_v2.dets` was restored before every commit; it is not staged
  and its working-tree diff is empty.
- The R3 branch adds the five commits above and touches no path under
  `tiannara_runtime/data/cpl/checkpoints/` or any of the three protected
  untracked files.
- Nothing in the R3 sequence was force-pushed; `git rev-list --count fd7babaf..HEAD`
  = 5, `--count HEAD..fd7babaf` = 0.

## Register after this checkpoint

67 rows — **43 open, 22 resolved, 2 partial**.

`TCP-B-064` (resolution not durably persisted) is **RESOLVED** by this
sequence. Its closure evidence is:

- resolutions persist through the durable event log via the canonical commit
  path (`resolution_registry.ex` → `EventStore`), bound to forecast,
  observation, evidence and verification record;
- recovery is a three-stage transaction with atomic single-object ETS
  publication;
- failed recovery invalidates any prior index and publishes nothing;
- exact retries are idempotent (`:duplicate_identical_resolution_event`) and
  conflicting identities are refused (`:conflicting_forecast_resolutions`);
- restart recovery is executed-tested (42-test suite, 0 failures at 7 seeds).

This closes the **persistence capability**. It does **not** claim that any
genuine resolution has been produced — that remains `TCP-B-048` (no live
external source; no registered forecast with a reachable live outcome
definition).

## Governance

- `Tiannara.Forecasting.ModelUpdateGate` — unchanged: `authority: :none`,
  `production_mutation: :forbidden`, `human_review_required: true`.
- `TCP-B-066` — **PROPOSED — NOT RATIFIED**; no real limited-assurance
  resolution is authorized.
- No model mutation, deployment, registry promotion, policy ratification,
  constitutional decision or physical actuation occurred.
- No synthetic evidence was presented as real; simulated fault injection is
  labelled as such; the `kill_after_write` case performs a real process kill at
  the process layer but no hardware, firmware, filesystem or power-loss fault
  was injected.
- `RL-565` remains **HIGH / OPEN**; `RL-564` **OPEN**; `F-ARC-018` **OPEN**.

## Open findings (unchanged by this checkpoint)

| Finding | Status |
|---|---|
| TCP-B-048 | OPEN / BLOCKED — no live external source; lifecycle remains `FORECAST_REGISTERED` |
| TCP-B-061 | OPEN — no trusted integrity anchor outside the log's storage boundary |
| TCP-B-062 | OPEN — single-writer log |
| TCP-B-058 | PARTIAL — integrity established, publisher authenticity not |
| TCP-B-067 | OPEN — verification authority key is ephemeral/process-exposed |
| TCP-B-056 | OPEN — pseudo-measurements |
| TCP-B-046 | OPEN — cross-stack boundary |
| TCP-B-065 | OPEN — unbounded runtime file growth |
| TCP-B-066 | PROPOSED — NOT RATIFIED |

## Independent verification

Not performed. No independent verifier was available for the executed tests or
the working-tree preservation claims; those remain locally reported. The
tests are self-authored against the contract asserted in the report.

## Independent review (post-push, performed on the published branch)

An independent review of the *committed and pushed* state was performed after
commit D, before commit E. It verified:

- the commit chain `fd7babaf → 37acceb5 → 96155353 → 500730e4 → df9231a7`,
  resolved D to `df9231a73497d8303a446b31e20a2f2e22431ddd`, and confirmed via
  the GitHub API that the branch is 4 commits ahead of the R2 baseline and
  0 behind (linear, no force-push);
- all six workflow runs against their actual commit SHAs (table above),
  including that the two R3 test-file warnings present on push B are absent
  on pushes C and D;
- D's failed-job logs: zero references to `resolution_registry_test.exs`,
  zero to `ResolutionRegistry`, five to the separate
  `Tiannara.CEL.Services.EventStore`;
- the source: the fail-closed states, poisoning, transactional publication,
  duplicate/conflict closure and the trust-gated commit path.

The review agreed with the disposition `IMPLEMENTED_WITH_PARTIAL_EVIDENCE /
VERIFICATION_BLOCKED` and with narrowing TCP-B-064's closure to a
persistence-capability finding. It explicitly did **not** re-execute the local
tests or the local preservation claims, and noted that the absence of R3 lines
in failed logs does not prove which passing tests executed. It raised one
bounded compatibility caveat, accepted here: the legacy readers `stream/2` and
`since/2` return bare event lists and discard parser diagnostics, and
`stream/2` includes `:unverified_legacy` events unlabelled, so a consumer of
those two readers could mistake a verified prefix of a damaged or truncated log
for complete history. The R3 recovery path itself uses `read_records/1` plus
live `health/1` and is unaffected. Making the compatibility readers explicit
is bounded next work (report §8 item 10); the readers are unchanged in this
sequence.

## Sequence disposition

Storage and recovery are **implemented and executed-tested**. They are **not
independently verified**, they are **not** protected against real hardware
faults, they do **not** prove any predictive claim, and they are **not**
claimed as passing CI (the pre-existing `suite` job fails on all three pushes
for reasons that predate this branch). The genuine forecast outcome lifecycle
remains blocked at acquisition (`TCP-B-048`) and at policy ratification
(`TCP-B-066`).

## Next

1. ~~Push commit D and verify remote HEAD equals local HEAD.~~ **Done** —
   pushed at `df9231a7`; remote HEAD verified equal; CI recorded above.
2. ~~Report the final dispositions honestly, including the CI outcome on all
   three pushes.~~ **Done** — see the report §12 and this document; commit E
   records this review and the D-push CI outcome.
3. Make the legacy compatibility readers (`stream/2`, `since/2`) explicit
   about incomplete or unverified history (bounded next engineering work;
   unchanged here).
4. Independent verification of the storage/recovery contract (none available
   in this environment).
5. TCP-002.7's genuine forecast outcome lifecycle remains out of scope until
   `TCP-B-048` and `TCP-B-066` are resolved by an authorized process.
