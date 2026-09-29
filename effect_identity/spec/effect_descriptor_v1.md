# Universal Effect Identity v1 — UAG-2F implementation contract

Status: IMPLEMENTED AS A BOUNDED IDENTITY SUBSTRATE; ADMISSION REMAINS DISABLED.

Semantic fields:
effect_schema_version, principal, authority, authorization_scope, operation,
target, parameters, intent, environment_scope, authority_epoch, policy_version.

Lifecycle/correlation fields are excluded from identity: request_id, correlation_id,
mission_id, execution_id, deployment_id, mutation_id, attempt, retry_count,
worker_id, process_id, timestamps, result/audit IDs, and random nonces.

Pipeline:
D -> validation/normalization -> canonical UTF-8 JSON -> SHA-256.

Digest input:
UTF8("tiannara-effect-v1") || 0x00 || canonical_bytes.

Objects use UTF-8 string keys and stable lexicographic JSON encoding. Arrays
preserve order. null is explicit. Unsupported BEAM terms hard-fail.

This module does NOT authorize, bind, admit, deploy, mutate, or execute effects.

Remaining UAG-2F gates:
1. executable frozen fixture corpus,
2. independent Python/Rust/TypeScript renderers,
3. byte and digest parity,
4. recovery/retry proof,
5. EffectBinding proof,
6. 28-sink admission conformance.

Any mismatch is a hard stop; fixtures must not be changed to accommodate an
implementation mismatch.
