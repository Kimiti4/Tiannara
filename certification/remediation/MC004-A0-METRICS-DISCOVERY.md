# MC-004-A0 — Metrics & Discovery

**Gate:** MC-004-A0 (Reconciliation) — **Date:** 2026-08-31 — **Mode:** READ-ONLY

## 1. Physics metrics truthfulness

`Tiannara.Domains.Physics.metrics/0` (physics.ex:37-49):

| Field | Value | Derivation | Truthful? |
|---|---|---|---|
| `active_hypotheses` | 0 | literal | YES |
| `open_experiments` | 0 | literal | YES |
| `discoveries_this_cycle` | 0 | `length(discoveries)` where `discover(%{})` → `{:ok, %{discoveries: []}}` (physics.ex:9) | YES — derived from honest empty discover |
| `knowledge_growth_rate` | 0.0 | literal | YES |
| `evidence_quality_score` | 0.0 | literal | YES |
| `hypotheses_generated` | 0 | literal | YES |
| `experiments_completed` | 0 | literal | YES |
| `metrics_source` | `:state_derived` | self-description (physics.ex:48) | **label is accurate** — all values derive from state, none fabricated |

**Truthful-zero.** No inflated or invented statistics. `discoveries_this_cycle = 0` does NOT imply framed discovery that didn't occur — it reflects an empty discovery result. This is the correct honest behavior.

## 2. Discovery machinery

- `generate_hypotheses/1` → `{:ok, []}` (physics.ex:21-22) — honest empty generation.
- `design_experiments/1` → `{:ok, []}` (physics.ex:24-25) — honest empty design.
- Domain `discover/1` (physics.ex:9) produces `[]` for ANY context — there is no discovery logic at all. Classified HONEST-EMPTY, not fabricated.
- ADE `generate_candidate_experiments/0` hardcodes a gravity/time_dilation spec (autonomous_discovery.ex:65-68) — a **placeholder**, not a real generated discovery; never used (dead path).

## 3. Standing debt: TD-MC001-M5-DOMAINS

- Recorded at MC-001-M, item M5: the domain layer contained fabricated/over-stated metrics across domains.
- This gate's physics scope is clean (truthful zeros). The other **19 canonical domains** are OUT of A0 scope; the debt persists and is tracked (`TD-MC001-M5-DOMAINS`). Full census deferred to a domain-wide gate.
- **Reconciliation note:** because `ResearchDirector.get_all_metrics/0` (research_director.ex:21) returns `%{}` with no registered domains, and ADE is dead, no fabricated domain metric currently flows into autonomous decisions. The isolation, while accidental, is currently protective.

## 4. Metrics-consumer map

| Consumer | Physics.metrics consumed? | Status |
|---|---|---|
| ADE `collect_domain_metrics/0` | would consume via `module.metrics()` (autonomous_discovery.ex:59) | DEAD (no caller) |
| ResearchDirector `get_all_metrics/0` | would aggregate | UNWIRED (empty registry) |
| LiveView dashboards | registry metadata, not domain metrics | metadata-only |
| BottleneckDetector | consumes ADE-collected metrics (autonomous_discovery.ex:17) | DEAD with ADE |

## 5. Verdict

- Physics metrics: **TRUTHFUL** (all zeros, correctly derived).
- Physics discovery: **HONEST-EMPTY** (no fabrication, no capability).
- Domain-wide metrics fabric as a whole: **PERSISTENT DEBT** in 19/20 domains (TD-MC001-M5-DOMAINS), out of A0 scope; to be addressed by a domain-wide gate, not MC-004.
- No discovery result can currently reach autonomy, learning, or decision-making.