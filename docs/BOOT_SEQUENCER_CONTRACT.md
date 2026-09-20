# Boot Sequencer Contract Decision

Recorded: 2026-09-20 · Decision owner: remediation F-048–F-095 review
Scope: `Tiannara.CEL.Kernel.BootSequencer.boot/5`

## Decision

`boot/5` **is the canonical CEL kernel boot API**, and its optional fifth
argument — an explicit `services` list — is a **first-class, verified entry
point**, not a test-only fixture.

## Rationale

- The F-048–F-095 remediation introduced fail-closed capability and
  constitutional gates at boot. Verifying those gates independently requires
  running the *same* gate pipeline over a *deterministic* service snapshot
  instead of the live `ServiceRegistry` runtime state.
- The optional `services` argument makes that verification a documented, stable
  contract rather than an incidental artifact of the regression fix
  (`e97a7e0a`), consistent with the constitution's emphasis on explicit
  interfaces and replaceability.

## Contract (both forms MUST behave identically on gate semantics)

1. `services \\\\ nil` (default) — platform boot: reads
   `ServiceRegistry.boot_order/0` and boots every registered service.
2. explicit list — boots exactly the given list, in the given order. Callers
   MUST supply a complete, dependency-consistent snapshot of
   `ServiceRegistry.service_spec()` structs. Dependency cascades are still
   derived from each spec's `depends_on`.

Five fail-closed gates run for every service: resource, capability, health,
constitutional-score, and critical-dependency propagation. A dependent of a
failed or degraded **critical** service is recorded as `:skipped` (never
started). Status derivation:

| condition                                    | status      |
| -------------------------------------------- | ----------- |
| any failed critical service                  | `:failed`   |
| no failed critical, any `:degraded`/`:skipped` | `:degraded` |
| otherwise                                    | `:ready`    |

## Replaceability invariant

Any future boot strategy MUST preserve:

- the five-gate fail-closed semantics,
- `:skipped` propagation for dependents of failed/degraded critical services,
- the `:ready` / `:degraded` / `:failed` status derivation,
- the `gate_results` map shape and the failure messages asserted by
  `test/tiannara/cel/kernel/boot_sequencer_remediation_test.exs`.

## Verification status

- `status=ready`, all 31 services pass all gates (boot probe, 2026-09-20).
- `test/tiannara/discovery`: 174 tests, 0 failures.
- `test/tiannara/cel`: 7 tests, 0 failures (incl. remediation gate tests).
- Failure clusters outside these suites are pre-existing on `main`.