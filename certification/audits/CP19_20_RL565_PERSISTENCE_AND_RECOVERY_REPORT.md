# CP19.20 — RL-565 Persistence and Recovery Report

## Registry format
v2 records: `{:tiannara_mint_registry, 2, seq, event, mac}` where `mac = HMAC-SHA256(key, canonical({tag, version, seq, event}))`. Sequence starts at 1 and must be gap-free. Key from `config :tiannara, :mint_registry_integrity_key` (>= 32 bytes).

## Strict load (fail closed)
`MintRegistry.init/1` and `reload/0` decode the whole file:
- Truncated tail → `:truncated_tail` → registry corrupt.
- Unknown/invalid term → `:invalid_record` / `:invalid_record_term` → corrupt.
- MAC mismatch → `{:record_mac_mismatch, seq}` → corrupt.
- Sequence gap → `{:sequence_gap, expected, seq}` → corrupt.
- Duplicate authorization/receipt → corrupt.
- Machine grant without issued receipt → corrupt.
- Receipt consumed twice or by two grants → corrupt.
- Bind/consume of unknown/terminal grant → corrupt.
- Machine bind without grant digest → corrupt.
- Missing/short integrity key → corrupt (all authority ops return `:registry_corrupt`).
- Legacy v1 records (`{:tiannara_mint_registry, 1, ...}`) → `:invalid_record` → corrupt.

No prefix is promoted: any failure marks the whole registry corrupt; no authority operation succeeds until repair/replacement.

## Atomicity
- Receipt issuance: `Council.decide/3` calls `MintRegistry.record_receipt/1` (single durable append) before returning the receipt.
- Machine mint: `MintRegistry.issue_machine/3` appends one compound record (grant + receipt consumption) in a single `File.write/3 [:append, :sync]`. Partial appends cannot occur because the term is serialized fully before write, and the write is fsynced before it is acknowledged.
- Consumption: `consume/2` appends one consume record with `[:append, :sync]`; status flips only after successful append.
- `reload/0` loads records into `empty_state(path)` so records are not replayed onto already-applied live state.

## Restart
- `MintRegistry.reload/0` re-reads the strict loader without disrupting the supervisor, enabling restart-integrity tests in-process.
- Receipt status, grant status, binding, and consumption state are reconstructed from the durable file.

## Recovery tests (CP19.22)
- `rl565_registry_persistence_recovery_test.exs` (6 tests, 0 failures at seeds 0 and 123456) covers: clean round-trip, truncation, MAC tamper, real sequence gap (records 1 then 3), receipt replay after reload, and restart replay of consumption.
- `rl565_council_decision_provenance_adversarial_test.exs` R565-16/17 verify post-bind substitution and unbound execution refusal.
- `rl565_emergency_durability_interlock_test.exs` (11 tests) covers first boot, corrupt/invalid/missing-after-init fail-closed loads, failed-publish memory invariance, disk reload of active state and epoch, Council.init refusal, and the emergency/effect interlock both directions.

## Emergency (CP19.22)
- Authoritative snapshot persisted to `emergency_state.bin` (atomic temp write + `[:sync]` + rename + best-effort directory fsync) and mirrored in `:persistent_term` with a monotonic epoch.
- `publish/1` persists before updating memory; a failed write returns `{:error, reason}` and leaves memory untouched.
- An `emergency_state.initialized` marker distinguishes first boot from lost state; a missing state file after initialization fails closed.
- Enforced at issuance, mint, bind, and effect execution. Emergency-active mint refused even with a valid pre-issued receipt.
- A `:global.trans` interlock serializes emergency activation/lifting with the protected UWM delete effect, with pre/post-consume emergency checks.

## Conclusion
Persistence and recovery fail closed on all tested tamper/truncation/duplication/gap/replay scenarios. No silent prefix promotion. Emergency state is durable and fail-closed, and emergency activation cannot interleave with a protected effect.
