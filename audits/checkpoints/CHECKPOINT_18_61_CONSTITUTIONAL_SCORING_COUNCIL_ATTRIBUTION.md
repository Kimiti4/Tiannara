### Checkpoint 18.61 — constitutional scoring, health reconciliation, Council authority, and attribution

**Audit boundary:** frozen source commit `68d27377d60e17543bc0ec4901a9ee141852a0e0` in `Kimiti4/Tiannara`. Source inspection only. No source code was modified. No Mix compilation, runtime execution, test suite, fault injection, or authorization integration test was run. Targeted GitHub code search was used for caller discovery; search-index absence is not treated as proof of global absence.

#### 18.61.1 — ConstitutionalScorePipeline is not an evidence-backed certification source

Inspected `lib/tiannara/cel/services/constitutional_score_pipeline.ex`:

- `health/0` always returns `:healthy`.
- `constitutional_score/0` returns hard-coded values (health/alignment/transparency/explainability 1.0, evidence quality 0.95, human oversight 0.6); it does not read the observation window.
- `record_observation/2` is an asynchronous cast. The in-memory window retains at most 100 observations per service, with no durable store or explicit eviction/expiry based on age.
- Constitutional telemetry uses defaults of 0.5 for absent alignment/transparency/evidence-quality metadata. Other attached telemetry events are converted to the same generic 0.5 observation, regardless of their actual semantics.
- Empty windows return a plausible score with health 1.0 and other components 0.5. Aggregated windows also hard-code health 1.0 and human oversight 0.6; explainability is inferred from alignment rather than independently observed.
- No validation of score types/ranges, evidence identity, source provenance, or observation freshness is visible in this module.
- The kernel's boot path invokes each service's registered `constitutional_score_check`; for this service that callback is the hard-coded `constitutional_score/0`, not the telemetry aggregation API. The two paths are therefore not joined for this service's boot certification.

**RL-396 OPEN — ConstitutionalScorePipeline self-certifies from hard-coded values rather than its own observed evidence.** The telemetry window does not feed the service's registered constitutional-score callback, so boot certification can consume the hard-coded score independently of the pipeline's observations.

**RL-397 OPEN — Missing and semantically unrelated telemetry is converted into plausible scores.** Missing score metadata defaults to 0.5, and non-constitutional events receive generic 0.5 dimensions. Unknown, malformed, or non-applicable evidence is not preserved as unavailable.

**RL-398 OPEN — Score observations lack demonstrated freshness, provenance, validation, persistence, and process-death invalidation.** A bounded count window is not a time bound; the inspected aggregation can include arbitrarily old observations until displaced. Recomputing `computed_at` does not refresh the underlying evidence.

#### 18.61.2 — ExecutiveStateManager can report completion without durable side effects

Inspected `lib/tiannara/cel/services/executive_state_manager.ex`:

- The periodic `:generate_snapshot` handler calls `EventBus.publish/2` and `ExecutiveMemory.record_event/3` but discards both return values.
- It then advances `current_snapshot`, increments `snapshots_generated`, and updates `last_snapshot_at` regardless of those results.
- The `force_snapshot` path also increments its counter and updates the timestamp after `build_snapshot/1` without establishing successful publication or persistence.
- Several source-query helpers rescue failures into empty maps, zero counts, `:unknown`, or empty lists. Examples include service health, resource allocation, scheduler, mission/workflow state, and capability statistics.
- `calculate_snapshot_confidence/1` only checks whether three selected service-health keys exist. It does not measure successful collection coverage across all snapshot inputs or distinguish unavailable data from genuine zero/empty observations.

**RL-399 OPEN — ExecutiveStateManager advances snapshot state when publication or memory recording fails.** Local snapshot counters/timestamps can claim completion without confirmed EventBus publication or ExecutiveMemory persistence.

**RL-400 OPEN — Executive-state confidence can conceal unavailable and incomplete source observations.** Rescue defaults and a three-key presence check permit incomplete snapshots to receive confidence values that do not represent actual collection coverage.

#### 18.61.3 — ConstitutionalMonitor defaults to perfect health when it has no evidence

Inspected `lib/tiannara/council/constitutional_monitor.ex`:

- The monitor starts with an empty `service_scores` map and `last_report: nil`.
- Its empty-input branch reports `aggregate_constitutional_score: 1.0` while `services_monitored: 0`.
- For each reported service, absent alignment, transparency, explainability, evidence-quality, and human-oversight fields default to 1.0.
- `report_score/2` stamps the current time, but no age-based expiry, source timestamp validation, service inventory reconciliation, or stale-score invalidation is implemented in the inspected module.
- The aggregate uses only constitutional alignment; the other reported dimensions do not affect that aggregate.
- Targeted caller searches did not establish a direct connection from `ConstitutionalScorePipeline.record_observation/2` or `all_scores/0` into `ConstitutionalMonitor.report_score/2`. This is an integration gap not yet proven globally absent; broader call-graph/runtime verification remains required.
- `ExecutiveStateManager.get_constitutional_status/0` maps an unavailable/other monitor result to `:compliant` through its catch-all branch, rather than preserving unknown.

**RL-401 OPEN — ConstitutionalMonitor can report a perfect aggregate with zero monitored services or incomplete score fields.** Empty or missing evidence is treated as full compliance, and stale score invalidation is not established. This can flow into ExecutiveStateManager's `:compliant` fallback when the monitor report is unavailable.

#### 18.61.4 — Kernel lifecycle authorization does not preserve the requesting actor

Inspected `lib/tiannara/cel/kernel.ex`, `lib/tiannara/council/council.ex`, `lib/tiannara/council/execution_context.ex`, and `lib/tiannara/council/rule_engine.ex`:

- `Kernel.restart_service/2` accepts an `actor`, but the handler calls `Council.authorize(:architectural_change, %{action: :restart, service: id}, nil)`. The actor is absent from both the authorization payload and execution context.
- `Kernel.halt/2` includes actor in its payload but still supplies `nil` as the Council execution context. No typed `ExecutionContext` carrying the actor, intent, correlation ID, evidence, and parent lineage is created at this boundary.
- The RuleEngine's accountability assessment reads `payload.actor`; the restart payload therefore scores accountability using its missing-actor fallback.
- Council's authorization API accepts an optional ExecutionContext. The execution-context type explicitly has an actor and correlation ID, but the inspected kernel lifecycle calls do not supply one.

**RL-402 OPEN — Kernel restart authorization drops the caller identity before Council evaluation.** The actor parameter is unused in the restart authorization request; the Council cannot attribute that authorization to the caller from the supplied payload/context. Halt carries actor only as an untyped payload field, not as a structured execution principal/context.

#### 18.61.5 — Council decisions and lifecycle effects lack a proven mandatory audit transaction

- In `Council.handle_call({:authorize, ...})`, normal decisions are evaluated and returned without a general append of the resulting authorization decision to `Council.AuditLog`. The inspected path logs selected exceptional events (for example emergency blocks and hard-invariant overrides), not every approval, conditional grant, deferral, or rejection.
- Kernel lifecycle success logging uses `log_to_council/2`, which catches all failures and returns `:ok`; its caller proceeds regardless of whether the audit append succeeded.
- The kernel audit helper records actor as the fixed value `:kernel`. For restart, the passed actor has already been discarded; for halt, actor appears only in payload.
- These source paths do not establish an atomic or otherwise mandatory link among authorization request, evaluated decision, actor/principal, conditions/evidence, effect execution, and durable audit record. No runtime failure was injected.

**RL-403 OPEN — Ordinary Council authorization outcomes are not mandatorily appended to the audit log in the inspected authorization handler.** The returned authorization object is not itself proof of a durable decision record; normal approvals and denials lack a demonstrated universal append at the decision boundary.

**RL-404 OPEN — Kernel lifecycle actions can proceed when their post-action audit append fails.** `log_to_council/2` suppresses append failures, and lifecycle handlers do not require confirmed durable audit evidence before acknowledging the effect. Actor attribution is further weakened by the fixed `:kernel` audit actor.

#### 18.61.6 — Disposition and next checkpoint

- New findings RL-396 through RL-404: **OPEN**.
- RL-393 through RL-395 and earlier findings remain OPEN; no findings were closed.
- No source code changes. No runtime/build/test/fault-injection validation was performed.
- Search-index non-results are treated as incomplete discovery evidence, not proof of global absence.

**Required remediation direction:** preserve unknown/stale/missing evidence as explicit non-certifying states; compute scores from validated, provenance-bearing observations; reconcile every registered and discovered service against live process and health state; make Council authorization carry a structured principal/context and correlation lineage; require durable decision/effect audit records or fail closed; and test all failure paths including monitor silence, telemetry loss, stale scores, process death, audit-store degradation, and partial snapshot writes.

**Next checkpoint 18.62:** trace the complete Council decision lifecycle from policy/rule evaluation through human approval, conditional-grant satisfaction, authorization consumption, execution, and audit persistence. Inspect emergency invocation/lifting authority and actor attribution; determine whether any caller can bypass Council or replay/forge a grant; trace whether authorization records are bound to exact effect payloads, expiry, nonce/idempotency, and correlation context. Continue the security and human-final-authority audit without treating policy documentation or an Authorization struct as proof of enforcement.
