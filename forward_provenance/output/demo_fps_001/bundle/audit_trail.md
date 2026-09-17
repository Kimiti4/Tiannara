# Independent Evidence Bundle — audit trail

bundle_name: IndependentEvidenceBundle

## 1. What was run
experiment: fps_001_forward_entropy_stability
execution_id: exec_1788900784743_06975c02-bcce
campaign: fp_demo_2026_09_08

## 2. Against what source
source identity: see identity_objects/source.json
  (repository commit + tree + source manifest hash)

## 3. With what contract
contract: see contracts/contract.bytes
  (contract hash bound in the execution envelope)

## 4. With what inputs
seed: 42
raw measurements: measurements/raw_corpus.json
  (corpus sha256 recorded in metrics/metric_computed.json)

## 5. Using what environment
environment: see identity_objects/environment.json
  (otp/elixir/deps_lock_hash — byte-exact execution environment)

## Derived metric
metric id: 22f199d6881e93b1dab4db9de7a0d488a2bf3a6b9b21dfc0835a60b7a095236e
mean: 0.500921  std_dev: 0.029287

## Decision
certificate_id: cert_0daeaecb0a5a4b8c1916831c4b8c81d8
decision: certified
authority: independent_verifier_v1

## Recomposition protocol
Every file in this bundle is referenced from bundle_manifest.json with its
sha256 computed under spec/canonicalization_spec.yaml (canon v1). An
independent verifier recomputes every identity from these bytes alone.
