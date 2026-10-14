# Stage 6 — Recursive Civilization Evolution: SIMULATION HARNESS

> **Evidence status: SIMULATION ONLY — NOT A REAL-ENGINE CERTIFICATION**
>
> The current `TiannaraOS.RecursiveCivilizationRunner` is a simulation harness. It generates synthetic episodes, simulated theories and validation outcomes, and simulated Stage 3–5 results. Those results do **not** establish that the production research engines were invoked, that real experiments occurred, or that Tiannara improved scientifically.
>
> Additional limitations in the current path:
> - `GenerationHistory.calculate_cai/1` computes a composite metric, but from largely synthetic harness inputs, so its outputs are not evidence of real improvement.
> - CSV history is written to disk, but durability across process/container interruption is not established.
> - The runner's `apply_pending_adaptations/1` currently returns the state unchanged; it does not apply adaptations to system behavior.
> - Several metrics are constants, simplified calculations, or random values (including resource utilization, prediction/replication indicators, rollback frequency, and constitutional/lifecycle counts).
> - Generated reports summarize harness output. They are not independent evidence of constitutional compliance, empirical prediction quality, provenance completeness, or self-improvement.
>
> The real Stage 3–5 engine modules may exist, but this runner does not call them. Their existence alone does not demonstrate integration. No results in this document should be treated as production measurements or certification evidence.

**Status:** SIMULATION HARNESS ONLY  
**Historical document date:** June 30, 2026  
**Purpose:** Exercise a multi-generation simulation path and expose integration requirements for future validation.

---

## What the harness currently does

The runner accepts a generation count and options, loops over generations, creates synthetic episodes, derives simulated theory/validation counts, generates synthetic Stage 3–5 results when adaptation is enabled, constructs history records, and attempts checkpoint/report output.

This demonstrates that the harness path can be exercised. It does **not** demonstrate that the full research civilization executes through real engines or that recursive adaptation improves scientific performance.

## Important implementation boundaries

| Area | Current behavior | Evidence status |
|---|---|---|
| Episode generation | Synthetic, randomized episode records | SIMULATED |
| Theory formation | Calculated from synthetic episode attributes and random variation | SIMULATED |
| Distributed validation | Synthetic counts based on episode uncertainty and random variation | SIMULATED |
| Stage 3 — Method Evolution | Randomized placeholder results; real engine is not invoked | SIMULATED / NOT INTEGRATED |
| Stage 4 — Institution Adaptation | Randomized placeholder results; real engine is not invoked | SIMULATED / NOT INTEGRATED |
| Stage 5 — Civilization Adaptation | Decision and transferability fields derived from simulated Stage 4 results | SIMULATED / NOT INTEGRATED |
| Adaptation application | `apply_pending_adaptations/1` returns state unchanged | NOT IMPLEMENTED |
| Civilization Adaptation Index | `GenerationHistory.calculate_cai/1` computes a composite metric from mostly synthetic inputs | COMPUTED; not real-improvement evidence |
| History persistence | CSV append writes to disk; durability across interruption is not established | WRITTEN; durability NOT VERIFIED |
| Constitutional provenance | History rows carry `manifest_id`/`certificate_id`; run manifest + per-generation attestations persisted with honest `:not_verified` statuses | LINKAGE IMPLEMENTED; still harness-only evidence |
| Checkpoints | JSON checkpoint output is attempted by the runner | HARNESS OUTPUT; not independent certification |
| Constitutional/lifecycle metrics | Some values are fixed in the harness | SYNTHETIC; not compliance evidence |

## Provenance correction (Phase 13.5B.3)

An earlier version of this harness could not establish durable provenance for history rows: the runner computed six hashes (`policy_version`, `policy_hash`, `definition_hash`, `ledger_hash`, `invariant_registry_hash`, `constitution_hash`) and passed them to `GenerationHistory.new/1`, which discards fields outside its struct, and neither `manifest_id` nor `certificate_id` was ever passed.

The runner now:

- builds a `ConstitutionManifest` from live system state at run start (canonical `ConstitutionSerializer` component hashes) and persists it as `constitution_manifest.json` in the output directory;
- generates a per-generation `ConstitutionCertificate` bound to that manifest and records its id on each history row and in the append-only `constitution_attestations.jsonl`;
- records certificate statuses honestly (`validation_status: :harness_simulated`, `replay_status: :not_verified`, `watchdog_status: :not_run`, `invariant_status: :not_verified`), so `certification_level` resolves to `"minimal"` — the linkage is a reference, not a certification claim;
- carries both ids in the durable CSV export.

This correction establishes resolvable provenance linkage for harness output only. It does not satisfy gate item 6 (read-back after interruption, independent hash verification against canonical artifacts) and must not be read as Stage 6 certification or scientific-capital certification. Regression coverage: `test/tiannara/os/recursive_civilization_runner_test.exs`.

## Historical numbers: not certified

Older versions of this document reported figures such as 100 generations, 20,000 episodes, 1,000 discoveries, CAI 86.13, 307.69% scientific-capital growth, 100% prediction reliability, zero constitutional violations, and 100% lifecycle completeness. These are **historical harness outputs, not validated empirical findings**. Their underlying execution evidence is not established here, and the synthetic CAI inputs invalidate using them as proof of real improvement.

Do not use those figures to claim:
- empirical self-improvement or improved scientific reasoning;
- calibrated predictions or validated prediction reliability;
- absence of constitutional violations;
- complete provenance or durable immutable history;
- successful integration of real Stage 3–5 engines;
- readiness to advance phases on the basis of Stage 6 certification.

## Gate for real Stage 6 validation

A future real-engine validation must not be declared complete until all applicable checks are independently evidenced:

1. The runner invokes the actual Stage 3, Stage 4, and Stage 5 engines through documented interfaces.
2. Each stage returns identifiable outputs tied to the input generation and its upstream evidence.
3. Adaptations approved in generation G are applied only in generation G+1, with tests proving no temporal leakage.
4. Metrics are computed from observed, validated outcomes rather than constants, random values, or simulated fixtures.
5. CAI is implemented and independently tested; stubbed values cannot satisfy the gate.
6. History persistence is verified by reading records back after process/container interruption, and provenance hashes are checked against canonical artifacts.
7. Constitutional and lifecycle claims are derived from actual verifier outputs; missing evidence is UNKNOWN, not PASS.
8. Failure, rollback, authorization, and partial-stage execution are tested.
9. A bounded end-to-end run records exact commit, configuration, inputs, outputs, and reproducible test commands.
10. Reports clearly distinguish PASS, FAIL, UNKNOWN, and SIMULATED results.

Until this gate passes, the appropriate status remains **SIMULATION HARNESS ONLY — REAL STAGE 6 VALIDATION NOT ESTABLISHED**.

## Next steps

1. Keep this harness for simulation and test development, with explicit simulation labels.
2. Map the real Stage 3–5 engine contracts and their existing tests before wiring them.
3. Implement the smallest bounded integration path behind the existing governance controls.
4. Validate real outputs and persistence before publishing empirical claims or advancing a certification gate.

**Conclusion:** The current code provides a multi-generation simulation path. It does not yet provide evidence that Tiannara's research civilization measurably improves itself through real recursive adaptation.
