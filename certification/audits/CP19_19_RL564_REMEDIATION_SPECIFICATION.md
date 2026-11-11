# CP19.19 — RL-564 Remediation Specification (Human Registry-Issuance Provenance)

**Finding:** RL-564 — `HumanDelivery.Authorization.record_mint/1` allows a caller-selected authorization ID to be registered as `:granted` through an allowlisted module, and downstream registry-backed consumers accept a forged human grant.  
**Severity:** HIGH  
**Status:** **OPEN** — specification only; no production remediation performed  
**Trust root:** Human decision + verified human identity (not Council)  
**Pinned source:** `de231a78db542a6172d7bd1ffd46e8a766deafa4`  
**Verified red baseline:** `268d2e9b442a504873a6f4af691a836ead79120b`  
**Companion artifacts:** `CHECKPOINT_19_19_INDEPENDENT_RED_BASELINE_VERIFICATION_AND_REMEDIATION_SPECIFICATION.md`, `CP19_19_RL565_REMEDIATION_SPECIFICATION.md`, `CP19_19_AUTHORIZATION_TRUST_CHAIN_DIAGRAM.md`

---

## 1. Purpose and boundary

This specification defines the minimum safe remediation for RL-564. It is deliberately **not** a shared human/machine validator specification. RL-564's authority originates in a human decision and a verified human identity. RL-565's authority originates in a Council decision and a Council-issued receipt. The two may share registry storage mechanics, digest utilities, integrity protection, and atomic consumption; they must not share an authority decision or a proof type that either issuer can satisfy.

The remediation must close the source-confirmed path:

```text
caller-selected ID
  -> Authorization.record_mint/1
  -> MintRegistry.record_mint/2 (allowlisted stack-origin module)
  -> durable :granted record with no grant, principal, explanation, candidate, or effect provenance
  -> forged %Authorization{} struct
  -> ExecutionGovernance.begin/2 / GovernedEffectSink.execute/3 / DeploymentGateway.deploy/5
  -> success
```

The replacement path must be:

```text
verified human identity
  -> pending authorization request for a specific explanation/scope
  -> atomic human issuance inside Authorization.human_grant/3
       -> server-generated authorization_id
       -> canonical grant digest
       -> one-time random issuance token (stored only as a hash)
       -> durable registry record with provenance and integrity MAC
  -> {:ok, grant, issuance_proof}
  -> proof-bound one-shot effect binding
  -> consumers verify the registry-anchored grant digest, principal, explanation, candidate/scope, and effect
  -> atomic consume
  -> effect
```

No caller-selected ID, struct field, or stack-origin module is authority.

---

## 2. Current defect (source-confirmed)

| Element | Pinned behavior | Security consequence |
|---|---|---|
| `Tiannara.Omega.MintRegistry.record_mint/2` | Authorizes by inspecting the caller's stack; the first non-infrastructure module must be in `@allowed_minters`. Writes `{:mint, id, ts, decision_ref}` and status `:granted`. | A public function in an allowlisted module can mint an arbitrary ID. The allowlist authenticates a module name, not an issuance event. |
| `Tiannara.Omega.HumanDelivery.Authorization.record_mint/1` | Public; accepts only an `authorization_id`; calls `MintRegistry.record_mint/2`; returns `:ok`. | No grant, identity, explanation, candidate, scope, or issuance receipt is required. `R564-01` returns `:ok`. |
| `MintRegistry.record_bind/3` | No caller authentication. Checks registration, consumption, prior binding, and the optional `council_decision_ref` anchor. | Any caller can bind an existing mint to an effect if it presents the matching (possibly `nil`) ref. `R564-07` returns `:ok`. |
| Registry record | `{authorization_id, status, minted_at, council_decision_ref}` plus binding/consumption maps. No grant digest, human ID, identity ID, explanation digest, candidate hash, scope, or record MAC. | Consumers cannot distinguish a genuine human grant from a forged struct with the same ID. |
| `ExecutionGovernance.begin/2` | Checks struct `:granted`, expiry, registry `:granted`, descriptor, bind-or-verify, registry binding, ETS claim, consume. Auto-binds an unbound grant. | A forged struct with a wrapper-registered ID enters admission; `R564-02` returns `{:ok, ...}`. |
| `GovernedEffectSink.execute/3` | Checks presence, struct status, registry status, expiry, `AuthenticatedHumanIdentity.authenticated?/1` and `identity.human_id == grant.human_id`, binding, descriptor, registry binding, consume, sink, result identity, audit. | A self-asserted identity matching a forged grant passes; `R564-03`, `R564-08a`, `R564-08b` return `{:ok, ...}`. |
| `DeploymentGateway.deploy/5` | Checks candidate/certification/lineage, grant presence, `valid_for?/2`, expiry, weak identity equality, `grant.candidate_content_hash == content_hash(candidate)`, registry status, effect binding/match, consume, candidate transition, audit. | A forged grant can supply all fields; `R564-04` returns `{:ok, ...}`. |
| `AuthenticatedHumanIdentity.authenticate/3` | Accepts any non-nil `human_id` and any non-empty binary credential; `authenticated?/1` checks a non-nil timestamp. | The identity is self-asserted. This is RL-426 / RL-479 territory, not closed by RL-564. |

The registry's only provenance anchor today is the optional `council_decision_ref`, which is for machine grants and is `nil` on the human path. The human path has no equivalent anchor.

---

## 3. Required security invariants

- **INV-564-1.** A durable human `:granted` record exists only if a verified human issuance event produced it atomically. Knowledge of an ID is never sufficient.
- **INV-564-2.** The record is bound to the exact grant that was issued. Changing the authorization ID, human, identity, explanation, candidate hash, status, TTL, scope, or effect after issuance invalidates presentation.
- **INV-564-3.** One issuance produces at most one valid grant record. Reusing the pending request or issuance proof cannot produce a second valid grant.
- **INV-564-4.** Binding is authorized by the issuance proof and is one-time. A non-issuer cannot bind; a grant cannot be rebound.
- **INV-564-5.** Every consumer verifies the registry-anchored grant digest and provenance, not a hash or field carried only by the presented struct. Refusal occurs before any sink, audit-success, candidate transition, deployment record, ETS claim, or consume.
- **INV-564-6.** Identity is verified by an identity-provider port, not by the presence of an `AuthenticatedHumanIdentity` struct or a non-empty credential. The verified identity assertion is bound into the record.
- **INV-564-7.** Durable records are integrity-protected and startup-verified. Truncation, tampering, duplication, or reordering fails closed and never silently promotes a partial prefix to authority.
- **INV-564-8.** Human authority and machine authority remain distinguishable in storage and verification. A human verifier accepts only human-issued records; a Council verifier accepts only Council-issued records.

---

## 4. Target design

### 4.1 Issuance proof

Add `Tiannara.Omega.HumanDelivery.IssuanceProof` as the one-time proof returned by human issuance and required for binding.

```elixir
defmodule Tiannara.Omega.HumanDelivery.IssuanceProof do
  @enforce_keys [
    :proof_id,
    :authorization_id,
    :grant_digest,
    :token,
    :issued_at,
    :expires_at
  ]
  defstruct [
    :proof_id,
    :authorization_id,
    :grant_digest,
    :token,
    :issued_at,
    :expires_at
  ]
end
```

Design rules:

- `proof_id` is a server-generated random identifier.
- `token` is at least 256 bits from `:crypto.strong_rand_bytes/1`.
- The registry stores only `sha256(token)`, never the token. Reading the registry file does not yield a usable proof.
- The proof is bound to `authorization_id` and `grant_digest`, and has a short expiry.
- The proof is returned to the caller exactly once by `Authorization.human_grant/3`. It is not reconstructible from the grant or the registry.
- The proof is consumed atomically by the first successful bind. A second bind returns `{:error, :bind_proof_consumed}`.
- A caller can construct the struct, but a guessed token cannot match the stored hash. Tests must cover both random-token forgery and replay.

This is a proof-of-issuance capability, not a second authorization. It does not let the holder exceed the human-authorized scope; the scope check is separate.

### 4.2 Atomic issuance

`Authorization.human_grant/3` becomes the only human issuance path. It must perform the following in one fail-closed operation:

1. Validate the pending authorization request state and expiry.
2. Validate the explanation/scope the human is approving. The grant must carry an `explanation_id`, an `explanation_digest` (content hash if available), and, where applicable, a `candidate_content_hash` or `scope_digest`.
3. Verify the human identity through an identity-provider port. A bare `%AuthenticatedHumanIdentity{}` is an assertion input, not proof. If no verified provider is configured, refuse with `:identity_verification_unavailable`; do not fall back to `authenticate/3` self-assertion.
4. Generate `authorization_id` server-side. Never accept a caller-selected ID for a new grant.
5. Build the grant with status `:granted`, a server timestamp, a bounded TTL, and lineage.
6. Compute `grant_digest` over the canonical authority-bearing fields (see §4.4).
7. Generate `proof_id` and `token`; compute `token_hash`.
8. Call `MintRegistry.issue_human/2` with the record and `token_hash`. The registry writes the record and its integrity MAC before returning `:ok`.
9. Return `{:ok, grant, %IssuanceProof{...}}`.

If any step fails, no grant is returned and no `:granted` record exists. There is no "mint later" step and no public `record_mint/1`.

`Authorization.prepare/1` and `request/1` may remain for the pending state machine, but they create no authority and must not generate a caller-controlled ID that can later be registered independently.

### 4.3 Registry record schema

The human record must carry at least:

| Field | Purpose |
|---|---|
| `authorization_id` | Server-generated grant identity |
| `issuer` | `:human` (distinct from `:council`) |
| `issuance_id` / `proof_id` | Human issuance event identity |
| `proof_hash` | `sha256(token)`; never the token |
| `grant_digest` | Canonical digest of the issued grant |
| `identity_id` | Verified identity assertion identifier |
| `identity_digest` | Digest of the verified assertion/method/issuer |
| `human_id` | Principal bound to the grant |
| `explanation_id` | Explanation the human approved |
| `explanation_digest` | Content digest of the explanation (or canonical digest of the explanation payload) |
| `candidate_content_hash` | Candidate scope, when applicable |
| `scope_digest` | Canonical digest of the authorized operation/target/effect scope |
| `issued_at`, `expires_at` | Temporal bounds |
| `status` | `:granted`, `:bound`, `:consumed`, `:revoked`, `:expired` |
| `effect_id`, `bound_at`, `consumed_at` | One-shot effect state |
| `record_seq` | Monotonic sequence for integrity/replay detection |
| `record_mac` | Integrity MAC over the canonical record fields |

The record must not contain the raw issuance token. The registry must not expose a public "update provenance" function.

### 4.4 Canonical grant digest

The digest must be computed by a single canonical function over every field that conveys authority, including:

- `authorization_id`
- `authority_class` / issuer tag (`:human`)
- `human_id`
- `identity_id` / `identity_digest`
- `explanation_id` / `explanation_digest`
- `candidate_content_hash`
- `scope_digest`
- `decision`/`status` (`:granted`)
- `granted_at`
- `ttl`
- `effect_id` (once bound)
- any lineage entries that affect authority

The digest must use a deterministic encoding (the repository's existing `:erlang.term_to_binary/1` convention is acceptable if map ordering is canonicalized; otherwise use a canonical JSON encoder). The same function must be used at issuance, bind, and every consumer verification. A digest computed over only `{id, status}` is insufficient.

### 4.5 Proof-bound binding

`Authorization.bind_effect/3` (or a new `bind_effect/3` with the proof) must:

1. Require a `%IssuanceProof{}`.
2. Verify `proof.authorization_id == grant.authorization_id`.
3. Verify `proof.grant_digest == canonical_grant_digest(grant)`.
4. Verify `proof.expires_at` is in the future.
5. Verify `sha256(proof.token)` equals the registry record's `proof_hash`.
6. Verify the proof is unconsumed.
7. Compute the effect ID from the descriptor.
8. Verify the effect is within the authorized scope:
   - if `candidate_content_hash` is present, the descriptor must be the canonical deployment effect for that candidate;
   - if `scope_digest` is present, the descriptor's canonical operation/target/effect digest must equal it;
   - if the grant is intentionally unscoped, that policy must be explicit at issuance and recorded; the spec recommends requiring a scope for all new production grants.
9. Atomically consume the proof and write `effect_id` / `bound_at` / status `:bound`.
10. Return the bound grant.

The old `Authorization.bind_effect/2` must either be removed or return `{:error, :bind_proof_required}`. It must not silently bind without proof.

`MintRegistry.record_bind/3` must not be a public authority path. If retained for internal use, it must require the proof and perform the same checks; a public caller with only an ID and effect must receive `:bind_proof_required`.

### 4.6 Consumer verification

Add a human-specific verifier, for example:

```elixir
MintRegistry.verify_human_presentation(grant, effect_id, identity_assertion)
  :: {:ok, verified_record}
   | {:error, :authorization_provenance_invalid
             | :authorization_grant_digest_mismatch
             | :authorization_human_mismatch
             | :authorization_explanation_mismatch
             | :authorization_candidate_mismatch
             | :authorization_scope_mismatch
             | :authorization_not_registered
             | :authorization_not_bound
             | :registry_binding_mismatch
             | :authorization_expired
             | :already_consumed
             | :identity_not_verified
             | :identity_human_mismatch
             | :registry_unavailable
             | :registry_corrupt}
```

Verification must compare the presented grant against the registry record, not against a hash carried by the grant:

- record exists and `issuer == :human`;
- record status is `:bound` (or `:granted` only if the consumer is the authorized binder; consumers should require `:bound`);
- record is unexpired and unconsumed;
- `record.grant_digest == canonical_grant_digest(grant)`;
- `record.human_id == grant.human_id`;
- the identity assertion is verified by the identity provider and its `identity_id`/`human_id` match the record;
- `record.explanation_id == grant.explanation_id` and `record.explanation_digest == digest(grant explanation)`;
- `record.candidate_content_hash == grant.candidate_content_hash` when present;
- `record.scope_digest` matches the operation/target scope;
- `record.effect_id == grant.effect_id == effect_id`;
- the registry binding agrees.

Consumer changes:

- **`ExecutionGovernance.begin/2`**: remove auto-bind. Require a bound grant and call `verify_human_presentation/3`. If unbound, return `:authorization_not_bound`. Keep the ETS claim and atomic consume, but only after verification. The caller must explicitly bind with the proof before admission.
- **`GovernedEffectSink.execute/3`**: replace the weak `check_identity/2` and registry-status/binding checks with `verify_human_presentation/3`. Require the identity assertion through opts; do not accept a bare `human_id`. Include the explanation digest and registry grant digest in the audit payload. Refuse before sink and audit.
- **`DeploymentGateway.deploy/5`**: call `verify_human_presentation/3` and compare the candidate hash/scope to the registry record. Do not trust `grant.candidate_content_hash` alone. Refuse before `Candidate.deploy_transition/1`, deployment-registry write, and audit.
- **`Authorization.valid_for?/2`**, `valid_for_effect?/2`, and `expired?/2` may remain local helpers, but they are not authority. No consumer may accept a grant solely on those predicates plus registry status.

### 4.7 Identity-provider port

Add a behaviour such as:

```elixir
defmodule Tiannara.Omega.HumanDelivery.IdentityProvider do
  @callback verify(assertion :: term()) ::
              {:ok, %{identity_id: binary(), human_id: term(), method: atom(),
                      verified_at: DateTime.t(), digest: binary()}}
              | {:error, term()}
end
```

- `AuthenticatedHumanIdentity.authenticate/3` must delegate to a configured provider or return `{:error, :identity_verification_unavailable}`. It must not accept an arbitrary non-empty credential as verification.
- The registry stores the verified `identity_id` and a digest of the assertion; it does not trust a caller-supplied `identity_id`.
- For tests, inject a deterministic test provider through application config or a supervised process. The test provider must still be explicit; tests must not pass a self-asserted struct through the production path.
- RL-564 closure is conditional on a production identity provider or an explicit governance decision that RL-426/RL-479 provides it. A registry `human_id` field alone is not identity verification.

### 4.8 Record integrity and restart

- Add a registry integrity key held by a `MintRegistry` key provider, not checked into the repository. The key may be loaded from a protected path or environment variable outside the repo; the spec must state the rotation and recovery policy.
- Each record carries `record_seq` and `record_mac = HMAC-SHA256(key, canonical(record without mac))`.
- Startup verifies every record in order. A MAC failure, sequence gap, duplicate ID with conflicting provenance, or out-of-order record fails closed with `:registry_corrupt` (or quarantines the stream under operator control). It must not silently load a prefix as authoritative.
- `decode_records/1` must distinguish "clean end of file" from "truncated record." The current `decode_records(_truncated) -> []` silently drops the tail; remediation must return an explicit corruption result.
- Restart tests must cover: valid history reload; valid bind/consume reload; forged record with invalid MAC; truncated tail; duplicated mint; reordered consume; missing key.
- If the key cannot be persisted securely, the design must state that durable authority is not available across restart and fail closed rather than trusting an unauthenticated file. Do not claim restart security from an in-memory-only key.

---

## 5. Error taxonomy

Use specific, stable errors. Closure tests must assert the specific error and postconditions; broad lists are prohibited.

| Situation | Canonical error |
|---|---|
| Old arbitrary-ID API called | `:unsupported_authority_path` |
| No issuance proof | `:grant_issuance_proof_required` |
| Proof token/hash invalid | `:grant_issuance_proof_invalid` |
| Proof expired | `:grant_issuance_proof_expired` |
| Proof already used for bind | `:bind_proof_consumed` |
| Grant digest mismatch | `:authorization_grant_digest_mismatch` |
| Human principal mismatch | `:authorization_human_mismatch` |
| Identity not verified | `:identity_not_verified` |
| Identity human mismatch | `:identity_human_mismatch` |
| Explanation mismatch | `:authorization_explanation_mismatch` |
| Candidate hash mismatch | `:authorization_candidate_mismatch` |
| Scope/operation mismatch | `:authorization_scope_mismatch` |
| Not registered | `:authorization_not_registered` |
| Not bound | `:authorization_not_bound` |
| Registry binding mismatch | `:registry_binding_mismatch` |
| Expired | `:authorization_expired` |
| Already consumed | `:already_consumed` |
| Registry unavailable | `:authorization_registry_unavailable` |
| Registry corrupt/tampered | `:registry_corrupt` |
| Duplicate issuance | `:authorization_already_issued` |
| Bind without proof | `:bind_proof_required` |
| Bind proof invalid | `:bind_proof_invalid` |

The existing names `:grant_issuance_proof_required` and `:authorization_provenance_invalid` may be retained where already used, but each test must select the canonical error for its situation. Do not use one generic error for every failure if the test is meant to distinguish causes.

---

## 6. Implementation sequence

1. **Freeze the authority surface.**
   - Remove `Authorization.record_mint/1` from the public API or make it unconditionally return `{:error, :unsupported_authority_path}` with no registry write.
   - Make `MintRegistry.record_mint/2` reject human IDs without a proof, even when called from an allowlisted module.
   - Add a compile-time or test-time gate that fails if a public function calls `record_mint/2` with only an ID.

2. **Add the human issuance proof and record schema.**
   - `IssuanceProof` struct.
   - Canonical grant digest.
   - Registry record fields, sequence, MAC.
   - `issue_human/2`, `bind_human/3`, `verify_human/3`.

3. **Refactor `Authorization`.**
   - Atomic `human_grant/3` issuance + registration.
   - `bind_effect/3` requiring the proof.
   - `record_mint/1` removed/deprecated.
   - Pending request state cannot be converted to a grant without identity verification.

4. **Refactor consumers.**
   - `ExecutionGovernance.begin/2`: no auto-bind; human verifier.
   - `GovernedEffectSink.execute/3`: human verifier; explanation/audit provenance.
   - `DeploymentGateway.deploy/5`: human verifier; registry candidate hash.
   - Any other human-grant consumer: audit and migrate or explicitly mark out of scope.

5. **Add identity-provider integration.**
   - Behaviour, production adapter or explicit unavailable state, deterministic test provider.
   - Registry identity fields.

6. **Add integrity/restart handling.**
   - Key provider.
   - Startup verification.
   - Truncation/tamper errors.
   - Recovery documentation.

7. **Update tests.**
   - Strengthen R564-01..R564-09 oracles.
   - Add new cases in §7.
   - Migrate existing positive tests that assert the vulnerable behavior.
   - Keep the suite `async: false` where named services/ETS are involved.

8. **Run and capture evidence.**
   - Focused suite at seed 0 and at least one other seed.
   - Full suite.
   - Fresh `TEST_PARTITION` each run.
   - Restart/tamper runs.
   - Independent verifier repeats the exact commands.

---

## 7. Test plan and oracle strengthening

### 7.1 Red-baseline cases to retain and strengthen

| Case | Current weakness | Closure oracle |
|---|---|---|
| `R564-01` | Accepts two errors | Assert `:grant_issuance_proof_required` (or `:unsupported_authority_path` for the removed API); status `:not_registered`; no ref/binding/audit |
| `R564-02` | Five-error list | Assert `:authorization_provenance_invalid` or `:grant_issuance_proof_required`; no bind, consume, or ETS claim; registry record unchanged |
| `R564-03` | Five-error list | Assert `:authorization_provenance_invalid`; no sink/audit/EventStore event; no consume; status/binding unchanged |
| `R564-04` | Five-error list | Assert `:authorization_provenance_invalid`; candidate remains `:approved`; no deployment record, transition, or audit |
| `R564-06` | Strong | Preserve; assert `:minter_not_authorized` only as defense-in-depth, not as the human authority |
| `R564-07` | Mint helper used for bind | Assert `:bind_proof_required`; no binding; no `{:bind, ...}` record; grant remains unbound |
| `R564-08a` | Five-error list; no registry postcondition | Assert `:authorization_human_mismatch`; registry human unchanged; no consume/sink/audit |
| `R564-08b` | Five-error list; no registry postcondition | Assert `:authorization_explanation_mismatch`; registry explanation unchanged; no consume/sink/audit |
| `R564-09` | Relies on auto-bind | Bind explicitly with the proof before the race; exactly one success; others `:already_consumed`/`:effect_already_executed`; status `:consumed`; no auto-bind path exists |

### 7.2 New negative and durability cases

Add the following. Names are descriptive; IDs may be assigned by the implementation checkpoint.

1. **Removed API.** Calling the old `record_mint/1` is undefined/private or returns `:unsupported_authority_path`; no registry row.
2. **Forged proof.** Construct `%IssuanceProof{token: random}` for a real grant; bind returns `:bind_proof_invalid`.
3. **Replayed proof.** Bind once with the real proof; bind again returns `:bind_proof_consumed`; the first binding remains.
4. **Forged grant with real ID.** Build a struct with the ID of a genuine grant but different fields; every consumer returns `:authorization_grant_digest_mismatch`; no effect.
5. **Post-bind human substitution.** Bind a genuine grant, mutate `human_id`, recompute any local hash, present with a matching self-asserted identity; consumer returns `:authorization_human_mismatch`; no effect.
6. **Post-bind explanation substitution.** Mutate `explanation_id`; consumer returns `:authorization_explanation_mismatch`; no effect.
7. **Post-bind candidate substitution.** Mutate `candidate_content_hash`; gateway returns `:authorization_candidate_mismatch`; no transition/deployment.
8. **Post-bind scope substitution.** Change operation/target/descriptor; consumer returns `:authorization_scope_mismatch`; no effect.
9. **Unbound admission.** `ExecutionGovernance.begin/2` on an unbound grant returns `:authorization_not_bound`; no auto-bind, no ETS claim, no consume.
10. **Identity unverified.** Issue with a self-asserted identity when no provider verifies it; issuance returns `:identity_not_verified`/`:identity_verification_unavailable`; no record.
11. **Identity mismatch.** Verified identity for human A, grant for human B; issuance or consumer refuses `:identity_human_mismatch`.
12. **Duplicate issuance.** Two `human_grant/3` calls for the same pending request produce one valid grant and one `:authorization_already_issued` (or equivalent); only one record.
13. **Registry tamper.** Append a forged `:granted` record with a valid-looking but unauthenticated MAC; restart; status is `:not_registered` or the registry is `:registry_corrupt`; no authority.
14. **Truncated tail.** Truncate the last record; restart fails closed (`:registry_corrupt`) or quarantines under operator control; it does not silently load the prefix as complete.
15. **Valid restart.** Mint, bind, consume, restart; status/binding survive; replay after restart returns `:already_consumed`; no second effect.
16. **Scope mismatch at bind.** Bind a candidate-scoped grant to a different candidate effect; returns `:authorization_scope_mismatch`; no binding.
17. **Audit explanation provenance.** A successful sink call records the registry grant digest and explanation digest; a refusal records no success audit.

### 7.3 Existing tests that must change

The following tests currently assert the vulnerable behavior as positive and must be migrated in the remediation change, not left in place:

- `test/tiannara/omega/step13_r2_mint_authentication_test.exs`
  - The case that calls `Authorization.record_mint(id)` for an arbitrary ID and asserts `:ok` / `:granted`.
  - Replace with: no-proof issuance is refused; a proof-bound `human_grant/3` is the only success path.
- `test/tiannara/omega/d127_authorization_attack_test.exs`
  - The setup that calls `:ok = Authorization.record_mint(grant.authorization_id)` after `human_grant`.
  - Replace with the atomic issuance API and proof-bound bind.
- Any other caller of `record_mint/1` or public `record_bind/3` found by:

```text
rg -n "record_mint|record_bind|Authorization\.record_mint|MintRegistry\.record_bind" lib test
```

No test may retain a positive assertion that an arbitrary ID becomes `:granted`.

### 7.4 Test isolation requirements

- Use a fresh `TEST_PARTITION` per run; do not reuse a DETS root.
- Use a test-only registry key; do not use a production key in tests.
- Restore application env, named processes, ETS tables, and identity-provider config in `on_exit`.
- Keep `async: false` for tests that touch named global services or ETS.
- Do not write repository-root DETS artifacts. If a module still does, fix it or mark the test as not clean-room; `F-ARC-018` is not closed by this spec.
- Capture seed, partition, test count, failure count, excluded count, and per-case results.

---

## 8. RL-564 acceptance criteria

RL-564 may be proposed for closure only when all of the following are independently verified.

### 8.1 Authority surface

- **A-564-1.** `Authorization.record_mint/1` no longer exists as a public function, or unconditionally returns `{:error, :unsupported_authority_path}` without any registry write.
- **A-564-2.** `MintRegistry.record_mint/2` cannot register a human authorization from an ID alone, even when called from an allowlisted module. A call without a valid human issuance proof returns a specific proof error and writes nothing.
- **A-564-3.** `Authorization.human_grant/3` is the only human issuance path and registers atomically. No returned `:granted` grant exists without a durable record carrying its provenance.

### 8.2 Proof and binding

- **A-564-4.** Issuance returns a one-time `%IssuanceProof{}` whose token is stored only as a hash and is bound to the authorization ID, grant digest, and expiry.
- **A-564-5.** `bind_effect/3` requires the proof, verifies the grant digest and scope, and consumes the proof atomically. A second bind fails; a forged token fails; a non-issuer cannot bind.
- **A-564-6.** The old `bind_effect/2` is removed or returns `:bind_proof_required`; no public path binds by ID alone.

### 8.3 Consumer verification

- **A-564-7.** `ExecutionGovernance.begin/2` refuses an unbound grant with `:authorization_not_bound` and performs no auto-bind.
- **A-564-8.** `GovernedEffectSink.execute/3` verifies the registry-anchored grant digest, human, identity, explanation, candidate/scope, and effect. Every substitution case fails before sink, audit, and consume.
- **A-564-9.** `DeploymentGateway.deploy/5` verifies the same provenance and the registry-anchored candidate hash. A forged or mutated grant fails before candidate transition, deployment record, and audit.
- **A-564-10.** A refusal leaves registry status/binding, ETS claims, EventStore events, candidate state, deployment registry, entity state, and audit-success entries unchanged, as applicable.

### 8.4 Identity

- **A-564-11.** Grant issuance requires a verified identity assertion from the identity-provider port. A self-asserted `%AuthenticatedHumanIdentity{}` or an arbitrary non-empty credential alone is refused.
- **A-564-12.** The registry record binds the verified `identity_id` and a digest of the assertion; a presented identity that does not match the record is refused.
- **A-564-13.** RL-564 closure explicitly depends on RL-426/RL-479 or an approved production identity adapter. If that dependency is unresolved, RL-564 remains OPEN even if the registry tests pass.

### 8.5 Durability and integrity

- **A-564-14.** Registry records carry a sequence and an integrity MAC; startup verifies them.
- **A-564-15.** A forged, truncated, duplicated, or reordered record fails closed; no partial prefix is silently promoted to authority.
- **A-564-16.** Valid mint/bind/consume history survives restart; replay after restart is still refused.
- **A-564-17.** `F-ARC-018` is not claimed closed by these tests. Repository-root persistence remains a separate finding.

### 8.6 Regression and evidence

- **A-564-18.** `R564-01` through `R564-09` pass with the strengthened, specific oracles in §7.1, and the new cases in §7.2 pass.
- **A-564-19.** Existing positive tests that asserted arbitrary-ID registration are migrated; no test asserts `record_mint(id) == :ok` as a legitimate authority path.
- **A-564-20.** The full relevant suite runs with no skipped/excluded authority tests at two seeds and at least one restart/tamper run, on Elixir 1.18.4 / OTP 28, with fresh partitions.
- **A-564-21.** An independent verifier repeats the exact commands at the exact commit and records the evidence. The implementer's summary is not sufficient.
- **A-564-22.** RL-564 remains `OPEN` until the verification evidence is recorded in the consolidated register. No CI/runtime green status is claimed without an exact SHA and run.

---

## 9. Prohibited shortcuts

The following do **not** satisfy RL-564:

- Making `record_mint/1` private while leaving an equivalent public helper in another allowlisted module.
- Adding a `human_id` field to the registry record but still accepting the caller's asserted human ID as verified.
- Comparing `identity.human_id` to `grant.human_id` when both are caller-supplied.
- Hashing only the presented struct and comparing it to a hash stored on the same struct.
- Auto-binding an unbound grant at first consumer presentation.
- Requiring only that the registry status is `:granted`.
- Accepting a broad error list in a closure test.
- Using the Council receipt type or verifier for human grants, or vice versa.
- Treating a green version of the current broad oracles as closure proof.
- Claiming `F-ARC-018` closed because per-run DETS partitions are used.
- Modifying PR #13 or using it as the remediation vehicle without a separate governance decision.

---

## 10. Rollout, observability, and rollback

- **Rollout:** ship the authority-surface freeze first (old APIs fail closed), then issuance/proof/registry, then consumers, then tests. Do not leave a window where a consumer accepts a grant that the new issuance path cannot produce.
- **Observability:** emit an audit event for issuance, bind, verification refusal, consume, and registry-integrity failure. Include authorization ID, proof ID (not token), grant digest, effect ID, and error. Do not log raw tokens or credentials.
- **Metrics:** count issuance refusals by reason, proof replay attempts, grant-digest mismatches, identity mismatches, and registry-integrity failures. A spike in proof replay or digest mismatch is a security signal.
- **Rollback:** if the new issuance path fails operationally, do not re-enable `record_mint/1`. Roll back to a prior build that does not expose the vulnerable API, or disable human effect admission. Fail closed.
- **Key management:** document where the registry integrity key lives, how it is rotated, how old records are re-MACed (if at all), and what happens when it is unavailable. Do not store the key in the repository.

---

## 11. Open dependencies and out-of-scope items

| Item | Relationship |
|---|---|
| RL-426 / RL-479 | Verified human identity. RL-564 closure depends on this or an approved adapter. |
| `F-ARC-018` | Store/path hygiene and repository-root DETS. Separate finding; not closed by RL-564. |
| RL-478 / RL-481 | Registry unbound-consume and corrupt-record recovery. The new integrity/restart design must not duplicate or contradict their remediation. |
| RL-480 | RealExecution reuse of a grant consumed/bound to a different Phase4 effect. Separate consumer issue. |
| R564-05 | Phase4 sandbox path; not implemented in CP19.18. Must be covered before claiming full human-grant consumer coverage. |
| R564-10 | Restart/corruption; this spec requires it, but CP19.18 did not implement it. |
| R564-11 | Standard HumanDelivery issuance; this spec's atomic issuance design must cover it. |
| RealExecution, PhysicsPilot, WorldMutationEngine, Baseline | Consumer coverage remains open; audit and migrate or explicitly scope out with governance approval. |
| PR #13 | Separate draft; unchanged. |

---

## 12. Definition of done

RL-564 is done only when:

1. The arbitrary-ID path is gone or unconditionally fail-closed.
2. Human issuance is atomic with a durable, provenance-bearing record.
3. Binding requires a one-time proof and enforces scope.
4. Every in-scope consumer verifies the registry-anchored grant, human, identity, explanation, candidate/scope, and effect.
5. Identity verification is real, not self-asserted.
6. Registry records are integrity-protected and restart/tamper-safe.
7. The strengthened red cases and new negative/durability cases pass with specific errors and postconditions.
8. Existing positive tests that asserted the vulnerability are migrated.
9. An independent verifier records exact-SHA, exact-command evidence.
10. The consolidated register records the result, and only then is RL-564 considered for closure.

Until all ten are true, RL-564 remains **HIGH / OPEN**.
