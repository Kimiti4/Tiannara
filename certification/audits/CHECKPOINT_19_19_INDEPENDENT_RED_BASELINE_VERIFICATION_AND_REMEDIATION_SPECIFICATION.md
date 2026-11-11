# Checkpoint 19.19 — Independent Red-Baseline Verification and Separate RL-564/RL-565 Remediation Specification

**Date:** 2026-11-12  
**Pinned candidate under verification:** `268d2e9b442a504873a6f4af691a836ead79120b`  
**Candidate parent / pinned implementation source:** `de231a78db542a6172d7bd1ffd46e8a766deafa4`  
**Audit branch at start:** `audit/consolidated-findings-r0a-2026-10-31`  
**Starting audit-branch head:** `57fd903a401075fe280a65ebe37db8108ba312a4`  
**Mode:** read-only independent verification; test execution only in a disposable worktree; no production change, registry promotion, deployment, or physical actuation

**Disposition:** `RED_BASELINE_INDEPENDENTLY_REPRODUCED` — `ORACLES_VALIDATED_WITH_DOCUMENTED_WEAKNESSES` — `RL-564_AND_RL-565_REMEDIATION_SPECIFICATIONS_ISSUED_SEPARATELY` — `NO_PRODUCTION_CHANGE` — `FINDINGS_REMAIN_OPEN`

Companion artifacts:

- `certification/audits/CP19_19_RL564_REMEDIATION_SPECIFICATION.md`
- `certification/audits/CP19_19_RL565_REMEDIATION_SPECIFICATION.md`
- `certification/audits/CP19_19_AUTHORIZATION_TRUST_CHAIN_DIAGRAM.md`

---

## 1. Executive determination

CP19.18 produced a tests-only adversarial suite for two distinct authority defects:

- **RL-564** — a caller-selected authorization ID can be registered in the durable `MintRegistry` through the public `Tiannara.Omega.HumanDelivery.Authorization.record_mint/1` wrapper, because the registry authenticates the *module on the caller's stack*, not an issuance capability. A forged human grant can then satisfy the downstream registry-backed admission checks.
- **RL-565** — `Tiannara.Council.MachineAuthorization.mint/2` accepts a caller-constructed `Tiannara.Council.Authorization` struct as if Council had issued it. A fabricated decision can be minted, bound, and presented to `Tiannara.World.UnifiedWorldModel.delete_entity/2`, which deletes a canonical entity without a Council-issued decision receipt.

CP19.19 independently reproduced the CP19.18 red baseline on the pinned candidate:

| Run | Partition | Seed | Result |
|---|---|---|---|
| Full suite A | `cp19_19_baseline_a` | `0` | **18 tests, 12 failures** |
| Full suite B | `cp19_19_baseline_b` | `123456` | **18 tests, 12 failures** |
| Controls only | `cp19_19_controls_a` | `0` | **18 tests, 0 failures, 12 excluded** |

The 12 failures are identical at both seeds. They are not setup errors, compilation errors, skipped tests, or missing dependencies. Every red case fails because the operation that the safe contract requires to be refused returns an unsafe success:

- `R564-01` and `R564-07` return `:ok`;
- `R564-02`, `R564-03`, `R564-04`, `R564-08a`, `R564-08b` return `{:ok, ...}` from the consumer;
- `R565-01`, `R565-02`, `R565-03`, `R565-04` return `{:ok, ...}` from `MachineAuthorization.mint/2`, and the `R565-03` chain proceeds through bind and delete;
- `R565-08` returns `{:ok, ...}` from `MachineAuthorization.mint/2` while a Council emergency is active.

The six controls pass while exercising their intended branches: direct non-allowlisted mint refusal, one-shot Phase4 replay, wrong-operation refusal at the delete sink, wrong-target refusal, one-shot delete replay, and genuine Council mint/bind.

The oracles are **valid for the red baseline but not yet sufficient as closure oracles**. Several non-control cases accept a broad list of errors, one case uses a mint-error helper to assert a bind refusal, and the emergency case accepts any error. Those weaknesses are enumerated with required strengthening in §5. The failures themselves are genuine, but a green run under the current assertions would not, by itself, prove that the intended security property is enforced.

Three groups of source-confirmed behavior are **not covered** by CP19.18 and must not be treated as closed by a green version of it:

1. post-bind decision substitution at the UWM delete boundary (the sink recomputes the struct's self-hash and never compares the registry-anchored `council_decision_ref` to the presented decision);
2. multiple machine mints from one genuine Council decision, and restart/tampered durable registry records;
3. verified human identity (the `AuthenticatedHumanIdentity` constructor remains self-asserted; that is RL-426 / RL-479 territory) and emergency enforcement at the effect boundary rather than only at mint.

RL-564 and RL-565 remain **HIGH / OPEN**. `F-ARC-018` remains **OPEN**: the per-run DETS partition is removed and the suites are deterministic, but repository-root persistence artifacts remained outside the per-run root, so test isolation is still partial.

No production remediation is performed or claimed here. The two companion specifications are design inputs for separate implementation checkpoints. They deliberately remain separate: RL-564 has a **human** trust root and issuance process; RL-565 has a **Council** trust root and issuance process. A single shared validator that accepts either proof, or that treats "the registry says granted" as sufficient for both, would collapse two independent authority boundaries and is prohibited.

---

## 2. Scope, provenance, and evidence identity

### 2.1 Candidate and implementation pin

| Item | Value |
|---|---|
| Candidate commit | `268d2e9b442a504873a6f4af691a836ead79120b` |
| Candidate parent | `de231a78db542a6172d7bd1ffd46e8a766deafa4` |
| Candidate subject | `test(omega): add RL-564/RL-565 adversarial red-baseline suites` |
| Candidate change | 2 files, 610 insertions, tests only |
| Production/config diff `de231a78..268d2e9b` over `lib config mix.exs mix.lock` | empty |
| RL-564 test blob | `91a46eae7f2bc63d112d1f4275cbb5c41ff4c4bc` |
| RL-565 test blob | `b6ad43f19f8ad154f222fc14ac3a05c0896331fa` |

The candidate is on local branch `test/cp19-18-rl564-rl565-red-baseline`. It is not pushed or merged. No CI or runtime certification exists for the candidate, and CP19.19 does not claim one.

### 2.2 Prior checkpoint identity

| Artifact | Commit | Blob |
|---|---|---|
| CP19.17 report | `6c46d7b3e67a84f83d7ab808cd5809bea182b705` | `451963e0ca3c48a584df76ee28abde2260adebb0` |
| Consolidated register (at CP19.17 close) | `57fd903a401075fe280a65ebe37db8108ba312a4` | `d6decc5f211c7167febb64909ffe6b1524e121d9` |
| CP19.17 report local copy | — | `451963e0ca3c48a584df76ee28abde2260adebb0` (verified equal) |

The CP19.17 report is `certification/audits/CHECKPOINT_19_17_RL564_ADVERSARIAL_REGISTRY_MINT_REGRESSION_AND_EFFECT_CONSUMER_MATRIX.md`. Its design cases R564-01 through R564-11 are the parent design; CP19.18 implemented R564-01 through R564-04, R564-06 through R564-09, and R565-01 through R565-08.

### 2.3 Environment

| Component | Version |
|---|---|
| Elixir | 1.18.4 |
| Erlang/OTP | 28 |
| ERTS | 16.4 |
| ExUnit execution | serial (`async: false`), `max_cases: 1` |

### 2.4 PR #13 boundary

PR #13 remains a separate draft regression baseline:

| Item | Value |
|---|---|
| Head commit | `8f03c32ad10fa9ad654f987d30dde1bc9a53df5d` |
| Parent | `496d833888bce78e6ed4dbbcb104c7f7e0b62c95` |
| Subject | `Test: isolate malformed HAI impact regression cases` |
| Ref containing the object | `remotes/origin/pr-13` only |

CP19.19 did not modify, retarget, merge, push, or mark ready any PR. It did not touch the `pr-13` ref.

### 2.5 Audit worktree and preservation

CP19.19 documentation was authored in a separate worktree based on the CP19.17 register tip `57fd903a401075fe280a65ebe37db8108ba312a4`, on local branch `audit/cp19-19-red-baseline-integrity`, at:

`C:\Users\user\AppData\Local\Temp\opencode\cp19_19_audit`

The following were left untouched: the main repository on `local/pr4` at `60933859f529db68863d6610ff5cf3901f722eb6`; the CP19.18 test worktree on `test/cp19-18-rl564-rl565-red-baseline` at `268d2e9b`; the `pr-13` ref; and all CP19.17 report/register content.

The main repository's pre-existing generated runtime artifacts and dirty state were not staged or committed.

---

## 3. Independent red-baseline reproduction

### 3.1 Commands and isolated partitions

Every run used a fresh `TEST_PARTITION`, which `config/test.exs` maps to `./test_data/dets/<partition>`. `test/test_helper.exs` wipes only that run root.

```text
TEST_PARTITION=cp19_19_baseline_a mix test \
  test/tiannara/omega/rl564_registry_issuance_adversarial_test.exs \
  test/tiannara/omega/rl565_council_decision_provenance_adversarial_test.exs \
  --seed 0 --trace

TEST_PARTITION=cp19_19_baseline_b mix test \
  test/tiannara/omega/rl564_registry_issuance_adversarial_test.exs \
  test/tiannara/omega/rl565_council_decision_provenance_adversarial_test.exs \
  --seed 123456 --trace

TEST_PARTITION=cp19_19_controls_a mix test \
  test/tiannara/omega/rl564_registry_issuance_adversarial_test.exs:221 \
  test/tiannara/omega/rl564_registry_issuance_adversarial_test.exs:337 \
  test/tiannara/omega/rl565_council_decision_provenance_adversarial_test.exs:144 \
  test/tiannara/omega/rl565_council_decision_provenance_adversarial_test.exs:160 \
  test/tiannara/omega/rl565_council_decision_provenance_adversarial_test.exs:178 \
  test/tiannara/omega/rl565_council_decision_provenance_adversarial_test.exs:221 \
  --seed 0 --trace
```

The control run excludes tests by `location`, not by a tag, a skip, or an environment flag. The twelve excluded tests listed by ExUnit are exactly the twelve red cases. All six selected controls executed.

### 3.2 Result summary

| Run | Tests | Failures | Excluded | Interpretation |
|---|---:|---:|---:|---|
| Baseline A (seed 0) | 18 | 12 | 0 | Red baseline reproduced |
| Baseline B (seed 123456) | 18 | 12 | 0 | Same failure identities; order differs |
| Controls A (seed 0) | 18 | 0 | 12 | All six controls green |

No test produced `** (CompileError)`, `** (UndefinedFunctionError)`, `** (MatchError)` from setup, `** (exit)`, or a missing-process error. All twelve red results are ExUnit equality/`in` assertion failures whose `left` is a success shape and whose `right` is the required refusal.

### 3.3 Red failure inventory

| Case | Test line | Required safe property | Observed unsafe result | Evidence class |
|---|---:|---|---|---|
| `R565-01` | 86 | Public `Authorization.approved/1` struct is not Council authority | `{:ok, ...}` from `MachineAuthorization.mint/2` | Assertion `left: {:ok, ...}` |
| `R565-02` | 95 | Manually reconstructed approved decision has no provenance | `{:ok, ...}` from mint | Assertion `left: {:ok, ...}` |
| `R565-03` | 104 | Fabricated mint → bind → delete cannot remove an entity | `{:ok, ...}` from `delete_entity/2` | Assertion `left: {:ok, ...}` |
| `R565-04` | 129 | Altered genuine decision cannot reuse provenance | `{:ok, ...}` from mint | Assertion `left: {:ok, ...}` |
| `R565-08` | 208 | Active Council emergency blocks new machine minting | `{:ok, ...}` from mint | Assertion `left: {:ok, ...}` |
| `R564-01` | 125 | Arbitrary ID cannot be self-registered through the human wrapper | `:ok` from `Authorization.record_mint/1` | Assertion `left: :ok` |
| `R564-02` | 133 | Wrapper-registered forged grant cannot enter Phase4 admission | `{:ok, ...}` from `ExecutionGovernance.begin/2` | Assertion `left: {:ok, ...}` |
| `R564-03` | 147 | Forged grant cannot reach the governed effect sink | `{:ok, ...}` from `GovernedEffectSink.execute/3` | Assertion `left: {:ok, ...}` |
| `R564-04` | 186 | Forged grant cannot deploy a candidate | `{:ok, ...}` from `DeploymentGateway.deploy/5` | Assertion `left: {:ok, ...}` |
| `R564-07` | 228 | Non-issuer cannot bind an existing minted authorization | `:ok` from `MintRegistry.record_bind/3` | Assertion `left: :ok` |
| `R564-08a` | 246 | Mint cannot be re-subjected to a different human | `{:ok, ...}` from `GovernedEffectSink.execute/3` | Assertion `left: {:ok, ...}` |
| `R564-08b` | 290 | Mint cannot be re-pointed to a different explanation digest | `{:ok, ...}` from `GovernedEffectSink.execute/3` | Assertion `left: {:ok, ...}` |

The `R564-01` and `R564-07` results are especially direct: the operation returns `:ok`, so the test's very first refusal assertion fails. The consumer cases return the sink/gateway/Phase4 success tuple; where the test has later callback or state assertions, those are not reached in the red run because the refusal assertion fails first.

### 3.4 Why these are genuine authorization violations

The pinned source confirms each success path:

- **`R564-01` / `R564-07`.** `MintRegistry.handle_call({:record_mint, ...})` authorizes the call by inspecting the blocked caller's stack and accepting frames whose first non-infrastructure module is in `@allowed_minters`. `Tiannara.Omega.HumanDelivery.Authorization` is allowlisted, and its public `record_mint/1` accepts only an ID. The registry then writes `{:mint, id, ts, nil}` and reports `:granted`. `record_bind/3` has no caller authentication at all; it only checks registration, consumption, prior binding, and the optional decision-ref anchor. A caller that supplies the same `council_decision_ref` as the registry record satisfies the anchor check.
- **`R564-02`.** `ExecutionGovernance.begin/2` checks the struct's `:granted` status, expiry, registry `:granted` status, descriptor identity, bind-or-verify, registry binding, ETS effect claim, and consume. It never checks a human issuance proof, a verified principal, or a registry-anchored grant digest. A wrapper-registered forged struct therefore passes the gate and returns `{:ok, %{grant: ..., effect_id: ...}}`.
- **`R564-03`.** `GovernedEffectSink.execute/3` checks presence, struct status, registry status, expiry, `AuthenticatedHumanIdentity.authenticated?/1` plus `identity.human_id == grant.human_id`, binding, descriptor identity, registry binding, and one-shot consume before invoking the sink and writing audit. A forged identity constructed by the public `authenticate/3` helper matches the forged grant, so the sink returns `{:ok, ...}`.
- **`R564-04`.** `DeploymentGateway.deploy/5` checks candidate status, certification shape, lineage shape, grant presence, `Authorization.valid_for?/2` against `candidate.proposal_id`, grant expiry, the same weak identity equality, `grant.candidate_content_hash == content_hash(candidate)`, registry status, `effect_id` presence, effect match, registry binding, and consume. A forged grant can set all of those fields, so the gateway returns `{:ok, record, deployed_candidate}`.
- **`R564-08a` / `R564-08b`.** The sink compares only the presented identity's `human_id` to the presented grant's `human_id`, and recomputes the effect identity from the descriptor. It does not compare either value to an unforgeable registry record, and it does not bind the explanation digest at all. Substituting `human_id` together with a matching forged identity, or substituting `explanation_id`, still returns `{:ok, ...}`.
- **`R565-01` / `R565-02`.** `MachineAuthorization.do_mint/3` accepts any struct for which `Authorization.permitted?/1` or `conditional_grant?/1` is true and `decided_at` is non-nil. It computes `decision_ref` by hashing the caller-supplied struct, registers that digest, and returns a machine grant. The digest proves only "this is the struct I was given"; it does not prove Council produced it.
- **`R565-03`.** The successful mint is bound with `MachineAuthorization.bind_effect/2`, which records the effect binding and the carried `council_decision_ref`. `UnifiedWorldModel.delete_entity/2` checks presence, registry/struct status, expiry, `authority_class`, `decision_type == :delete_entity`, the public decision predicates, non-nil `policy_applied` and `decided_at`, a self-recomputed `content_hash` against the struct's own stored hash, the effect descriptor, registry binding, node-local executed set, and consume. None of those checks calls Council or verifies a Council receipt, so the chain returns `{:ok, %{entity_id: ..., effect_id: ..., authorization_id: ...}}`.
- **`R565-04`.** The genuine decision is used to mint; the altered copy is then presented to mint. Because `do_mint/3` re-hashes the altered caller-supplied struct and never consults the Council-issued original, the altered decision mints successfully.
- **`R565-08`.** `Council.authorize/3` refuses decisions during an active emergency inside the Council GenServer. `MachineAuthorization.mint/2` does not call `Council.authorize/3`, does not consult `Council.emergency_state/0`, and does not verify any receipt. The direct mint therefore succeeds.

These are authorization violations in the tested, source-confirmed composition. They are not claims of remote reachability, production deployment, external infrastructure effect, physical actuation, or a completed real-world exploit.

### 3.5 Control inventory

| Control | Line | Branch exercised | Assertion / observed result |
|---|---:|---|---|
| `R564-06` | 221 | Direct non-allowlisted registry mint | `{:error, :minter_not_authorized}`; status `:not_registered` |
| `R564-09` | 337 | Concurrent Phase4 replay of one legitimate human grant | Exactly one `{:ok, _}`; every other result is `{:error, :already_consumed}` or `{:error, :effect_already_executed}`; status `:consumed` |
| `R565-05` | 144 | Genuine `:update_entity` grant presented to `delete_entity` | `{:error, :decision_type_mismatch}` |
| `R565-06` | 160 | Genuine grant bound to entity A, presented for entity B | `{:error, :effect_id_mismatch}`; both entities remain |
| `R565-07` | 178 | Concurrent delete replay of one genuine grant | Exactly one `{:ok, _}`; every other result is `{:error, :already_consumed}`; entity gone; status `:consumed` |
| Genuine Council control | 221 | Genuine Council decision → mint → bind | `decision` is `:approved` or `:conditional`; mint returns `{:ok, grant}`; `council_decision_ref` is a binary; bind returns `{:ok, bound}`; `bound.effect_id` is a binary |

The controls confirm that the test harness is not globally broken: allowlist refusal, one-shot semantics, scope checks, and genuine Council issuance all still work on the pinned source. They also confirm that the red failures are selective authority failures, not a blanket inability to refuse.

The genuine control accepts `:conditional` because `Council.authorize/3` can legitimately return a conditional decision and `MachineAuthorization.mint/2` accepts it through `conditional_grant?/1`. This is a control over the existing contract, not a claim that conditional authority is correctly scoped elsewhere; conditional-consumer correctness remains an open concern recorded by CP19.17.

### 3.6 Determinism and isolation

- Both seeds produced the same twelve failing test identities. Only the execution order changed.
- Each run used a distinct `TEST_PARTITION`; no run reused another run's DETS root.
- `test_data/dets` contained no per-run partition directory after the runs; the run roots were removed.
- The CP19.18 worktree's `git status` before and after the runs retained the same pre-existing entries: modified `cel_memory_v2.dets`, untracked `conflict_resolution_engine.dets`, and untracked `cp19_17_report.md`.
- `cel_memory_v2.dets` is a repository-root artifact, not a per-run partition artifact. Its modification time (`2026-11-12 00:28:48`) falls inside the control run window, which confirms that at least one test path wrote outside the isolated DETS root. `conflict_resolution_engine.dets` also remains outside that root.
- Therefore the suite is deterministic and partition-isolated for the registry under test, but the repository is **not** fully state-isolated. `F-ARC-018` remains `OPEN`. No claim of clean-room execution is made.

---

## 4. Test-oracle integrity matrix

Verdict vocabulary:

- **Strong** — the oracle asserts the specific safe result and at least one material postcondition; suitable as a closure oracle after remediation with at most naming cleanup.
- **Adequate-for-red** — the oracle proves the current unsafe success, but is too broad or incomplete for closure.
- **Weak** — the oracle could pass for the wrong reason, or omits a postcondition needed to distinguish refusal from collateral failure.

| Case | Security property asserted | Oracle | Red evidence | Verdict | Required strengthening for closure |
|---|---|---|---|---|---|
| `R564-01` | No public path registers an arbitrary ID | Exact membership in two proof errors; status remains `:not_registered` | `:ok` | Strong for red; tighten for closure | Require the canonical `:grant_issuance_proof_required`; assert no registry record/ref/binding; assert no audit row |
| `R564-02` | Forged grant cannot enter Phase4 admission | Membership in five consumer errors; status in `[:granted, :not_registered]`; binding `:not_bound`; `executed?` false | `{:ok, ...}` | Adequate-for-red, weak on error | Require exact `:grant_issuance_proof_required` or `:authorization_provenance_invalid`; assert no bind, no consume, no ETS claim; assert registry record unchanged |
| `R564-03` | Forged grant cannot reach the governed sink | Membership in five errors; refute sink and audit messages; status/binding unchanged | `{:ok, ...}` | Adequate-for-red; callback assertions are strong | Require exact provenance error; assert no sink/audit/EventStore event; assert registry not consumed; assert status/binding unchanged |
| `R564-04` | Forged grant cannot deploy a candidate | Membership in five errors; candidate status `:approved`; status/binding unchanged; no deployment audit | `{:ok, ...}` | Adequate-for-red, weak on error | Require exact provenance error; assert no `Candidate.deploy_transition`, no `DeploymentRecord`, no deployment-registry row, no audit row |
| `R564-06` | Direct non-allowlisted mint remains refused | Exact `:minter_not_authorized`; status `:not_registered` | Pass | Strong | Preserve; after remediation, assert the allowlist is defense-in-depth, not the authority |
| `R564-07` | Non-issuer cannot bind an existing mint | Uses `assert_mint_refused/1` (two mint errors); binding remains `:not_bound` | `:ok` | Weak / semantically mismatched | Use a bind-specific oracle with `:grant_bind_proof_required` or `:authorization_provenance_invalid`; assert no `{:bind, ...}` record and no binding; assert the minted grant remains unbound |
| `R564-08a` | A mint cannot be re-subjected to another human | Membership in five errors; refute sink/audit | `{:ok, ...}` | Weak | Require exact registry-provenance mismatch; assert registry-anchored `human_id` unchanged; assert no consume/effect; assert sink/audit not called |
| `R564-08b` | A mint cannot be re-pointed to another explanation | Membership in five errors; refute sink/audit | `{:ok, ...}` | Weak | Require exact explanation-digest mismatch; assert registry-anchored digest unchanged; assert no consume/effect; assert sink/audit not called |
| `R564-09` | Concurrent replay admits exactly one | Exactly one success; others in two named errors; status `:consumed` | Pass | Strong | Preserve; after remediation, assert the one success used a registry-anchored grant and no auto-bind occurred |
| `R565-01` | Public `approved/1` struct is not authority | Exact `:council_decision_proof_required` | `{:ok, ...}` | Strong on error; incomplete postcondition | Assert no registry record, no decision ref, no audit row |
| `R565-02` | Reconstructed approved decision is not authority | Exact `:council_decision_proof_required` | `{:ok, ...}` | Strong on error; incomplete postcondition | Same as R565-01 |
| `R565-03` | Fabricated mint → bind → delete cannot delete | Exact `:council_decision_proof_required`; entity exists | `{:ok, ...}` | Strong on error and target postcondition | Assert refusal occurs before registry consume and before `:world_entity_deleted` audit; assert no registry record/binding; assert relationships remain |
| `R565-04` | Altered decision cannot reuse genuine provenance | Exact `:council_decision_proof_required` | `{:ok, ...}` | Strong on error; incomplete replay dimension | Assert the genuine receipt is not consumed by the failed attempt; add a second mint from the genuine decision; see §6 |
| `R565-05` | Delete grant cannot authorize an update | Exact `:decision_type_mismatch` | Pass | Strong | Preserve; create the target entity if the control is meant to prove no write |
| `R565-06` | Grant for A cannot delete B | Exact `:effect_id_mismatch`; both entities remain | Pass | Strong | Preserve |
| `R565-07` | Concurrent replay deletes exactly once | Exactly one success; others `:already_consumed`; entity gone; status `:consumed` | Pass | Strong | Preserve; after remediation, assert the one success verified the receipt at the effect boundary |
| `R565-08` | Active emergency blocks new machine minting | `match?({:error, _})` | `{:ok, ...}` | Weak | Require exact `:council_emergency_active`; assert no registry record and no grant; add an effect-boundary emergency case after a grant exists |
| Genuine Council control | Genuine decision still mints and binds | Decision approved/conditional; mint ok; binary ref; bind ok; binary effect | Pass | Strong for the positive path; incomplete provenance check | Assert `MintRegistry.decision_ref(id)` equals the grant's `council_decision_ref` and that the receipt was consumed exactly once |

### 4.1 Oracle weaknesses that must not be carried into closure

1. **Broad error lists.** `R564-02`, `R564-03`, `R564-04`, `R564-08a`, and `R564-08b` accept five different errors. A remediation that fails for an unrelated reason (for example, a malformed descriptor or an unavailable registry) could satisfy the assertion without enforcing issuance provenance. Closure tests must require the specific provenance error and assert the registry state is untouched.
2. **Mint-error helper used for a bind call.** `R564-07` calls `assert_mint_refused/1` around `MintRegistry.record_bind/3`. The error vocabulary for mint and bind is not the same, and a bind failure for `:not_registered` or `:already_consumed` would not prove issuer authentication. Closure must use a bind-specific error and a bind-specific postcondition.
3. **Any-error emergency assertion.** `R565-08` uses `match?({:error, _})`, so it would pass if mint failed because the registry was down, the decision was malformed, or a test process was missing. Closure must require the emergency-specific error and assert no mint record.
4. **Missing negative postconditions.** Several cases assert only the return value. A refusal must also leave the registry status, binding, consumption, ETS claim, sink callback, audit log, candidate state, deployment registry, entity, and relationships unchanged, as applicable.
5. **Self-referential hash assertions.** The UWM oracle relies on `MachineAuthorization.content_hash/1` and the struct's own stored hash. That is exactly the predicate the vulnerability preserves: an attacker who rewrites the decision and recomputes the hash still passes. Closure must compare the presented decision to the **registry-anchored** decision digest, not to a value carried by the same struct.
6. **No restart or tamper case.** `R564-10` was designed but not implemented. A durable registry that trusts a caller-written file cannot be certified by in-memory tests alone.
7. **No multi-mint case.** `R565-04` proves an altered struct cannot reuse provenance, but it does not prove that one genuine Council decision cannot mint more than one grant. The receipt must be one-time.
8. **No post-bind substitution case.** `R565-04` alters before mint. The UWM path accepts a grant that was genuine at mint, bound, and then mutated; that is a distinct failure and is source-confirmed.
9. **No verified-human case.** `R564-03`, `R564-04`, `R564-08a`, and `R564-09` use `AuthenticatedHumanIdentity.authenticate/3`, which accepts any non-empty credential. The tests prove the registry/consumer provenance gap, not human authenticity. RL-426 / RL-479 remain separate and must be resolved or explicitly bounded for RL-564 closure.

---

## 5. What the red baseline proves and does not prove

### 5.1 Proved by CP19.19

- The candidate commit and both test-file blobs match the CP19.18 record.
- The candidate is tests-only against `de231a78`; no production or configuration file changed.
- The full suite reliably produces 18 tests and 12 failures at two seeds in isolated partitions.
- The 12 failures are unsafe successes, not setup or harness failures.
- The six controls execute their intended branches and pass.
- The nine tested unsafe compositions are real on the pinned source:
  1. arbitrary-ID registration through the human wrapper (`R564-01`);
  2. forged human grant admitted to Phase4 (`R564-02`);
  3. forged human grant admitted to the governed sink (`R564-03`);
  4. forged human grant admitted to the deployment gateway (`R564-04`);
  5. unauthenticated binding of an existing mint (`R564-07`);
  6. human-subject substitution accepted by the sink (`R564-08a`);
  7. explanation-digest substitution accepted by the sink (`R564-08b`);
  8. fabricated/reconstructed/altered Council decision accepted by machine mint (`R565-01`, `R565-02`, `R565-04`);
  9. fabricated mint → bind → delete accepted by UWM (`R565-03`), and direct machine mint during emergency accepted (`R565-08`).

### 5.2 Not proved

- No production caller, external HTTP route, network exposure, real deployment, or physical actuation was established.
- No production MintRegistry was mutated. The tests wrote only to isolated test partitions.
- No claim is made that every consumer of the registry is covered. The CP19.17 matrix listed RealExecution, PhysicsPilot, WorldMutationEngine, Omega.Verification.Baseline, and other consumers; CP19.18 covers Phase4, the governed sink, the deployment gateway, and UWM delete only.
- No claim is made that the human identity is authentic. The identity helper is self-asserted.
- No claim is made that the durable registry survives restart, truncation, tampering, or partial writes.
- No claim is made that a green version of the current suite would prove closure; the oracle weaknesses in §4.1 are material.
- No CI run, runtime certification, or green build status is claimed.

---

## 6. Additional source-confirmed gaps beyond CP19.18

These gaps are design inputs to the two remediation specifications. They are not new permanent finding IDs in CP19.19.

### 6.1 Post-bind decision substitution (RL-565)

`MachineAuthorization.bind_effect/2` records the effect and passes the carried `council_decision_ref` to `MintRegistry.record_bind/3`. After binding, a caller can mutate the grant's `decision` payload and recompute `content_hash`. `UnifiedWorldModel.check_authority/1` recomputes `MachineAuthorization.content_hash(authorization)` and compares it to `authorization.content_hash`; both are derived from the same mutated struct, so the check passes. `check_binding/2` compares only the effect ID and registry binding. It never compares `MintRegistry.decision_ref(authorization_id)` to a digest of the presented decision. The registry anchor is therefore not consulted at the effect boundary. This is distinct from `R565-04` (alteration before mint) and requires its own negative test.

### 6.2 Multiple mints from one genuine Council decision (RL-565)

`Council.authorize/3` returns a plain struct with no one-time receipt. `MachineAuthorization.mint/2` can be called repeatedly with the same struct; each call generates a fresh `authorization_id` and a fresh registry record. Each grant is individually one-shot, but the decision itself is not. A receipt must be single-use and consumed atomically at mint.

### 6.3 Restart, truncation, and tamper (RL-564 and RL-565)

`MintRegistry` stores append-only `:erlang.term_to_binary/1` records with a 32-bit length prefix. There is no MAC, hash chain, or signature over the record stream. `load_state/1` silently discards a truncated tail (`decode_records/1` returns `[]` for a truncated remainder), logs only when the whole file yields an empty map, and otherwise trusts the reconstructed statuses/bindings/refs. A caller who can write the registry file can forge a `:granted` record, and a partial write can make prior authority disappear. `F-ARC-018` also records broader store-hygiene problems. The remediation specifications must define integrity, startup verification, and corruption behavior; they must not claim durability security from the current append-only format.

### 6.4 Verified human identity (RL-564 dependency)

`AuthenticatedHumanIdentity.authenticate/3` accepts any non-nil `human_id` and any non-empty binary credential; `authenticated?/1` checks a non-nil timestamp. The struct is a self-asserted constructor, not a credential-store verification. `GovernedEffectSink` and `DeploymentGateway` compare `identity.human_id` to the grant's `human_id`, which is meaningful only if both values are independently anchored. RL-564 closure therefore requires either RL-426 / RL-479 to be closed first or an explicitly verified identity adapter whose assertion is bound into the registry record. Adding a registry human-ID field without verified identity would not close the trust root.

### 6.5 Emergency at the effect boundary (RL-565)

`Council.authorize/3` blocks new decisions while the emergency is active, but `MachineAuthorization.mint/2` does not consult the emergency state. Even after mint-time enforcement is added, a grant minted before the emergency can be presented to UWM during the emergency. `R565-08` covers only mint-time. The effect boundary must re-check emergency state (or a receipt revocation/epoch) before consume and effect.

### 6.6 Unimplemented CP19.17 cases

- **`R564-05`** — Phase4 sandbox path with the `real_execution_enabled` flag and an instrumented backend callback. Not implemented.
- **`R564-10`** — restart/corruption recovery after mint/bind/consume, including partial records. Not implemented.
- **`R564-11`** — standard `HumanDelivery.authorize/3` pending-request path and durable completion. Not implemented.

### 6.7 Consumer coverage still open

CP19.18 covers `ExecutionGovernance`, `GovernedEffectSink`, `DeploymentGateway`, and `UnifiedWorldModel.delete_entity/2`. The CP19.17 matrix also identified `RealExecution`, `PhysicsPilot`, `WorldMutationEngine`, `Omega.Verification.Baseline` minting, CEL Kernel restart/halt, ResourceManager allocation, ExperimentOrchestrator gates, and Forecasting.DecisionImpl. Their registry/authority use is not covered by this red baseline and must be included in the relevant remediation closure matrix or explicitly declared out of scope with a governance decision.

---

## 7. Separate remediation specifications

The two defects have different trust roots and different issuance processes. They must not be collapsed into one "shared validator" that accepts either proof or that treats the registry's `:granted` status as sufficient authority.

| Dimension | RL-564 | RL-565 |
|---|---|---|
| Trust root | Human decision + verified human identity | Council decision + Council-issued receipt |
| Issuer | `HumanDelivery.Authorization` issuance path | `Tiannara.Council` GenServer |
| Proof object | One-time human issuance capability bound to a grant digest | One-time Council decision receipt bound to decision digest and scope |
| Canonical digest | Grant digest (human, explanation, candidate hash, effect) | Decision digest (decision payload, type, scope, actor, versions) |
| Registry record | Human provenance + grant digest + effect | Council provenance + decision ref + receipt + scope + effect |
| Emergency semantics | Human path policy decision; not the Council machine-mint gate | Must block both receipt issuance and effect-boundary consumption |
| Primary prerequisite | Verified identity (RL-426 / RL-479) | Council receipt API and one-time consumption |
| Spec | `CP19_19_RL564_REMEDIATION_SPECIFICATION.md` | `CP19_19_RL565_REMEDIATION_SPECIFICATION.md` |

Shared **mechanisms** are allowed and desirable: a registry record with an integrity MAC, atomic compare-and-set consumption, a canonical digest function, a common error vocabulary, and a common `verify_presentation` primitive that takes a **typed proof** and dispatches to the correct issuer verification. What is prohibited is a shared **authority decision** that accepts a human grant and a machine grant interchangeably, or a validator whose only requirement is "the registry says `:granted`".

The trust-chain diagram is in `CP19_19_AUTHORIZATION_TRUST_CHAIN_DIAGRAM.md`. It shows the two roots, the required proof objects, the effect boundaries, and the prohibited shortcuts.

Recommended sequencing:

1. Freeze the public authority surface (RL-564 and RL-565) so no new caller can mint by ID or by plain struct.
2. Implement the Council receipt and one-time mint path (RL-565), including emergency enforcement at mint and at the effect boundary.
3. Implement atomic human issuance and proof-bound registration/binding (RL-564), including verified-identity integration.
4. Migrate consumers to registry-anchored verification; remove auto-bind from `ExecutionGovernance.begin/2`.
5. Update existing positive tests that currently assert the vulnerable behavior; add the missing negative and restart/tamper tests.
6. Run independent verification with exact SHAs, seeds, isolated partitions, and complete postcondition checks.
7. Only then update the register and consider a finding-closure proposal. CP19.19 does not close either finding.

---

## 8. Production remediation acceptance criteria

These are the shared acceptance criteria for any remediation claiming to close RL-564 or RL-565. Finding-specific criteria are in the companion specifications. A remediation that meets only the red tests as written does not meet these criteria.

### 8.1 Authority surface

- **AC-1.** No public API accepts a caller-selected authorization ID as sufficient to create a durable `:granted` record. The arbitrary-ID wrapper is removed, made private, or requires an unforgeable one-time issuance proof that is verified by the registry.
- **AC-2.** No public API accepts a caller-constructed `Council.Authorization` struct as sufficient to mint machine authority. `MachineAuthorization.mint/2` requires a Council-issued receipt or capability, and verifies it against the decision.
- **AC-3.** Stack-origin module inspection is not the authority for minting. It may remain as defense-in-depth, but a caller that reaches an allowlisted module without a proof must be refused.
- **AC-4.** Human and machine proofs are distinct types with distinct issuers. A shared low-level verification helper must not accept either proof interchangeably or treat registry status alone as authority.

### 8.2 Registry provenance and effect boundary

- **AC-5.** Every durable record carries immutable provenance sufficient to re-derive the authorized effect: authorization ID, issuance/receipt ID, grant or decision digest, issuer class, principal/actor, explanation or decision scope, candidate/payload digest where applicable, issued-at/expiry, and effect binding. The record is written atomically with issuance, not by a separate caller-selected step.
- **AC-6.** Every consumer verifies the presented grant against the registry-anchored grant/decision digest, not against a hash carried by the same struct. Post-bind mutation of the decision, human, explanation, candidate hash, operation, scope, TTL, or effect must fail before consume and before any sink, audit, candidate transition, or graph deletion.
- **AC-7.** Binding is an authenticated issuer operation or is verified against the issuance proof. An arbitrary caller cannot bind an existing mint. A grant cannot be rebound to a second effect.
- **AC-8.** Consumption is an atomic compare-and-set; of N concurrent presentations, at most one succeeds, and every refusal is a named error. A refused consume must not leave the effect claimed or the grant consumed.
- **AC-9.** Refusals occur before the consequential action. For the governed sink: no sink callback, no EventStore event, no audit-success row. For the deployment gateway: no candidate transition, no deployment record, no deployment-registry row. For UWM: no entity or relationship deletion and no `:world_entity_deleted` audit row.

### 8.3 One-time and replay semantics

- **AC-10.** One human issuance produces at most one valid grant record; reusing the pending request or proof cannot produce a second valid grant.
- **AC-11.** One Council decision receipt produces at most one machine grant; a second mint from the same receipt fails with a specific `:council_receipt_consumed` (or equivalent) error.
- **AC-12.** A grant is one-shot for one effect. Replay after consumption fails; concurrency admits exactly one effect.

### 8.4 Durability and restart

- **AC-13.** Registry records are integrity-protected (for example, a keyed MAC or hash chain) so a caller who can write the file cannot forge a `:granted` record or alter provenance without detection. The key-management and threat model must be stated; an in-memory-only key that cannot survive restart is not sufficient for durable authority.
- **AC-14.** Startup verifies the record stream. Truncated, out-of-order, duplicated, or MAC-invalid records fail closed with a named error and do not silently promote a partial prefix to authoritative state. A documented recovery path exists for legitimate retention/rotation.
- **AC-15.** Restart preserves valid mint/bind/consume history and re-verifies provenance before a record is usable. A forged or tampered record is refused after restart, not merely during the original process lifetime.

### 8.5 Emergency and governance

- **AC-16.** Council emergency blocks new machine receipt issuance and direct machine mint. A direct `MachineAuthorization.mint/2` cannot bypass the emergency gate.
- **AC-17.** Council emergency is re-checked at the effect boundary (or enforced through a receipt epoch/revocation) so a grant minted before the emergency cannot delete or execute during it. Emergency-allowed operations are explicitly enumerated; `delete_entity` is not one of them.
- **AC-18.** No remediation fabricates Council authority, auto-approves a human decision, bypasses Constitutional Council authority, or promotes a caller-selected ID to authority. No verification merely repeats an implementation predicate; it must exercise the public API and assert the security property and its postconditions.

### 8.6 Verification and evidence

- **AC-19.** The full relevant suite passes with no skipped, excluded, or pending authority tests. The CP19.18 red cases remain in the suite with strengthened oracles; they may not be deleted or converted to controls to obtain green.
- **AC-20.** Independent verification runs the exact candidate SHA on Elixir 1.18.4 / OTP 28 with fresh `TEST_PARTITION` values and records the command, seed, test count, failure count, excluded count, and per-case results. The verifier is not the implementer and does not rely on implementation-authored summaries.
- **AC-21.** Oracle integrity is re-reviewed before closure: specific errors, postconditions, no broad error lists, no any-error matches, and no self-referential hash checks.
- **AC-22.** Existing tests that assert the vulnerable behavior as positive are updated in the remediation change, with the security rationale recorded. At minimum: the R-2 test's arbitrary-ID wrapper assertion and the D127 positive path that manually calls `record_mint/1` must be migrated to the new issuance API.
- **AC-23.** `F-ARC-018` closure is tracked separately. A green RL-564/RL-565 suite does not close persistence/state-hygiene findings; repository-root DETS writes must be eliminated or explicitly contained, and the store map/path ownership must be established.
- **AC-24.** RL-564, RL-565, and `F-ARC-018` remain `OPEN` until the verification evidence is recorded in the consolidated register with exact commit and run identities. No CI or runtime green status is claimed without an exact SHA and run.
- **AC-25.** PR #13 remains unchanged unless a separate governance decision explicitly authorizes a change; this checkpoint does not.

---

## 9. Execution boundary and limitations

- CP19.19 executed tests only. It did not modify production source, configuration, production registries, deployment state, Council state, or physical systems.
- Test execution occurred in the disposable CP19.18 worktree at `268d2e9b`; documentation was authored in the separate audit worktree at `57fd903a` (branch `audit/cp19-19-red-baseline-integrity`).
- DETS writes were confined to per-run `TEST_PARTITION` roots and those roots were removed. Repository-root persistence artifacts remained outside the partition; this is recorded as a limitation, not concealed.
- No external HTTP request, live service, real hardware adapter, or physical actuation was used.
- No Council authority was fabricated, no human approval was automated, and no finding was closed.
- No CI or runtime certification is claimed. The only executed evidence is the local ExUnit runs described in §3.
- The main repository's `local/pr4` state, the CP19.17 report/register, and PR #13 were preserved.

---

## 10. Disposition and next checkpoint

**Checkpoint 19.19 final disposition:** The CP19.18 red baseline is independently reproduced at two seeds with isolated DETS partitions: 18 tests, 12 genuine unsafe-success failures, 6 valid controls. The failures are authorization violations on the pinned source, not harness errors. The oracles are valid for the red baseline but have documented weaknesses that must be strengthened before they can serve as closure oracles. The additional gaps — post-bind substitution, multi-mint, restart/tamper, verified human identity, emergency at the effect boundary, unimplemented R564-05/10/11, and remaining consumers — are documented. Separate RL-564 and RL-565 remediation specifications and a two-root trust-chain diagram are issued. No production change was made.

**Findings status:**

| ID | Status | Basis |
|---|---|---|
| RL-564 | **HIGH / OPEN** | Arbitrary-ID mint and forged human-grant admission reproduced; remediation not implemented |
| RL-565 | **HIGH / OPEN** | Fabricated Council decision mint and UWM delete reproduced; remediation not implemented |
| `F-ARC-018` | **OPEN** | Per-run partitions are deterministic, but repository-root persistence and store-map hygiene are not closed |

**Next checkpoint:** 19.20 — production remediation implementation for RL-565 (Council receipt, one-time mint, registry provenance, UWM effect-boundary verification, emergency enforcement), followed by a separate RL-564 implementation checkpoint. Each implementation must be independently verified against §8 before any register closure entry is proposed. The two findings may share registry mechanisms but must retain separate trust roots, proof types, issuers, and acceptance evidence.
