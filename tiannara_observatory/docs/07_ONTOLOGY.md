# Observatory Ontology

## Introduction

This document defines every first-class concept in the Observatory domain model.
Each entry specifies the concept's definition, properties, relationships, and constitutional constraints.

---

## 1. Observation

An observation is a raw signal emitted by the Runtime (or another observed system). It has not yet been validated or schematized. Observations are ephemeral — they exist only at the boundary between the observed system and the telemetry pipeline.

**Relationships:** Produced-by Runtime. Consumed-by Telemetry.
**Constitutional constraint:** Observation must never mutate the observed system (Art. I.1).

---

## 2. Metric

A metric is a quantifiable measurement derived from one or more observations. Metrics have units, aggregation rules, and sampling frequencies.

**Relationships:** Derived-from Observations. Aggregated-into Indicators. Stored-in MetricStore.
**Properties:** name, definition, formula, units, sampling_frequency, aggregation, retention, confidence, dependencies, certification_status.

---

## 3. Indicator

An indicator is a composite metric that represents a higher-level property of the observed system. Examples: "Discovery Health Index," "Constitutional Drift," "Innovation Velocity."

**Relationships:** Composed-of Metrics. Visualized-on Widgets. Tracked-by Missions.

---

## 4. Signal

A signal is a time-ordered sequence of metric values. Signals are the primary data type for trend analysis, prediction, and anomaly detection.

**Relationships:** Is-a Metric (over time). Projects-into Trends. Triggers Alerts.

---

## 5. Alert

An alert is a notification triggered when a signal crosses a defined threshold or exhibits anomalous behavior. Alerts have severity, scope, and operator assignment.

**Relationships:** Triggered-by Signals. Addressed-by Operators. Logged-in Audit.
**Properties:** severity (info, warning, critical, constitutional), threshold, current_value, triggered_at.

---

## 6. Event

An event is a structured, versioned, signed record of something that happened. Events are the unit of persistence in the Observatory. Every event satisfies the Data Contract (O0.3).

**Relationships:** Stored-in EventStore. Replayed-by Replay. Aggregated-into Metrics.

---

## 7. State

State is a point-in-time snapshot of the Observatory's understanding of a domain. State is maintained in ETS tables and periodically persisted to PostgreSQL.

**Relationships:** Derived-from Events. Snapshotted-as Snapshots. Reconstructed-by Replay.
**Properties:** domain, timestamp, generation, checksum.

---

## 8. Snapshot

A snapshot is a persisted copy of state at a specific checkpoint. Snapshots enable fast replay without replaying the entire event stream.

**Relationships:** Is-a State (persisted). Created-by SnapshotScheduler. Used-by Replay.
**Properties:** snapshot_id, checkpoint_id, domain, timestamp, data, checksum.

---

## 9. Replay

Replay is the deterministic reconstruction of state at a given historical timestamp. It is the mechanism for auditing, archaeology, and verification.

**Relationships:** Reads EventStore. Reads Snapshots. Produces State.
**Constitutional constraint:** Replay must be deterministic (Art. III.2).

---

## 10. Archaeology

Archaeology is the process of tracing current state backward through its causal event chain. It answers the question: "How did we get here?"

**Relationships:** Uses Lineage. Reads EventStore. Produces ProvenanceTrace.
**Constitutional constraint:** Every state must have archaeology (Art. IV.2).

---

## 11. Dashboard

A dashboard is a curated layout of widgets that presents a view of Observatory data. Dashboards are versioned, reconstructable, and certified.

**Relationships:** Composed-of Widgets. Viewable-by Operators. Versioned-in DashboardStore.
**Constitutional constraint:** Every dashboard is reconstructable from its widget definitions and the event stream (Art. III.3).

---

## 12. Widget

A widget is a visualization component that renders a specific query against certified data. Widgets are the atomic unit of the Observatory UI.

**Relationships:** Belongs-to Dashboard. Queries DataSources. Renders-as Visualization.
**Properties:** id, spec_version, data_sources, refresh_policy, replay_compatibility, certification_requirements, security_classification, interaction_policy.

---

## 13. Mission

A mission is a time-bound observatory campaign with specific scientific or engineering objectives. Missions have start/end dates, success criteria, and an assigned operator team.

**Relationships:** Conducted-by Operators. Tracks Indicators. Produces CampaignReports.

---

## 14. Operator

An operator is an agent (human or automated) authorized to interact with the Observatory. Operators have roles, permissions, and audit trails.

**Relationships:** Assigned-roles. Performs-actions. Triggers-decisions.
**Properties:** operator_id, roles, credentials, audit_log.

---

## 15. Campaign

A campaign is an extended observation program targeting a specific domain or hypothesis. Campaigns span multiple missions and produce longitudinal datasets.

**Relationships:** Contains Missions. Targets Domains. Produces CampaignReports.

---

## 16. Certification

Certification is the process of assessing data quality, freshness, integrity, and trust. Every datum in the Observatory carries a certification status.

**Relationships:** Assesses Events, Metrics, Snapshots, Visualizations.
**Properties:** status, checked_at, checked_by, confidence, reasons.

---

## 17. Health

Health is a domain-agnostic measure of a subsystem's operational status. Health is always observable for every component.

**Properties:** status (nominal, degraded, down), uptime, last_contact, error_rate, queue_depth.

---

## 18. Drift

Drift is a measure of deviation from expected behavior over time. Drift is computed per metric, per indicator, and per domain.

**Relationships:** Derived-from Signals. May-trigger Alerts. Tracked-by Governance.

---

## 19. Trend

A trend is a directional pattern in a signal over time. Trends are computed by the Metrics Engine using configurable algorithms.

**Relationships:** Derived-from Signals. Feeds-into Predictions. Visualized-on Widgets.

---

## 20. Prediction

A prediction is a forward-looking estimate of a metric or indicator's future value. Predictions carry confidence intervals that widen with forecast horizon.

**Relationships:** Derived-from Trends. Verified-by Replay. Tracked-by Missions.

---

## 21. Unknown

An unknown is a formally recognized gap in Observatory knowledge. Unknowns are tracked, categorized, and prioritized for investigation.

**Relationships:** Identified-by Operators. Resolved-by Missions. Logged-in KnowledgeBase.
**Properties:** category, impact, priority, status, assigned_to.
