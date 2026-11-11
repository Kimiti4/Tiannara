# CP19.19 — RL-565 Remediation Specification (Council Decision Provenance)

**Finding:** RL-565 — `MachineAuthorization.mint/2` accepts caller-constructed `Council.Authorization` structs as Council-issued decisions, allowing fabricated machine authority to reach `UnifiedWorldModel.delete_entity/2`; direct machine mint also bypasses the Council emergency gate.  
**Severity:** HIGH  
**Status:** **OPEN** — specification only; no production remediation performed  
**Trust root:** Council decision + Council-issued one-time receipt (not human issuance)  
**Pinned source:** `de231a78db542a6172d7bd1ffd46e8a766deafa4`  
**Verified red baseline:** `268d2e9b442a504873a6f4af691a836ead79120b`  
**Companion artifacts:** `CHECKPOINT_19_19_INDEPENDENT_RED_BASELINE_VERIFICATION_AND_REMEDIATION_SPECIFICATION.md`, `CP19_19_RL564_REMEDIATION_SPECIFICATION.md`, `CP19_19_AUTHORIZATION_TRUST_CHAIN_DIAGRAM.md`

---

## 1. Purpose and boundary

This specification defines the minimum safe remediation for RL-565. Its authority originates in a **Council decision** and a **Council-issued one-time receipt**. It is not a human-grant specification and must not share an authority decision or proof type with RL-564. The two remediations may share registry storage mechanics, canonical digest utilities, integrity protection, atomic consumption, and error-reporting conventions. They must not share a validator that accepts either proof or that treats a registry `:granted` status as sufficient authority.

The remediation must close the source-confirmed path:

```text
caller constructs %Council.Authorization{decision: :approved, decided_at: ...}
  -> MachineAuthorization.mint/2
  -> public permitted?/1 or conditional_grant?/1 + decided_at
  -> hash the caller-supplied struct
  -> MintRegistry.record_mint/2 from allowlisted MachineAuthorization module
  -> bind to an effect
  -> UnifiedWorldModel.delete_entity/2
  -> structural checks + self-recomputed content_hash + registry binding + consume
  -> entity deleted
```

The replacement path must be:

```text
Council evaluates policy/constitution (inside the Council GenServer)
  -> checks emergency state
  -> builds the decision payload
  -> computes the canonical decision digest and scope digest
  -> issues an opaque, MAC-protected, expiring, one-time DecisionReceipt
  -> {:ok, decision, receipt}
  -> MachineAuthorization.mint(decision, receipt, opts)
       -> verifies receipt MAC, issuer, decision digest, type, scope, expiry, emergency
       -> atomically consumes the receipt and writes the machine grant record
       -> {:ok, machine_grant}
  -> proof-bound / scope-bound effect binding
  -> consumers verify the registry-anchored grant digest, decision ref, scope, and effect
  -> emergency re-check at the effect boundary
  -> atomic consume
  -> effect
```

A plain `%Council.Authorization{}` is a decision payload, never a capability.

---

## 2. Current defect (source-confirmed)

| Element | Pinned behavior | Security consequence |
|---|---|---|
| `Tiannara.Council.authorize/3` | GenServer call evaluates policy and returns a plain `%Council.Authorization{}`. During an active emergency it returns a rejected struct. | No issuer receipt, nonce, MAC, scope, or one-time marker. Any caller who receives the struct can copy or reuse it. |
| `Tiannara.Council.Authorization.approved/1` | Public constructor returning `decision: :approved`, `decided_at: DateTime.utc_now()`, and caller-supplied fields. | A caller can fabricate a structurally valid approved decision. |
| `Tiannara.Council.MachineAuthorization.mint/2` | Requires `Authorization.permitted?/1` or `conditional_grant?/1` and non-nil `decided_at`; hashes the caller-supplied struct; registers it from the allowlisted module; returns a machine grant. | The hash anchors the caller's struct, not Council issuance. Fabricated and reconstructed decisions mint successfully (`R565-01`, `R565-02`). An altered genuine decision also mints because the altered struct is re-hashed (`R565-04`). |
| Emergency gate | `Council.authorize/3` checks the emergency inside its GenServer handler. `MachineAuthorization.mint/2` does not call Council and does not consult `Council.emergency_state/0`. | A direct machine mint bypasses the emergency (`R565-08`). |
| `MachineAuthorization.bind_effect/2` | Records the effect and the carried `council_decision_ref` through `MintRegistry.record_bind/3`; checks status/binding/ref anchor. | Any caller holding the grant can bind it; the ref anchor is a digest of the caller-supplied decision, not a Council receipt. |
| `UnifiedWorldModel.delete_entity/2` | Checks presence, registry/struct status, expiry, `authority_class`, `decision_type == :delete_entity`, public decision predicates, non-nil `policy_applied`/`decided_at`, self-recomputed `content_hash` vs stored `content_hash`, effect descriptor, registry binding, node-local executed set, consume, delete, audit. | No Council receipt or registry-anchored decision digest is checked. A fabricated chain deletes an entity (`R565-03`). Post-bind decision substitution also passes because the self-hash is recomputed from the mutated struct. |
| Registry record | Stores `{authorization_id, status, minted_at, council_decision_ref}` plus binding/consumption. No decision scope, receipt ID, grant digest, or MAC. | The registry cannot distinguish a genuine Council decision from a fabricated one, and cannot detect post-bind mutation. |

The current `council_decision_ref` is an important but insufficient anchor: it is a digest of whatever struct the caller supplied. It proves consistency with that struct, not that Council produced the struct. The UWM sink does not compare the registry-anchored ref to the presented decision at all.

---

## 3. Required security invariants

- **INV-565-1.** A machine `:granted` record exists only if Council issued a one-time receipt for the exact decision, and that receipt was verified and consumed atomically at mint.
- **INV-565-2.** A plain `%Council.Authorization{}` or `Authorization.approved/1` struct is never authority. Possession of a struct, a decision digest, or an authorization ID is never sufficient.
- **INV-565-3.** The receipt binds the decision digest, decision type, operation/target scope, actor, issuer identity/version, policy/constitution versions, issue time, expiry, and nonce.
- **INV-565-4.** One Council decision receipt produces at most one machine grant. A second mint from the same receipt fails.
- **INV-565-5.** Binding verifies the registry-anchored decision ref and scope. The grant cannot be bound outside the authorized operation/target.
- **INV-565-6.** The effect boundary verifies the registry-anchored grant digest, decision ref, scope, effect, expiry, and consumption state. Post-bind mutation of the decision, decision type, scope, TTL, or effect fails before consume, graph deletion, or audit-success.
- **INV-565-7.** Council emergency blocks receipt issuance, direct machine mint, and effect-boundary consumption. A direct mint cannot bypass the gate.
- **INV-565-8.** Machine authority and human authority remain distinguishable in storage and verification. A Council verifier accepts only Council-issued records; a human verifier accepts only human-issued records.
- **INV-565-9.** Receipt and registry integrity survive restart or fail closed. A forged/tampered record or a replayed receipt is refused after restart.

---

## 4. Target design

### 4.1 Council decision receipt

Add `Tiannara.Council.DecisionReceipt`:

```elixir
defmodule Tiannara.Council.DecisionReceipt do
  @enforce_keys [
    :receipt_id,
    :decision_digest,
    :decision_type,
    :scope_digest,
    :actor,
    :issued_at,
    :expires_at,
    :nonce,
    :issuer,
    :policy_version,
    :constitution_version,
    :mac
  ]
  defstruct [
    :receipt_id,
    :decision_digest,
    :decision_type,
    :scope_digest,
    :actor,
    :issued_at,
    :expires_at,
    :nonce,
    :issuer,
    :policy_version,
    :constitution_version,
    :mac
  ]
end
```

Design rules:

- `receipt_id` and `nonce` are server-generated random values (at least 128 bits each; nonce at least 256 bits).
- `decision_digest` is the canonical digest of the **exact** decision payload Council produced.
- `decision_type` is the operation class (`:delete_entity`, `:update_entity`, etc.).
- `scope_digest` is the canonical digest of the authorized operation/target/payload scope. For `delete_entity`, it must include the target entity ID or the canonical effect descriptor digest. For other operations, it includes the operation and target/payload identity.
- `actor` is the requesting actor from the evaluated context.
- `issuer` identifies the Council instance/version (at minimum a stable node/authority identifier plus code version).
- `policy_version` and `constitution_version` bind the decision to the rules that produced it.
- `mac` is an HMAC-SHA256 over all prior fields with a key held only by the Council receipt issuer/verifier boundary. The struct is constructible, but a valid MAC is not.
- The receipt is returned to the caller exactly once by `Council.decide/3`. It is not embedded in a caller-mutable field.

A receipt is **not** a decision. It is evidence that Council evaluated and issued this decision. It carries no independent permission to exceed the decision/scope.

### 4.2 Council issuance API

Add `Council.decide/3` (name may vary) for decisions that may authorize machine effects:

```elixir
Council.decide(decision_type, payload, context \\ nil)
  :: {:ok, %Council.Authorization{}, %DecisionReceipt{}}
   | {:error, :council_emergency_active
             | :policy_rejected
             | :constitution_rejected
             | :invalid_scope
             | :receipt_unavailable
             | term()}
```

Behavior:

1. Enter the Council GenServer.
2. If the emergency is active and the operation is not explicitly emergency-allowed, return `{:error, :council_emergency_active}` and write no receipt. Do **not** return a rejected decision that a caller could misread as a payload.
3. Evaluate policy and constitutional rules exactly as the current decision path does.
4. If the result is not an approving/conditional decision that may authorize a machine effect, return an error or a non-authorizing decision with no receipt. A rejected/deferred decision must never produce a receipt.
5. Require a scope for machine-authorizing decisions. If the caller did not supply a target/operation scope, return `:invalid_scope`. Do not issue a broad receipt and rely on bind-time discretion.
6. Build the decision payload with the evaluated fields, policy/constitution versions, actor, and decision timestamp.
7. Compute `decision_digest` and `scope_digest` with the canonical encoder.
8. Generate `receipt_id`, `nonce`, `issued_at`, and a short `expires_at`.
9. Compute the MAC and return `{:ok, decision, receipt}`.

Keep `Council.authorize/3` for advisory/non-machine decisions, but document and enforce that its return value cannot mint. `MachineAuthorization.mint/2` must refuse a plain decision with `:council_decision_proof_required`. Any production caller that needs machine authority must migrate to `Council.decide/3` and `mint/3`.

### 4.3 Machine mint

Change the machine mint surface to:

```elixir
MachineAuthorization.mint(decision, receipt, opts)
  :: {:ok, t()}
   | {:error, :council_decision_proof_required
             | :council_decision_receipt_invalid
             | :council_decision_receipt_expired
             | :council_decision_receipt_consumed
             | :council_decision_digest_mismatch
             | :council_decision_type_mismatch
             | :council_scope_mismatch
             | :council_receipt_issuer_invalid
             | :council_receipt_policy_mismatch
             | :council_emergency_active
             | :council_receipt_unavailable
             | :registry_corrupt
             | :authorization_registry_unavailable
             | term()}
```

Verification order (fail closed before any registry write):

1. Require a `%DecisionReceipt{}`. A missing receipt returns `:council_decision_proof_required`; the old `mint/2` should be retained only as a fail-closed compatibility clause.
2. Verify the receipt MAC and issuer identifier. A random/forged MAC returns `:council_decision_receipt_invalid` or `:council_receipt_issuer_invalid`.
3. Verify `receipt.decision_digest == canonical_decision_digest(decision)`.
4. Verify `receipt.decision_type == opts[:decision_type]`.
5. Verify `receipt.scope_digest` matches the requested operation/scope and the decision payload's target.
6. Verify the issuer/policy/constitution versions are the current accepted versions (or an explicitly allowed prior version).
7. Verify `receipt.expires_at` is in the future.
8. Consult Council emergency state (or a receipt epoch) and refuse `:council_emergency_active` if active.
9. Build the machine grant with a server-generated `authorization_id`, `council_decision_ref = receipt.decision_digest`, `decision_type`, `granted_at`, TTL, and a canonical `content_hash`.
10. Call `MintRegistry.issue_machine/2` with the receipt ID/digest, grant digest, scope, decision ref, and receipt metadata. The registry atomically:
    - checks the receipt ID is unconsumed;
    - writes the grant record and its integrity MAC;
    - marks the receipt consumed;
    - returns `:ok`.
11. Return `{:ok, grant}` only after the durable write.

If the registry is unavailable or corrupted, no grant is returned. Receipt consumption and grant registration must be one atomic operation; a consumed receipt with no grant or a grant with an unconsumed receipt is not acceptable.

### 4.4 Machine registry record

The machine record must carry at least:

| Field | Purpose |
|---|---|
| `authorization_id` | Server-generated machine grant identity |
| `issuer` | `:council` (distinct from `:human`) |
| `receipt_id` | Council receipt identity |
| `receipt_digest` | Digest of the receipt (or receipt MAC fingerprint) |
| `decision_digest` | Canonical digest of the decision payload |
| `grant_digest` | Canonical digest of the machine grant |
| `decision_type` | Operation class |
| `scope_digest` | Authorized operation/target/scope |
| `actor` | Council decision actor |
| `issuer_id` / `issuer_version` | Council authority identity |
| `policy_version`, `constitution_version` | Decision rule versions |
| `issued_at`, `expires_at` | Temporal bounds |
| `status` | `:granted`, `:bound`, `:consumed`, `:revoked`, `:expired` |
| `effect_id`, `bound_at`, `consumed_at` | One-shot effect state |
| `record_seq`, `record_mac` | Integrity and replay protection |

The record must not rely on a caller-supplied `council_decision_ref` alone. The decision digest must be derived from the verified Council receipt and the decision payload, and the registry copy must be compared at bind and at the effect boundary.

### 4.5 Binding

`MachineAuthorization.bind_effect/2` (or `/3`) must verify against the registry:

1. Record exists and `issuer == :council`.
2. Record status is `:granted` (unbound) or the exact same binding already exists.
3. Grant digest matches the record's `grant_digest`.
4. `grant.council_decision_ref == record.decision_digest`.
5. `grant.decision_type == record.decision_type`.
6. The effect descriptor's canonical operation/target/effect digest is within `record.scope_digest`.
7. The grant is unexpired and the receipt was validly consumed at mint.
8. Atomically write `effect_id`/`bound_at` and return the bound grant.

Binding must not be a public "bind by ID" authority path. A caller holding a genuine machine grant can request binding only within the authorized scope; a caller holding an ID alone cannot bind. If the design requires a bind capability, derive it from the receipt/grant and keep it one-time; do not accept a caller-selected effect without a scope check.

The current public `MintRegistry.record_bind/3` must be removed or made internal with the same provenance checks. A caller that supplies only an ID, effect, and `council_decision_ref` must receive `:authorization_provenance_invalid` (or `:bind_proof_required`), not `:ok`.

### 4.6 Effect-boundary verification

Add a Council-specific verifier, for example:

```elixir
MintRegistry.verify_council_presentation(grant, effect_id)
  :: {:ok, verified_record}
   | {:error, :authorization_provenance_invalid
             | :authorization_grant_digest_mismatch
             | :council_decision_digest_mismatch
             | :council_decision_type_mismatch
             | :council_scope_mismatch
             | :authorization_not_registered
             | :authorization_not_bound
             | :registry_binding_mismatch
             | :authorization_expired
             | :already_consumed
             | :council_emergency_active
             | :registry_corrupt
             | :authorization_registry_unavailable}
```

Verification must compare the presented grant to the registry record, not to a hash carried by the grant:

- record exists, `issuer == :council`, status `:bound`, unexpired, unconsumed;
- `record.grant_digest == canonical_machine_grant_digest(grant)` (include authorization ID, decision type, decision digest, scope, effect ID, status, granted_at, TTL);
- `record.decision_digest == grant.council_decision_ref == canonical_decision_digest(grant.decision)`;
- `record.decision_type == grant.decision_type == requested operation`;
- `record.scope_digest` matches the canonical operation/target/effect descriptor;
- `record.effect_id == grant.effect_id == effect_id`;
- registry binding agrees;
- Council emergency is not active (or the receipt epoch is still valid for this operation);
- the receipt was consumed exactly once at mint and is not revoked.

`MachineAuthorization.content_hash/1` may remain as a local tamper-evidence check, but it must not be the authority. The authority is the registry-anchored digest and decision ref.

Consumer changes:

- **`UnifiedWorldModel.delete_entity/2`**: call `verify_council_presentation/2` before `consume/1` and before `UnifiedRealityGraph.remove_entity/1`. Keep the operation/target check and registry binding as defense-in-depth. Refuse `:council_decision_digest_mismatch` or `:authorization_grant_digest_mismatch` for post-bind mutation. Re-check emergency at this boundary. Only then consume, remove entity, remove relationships, audit, and verify the audit.
- **`WorldMutationEngine` and other Council-authorized effect consumers**: audit and migrate to the same verifier or explicitly scope out with governance approval. The CP19.17 matrix identified them; CP19.18 does not cover them.
- **`MachAuthorization` consumers generally**: no consumer may accept a machine grant solely because `status == :granted`, the registry says `:granted`, and `content_hash` matches itself.

### 4.7 Emergency enforcement

Emergency must be enforced at three points:

1. **Receipt issuance.** `Council.decide/3` refuses during an active emergency (except explicitly enumerated emergency operations such as `:emergency_halt`/`:circuit_breaker`).
2. **Machine mint.** `MachineAuthorization.mint/3` re-checks emergency state (or a receipt epoch) before registry write. A receipt minted before the emergency must not produce a new grant during it.
3. **Effect boundary.** `verify_council_presentation/2` re-checks emergency before consume. A grant minted and bound before the emergency must not delete/execute during it. Emergency-allowed operations are explicitly enumerated; `delete_entity` is not one.

The emergency check must not be a caller-supplied boolean or a struct field. It must consult the authoritative Council state (or a monotonic epoch replicated into the verifier) at the point of decision.

`Council.lift_emergency/1` currently accepts a caller-supplied `human_id` without identity verification; that is a separate authority concern. This spec does not use emergency lift as proof of anything.

### 4.8 Receipt and registry integrity

- The receipt MAC key is held by the Council receipt issuer/verifier boundary, not checked into the repository. Document generation, storage, rotation, and recovery.
- The registry record MAC uses a registry integrity key (separate from the receipt key), as in the RL-564 design but with a distinct record schema/tag.
- Startup verifies receipt-consumption records and grant records. A forged record, a consumed receipt with no grant, a grant with an unconsumed receipt, a sequence gap, or a MAC failure fails closed with `:registry_corrupt`.
- Receipt replay after restart: the registry's consumed set must survive restart. If it does not, a valid receipt could mint again. The spec requires durable receipt-consumption state or a receipt expiry/epoch design that makes replay harmless; the preferred design is durable consumption in the same registry transaction as the grant.
- `decode_records/1` must distinguish clean EOF from truncation. Do not silently drop a truncated tail and load the prefix as authoritative.

### 4.9 Decision digest and scope canonicalization

- Use one canonical encoder for both `decision_digest` and `scope_digest`. The current `:erlang.term_to_binary/1` over a struct with maps/lists is not sufficient unless map ordering is canonicalized and the encoder version is pinned.
- Include the encoder version in the receipt and registry record so a future encoding change does not silently invalidate or, worse, reinterpret authority.
- The decision digest must cover every authority-bearing field: decision, confidence, constitutional score, violated principles, required human review, explanation, evidence, risks, simulation results, recommendation, context, decided_at, policy_applied, metadata, conditions, and any scope/actor fields.
- The scope digest must cover operation, target entity/candidate, payload digest, and the canonical effect descriptor digest where known. A scope that is only `:delete_entity` with no target is too broad and must be rejected for machine-authorizing decisions.

---

## 5. Error taxonomy

| Situation | Canonical error |
|---|---|
| Plain struct presented to mint | `:council_decision_proof_required` |
| Receipt missing/invalid MAC | `:council_decision_receipt_invalid` |
| Receipt issuer/version not accepted | `:council_receipt_issuer_invalid` |
| Receipt policy/constitution version mismatch | `:council_receipt_policy_mismatch` |
| Receipt expired | `:council_decision_receipt_expired` |
| Receipt already consumed | `:council_decision_receipt_consumed` |
| Decision digest mismatch | `:council_decision_digest_mismatch` |
| Decision type mismatch | `:council_decision_type_mismatch` |
| Scope/target mismatch | `:council_scope_mismatch` |
| Emergency active | `:council_emergency_active` |
| Grant digest mismatch at effect | `:authorization_grant_digest_mismatch` |
| Registry decision ref mismatch | `:council_decision_digest_mismatch` |
| Not registered | `:authorization_not_registered` |
| Not bound | `:authorization_not_bound` |
| Registry binding mismatch | `:registry_binding_mismatch` |
| Expired grant | `:authorization_expired` |
| Already consumed | `:already_consumed` |
| Registry corrupt/tampered | `:registry_corrupt` |
| Registry unavailable | `:authorization_registry_unavailable` |
| Invalid scope at decision | `:invalid_scope` |
| Bind without proof/scope | `:bind_proof_required` / `:authorization_provenance_invalid` |

Closure tests must select the specific error for the situation and assert postconditions. Broad error lists and `match?({:error, _})` are prohibited.

---

## 6. Implementation sequence

1. **Freeze the authority surface.**
   - Add the fail-closed `mint/2` compatibility clause returning `:council_decision_proof_required`.
   - Add a caller inventory gate for every `MachineAuthorization.mint` and `MintRegistry.record_mint` call.
   - Document that `Council.authorize/3` is non-mintable.

2. **Add the receipt type and Council issuance.**
   - `DecisionReceipt` struct.
   - Canonical decision/scope digest with an encoder version.
   - `Council.decide/3` with policy/constitution evaluation, scope requirement, emergency check, MAC, expiry, nonce.
   - Receipt verifier/key management.

3. **Add machine mint verification and atomic registration.**
   - `MachineAuthorization.mint/3`.
   - `MintRegistry.issue_machine/2` with receipt consumption + grant record in one transaction.
   - Durable receipt-consumption state.
   - Grant digest and record MAC.

4. **Refactor binding and consumers.**
   - `MachineAuthorization.bind_effect/2` verifies registry provenance and scope.
   - `UnifiedWorldModel.delete_entity/2` uses `verify_council_presentation/2`, re-checks emergency, then consumes/deletes/audits.
   - Audit and migrate other machine-effect consumers or scope them out.

5. **Add restart/tamper handling.**
   - Startup verification of receipt consumption and grant records.
   - Truncation/tamper fail-closed behavior.
   - Replay-after-restart tests.

6. **Migrate tests.**
   - Strengthen R565-01..08 oracles.
   - Add the new cases in §7.
   - Migrate positive tests that mint a plain struct.
   - Keep controls green.

7. **Run and capture evidence.**
   - Focused suite at two seeds.
   - Emergency tests at mint and effect boundary.
   - Restart/tamper.
   - Full suite.
   - Independent verifier repeats the exact commands.

---

## 7. Test plan and oracle strengthening

### 7.1 Red-baseline cases to retain and strengthen

| Case | Current weakness | Closure oracle |
|---|---|---|
| `R565-01` | Exact error, no registry postcondition | Assert `:council_decision_proof_required`; no registry record, no decision ref, no audit row |
| `R565-02` | Same | Same |
| `R565-03` | Exact error + entity exists; no registry/audit postcondition | Assert `:council_decision_proof_required`; no registry record/binding/consume; no `:world_entity_deleted` audit; entity and relationships remain |
| `R565-04` | Alteration before mint; no one-time receipt check | Assert `:council_decision_receipt_invalid` or `:council_decision_digest_mismatch`; the genuine receipt remains unconsumed; the genuine decision can still mint exactly once |
| `R565-05` | Control; no entity created | Create the target entity; assert `:decision_type_mismatch`; entity remains; grant not consumed |
| `R565-06` | Control; decision payload target is a dummy | Issue the genuine decision for entity A (scope-bound); bind to A; assert delete B returns `:effect_id_mismatch`; both entities remain; grant not consumed |
| `R565-07` | Strong replay control | Preserve; assert the one success verified the receipt/decision ref at the effect boundary; status `:consumed`; entity gone |
| `R565-08` | `match?({:error, _})`; only mint-time | Split into three assertions: (a) `Council.decide/3` during emergency returns `:council_emergency_active` and no receipt; (b) `MachineAuthorization.mint/3` with a valid pre-emergency receipt returns `:council_emergency_active` and writes no record; (c) a pre-emergency minted/bound grant presented to UWM during emergency returns `:council_emergency_active`, entity remains, not consumed, no audit |
| Genuine Council control | Strong positive path; no receipt-consumption assertion | Assert `MintRegistry.decision_ref(id) == grant.council_decision_ref`; the receipt is consumed exactly once; a second mint from the same receipt returns `:council_decision_receipt_consumed` |

### 7.2 New negative, replay, substitution, and durability cases

1. **Plain struct cannot mint.** `MachineAuthorization.mint(Authorization.approved(...), opts)` returns `:council_decision_proof_required`; no registry record.
2. **Forged receipt MAC.** Construct a receipt with a random MAC; mint returns `:council_decision_receipt_invalid`; no record.
3. **Receipt from another decision.** Mint decision B with decision A's receipt; returns `:council_decision_digest_mismatch`; A's receipt remains unconsumed.
4. **Altered decision with real receipt.** Alter a field, keep the receipt; returns `:council_decision_digest_mismatch`; no record.
5. **Wrong decision type.** Receipt for `:update_entity`, mint with `:delete_entity`; returns `:council_decision_type_mismatch`; no record.
6. **Wrong scope/target.** Receipt for entity A, mint/bind for entity B; returns `:council_scope_mismatch`; no record/binding.
7. **Multiple mints from one receipt.** First mint succeeds; second returns `:council_decision_receipt_consumed`; exactly one registry record and one grant.
8. **Post-bind decision substitution.** Mint genuine, bind, mutate `decision` and recompute `content_hash`; UWM returns `:authorization_grant_digest_mismatch` or `:council_decision_digest_mismatch`; entity remains; not consumed; no audit.
9. **Post-bind decision-type substitution.** Mutate `decision_type` and recompute local hash; UWM returns `:council_decision_digest_mismatch`/`:authorization_grant_digest_mismatch`; no delete.
10. **Post-bind scope/effect substitution.** Mutate `effect_id` or present a different entity; returns `:registry_binding_mismatch`/`:council_scope_mismatch`; no delete.
11. **Expired receipt.** Mint after `expires_at`; returns `:council_decision_receipt_expired`; no record.
12. **Expired grant at effect.** Bind, wait past TTL (or inject clock); UWM returns `:authorization_expired`; no delete.
13. **Emergency at effect boundary.** Mint/bind before emergency, invoke emergency, present to UWM; returns `:council_emergency_active`; entity remains; not consumed; no audit.
14. **Restart replay.** Mint/bind, restart registry/Council, replay the receipt and the grant; receipt mint fails `:council_decision_receipt_consumed`; grant replay fails `:already_consumed`; no second effect.
15. **Registry tamper.** Forge a machine grant record with an invalid MAC or mismatched receipt; restart; record is `:registry_corrupt`/unusable; no authority.
16. **Truncated tail.** Truncate the last record; restart fails closed; no silent prefix promotion.
17. **Receipt issuer/version mismatch.** A receipt from an unaccepted issuer or stale policy/constitution version returns `:council_receipt_issuer_invalid`/`:council_receipt_policy_mismatch`; no record.
18. **Audit provenance.** A successful delete records the grant digest, decision ref, receipt ID, and effect ID; a refusal records no success audit.

### 7.3 Existing tests that must change

The following tests currently assert plain-struct minting as positive and must be migrated:

- `test/tiannara/omega/step13_r2_mint_authentication_test.exs`
  - The case that constructs `Authorization.approved(...)` and asserts `MachineAuthorization.mint(...)` succeeds.
  - Replace with: `Council.decide/3` + `MachineAuthorization.mint/3` for the positive path, and a separate negative case asserting a plain struct returns `:council_decision_proof_required`.
- `test/tiannara/world/d127_uwm_delete_evaluation_test.exs`
  - Uses `Council.authorize/3` then `MachineAuthorization.mint/2`.
  - Migrate the positive path to `Council.decide/3` + `mint/3`, with a scope that matches the target entity.
  - Keep the D127.6 unregistered/forged-ID negative case; add a receipt-forgery negative case.
- Any other `MachineAuthorization.mint` or `MintRegistry.record_mint` caller found by:

```text
rg -n "MachineAuthorization\.mint|MintRegistry\.record_mint|Council\.authorize\(" lib test
```

Audit each caller: either migrate to `Council.decide/3` + `mint/3`, or confirm it does not use the result for machine authority.

No test may retain a positive assertion that a plain `Authorization.approved/1` struct mints.

### 7.4 Test isolation requirements

- Fresh `TEST_PARTITION` per run.
- Test-only Council receipt key and registry integrity key; no production keys.
- Restore Council emergency state, named processes, ETS, application env, and receipt-consumption state in `on_exit`.
- Keep `async: false` for tests that touch the Council GenServer, registry, ETS, or global identity state.
- Capture seed, partition, test count, failure count, excluded count, and per-case results.
- Do not write repository-root DETS artifacts; `F-ARC-018` remains separate.

---

## 8. RL-565 acceptance criteria

RL-565 may be proposed for closure only when all of the following are independently verified.

### 8.1 Authority surface

- **A-565-1.** `MachineAuthorization.mint/2` (plain decision) fails closed with `:council_decision_proof_required`; no registry write.
- **A-565-2.** `Council.decide/3` is the only path that issues a decision receipt, and it does so inside the Council GenServer after policy/constitution evaluation and emergency check.
- **A-565-3.** A receipt is MAC-protected, issuer/version-bound, decision-digest-bound, scope-bound, expiring, and one-time. A caller can construct the struct but cannot forge a valid receipt.
- **A-565-4.** `MachineAuthorization.mint/3` verifies the receipt before any registry write and consumes it atomically with grant registration.

### 8.2 Registry and binding

- **A-565-5.** The machine registry record stores the receipt ID/digest, decision digest, grant digest, decision type, scope, actor, issuer/version, policy/constitution versions, expiry, effect, and integrity MAC.
- **A-565-6.** Binding verifies the registry-anchored grant digest, decision ref, decision type, scope, and effect. Binding outside scope fails; binding by ID alone fails; rebinding fails.
- **A-565-7.** One receipt produces at most one machine grant; a second mint returns `:council_decision_receipt_consumed`.

### 8.3 Effect boundary

- **A-565-8.** `UnifiedWorldModel.delete_entity/2` verifies the registry-anchored grant digest, decision ref, decision type, scope, effect, expiry, and consumption state before consume/delete/audit.
- **A-565-9.** Post-bind substitution of the decision, decision type, scope, TTL, or effect fails with a specific provenance error; the entity and relationships remain; no consume or success audit.
- **A-565-10.** A fabricated mint → bind → delete chain fails before registry consume, graph deletion, and audit.
- **A-565-11.** Other machine-effect consumers are migrated or explicitly scoped out with governance approval; `MachineAuthorization.content_hash/1` is not treated as provenance.

### 8.4 Emergency

- **A-565-12.** Emergency blocks `Council.decide/3` receipt issuance with `:council_emergency_active`.
- **A-565-13.** Emergency blocks direct `MachineAuthorization.mint/3` even with a valid pre-emergency receipt.
- **A-565-14.** Emergency blocks effect-boundary consumption; a pre-emergency grant cannot delete during the emergency.
- **A-565-15.** Emergency-allowed operations are explicitly enumerated; `delete_entity` is not one.

### 8.5 Durability and integrity

- **A-565-16.** Receipt consumption and grant registration are durable and atomic; restart preserves the consumed set and grant status.
- **A-565-17.** A forged/tampered machine record, a consumed receipt with no grant, a grant with an unconsumed receipt, a truncated tail, or a sequence gap fails closed.
- **A-565-18.** Replaying a receipt or grant after restart is refused; no second effect.
- **A-565-19.** `F-ARC-018` is not claimed closed by these tests.

### 8.6 Regression and evidence

- **A-565-20.** `R565-01` through `R565-08` pass with the strengthened oracles in §7.1, and the new cases in §7.2 pass.
- **A-565-21.** The controls `R565-05`, `R565-06`, `R565-07`, and the genuine Council path remain green, with the scope-aware updates in §7.3.
- **A-565-22.** Existing positive tests that minted plain structs are migrated; no test asserts plain-struct mint success.
- **A-565-23.** The full relevant suite runs with no skipped/excluded authority tests at two seeds and at least one restart/tamper run, on Elixir 1.18.4 / OTP 28, with fresh partitions.
- **A-565-24.** An independent verifier repeats the exact commands at the exact commit and records the evidence.
- **A-565-25.** RL-565 remains `OPEN` until the verification evidence is recorded in the consolidated register. No CI/runtime green status is claimed without an exact SHA and run.

---

## 9. Prohibited shortcuts

The following do **not** satisfy RL-565:

- Adding a `receipt` field to `%Council.Authorization{}` that is caller-constructible and not MAC-verified.
- Hashing the decision struct and calling that digest a receipt.
- Treating `Authorization.approved/1` plus a non-nil `decided_at` as provenance.
- Verifying the receipt only at mint and not at bind/effect boundary.
- Consuming the receipt at bind instead of mint, allowing multiple mints.
- Accepting a receipt with no scope, or a scope that is only the operation name with no target.
- Checking emergency only inside `Council.authorize/3` while direct `MachineAuthorization.mint` bypasses it.
- Checking emergency only at mint, not at the effect boundary.
- Using `MachineAuthorization.content_hash/1` compared to the struct's own field as authority.
- Sharing the human issuance proof or human verifier with machine grants, or vice versa.
- Broad error lists or any-error assertions in closure tests.
- Treating a green version of the current `R565-08` any-error oracle as emergency proof.
- Claiming `F-ARC-018` closed because per-run DETS partitions are used.
- Modifying PR #13 without a separate governance decision.

---

## 10. Rollout, observability, and rollback

- **Rollout:** ship the fail-closed plain-struct mint first, then the receipt/issuance path, then binding/effect-boundary verification, then consumer migration, then tests. Do not leave a window where a consumer accepts a grant the new mint cannot produce.
- **Observability:** audit receipt issuance, receipt refusal, receipt consumption, grant registration, bind, effect-boundary refusal, consume, and integrity failure. Include receipt ID, decision digest, grant digest, authorization ID, effect ID, and error. Do not log raw MAC keys or secrets.
- **Metrics:** receipt forgery, digest mismatch, scope mismatch, replay attempts, emergency refusals, and registry-integrity failures. A spike in receipt replay/digest mismatch is a security signal.
- **Rollback:** if the receipt path fails operationally, do not re-enable plain-struct mint. Roll back to a prior build that does not expose the vulnerable path, or disable machine effect admission. Fail closed.
- **Key management:** document the Council receipt key and registry integrity key separately. Define rotation, issuer/version acceptance, and what happens when a key is unavailable. Do not store keys in the repository.
- **Policy/constitution versions:** define how a receipt issued under version N is treated after an upgrade. The safe default is to reject stale-version receipts unless an explicit migration window is approved and recorded.

---

## 11. Open dependencies and out-of-scope items

| Item | Relationship |
|---|---|
| RL-564 | Separate human trust root; do not share authority. |
| `F-ARC-018` | Store/path hygiene; separate finding. |
| RL-478 / RL-481 | Registry unbound-consume and corrupt-record recovery; the new integrity design must align. |
| RL-480 | RealExecution grant/effect reuse; separate consumer issue. |
| Council emergency lift | `lift_emergency/1` accepts a caller-supplied human ID; separate authority concern. |
| Policy/constitution versioning | Receipts must bind versions; upgrade behavior needs governance approval. |
| `WorldMutationEngine`, `PhysicsPilot`, `RealExecution`, `Baseline` | Machine-effect consumer coverage remains open; audit and migrate or scope out. |
| `R564-05`, `R564-10`, `R564-11` | Human-side gaps; not this spec. |
| PR #13 | Separate draft; unchanged. |

---

## 12. Definition of done

RL-565 is done only when:

1. Plain-struct mint is fail-closed and no production caller can mint by struct alone.
2. Council issues a MAC-protected, scoped, expiring, one-time receipt for the exact decision.
3. Machine mint verifies the receipt before any registry write and consumes it atomically with grant registration.
4. Binding verifies registry provenance and scope; one receipt produces one grant.
5. UWM and every in-scope machine-effect consumer verify the registry-anchored grant digest, decision ref, scope, effect, expiry, and consumption before effect.
6. Emergency blocks receipt issuance, mint, and effect-boundary consumption.
7. Post-bind substitution, multi-mint, receipt replay, and restart/tamper are covered by negative tests with specific errors and postconditions.
8. Existing positive tests that asserted plain-struct minting are migrated.
9. An independent verifier records exact-SHA, exact-command evidence.
10. The consolidated register records the result, and only then is RL-565 considered for closure.

Until all ten are true, RL-565 remains **HIGH / OPEN**.
