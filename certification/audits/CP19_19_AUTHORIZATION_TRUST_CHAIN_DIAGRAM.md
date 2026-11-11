# CP19.19 — Authorization Trust-Chain Diagram (RL-564 and RL-565)

**Date:** 2026-11-12  
**Pinned source:** `de231a78db542a6172d7bd1ffd46e8a766deafa4`  
**Verified red baseline:** `268d2e9b442a504873a6f4af691a836ead79120b`  
**Status:** design reference for the two separate remediation specifications; no production change

This diagram is normative for the separation requirement. RL-564 and RL-565 may share registry storage, canonical encoding, integrity MACs, atomic compare-and-set consumption, and error-reporting mechanics. They must **not** share an authority decision, an issuer, a proof type, or a verifier that accepts either proof.

---

## 1. Two trust roots at a glance

```text
┌─────────────────────────────────────┐        ┌─────────────────────────────────────┐
│ HUMAN TRUST ROOT — RL-564           │        │ COUNCIL TRUST ROOT — RL-565         │
│                                     │        │                                     │
│ "A verified human approved this     │        │ "Council evaluated and issued this  │
│  explanation/scope for this human." │        │  decision for this operation/scope."│
│                                     │        │                                     │
│ Issuer: HumanDelivery.Authorization │        │ Issuer: Tiannara.Council GenServer  │
│ Proof:  one-time issuance token     │        │ Proof:  one-time DecisionReceipt    │
│         (stored as sha256 only)     │        │         (MAC + nonce + expiry)      │
│ Root:   human decision + verified   │        │ Root:   policy/constitution +       │
│         identity-provider assertion │        │         Council authority           │
└─────────────────────────────────────┘        └─────────────────────────────────────┘
                    │                                              │
                    │        SHARED MECHANICS ONLY                 │
                    │  ┌──────────────────────────────────────┐    │
                    └──┤ canonical digest · record MAC        ├────┘
                       │ atomic consume · error taxonomy      │
                       │ durable append-only registry storage │
                       └──────────────────────────────────────┘
                    │                                              │
                    ▼                                              ▼
        verify_human_presentation                      verify_council_presentation
        (issuer == :human only)                        (issuer == :council only)
```

The two verifiers are deliberately different entry points. There is no `verify_any/2`, no "registry says `:granted`" shortcut, and no proof object that either issuer can satisfy.

---

## 2. Target human chain (RL-564)

```text
HUMAN
  │
  │  decision to approve a specific explanation / candidate / scope
  ▼
IDENTITY PROVIDER
  │  verify credential / assertion
  │  returns %VerifiedIdentity{identity_id, human_id, method, verified_at, digest}
  │
  │  ✗ NOT: AuthenticatedHumanIdentity.authenticate(any_non_empty_binary)
  │  ✗ NOT: a bare human_id atom or string
  ▼
HumanDelivery.Authorization.human_grant/3
  │  atomic issuance:
  │    - validate pending request + explanation/scope
  │    - server-generate authorization_id
  │    - canonical grant_digest over all authority-bearing fields
  │    - generate 256-bit token; store only sha256(token)
  │    - write durable registry record with provenance + MAC
  │  returns {:ok, grant, %IssuanceProof{token, grant_digest, ...}}
  ▼
MintRegistry record
  │  issuer: :human
  │  authorization_id · grant_digest · identity_id/digest
  │  human_id · explanation_id/digest · candidate_content_hash
  │  scope_digest · issued_at/expires_at · record_seq · record_mac
  │  status: :granted → :bound → :consumed
  ▼
Proof-bound one-shot bind
  │  Authorization.bind_effect/3(grant, descriptor, proof)
  │    - verify token hash, grant digest, proof expiry, scope
  │    - consume proof atomically; write effect_id + bound_at
  │    - second bind → :bind_proof_consumed
  ▼
EFFECT CONSUMERS
  │  ExecutionGovernance.begin/2
  │  GovernedEffectSink.execute/3
  │  DeploymentGateway.deploy/5
  │
  │  each calls verify_human_presentation(grant, effect_id, identity)
  │    - issuer == :human
  │    - registry grant_digest == canonical_grant_digest(grant)
  │    - record human_id / identity_id / explanation_digest / candidate_hash / scope
  │    - record effect_id == grant.effect_id == presented effect
  │    - record status :bound, unexpired, unconsumed
  ▼
  │  atomic consume (granted/bound → consumed)
  ▼
EFFECT + SUCCESS AUDIT
```

### Human-chain prohibitions

```text
caller-selected ID ──✗──> Authorization.record_mint/1 ──✗──> registry :granted
stack-origin module ──✗──> authority
identity.human_id == grant.human_id ──✗──> proof (both caller-supplied)
grant.content_hash == grant.content_hash ──✗──> provenance
auto-bind at first consumer ──✗──> binding authority
one pending request ──✗──> multiple valid grants
```

---

## 3. Target Council chain (RL-565)

```text
COUNCIL
  │
  │  decision request: operation + target/scope + payload/evidence
  ▼
Council GenServer — decide/3
  │  - policy + constitution evaluation
  │  - emergency check (active → :council_emergency_active; no receipt)
  │  - scope required (operation + target/effect descriptor digest)
  │  - canonical decision_digest + scope_digest (versioned encoder)
  │  - build %Council.Authorization{} decision payload
  │  - generate receipt_id + nonce + issued_at/expires_at
  │  - MAC over receipt fields with Council-held key
  │  returns {:ok, decision, %DecisionReceipt{}}
  ▼
MachineAuthorization.mint/3(decision, receipt, opts)
  │  verify before any registry write:
  │    - receipt MAC + issuer/version
  │    - receipt.decision_digest == canonical_decision_digest(decision)
  │    - decision_type matches opts
  │    - scope matches requested operation/target
  │    - policy/constitution versions accepted
  │    - receipt unexpired
  │    - emergency not active
  │  atomic registry operation:
  │    - check receipt_id unconsumed
  │    - write grant record + record MAC
  │    - mark receipt consumed
  ▼
MintRegistry record
  │  issuer: :council
  │  authorization_id · receipt_id/digest · decision_digest
  │  grant_digest · decision_type · scope_digest · actor
  │  issuer_id/version · policy_version · constitution_version
  │  issued_at/expires_at · record_seq · record_mac
  │  status: :granted → :bound → :consumed
  ▼
Scope-bound one-shot bind
  │  MachineAuthorization.bind_effect/2
  │    - record grant_digest == canonical_machine_grant_digest(grant)
  │    - record decision_digest == grant.council_decision_ref
  │    - record decision_type == grant.decision_type
  │    - effect descriptor within record.scope_digest
  │    - write effect_id + bound_at
  ▼
EFFECT CONSUMERS
  │  UnifiedWorldModel.delete_entity/2
  │  WorldMutationEngine and other machine-effect consumers (audit/migrate)
  │
  │  each calls verify_council_presentation(grant, effect_id)
  │    - issuer == :council
  │    - registry grant_digest == canonical_machine_grant_digest(grant)
  │    - registry decision_digest == grant.council_decision_ref
  │    - registry decision_type == grant.decision_type == operation
  │    - registry scope matches entity/effect descriptor
  │    - registry effect_id == grant.effect_id == presented effect
  │    - record status :bound, unexpired, unconsumed
  │    - emergency re-check at effect boundary
  ▼
  │  atomic consume → effect → success audit
```

### Council-chain prohibitions

```text
Authorization.approved/1 struct ──✗──> MachineAuthorization.mint/2
caller-supplied decided_at ──✗──> Council issuance
hash(caller-supplied struct) ──✗──> decision receipt
plain Council.authorize/3 result ──✗──> machine mint
receipt verified only at mint ──✗──> effect-boundary authority
receipt consumed at bind ──✗──> multiple mints
emergency checked only at authorize/3 ──✗──> direct mint bypass
content_hash(struct) == struct.content_hash ──✗──> provenance
```

---

## 4. Current red paths (what the baseline proves)

```text
RL-564 — CURRENT (RED)
──────────────────────
caller
  │  arbitrary ID
  ▼
Authorization.record_mint/1 ──allowlisted stack──> MintRegistry.record_mint/2
  │                                                   │
  │                                                   ▼
  │                                            status :granted
  │                                            {id, ts, nil} only
  ▼
forged %Authorization{} ──> ExecutionGovernance.begin/2 ──> {:ok, ...}   [R564-02]
forged %Authorization{} ──> GovernedEffectSink.execute/3 ──> {:ok, ...} [R564-03]
forged %Authorization{} ──> DeploymentGateway.deploy/5 ──> {:ok, ...}   [R564-04]
mutated human_id/explanation ──> GovernedEffectSink ──> {:ok, ...}      [R564-08a/b]
non-issuer ──> MintRegistry.record_bind/3 ──> :ok                       [R564-07]
```

```text
RL-565 — CURRENT (RED)
──────────────────────
Authorization.approved/1 / manual struct / altered genuine
  │
  ▼
MachineAuthorization.mint/2
  │  permitted?/1 or conditional_grant?/1
  │  decided_at != nil
  │  hash(caller struct)
  ▼
MintRegistry.record_mint/2 ──> status :granted, council_decision_ref = hash(caller struct)
  │
  ▼
MachineAuthorization.bind_effect/2 ──> effect binding
  │
  ▼
UnifiedWorldModel.delete_entity/2
  │  decision_type == :delete_entity
  │  permitted?/1
  │  content_hash(struct) == struct.content_hash   ← self-referential
  │  registry binding == effect_id
  │  consume
  ▼
{:ok, ...} + entity deleted                                          [R565-03]
```

```text
EMERGENCY — CURRENT (RED)
─────────────────────────
Council.invoke_emergency/2
  │
  ├──> Council.authorize/3 ──> rejected decision (blocked)
  │
  └──> MachineAuthorization.mint/2 ──> {:ok, ...}                    [R565-08]
```

### Current-path defects, restated

| Red path | Missing authority check |
|---|---|
| Human wrapper mint | No issuance event, grant digest, identity, explanation, candidate, scope, or record MAC |
| Human consumer admission | Trusts struct fields + registry status + weakly matching identity; no registry-anchored grant digest |
| Human binding | No caller/issuer authentication |
| Machine mint | No Council receipt; hash of caller struct is mistaken for provenance |
| Machine bind | No registry decision/scope check beyond the carried ref |
| UWM delete | No Council receipt; self-hash is not provenance; no registry decision-ref comparison |
| Emergency | Only `Council.authorize/3` is gated; direct mint and effect boundary are not |

---

## 5. Prohibited cross-links

These are the shortcuts that would collapse the two trust roots. Each is a design violation even if the CP19.18 red tests turn green.

| Prohibited shortcut | Why it is prohibited |
|---|---|
| `verify_any(proof)` / `verify_authorization(grant)` that accepts both `:human` and `:council` records | Erases the distinction between human approval and Council decision; either issuer could satisfy the other's effects |
| Reusing `IssuanceProof` for Council decisions | A human-issued token would become machine authority |
| Reusing `DecisionReceipt` for human grants | A Council receipt would become human approval |
| A registry record without an `issuer` tag | Verification cannot dispatch to the correct trust root |
| Accepting `MintRegistry.status(id) == :granted` as sufficient | Status is a consequence of issuance, not proof of the correct issuer/scope |
| A caller-selected ID + any allowlisted module | Stack origin is not issuance |
| `Authorization.approved/1` + `decided_at` as machine proof | Public constructor + timestamp is not Council issuance |
| Hashing the presented struct as the authority anchor | Proves self-consistency, not issuer provenance |
| Comparing `content_hash(grant)` to `grant.content_hash` | Both derive from the same mutable struct |
| Auto-binding an unbound grant at first consumer | Moves binding authority to the consumer/caller |
| Binding by authorization ID alone | Knowledge of an ID is not authority |
| One Council decision → many grants | The decision is a one-time authority event |
| One human issuance → many grants | The human approved one explanation/scope |
| Emergency checked only at `Council.authorize/3` | Direct mint and pre-existing grants bypass it |
| Emergency checked only at mint | A grant minted before the emergency still executes |
| Verifying a receipt only at mint | Post-bind substitution reaches the effect |
| Broad error lists in closure tests | A failure for the wrong reason can masquerade as a refusal |
| Treating a green broad oracle as closure | The oracle may not assert the security property |
| Closing `F-ARC-018` from per-run DETS partitions | Repository-root persistence and store-map ownership remain open |

---

## 6. Effect-boundary matrix

| Consumer | Current authority check | Required human proof (RL-564) | Required Council proof (RL-565) | Refusal point |
|---|---|---|---|---|
| `Phase4.ExecutionGovernance.begin/2` | Struct status, registry status, descriptor, bind-or-verify, registry binding, ETS claim, consume | `verify_human_presentation`; bound grant; no auto-bind | Not a Council consumer | Before bind/claim/consume |
| `Omega.GovernedEffectSink.execute/3` | Struct status, registry status, weak identity, binding, descriptor, registry binding, consume, sink, audit | `verify_human_presentation`; verified identity; explanation digest | Not a Council consumer | Before sink/audit/consume |
| `Omega.DeploymentGateway.deploy/5` | Candidate/certification/lineage, grant match/expiry, weak identity, candidate hash from grant, registry status/binding, consume, transition, audit | `verify_human_presentation`; registry candidate hash/scope | Not a Council consumer | Before transition/deployment record/audit |
| `World.UnifiedWorldModel.delete_entity/2` | Struct/registry status, decision type, public predicates, self-hash, effect, registry binding, executed set, consume, delete, audit | Not a human consumer | `verify_council_presentation`; registry grant/decision digest, scope, effect, receipt consumption, emergency | Before consume/delete/audit |
| `World.WorldMutationEngine` | Council decision use (per CP19.17; not covered by CP19.18) | N/A | Audit and migrate to `verify_council_presentation` or scope out with governance approval | Before mutation |
| `Phase4.RealExecution` / `PhysicsPilot` | Human grant admission (per CP19.17; R564-05 not implemented) | Audit and migrate; cover R564-05 | N/A | Before backend/harness |
| `Omega.Verification.Baseline` mint helper | Allowlisted mint source (per CP19.17) | Audit and migrate or remove | Audit and migrate or remove | Before registry write |

The matrix is not a claim that every dynamic/plugin caller is covered. It is the concrete source-consumer set identified by CP19.17 and the CP19.18 tests.

---

## 7. Registry record separation

Use one storage mechanism with a tagged record schema, not one authority decision.

```text
MintRegistry record
├── issuer: :human
│   ├── issuance_id / proof_hash
│   ├── grant_digest
│   ├── identity_id / identity_digest
│   ├── human_id
│   ├── explanation_id / explanation_digest
│   ├── candidate_content_hash / scope_digest
│   └── effect_id / status / record_mac
│
└── issuer: :council
    ├── receipt_id / receipt_digest
    ├── decision_digest
    ├── grant_digest
    ├── decision_type
    ├── scope_digest
    ├── actor / issuer_id / issuer_version
    ├── policy_version / constitution_version
    └── effect_id / status / record_mac
```

Verifier dispatch:

```text
verify_human_presentation/3
  └── requires issuer == :human
      └── rejects :council records with :authorization_provenance_invalid

verify_council_presentation/2
  └── requires issuer == :council
      └── rejects :human records with :authorization_provenance_invalid
```

There is no fallback from one verifier to the other.

---

## 8. State and transition model

```text
HUMAN RECORD
  :granted ──bind(proof)──> :bound ──consume──> :consumed
      │                       │
      └──expire───────────────┴──> :expired
      └──revoke──────────────────> :revoked

COUNCIL RECORD
  :granted ──bind(scope)──> :bound ──consume──> :consumed
      │                       │
      └──expire───────────────┴──> :expired
      └──revoke──────────────────> :revoked

RECEIPT
  issued ──mint(atomic)──> consumed
      │
      └──expire──> expired
```

A consumed receipt cannot mint again. A consumed grant cannot effect again. A bound grant cannot rebind. A revoked/expired grant cannot be consumed.

---

## 9. Verification checklist for independent review

A reviewer should be able to answer "yes" to all of the following from public APIs and durable state, not from implementation predicates alone:

1. Can any public function create a human `:granted` record from an ID alone? **Must be no.**
2. Can any public function mint a machine grant from a plain `%Council.Authorization{}`? **Must be no.**
3. Does human issuance return a one-time proof bound to the exact grant and scope? **Must be yes.**
4. Does Council issuance return a one-time receipt bound to the exact decision and scope? **Must be yes.**
5. Does every human consumer compare the presented grant to the registry-anchored grant digest, human, identity, explanation, candidate/scope, and effect? **Must be yes.**
6. Does every machine consumer compare the presented grant to the registry-anchored grant digest, decision digest/ref, type, scope, and effect? **Must be yes.**
7. Does a post-bind mutation fail before consume and before the effect? **Must be yes.**
8. Can one receipt mint more than one grant? **Must be no.**
9. Can one human issuance produce more than one valid grant? **Must be no.**
10. Does emergency block Council decide, machine mint, and effect-boundary consume? **Must be yes.**
11. Does a forged/truncated/tampered registry record fail closed after restart? **Must be yes.**
12. Are the closure tests specific about errors and postconditions, with no broad lists or any-error matches? **Must be yes.**
13. Are the human and Council verifiers separate, with no cross-issuer fallback? **Must be yes.**
14. Is `F-ARC-018` still tracked separately rather than claimed closed by this work? **Must be yes.**

A "no" or an "unknown" is a no-go for closure.
