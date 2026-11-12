# CP19.20 — RL-565 Council Decision-Provenance and Machine-Authorization Remediation

**Disposition (expected):** `IMPLEMENTED_WITH_PARTIAL_EVIDENCE` — RL-565 remains pending independent review. RL-564 and `F-ARC-018` remain `OPEN`.

**Base:** `local/pr4` @ `60933859f529db68863d6610ff5cf3901f722eb6`; implementation worktree `feat/cp19-20-rl565-council-provenance`; baseline commit `ac39083923e1352eed430d1d880cb6affb8adbf2`.

**Governing spec:** `certification/audits/CP19_19_RL565_REMEDIATION_SPECIFICATION.md` (invariants R565-I01..I12, acceptance criteria AC-01..AC-14).

## 1. What was implemented

### WP1 — Council `DecisionReceipt` (new trust root)
- `lib/tiannara/council/decision_digest.ex` — canonical versioned digests (decision, scope, receipt, machine grant). Encoder version pinned.
- `lib/tiannara/council/decision_receipt.ex` — `@enforce_keys` struct per spec; MAC signing restricted to the registered Council process (`sign/1`); `sign_test/1` gated by `config :tiannara, :allow_test_receipt_signing` (test-only); constant-time MAC verification; issuer identity `tiannara.council/v1`.
- `lib/tiannara/council/emergency_state.ex` — authoritative snapshot published to `:persistent_term` with monotonic epoch; read by mint/registry/UWM to avoid a Council↔registry cycle.

### WP2 — `Council.decide/3`
- Added `Council.decide/3` returning `{:ok, decision, receipt}` for approving/conditional decisions, `{:ok, decision, nil}` otherwise, `{:error, reason}` on refusal.
- Exact scope validation: payload `:scope` must be `%{operation:, target:}` with non-empty target; `payload[:target] == scope.target`; scope operation matches `payload[:mutation_type]` or decision type. Broad scopes refused `:invalid_scope`.
- Policy version and constitution version bound into every receipt.
- Emergency enforced at issuance: non-emergency-allowed types refused `:council_emergency_active`.
- Durable `MintRegistry.record_receipt/1` on issuance.

### WP3 — Atomic mint/consumption
- `MachineAuthorization.mint/2` now **fail-closed**: always `{:error, :council_decision_proof_required}`.
- `MachineAuthorization.mint/3` verifies receipt MAC, issuer, decision digest, type, scope, policy, constitution, expiry, emergency, and one-time receipt status, then atomically issues via `MintRegistry.issue_machine/3` (single durable append consuming the receipt).
- `MintRegistry` rewritten as v2: `{:tiannara_mint_registry, 2, seq, event, mac}` with HMAC-SHA256 integrity; strict loader; gap-free sequence; duplicate/sequence/receipt/grant validation; `record_receipt`, `receipt_status`, `issue_machine`, `bind_machine`, `verify_council_presentation`, `reload`, `path`.

### WP4 — UWM effect-boundary provenance
- Delete path now calls `MintRegistry.verify_council_presentation/3` (registry-anchored grant/decision/type/scope/effect), not a self-recomputed struct hash.
- Emergency enforced via verifier and `MachineAuthorization`/registry.
- `:registry_corrupt` fail-closed clauses added to `check_status` and consume.

### WP5 — Emergency at all three boundaries
- Enforced independently at Council decision issuance, machine mint, and UWM effect execution (and bind).

### WP6 — Persistence/tamper/restart
- Strict v2 loader: truncated tail, bad term, MAC failure, sequence gap, duplicate authorization/receipt, machine grant without receipt, receipt consumed twice, bind/consume unknown/terminal, machine bind without grant digest → whole registry corrupt; no prefix promotion.
- `MintRegistry.reload/0` re-reads strict loader without disrupting the supervisor.
- Legacy v1 records treated as corrupt (fail closed); writer emits only v2.

### Human trust root (RL-564) isolation
- `HumanDelivery.Authorization`, `ExecutionGovernance`, `GovernedEffectSink`, `DeploymentGateway` unchanged except explicit `:registry_corrupt` fail-closed clauses. No shared verifier. `MintRegistry.record_bind/3` refuses machine records with `:authorization_provenance_invalid`.

### Configuration
- `config/test.exs`: per-run `:council_receipt_key`, `:mint_registry_integrity_key` (random 32 bytes), `:allow_test_receipt_signing, true`. Production provisioning is a deployment requirement.

## 2. Files changed
See git diff on branch `feat/cp19-20-rl565-council-provenance`. New: `decision_digest.ex`, `decision_receipt.ex`, `emergency_state.ex`, `test/support/authority_fixtures.ex`. Rewritten: `council.ex`, `machine_authorization.ex`, `mint_registry.ex`. Migrated: `world_mutation_engine.ex`, `unified_world_model.ex`, `phase3_test_helpers.ex`, and affected tests.

## 3. Consumer classification
See `CP19_20_RL565_CONSUMER_CLOSURE_MATRIX.md`. Machine-authority consumers closed: `WorldMutationEngine`, `UnifiedWorldModel.delete_entity/2`. Direct `Council.authorize/3` callers (`CEL.Kernel`, `ResourceManager`, `ExperimentOrchestrator`, `Forecasting.Adapters.DecisionImpl`) remain unresolved direct decision consumers and are disclosed; they do not mint machine grants today.

## 4. Test results
- `rl565_council_decision_provenance_adversarial_test.exs`: 19 tests, 0 failures at seeds 0 and 123456.
- Migrated UWM/D127 suites: 34 tests, 0 failures.
- `rl564_registry_issuance_adversarial_test.exs`: remains red baseline (RL-564 out of scope).

## 5. Disposition
`IMPLEMENTED_WITH_PARTIAL_EVIDENCE`. RL-565 pending independent review. No push/merge/deployment/closure performed.
