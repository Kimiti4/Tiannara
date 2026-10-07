# Tiannara Operator Guide — Native Cognition, Research and Worlds

## Purpose

This is the practical starting point for using Tiannara without an external LLM.

The native cognition path is deterministic and evidence-aware. It can:
- maintain conversation state;
- classify intent;
- distinguish observations, evidence, inference and unknowns;
- propose investigations;
- acquire external research evidence through the Research API;
- operate bounded world simulations;
- expose world lineage and measured state;
- refuse unsupported claims.

An external LLM is **not required** for the native conversation path.

## Start the Python/API stack

Development infrastructure:

```bash
docker compose up -d postgres redis
```

Then:

```uv run uvicorn tiannara_api.main:app --host 0.0.0.0 --port 8000```

If `uv` is not installed:

```bash
python -m uvicorn tiannara_api.main:app --host 0.0.0.0 --port 8000
```

## Start the Elixir runtime

From `tiannara_runtime/`:

```bash
mix deps.get
mix compile
mix phx.server
```

The API world adapter expects the runtime at:

```text
http://localhost:4000/api
```

Do not enable `real_execution_enabled` merely to make the system appear operational. Real experiment execution requires a real substrate and authorization grant.

## Native conversation

POST:

```text
/chat
```

Example:

```json
{
  "message": "Can you determine whether this hypothesis is actually supported?",
  "context": {
    "known_facts": [],
    "unknowns": ["independent replication"]
  }
}
```

Tiannara should report an epistemic gap instead of inventing an answer.

## Proactive conversation

POST:

```text
/chat/initiate
```

Context may contain:
- `knowledge_gaps`
- `anomalies`
- `goals`

The engine chooses a conversation from current state rather than emitting a random greeting.

## Independent research

POST:

```text
/chat/research
```

Example:

```json
{
  "query": "recent experimental evidence for room-temperature superconductivity",
  "num_results": 6,
  "fetch_sources": true
}
```

Research results are **evidence candidates**, not facts. The response records source provenance and explicitly identifies the need for independent verification.

## Worlds

List worlds:

```text
GET /worlds/
```

Inspect a world:

```text
GET /worlds/{world_id}
```

Fork a world:

```text
POST /worlds/fork
{
  "parent_world_id": "WORLD_ID",
  "mutation": {}
}
```

Inspect lineage:

```text
GET /worlds/{world_id}/lineage
```

A child world should inherit the parent's genome, mutate it, receive the next generation number, and retain the parent ID.

## Observatory

The Observatory should be treated as a **measurement surface**, not a simulator of health.

If the runtime is unavailable:
- nodes are unavailable;
- predictions are unavailable;
- causal traces are unavailable;
- universe state is unavailable;
- calibration is unavailable.

The API intentionally no longer substitutes fabricated agents, probabilities or stability metrics for those states.

Use:

```text
GET /observatory/health
GET /observatory/universe
GET /observatory/predictions
GET /observatory/timeline
```

## Scientific status vocabulary

Prefer these states:

```text
observed
evidence_available
hypothesis_only
evidence_unverified
replicated_unverified
validated_replicated
bounded_proof
inconclusive
unavailable
```

Never convert `unavailable` into `healthy`, `validated`, or `successful`.

## What Tiannara can claim today

It can claim a computation when the computation actually ran.

It can claim an observation when a real provider supplied it.

It can claim evidence when provenance exists.

It can claim replication only when independent execution actually occurred.

It can claim a bounded proof only when the corresponding proof/verification engine produced it.

Everything else remains a hypothesis, proposal or unknown.

## Verification before release

Run:

```bash
python scripts/truth_surface_audit.py
```

Python:

```bash
pytest -q tiannara_core/tests/test_native_dialogue.py
```

Elixir:

```bash
cd tiannara_runtime
mix test test/world_scientific_closure_test.exs
mix test
```

Frontend:

```bash
cd tiannara_saas
npm ci
npm run build
```

Observatory:

```bash
cd tiannara_observatory/apps/observatory_ui
npm ci
npm run build
```

## Current release boundary

The repository now deliberately distinguishes:
1. native cognition;
2. evidence acquisition;
3. world simulation;
4. scientific execution;
5. formal verification;
6. constitutional admission.

A missing layer must remain visibly missing until its real implementation and tests exist.
