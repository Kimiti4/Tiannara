# Observatory Event Taxonomy

## Domain Classification

Every event in the Observatory is classified under exactly one domain.
Domains are hierarchical: `category/subcategory`.

### Domain Tree

```
runtime/
  health          — Runtime process health, uptime, resource usage
  discovery       — Discovery cycle events (start, progress, completion, failure)
  challenge       — Challenge lifecycle (created, activated, completed, expired)
  experiment      — Experiment execution events (started, result, aborted)
  hypothesis      — Hypothesis lifecycle (formulated, tested, confirmed, refuted)
  checkpoint      — CPL checkpoint events
  generation      — Generation lifecycle (created, evolved, archived)

scientific/
  observation     — Observational data events from experiments
  measurement     — Quantified experimental results
  analysis        — Analysis pipeline events (started, completed, finding)
  peer_review     — Peer review lifecycle (submitted, reviewed, decision)
  replication     — Replication attempts (planned, executed, result)

engineering/
  design          — System design events (proposed, reviewed, implemented)
  optimization    — Optimization events (parameter_tuned, performance_gain)
  deployment      — Deployment events (staged, rolled_out, rolled_back)
  integration     — Integration test events
  trl             — TRL assessment events (level_assigned, level_changed)

knowledge/
  concept         — Concept lifecycle (identified, defined, refined, retired)
  theory          — Theory lifecycle (formulated, evidenced, accepted, refuted)
  relationship    — Relationship mapping between concepts
  literature      — External knowledge ingestion

governance/
  policy          — Policy lifecycle (created, enforced, violated, amended)
  drift           — Constitutional drift measurements
  compliance      — Compliance check events (passed, failed, waived)
  constitution    — Constitution version events (amended, superseded)

planetary/
  earth_model     — Earth system model events (updated, forecast, anomaly)
  environmental   — Environmental metric events
  resource        — Resource monitoring events

civilization/
  innovation      — Innovation index events
  kardashev       — Kardashev scale assessment events
  societal        — Societal impact events

evolution/
  self_modification — Self-modification events (proposed, approved, executed)
  generation_gene   — Generation-level genetic events
  adaptation        — Adaptation events

certification/
  status          — Certification status changes
  invalidation    — Certification invalidation events
  audit           — Certification audit events

security/
  auth            — Authentication events (login, logout, failure)
  access          — Authorization events (granted, denied, escalated)
  audit           — Security audit events

infrastructure/
  node            — Node lifecycle (joined, left, failed, recovered)
  network         — Network events (latency_change, partition, healed)
  storage         — Storage events (usage_threshold, archival, corruption_detected)

research/
  campaign        — Campaign lifecycle (proposed, funded, active, concluded)
  finding         — Research finding publication events
  review          — Research review events

economics/
  compute_cost    — Compute resource cost events
  storage_cost    — Storage cost events
  efficiency      — Efficiency metric events

simulation/
  run             — Simulation run events (started, progress, completed)
  parameter       — Simulation parameter change events
  result          — Simulation result events

experiment/
  design          — Experiment design events
  execution       — Experiment execution events
  result          — Experiment result events

operator/
  action          — Operator action events (viewed, configured, intervened)
  decision        — Operator decision events
  note            — Operator annotation events

audit/
  review          — Audit review events
  finding         — Audit finding events
  recommendation — Audit recommendation events

replay/
  session         — Replay session lifecycle (started, completed, cancelled)
  check           — Replay consistency check events (matched, diverged)
  export          — Replay export events

alert/
  triggered       — Alert triggered events
  acknowledged    — Alert acknowledged events
  resolved        — Alert resolved events
  escalated       — Alert escalation events

prediction/
  forecast        — Prediction events (generated, updated)
  verification    — Prediction verification events
  accuracy        — Prediction accuracy events
```

## Taxonomy Rules

| Rule | Description |
|------|-------------|
| **Uniqueness** | Every event maps to exactly one leaf domain. No ambiguous classification. |
| **Extensibility** | New subcategories may be added without changing the parent contract. |
| **Backward Compatibility** | Adding a new subcategory never changes the schema of existing subcategories. |
| **Deprecation** | Domains may be deprecated but never removed. Deprecated events still replay correctly. |
| **Future-Proofing** | New systems (Planetary Observatory, Civilizational Observatory) add domains under their own top-level category. They do not need to invent new taxonomies from scratch. |
