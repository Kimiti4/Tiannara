# Observatory APIs Constitution

## Preamble

All Observatory APIs — present and future — must satisfy the constitutional guarantees defined in this document. No API is deployed without a published specification that demonstrates compliance.

---

## Article I — API Types

The Observatory recognizes the following API types. Each must satisfy the articles of this constitution.

| Type | Protocol | Use Case | Replayable |
|------|----------|----------|------------|
| **REST** | HTTP/2 | Query current state, list events, retrieve metrics | Yes (via timestamp query param) |
| **WebSocket** | WS/WSS | Real-time streaming, live updates, alerts | Yes (via replay channel) |
| **Streaming** | Server-Sent Events | One-direction event streams | Yes (via replay parameter) |
| **Replay** | HTTP/2 | Reconstruct historical state at timestamp T | Intrinsically |
| **Batch** | HTTP/2 + async | Large data exports, historical backfills | Yes (by definition) |
| **Historical** | HTTP/2 | Time-range queries with aggregation | Yes |
| **Live** | WS/SSE | Current state with ongoing updates | No (only present) |
| **GraphQL** | HTTP/2 (future) | Flexible data composition | Conditional |

---

## Article II — Universal Guarantees

Every API response satisfies:

### II.1 — Certification Status

Every response includes certification status for the data it returns.

```json
{
  "data": { ... },
  "certification": {
    "status": "certified",
    "timestamp": "2026-07-16T14:30:00Z",
    "domains": ["runtime/health"]
  }
}
```

### II.2 — Provenance

Every response includes the provenance of the data.

```json
{
  "provenance": {
    "source": "runtime://generation/42",
    "generation": 42,
    "constitution": "1.0.0",
    "last_event_id": "0193b5c0-...",
    "last_event_timestamp": "2026-07-16T14:30:00Z"
  }
}
```

### II.3 — Versioning

Every response includes the API version and the schema version of the data.

```json
{
  "api_version": "1.0.0",
  "schema_version": "1.0.0"
}
```

### II.4 — Replayability

Every GET/query endpoint accepts an optional `at_timestamp` parameter.
When provided, the response reflects the state at that historical timestamp.

```
GET /api/v1/runtime/health?at_timestamp=2026-07-16T00:00:00Z
```

### II.5 — Idempotency

Write endpoints accept an `idempotency_key` header. If a request with the same key
is received within the idempotency window (configurable, default 5 minutes), the
server returns the original response without applying the mutation again.

### II.6 — Response Envelope

All responses follow a standard envelope:

```json
{
  "success": true,
  "data": { ... },
  "certification": { ... },
  "provenance": { ... },
  "api_version": "1.0.0",
  "meta": {
    "request_id": "req-abc123",
    "processing_time_ms": 42,
    "pagination": { ... }  // if applicable
  },
  "errors": []  // non-empty only on failure
}
```

### II.7 — Error Format

```json
{
  "success": false,
  "data": null,
  "errors": [
    {
      "code": "CERTIFICATION_DEGRADED",
      "message": "Data source certification is degraded",
      "details": { ... },
      "request_id": "req-abc123"
    }
  ]
}
```

### II.8 — Rate Limiting

Every response includes rate limit headers:

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 987
X-RateLimit-Reset: 1626451200
X-RateLimit-Operator: operator-uuid
```

---

## Article III — REST-Specific Guarantees

| Rule | Description |
|------|-------------|
| **Naming** | Resources are plural nouns: `/metrics`, `/events`, `/operators`. |
| **Actions** | Actions use POST with action name: `POST /events/:id/replay`. |
| **Pagination** | Cursor-based: `?cursor=...&limit=100`. |
| **Filtering** | Query parameters: `?domain=runtime&since=...&until=...`. |
| **Versioning** | Version in URL path: `/api/v1/`. |
| **Caching** | Responses include `ETag` and `Cache-Control`. |
| **Compression** | `Content-Encoding: gzip` supported. |
| **CORS** | Configurable origins, not wildcard in production. |

---

## Article IV — WebSocket-Specific Guarantees

| Rule | Description |
|------|-------------|
| **Auth** | JWT in connection parameters. Reconnect with new token. |
| **Channels** | One channel per domain: `ws://host/ws/runtime`, `/ws/science`, etc. |
| **Replay** | `ws://host/ws/replay?timestamp=T` replays historical events. |
| **Heartbeat** | Server sends ping every 30s. Client responds pong. |
| **Backpressure** | Client can signal `slow_consumer`. Server buffers up to limit. |
| **Reliability** | Event IDs enable gap detection. Client requests missed events on reconnect. |

---

## Article V — GraphQL Guarantees (Future)

| Rule | Description |
|------|-------------|
| **Schema** | Schema is published and versioned. |
| **Depth Limit** | Maximum query depth: 10. |
| **Complexity** | Query complexity scoring. Reject queries exceeding operator limit. |
| **N+1** | DataLoader pattern required. |
| **Certification** | Each resolved field includes certification status. |

---

## Article VI — Constitutional Consistency

API responses must be consistent with what replay would produce.
For any REST response at time T, re-issuing the same query with `at_timestamp=T`
after new events arrive must return the same result.

```json
{
  "constitutional_consistency": {
    "verified": true,
    "replay_matched": true,
    "divergence": null
  }
}
```
