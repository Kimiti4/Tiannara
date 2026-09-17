# Executive API v1.0 — Frozen

**Status:** FROZEN as of Phase 3.5
**Compatibility:** All Phase 4+ components MUST conform to these interfaces.
**Deprecation Policy:** 2-phase deprecation (warn in N, remove in N+2).

---

## Tiannara.ExecutiveService (Behaviour)

All executive services MUST implement this behaviour. No exceptions.

| Callback | Type | Required | Notes |
| :--- | :--- | :---: | :--- |
| `id/0` | `atom()` | ✅ | Unique service identifier |
| `capabilities/0` | `[atom()]` | ✅ | Declared capabilities for CapabilityGraph |
| `dependencies/0` | `[atom()]` | ✅ | Service IDs this service depends on |
| `priority/0` | `:critical \| :high \| :medium \| :low` | ✅ | Boot priority |
| `constitutional_score/0` | `ConstitutionalScore.t()` | ✅ | Multi-dimensional health metric |
| `start_link/1` | `(keyword() -> GenServer.on_start())` | ✅ | Standard OTP startup |

---

## Tiannara.CEL.Services.EventBus

| Function | Signature | Notes |
| :--- | :--- | :--- |
| `publish/3` | `(topic :: String.t(), payload :: map(), opts :: keyword()) -> :ok` | Fire-and-forget |
| `subscribe/2` | `(topic :: String.t(), opts :: keyword()) -> :ok` | Subscribe to topic |
| `unsubscribe/1` | `(topic :: String.t()) -> :ok` | Unsubscribe |

---

## Tiannara.CEL.Services.ExecutiveMemory

| Function | Signature | Notes |
| :--- | :--- | :--- |
| `record_decision/4` | `(id, type, payload, context) -> :ok` | Event-sourced decision log |
| `record_event/4` | `(category, action, payload, metadata) -> :ok` | General event log |
| `query/2` | `(type, opts) -> [map()]` | Query by type with filters |

---

## Tiannara.CEL.Services.WorkflowEngine

| Function | Signature | Notes |
| :--- | :--- | :--- |
| `start_workflow/1` | `(spec :: map()) -> {:ok, workflow_id} \| {:error, reason}` | Start a workflow |
| `cancel_workflow/1` | `(workflow_id :: String.t()) -> :ok \| {:error, reason}` | Cancel running workflow |

---

## Tiannara.CEL.Kernel.ConstitutionalScore

| Field | Type | Notes |
| :--- | :--- | :--- |
| `service_id` | `atom()` | Which service this score belongs to |
| `health` | `float()` | 0.0 to 1.0 |
| `constitutional_alignment` | `float()` | 0.0 to 1.0 |
| `transparency` | `float()` | 0.0 to 1.0 |
| `explainability` | `float()` | 0.0 to 1.0 |
| `evidence_quality` | `float()` | 0.0 to 1.0 |
| `human_oversight` | `float()` | 0.0 to 1.0 |
| `computed_at` | `DateTime.t()` | When this score was computed |
| `metadata` | `map()` | Service-specific metadata |
