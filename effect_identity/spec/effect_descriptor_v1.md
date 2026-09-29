# Universal Effect Identity v1 — UAG-2F implementation contract

Status: BOUNDED IDENTITY SUBSTRATE IMPLEMENTED; CROSS-RUNTIME CONFORMANCE IN PROGRESS; ADMISSION REMAINS DISABLED.

## Semantic descriptor

The semantic descriptor is exactly:

- effect_schema_version
- principal
- authority
- authorization_scope
- operation
- target
- parameters
- intent
- environment_scope
- authority_epoch
- policy_version

Lifecycle/correlation fields are excluded from identity: request_id, correlation_id,
mission_id, execution_id, deployment_id, mutation_id, attempt, retry_count,
worker_id, process_id, timestamps, result/audit IDs, and random nonces.

## Canonical pipeline

D -> semantic validation/normalization -> canonical UTF-8 JSON -> SHA-256.

Digest input:

UTF8("tiannara-effect-v1") || 0x00 || canonical_bytes

Objects use UTF-8 string keys sorted by UTF-8 byte order. Arrays preserve order.
null is explicit. Unsupported runtime-specific values hard-fail.

## Cross-runtime scalar contract

Native floating-point values are rejected in v1 because native JSON/JavaScript
number models do not preserve the required distinction between integer and
decimal representations.

Where decimal semantics are required, parameters use an explicit semantic wrapper:

{"$number":"int:1"}
{"$number":"decimal:1.0"}

The token grammar is strict and does not accept NaN, Infinity, leading-zero
integers, or malformed decimal forms. Therefore 1 and 1.0 remain distinct
semantic values unless a future schema explicitly declares them equivalent.

## Collection contract

Ordered sequences remain ordinary JSON arrays and preserve order.

Set and multiset semantics use explicit wrappers:

{"$collection":"set","items":[...]}
{"$collection":"multiset","items":[...]}

Set items are canonicalized, sorted by canonical bytes, and deduplicated.
Multiset items are canonicalized and sorted while preserving multiplicity.

Ordinary JSON objects remain maps and are key-order invariant.

## Lifecycle separation

Changing request_id, correlation_id, execution_id, deployment_id, mutation_id,
attempt, worker/process metadata, or timestamps MUST NOT change EffectID.

Changing any semantic descriptor component normally MUST change EffectID.

## Scope

This module does NOT authorize, bind, admit, deploy, mutate, or execute effects.

Current UAG-2F gates:

1. frozen 117-vector fixture corpus
2. independent Python/Rust/TypeScript renderers
3. byte/digest parity
4. adversarial semantic coverage
5. recovery/reconstruction proof
6. retry/idempotency proof
7. EffectBinding proof
8. 28-sink admission conformance

Any mismatch is a hard stop; fixtures must not be changed to accommodate an
implementation mismatch.
