# Failure Constitution

## Preamble

Every failure mode of the Observatory is documented before it occurs. This document specifies each mode's detection, impact, response, recovery, and post-mortem requirements. No failure mode is "impossible" — all are planned for.

---

## Failure Mode Classification

| Class | Description | Response SLA |
|-------|-------------|-------------|
| **Class 1** — Graceful Degradation | Partial loss of non-critical functionality. Observatory continues operating. | 1 hour |
| **Class 2** — Partial Outage | Loss of a subsystem. Some observatory functions unavailable. | 30 minutes |
| **Class 3** — Major Outage | Observatory is unable to ingest or serve data. Critical functions unavailable. | 15 minutes |
| **Class 4** — Catastrophic | Data loss, replay divergence, certification chain broken. | Immediate |

---

## Failure Mode Register

### F-01: Telemetry Loss

**Class:** 2
**Description:** The Observatory stops receiving telemetry from the Runtime.
**Detection:**
- Heartbeat metric `runtime.uptime` goes stale
- No events received in expected interval (configurable, default 30s)
- Alert: `alert/triggered` for `telemetry_gateway`
**Impact:**
- Metrics go stale
- Dashboards show stale data indicator
- Certification degrades to `stale`
**Response:**
1. Verify network connectivity between Runtime and Observatory
2. Verify NATS/HTTP bridge is operational
3. Check telemetry gateway process health
4. If gateway is down: restart gateway
5. If Runtime is down: await Runtime recovery (out of Observatory scope)
**Recovery:**
- On telemetry resumption: backfill metrics from buffered events
- Certification returns to `certified` once fresh data arrives
**Post-Mortem:**
- Root cause analysis: why was telemetry interrupted?
- Duration histogram: time-to-detect, time-to-respond, time-to-recover
- Gap analysis: how many events were lost vs. buffered vs. recovered?

---

### F-02: Event Store Write Failure

**Class:** 2
**Description:** The event store (PostgreSQL) is unable to accept writes.
**Detection:**
- `event_store.write_error_count` increases
- Write latency exceeds threshold (configurable, default 5s)
- Database connection pool exhaustion
**Impact:**
- New events are not persisted
- Telemetry gateway enters buffer mode (in-memory buffer up to 10,000 events)
- Metrics engine continues on buffered events
- Certification: degrades to `provisional`
**Response:**
1. Check PostgreSQL health (connections, disk space, replication lag)
2. Increase connection pool if needed
3. If disk full: trigger storage expansion or archival job
4. If replication lag: failover to replica
5. If primary is down: promote replica
**Recovery:**
- Flush buffer to event store
- Verify event ordering is preserved
- Certification returns to `certified` once write buffer is empty
**Post-Mortem:**
- Buffer utilization at peak
- Was the buffer sufficient? (target: never lose events within buffer limit)
- Database root cause: storage, query, or infrastructure?

---

### F-03: Replay Divergence

**Class:** 4
**Description:** Replaying the event stream produces a different state than the original.
**Detection:**
- Automatic replay verification fails
- Checksum mismatch between two independent replays of the same timestamp
- `replay/check` event with status `diverged`
**Impact:**
- Historical audit is unreliable
- Certification chain is broken
- All dashboards showing historical data are suspect
**Response:**
1. IMMEDIATE: Invalidate certification for all data derived from the affected time range
2. Lock the event store to prevent new writes (immutable freeze)
3. Identify divergence point: first event where replay diverges
4. Determine cause: code change, data corruption, clock skew, ordering bug
5. If code change: roll back to known-good version
6. If data corruption: restore from verified backup
**Recovery:**
- Re-replay from the last known-good snapshot
- Verify checksum against secondary replay instance
- Recertify all data from the divergence point forward
- Unlock event store
**Post-Mortem:**
- Full incident report with timeline
- Root cause analysis: why did replay diverge?
- Remediation: how to prevent this class of divergence
- Certification invalidation: which data products were affected, for how long?

---

### F-04: Storage Corruption

**Class:** 4
**Description:** Event store or snapshot data is corrupted (bit rot, disk failure, software bug).
**Detection:**
- Checksum verification on read fails
- Database reports corruption errors
- Snapshot restore fails checksum validation
**Impact:**
- Some historical data may be unrecoverable
- Replay may produce incorrect results for affected time ranges
- Certification: degraded or invalidated for affected data
**Response:**
1. IMMEDIATE: Identify and isolate corrupted data (by checksum)
2. Determine corruption scope: single event, range, or full store
3. Restore corrupted data from backup
4. If backup is also corrupted: restore from secondary (replica) store
5. If no uncorrupted copy exists: mark gap explicitly, do not fabricate data
**Recovery:**
- Verify restored data against checksums
- Re-replay affected time range
- Recertify affected data products
**Post-Mortem:**
- Corruption root cause: hardware, software, or environmental?
- Backup restoration success/failure
- Data gap documentation if data is permanently lost
- Remediation: additional redundancy, more frequent checksums, different storage backend?

---

### F-05: Metric Drift

**Class:** 2
**Description:** Aggregated metrics diverge from what they should be if recomputed from raw events.
**Detection:**
- Periodic recomputation check fails
- `certification/audit` finds inconsistency between raw and aggregated values
- Comparative replay produces different metric values
**Impact:**
- Dashboards show incorrect metric values
- Decisions based on drifted metrics may be flawed
**Response:**
1. IMMEDIATE: invalidate certification for affected metrics
2. Identify cause: aggregation logic bug, missed events, window boundary issue
3. Recompute metrics from raw events for affected time range
4. Verify corrected values against secondary computation
**Recovery:**
- Publish corrected metric values
- Recertify affected metrics
- Log the correction in audit trail with before/after values
**Post-Mortem:**
- How long was the drift undetected?
- How many dashboards displayed incorrect values?
- Root cause: algorithmic, implementation, or configuration?
- Remediation: more frequent recomputation checks, additional monitoring?

---

### F-06: Clock Skew

**Class:** 2
**Description:** Significant clock difference between Runtime and Observatory nodes.
**Detection:**
- HLC comparison detects drift beyond threshold (configurable, default 100ms)
- Event timestamps from different sources have impossible ordering
**Impact:**
- Event ordering may be incorrect
- Replay may produce incorrect state
- Certification: potentially affected
**Response:**
1. Check NTP status on all nodes
2. Synchronize clocks (NTP restart)
3. Re-evaluate event ordering with corrected clocks
4. If events have been misordered: flag affected time range for review
**Recovery:**
- Natural: clock skew resolved, new events are correctly ordered
- If misordering was significant: re-replay affected range with corrected timestamps
**Post-Mortem:**
- Skew magnitude and duration
- Were any events misordered?
- Remediation: better NTP monitoring, hardware clock, or PTP?

---

### F-07: Dashboard Lag

**Class:** 1
**Description:** Dashboard visualization lags significantly behind the event stream.
**Detection:**
- Dashboard timestamp differs from event store latest timestamp by > threshold
- WebSocket subscriber experiencing high latency
**Impact:**
- Operators see outdated data
- Decisions may be based on stale information
**Response:**
1. Identify bottleneck: API, WebSocket, Widget rendering, or network
2. Scale the bottleneck (more API instances, increase WS capacity, optimize rendering)
3. If widget rendering is slow: reduce data density, increase aggregation window
**Recovery:**
- Dashboard catches up to real-time
- Operators receive notification of lag resolution
**Post-Mortem:**
- Lag root cause
- Duration and maximum lag
- Remediation: performance optimization, auto-scaling, or architectural change?

---

### F-08: Partial Outage — Subsystem Down

**Class:** 2
**Description:** One or more Observatory subsystems are unavailable (e.g., Metrics Engine, Certification Engine, Replay Store).
**Detection:**
- Health check endpoint returns non-200 for the subsystem
- Subsystem-specific metrics show zero throughput
- Downstream components report upstream unavailability
**Impact:**
- Depends on which subsystem is down:
  - Metrics Engine: dashboards show no metric data
  - Certification Engine: all data becomes `uncertain`
  - Replay Store: replay queries fail
  - Event Store: see F-02
  - API: see F-03
**Response:**
1. Identify which subsystem is down
2. Attempt restart
3. If restart fails: escalate
4. Degrade gracefully: other subsystems continue operating
**Recovery:**
- Subsystem back online
- Backfill any missed work (re-aggregate missed events, recertify missed data)
**Post-Mortem:**
- Root cause per subsystem
- Impact duration and scope
- Were graceful degradation mechanisms effective?

---

### F-09: Cluster Split

**Class:** 3
**Description:** Observatory nodes lose network connectivity and form separate clusters.
**Detection:**
- Cluster membership changes detected
- Health check: one partition cannot reach the other
- Event ordering inconsistencies between partitions
**Impact:**
- Both partitions may accept events, creating divergent event streams
- Replay becomes inconsistent between partitions
- Certification: cannot be trusted
**Response:**
1. IMMEDIATE: pause event ingestion on both partitions
2. Determine which partition has the authoritative event stream
   - Usually the partition with the most events or the one that can reach the event store
3. Discard or merge events from the non-authoritative partition
   - If merge: reconcile ordering using HLC timestamps
4. Resume ingestion on authoritative partition
**Recovery:**
- Once network heals: verify event stream is consistent
- Replay from split point to verify state is correct
- Recertify all data from split window
**Post-Mortem:**
- Split duration
- Were events lost or duplicated?
- Reconciliation outcome
- Remediation: anti-entropy protocol, split-brain detection, automatic healing?

---

### F-10: Certification Invalidation Cascade

**Class:** 3
**Description:** A certification invalidation in one domain propagates to invalidate many or all data products.
**Detection:**
- `certification/invalidation` events with high propagation count
- Dashboard widgets transitioning to greyed/warning state en masse
**Impact:**
- Major loss of observatory trustworthiness
- Operators cannot trust any visualization
- Automated decisions relying on certification may halt
**Response:**
1. IMMEDIATE: Identify the root invalidation source
2. Assess whether the invalidation is correct or a false positive
3. If correct: follow F-03 or F-05 recovery as appropriate
4. If false positive: correct the certification logic, trigger recertification
**Recovery:**
- Root cause resolved
- Recertification propagates from root outward
- Operators notified of restored trustworthiness
**Post-Mortem:**
- Causal chain: how did one invalidation cascade?
- Were the invalidation propagation rules correct?
- Was there an over-invalidation (certification too strict)?
- Remediation: adjust certification propagation rules, add circuit breakers?

---

### F-11: Resource Exhaustion

**Class:** 2
**Description:** Observatory nodes run out of memory, disk, or CPU.
**Detection:**
- System metrics cross warning/critical thresholds
- OOM killer events in system logs
- API latency increases dramatically
**Impact:**
- Node may crash (OOM)
- Event ingestion may slow or stop
- API may become unresponsive
**Response:**
1. Identify exhausted resource
2. If memory: reduce load, increase RAM, or scale out
3. If disk: run archival, increase storage, or stream to cold storage
4. If CPU: optimize hot paths, reduce aggregation frequency, add nodes
**Recovery:**
- Resource usage returns to normal
- Verify no data was lost during exhaustion period
**Post-Mortem:**
- Root cause: load spike, memory leak, or insufficient capacity?
- Were auto-scaling mechanisms triggered? Did they work?
- Remediation: better monitoring, proactive scaling, resource limits?

---

### F-12: Data Loss (Unrecoverable)

**Class:** 4
**Description:** Events or snapshots are permanently lost.
**Detection:**
- Integrity check fails and no backup can restore the data
- Gap in event sequence detected (missing sequence numbers)
- Replay produces incomplete state
**Impact:**
- Historical record is incomplete
- Some replay queries will produce gaps
- Certification: affected time ranges marked as `uncertain`
**Response:**
1. IMMEDIATE: freeze the gap boundaries
2. Document the gap: start timestamp, end timestamp, event IDs, cause
3. Do NOT fabricate missing data
4. Flag all downstream data products that depend on the lost data
**Recovery:**
- Mark gaps explicitly in the event store
- Certification indicates `uncertain` for affected ranges
- Dashboards show gaps with visual indicators
**Post-Mortem:**
- How was the data lost?
- Was there a backup that should have protected this data?
- Impact assessment: which analyses, decisions, or audits are incomplete?
- Remediation: improve backup strategy, add redundancy, add integrity checks?

---

## Failure Mode Summary Matrix

| ID | Name | Class | Detection SLA | Response SLA | Data Loss Risk |
|----|------|-------|---------------|--------------|----------------|
| F-01 | Telemetry Loss | 2 | 30s | 1h | None (buffered) |
| F-02 | Event Store Write Failure | 2 | 5s | 30m | Low (buffered) |
| F-03 | Replay Divergence | 4 | Immediate | Immediate | Medium |
| F-04 | Storage Corruption | 4 | Immediate | Immediate | High |
| F-05 | Metric Drift | 2 | 5m | 1h | None |
| F-06 | Clock Skew | 2 | 100ms | 30m | None |
| F-07 | Dashboard Lag | 1 | 10s | 1h | None |
| F-08 | Partial Outage | 2 | 30s | 30m | Low |
| F-09 | Cluster Split | 3 | Immediate | 15m | Medium |
| F-10 | Certification Invalidation Cascade | 3 | Immediate | 15m | None (trust only) |
| F-11 | Resource Exhaustion | 2 | 30s | 30m | Low |
| F-12 | Data Loss (Unrecoverable) | 4 | Immediate | Immediate | Permanent |

---

## Recovery Drills

Each failure mode must be drilled at least once per quarter.
Drills verify that:
1. Detection mechanisms work
2. Response procedures are documented and known
3. Recovery procedures produce correct state
4. Post-mortem process produces actionable improvements

Drill results are recorded as `audit/review` events in the event store.
