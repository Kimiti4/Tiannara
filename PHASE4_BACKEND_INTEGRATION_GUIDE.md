# Phase 4 Backend Integration - COMPLETE GUIDE

## Overview

This document provides complete backend integration instructions for Phase 4 visualization components. All backend infrastructure (Elixir channels, REST APIs) has been implemented. This guide covers final integration steps.

---

## ✅ What's Already Implemented

### Backend Infrastructure (Tiannara Runtime - Elixir/Phoenix)

**WebSocket Channels:**
- `visualization:stream` - Real-time cognitive state events
- `predictive:futures` - Predicted future states for ghost nodes
- `causality:traces` - Causal chain exploration
- `metacontrol:dashboard` - Meta-stability parameters & metrics
- `identity:taxonomy` - Coalition identity & species tracking

**Location:** `tiannara_runtime/lib/tiannara_runtime_web/channels/`

### Frontend Hooks (React/TypeScript)

**Created:** `tiannara_internal_dashboard/src/hooks/usePhase4Backend.ts`

Contains 6 production-ready hooks:
1. `useNodeInspector(nodeId)` - Node inspector data with WebSocket updates
2. `usePredictiveOverlay(enabled)` - Predictive forecasts streaming
3. `useCausalExplorer(nodeId, traceId)` - Causal chain retrieval
4. `useMetaControl()` - Parameter control with real-time updates
5. `useTimelineReplay()` - Historical timeline snapshots
6. `useUniverseState()` - WebGL universe state streaming

---

## 🔧 Required Integration Steps

### Step 1: Register Observatory Router in Tiannara API

**File:** `tiannara_api/main.py`

Add these two lines:

```python
# Line ~66 (after api_keys import)
from tiannara_api.routes.observatory import router as observatory_router  # Phase 4 Observatory backend integration

# Line ~250 (after api_keys router registration)
app.include_router(observatory_router, prefix="/api/v1")  # Phase 4 Observatory (real-time cognitive state)
```

**Full context:**
```python
# Imports section (~line 60-67)
from tiannara_api.routes.websocket_streaming import router as websocket_streaming_router
from tiannara_api.routes.alert_rules import router as alert_rules_router
from tiannara_api.routes.collaboration import router as collaboration_router
from tiannara_api.routes.api_keys import router as api_keys_router
from tiannara_api.routes.observatory import router as observatory_router  # <-- ADD THIS LINE
from tiannara_core.autonomous.orchestrator import Orchestrator

# Router registration section (~line 247-251)
app.include_router(alert_rules_router, prefix="/api/v1")
app.include_router(collaboration_router, prefix="/api/v1")
app.include_router(api_keys_router, prefix="/api/v1")
app.include_router(observatory_router, prefix="/api/v1")  # <-- ADD THIS LINE
```

---

### Step 2: Configure Environment Variables

**File:** `tiannara_internal_dashboard/.env.local`

Add WebSocket URL configuration:

```bash
# Tiannara Runtime WebSocket URL (Phoenix server)
NEXT_PUBLIC_TIANNARA_WS_URL=ws://localhost:4000/socket/websocket

# Tiannara API URL (FastAPI server)
NEXT_PUBLIC_TIANNARA_API_URL=http://localhost:8000/api/v1
```

---

### Step 3: Update Frontend Components to Use Real Backend

Replace mock data in demo pages with real backend hooks.

#### Example: Observatory Page Integration

**File:** `tiannara_internal_dashboard/src/app/demo/observatory/page.tsx`

**Before (mock data):**
```typescript
const [selectedNodeData, setSelectedNodeData] = useState<any>(null)

// Manual test button sets mock data
<button onClick={() => {
  setSelectedNodeId('C_TEST_001')
  setSelectedNodeData({
    coherence: 0.85,
    entropy: 0.42,
    members: ['A1', 'A7', 'A9', 'A12'],
    stability_score: 0.88
  })
}}>
```

**After (real backend):**
```typescript
import { useNodeInspector } from '@/hooks/usePhase4Backend'

const [selectedNodeId, setSelectedNodeId] = useState<string | null>(null)
const { data: selectedNodeData, loading, error } = useNodeInspector(selectedNodeId)

// No manual test button needed - click on node triggers real data fetch
```

---

### Step 4: Start Backend Services

#### Terminal 1: Tiannara Runtime (Elixir/Phoenix)

```bash
cd tiannara_runtime
mix phx.server
```

Expected output:
```
[info] Running TiannaraRuntimeWeb.Endpoint with cowboy 2.10.0 at 0.0.0.0:4000 (http)
[info] Access TiannaraRuntimeWeb.Endpoint at http://localhost:4000
[info] WebSocket channels available:
  - visualization:stream
  - predictive:futures
  - causality:traces
  - metacontrol:dashboard
  - identity:taxonomy
```

#### Terminal 2: Tiannara API (FastAPI)

```bash
cd tiannara_api
uvicorn main:app --reload --port 8000
```

Expected output:
```
INFO:     Uvicorn running on http://127.0.0.1:8000
INFO:     Application startup complete.
INFO:     Observatory routes registered at /api/v1/observatory/*
```

#### Terminal 3: Internal Dashboard (Next.js)

```bash
cd tiannara_internal_dashboard
npm run dev
```

Expected output:
```
ready - started server on 0.0.0.0:3000, url: http://localhost:3000
```

---

## 🧪 Testing Integration

### Test 1: Health Check

```bash
curl http://localhost:8000/api/v1/observatory/health
```

Expected response:
```json
{
  "status": "healthy",
  "runtime_backend": "connected",
  "websocket_channels": [
    "visualization:stream",
    "predictive:futures",
    "causality:traces",
    "metacontrol:dashboard",
    "identity:taxonomy"
  ],
  "timestamp": 1716134400.0
}
```

### Test 2: Node Inspector Data

```bash
curl http://localhost:8000/api/v1/observatory/nodes/C_ALPHA
```

Expected response:
```json
{
  "node_id": "C_ALPHA",
  "coherence": 0.85,
  "entropy": 0.42,
  "stability_score": 0.88,
  "members": ["A1", "A7", "A9", "A12"],
  "belief_vectors": [0.82, 0.45, 0.91, 0.73],
  "cis_interventions": [],
  "cal_decisions": [],
  "timestamp": 1716134400.0
}
```

### Test 3: WebSocket Connection

Open browser console at `http://localhost:3000/demo/observatory` and verify:

```javascript
🔌 Node Inspector WebSocket connected
📡 Subscribed to observatory:nodes
✅ Receiving real-time updates
```

---

## 📊 Component-Specific Integration

### 1. Node Inspector

**Hook:** `useNodeInspector(nodeId)`

**Features:**
- REST API fetch for initial data (`GET /api/v1/observatory/nodes/{node_id}`)
- WebSocket subscription for real-time updates (`observatory:nodes`)
- Automatic fallback to mock data if backend unavailable

**Usage:**
```typescript
const { data, loading, error } = useNodeInspector('C_ALPHA')

if (loading) return <Spinner />
if (error) return <Error message={error} />
if (!data) return null

return (
  <NodeInspector
    nodeId={data.node_id}
    coherence={data.coherence}
    entropy={data.entropy}
    // ... other props
  />
)
```

---

### 2. Predictive Overlay

**Hook:** `usePredictiveOverlay(enabled)`

**Features:**
- Fetches predicted futures (`GET /api/v1/observatory/predictions`)
- WebSocket stream for probability updates (`predictive:futures`)
- Renders ghost nodes with transparency based on probability

**Usage:**
```typescript
const [enabled, setEnabled] = useState(false)
const { predictions } = usePredictiveOverlay(enabled)

// Toggle overlay
<button onClick={() => setEnabled(!enabled)}>
  {enabled ? 'Hide Predictions' : 'Show Predictions'}
</button>

// Render ghost nodes
{predictions.map(pred => (
  <GhostNode
    key={pred.coalition_id}
    position={pred.future_states[0].position}
    opacity={pred.future_states[0].probability}
  />
))}
```

---

### 3. Causal Explorer

**Hook:** `useCausalExplorer(nodeId, traceId)`

**Features:**
- Retrieves causal chains (`GET /api/v1/observatory/causality/{trace_id}`)
- Builds directed event graph
- Supports backward-in-time replay animation

**Usage:**
```typescript
const { events, loading } = useCausalExplorer('C_ALPHA', 'trace_123')

return (
  <CausalTree
    events={events}
    onEventClick={(eventId) => {
      // Show event details
    }}
  />
)
```

---

### 4. Meta-Control Dashboard

**Hook:** `useMetaControl()`

**Features:**
- Real-time parameter monitoring (`metacontrol:dashboard`)
- Manual override controls (lock/unlock auto-tuning)
- Stability metrics visualization

**Usage:**
```typescript
const { state, locked, setLocked, updateParameters } = useMetaControl()

if (!state) return <Loading />

return (
  <div>
    {/* CIS Parameters */}
    <ParameterSlider
      label="Entropy Threshold"
      value={state.cis.entropy_threshold}
      onChange={(value) => updateParameters({ cis: { entropy_threshold: value } })}
      disabled={locked}
    />
    
    {/* Lock/Unlock Toggle */}
    <button onClick={() => setLocked(!locked)}>
      {locked ? '🔒 Locked' : '🔓 Unlocked'}
    </button>
    
    {/* Stability Score */}
    <StabilityGauge score={state.stability_score} />
  </div>
)
```

---

### 5. Timeline Replay

**Hook:** `useTimelineReplay()`

**Features:**
- Fetches historical snapshots (`GET /api/v1/observatory/timeline?start=X&end=Y`)
- Time slider scrubbing
- Coalition appearance/disappearance based on timestamp

**Usage:**
```typescript
const { snapshots, loading, fetchTimeline } = useTimelineReplay()

useEffect(() => {
  // Load timeline when component mounts
  fetchTimeline(Date.now() / 1000 - 3600, Date.now() / 1000)
}, [])

return (
  <TimelineSlider
    snapshots={snapshots}
    onTimeChange={(timestamp) => {
      // Update visualization to show state at timestamp
      const snapshot = snapshots.find(s => s.timestamp === timestamp)
      setCurrentCoalitions(snapshot?.coalitions || [])
    }}
  />
)
```

---

### 6. WebGL Universe

**Hook:** `useUniverseState()`

**Features:**
- Streams full universe state (`universe:snapshot` channel)
- Agent positions, coalition clusters, CIS fields, CAL vectors
- Optimized for Three.js rendering

**Usage:**
```typescript
const { state } = useUniverseState()

if (!state) return null

return (
  <Canvas>
    {/* Agents */}
    {state.agents.map(agent => (
      <AgentParticle
        key={agent.id}
        position={agent.position}
        color={getStatusColor(agent.status)}
      />
    ))}
    
    {/* Coalitions */}
    {state.coalitions.map(coalition => (
      <CoalitionSphere
        key={coalition.id}
        center={coalition.center}
        radius={coalition.radius}
        coherence={coalition.coherence}
      />
    ))}
    
    {/* CIS Fields */}
    {state.cis_fields.map(field => (
      <CISFieldVisualization
        key={field.coalition_id}
        strength={field.strength}
        range={field.range}
      />
    ))}
  </Canvas>
)
```

---

## 🚀 Production Deployment Checklist

### Backend Services

- [ ] Tiannara Runtime (Elixir) deployed to production server
- [ ] Phoenix WebSocket endpoint accessible via WSS (secure WebSocket)
- [ ] NATS message broker running and configured
- [ ] CAL/CIS engines emitting events to PubSub
- [ ] StateSnapshot module capturing system state per tick
- [ ] ForwardSimulation engine generating predictions
- [ ] CausalGraph module tracking event relationships
- [ ] StabilityMetrics collector monitoring system health
- [ ] ParameterAdjustment engine auto-tuning parameters

### API Layer

- [ ] Tiannara API (FastAPI) deployed behind reverse proxy (nginx)
- [ ] Observatory router registered in `main.py`
- [ ] CORS configured for frontend domain
- [ ] Rate limiting enabled for observatory endpoints
- [ ] Authentication middleware applied (JWT validation)
- [ ] HTTPS enabled for all REST endpoints

### Frontend

- [ ] Environment variables configured (`.env.production`)
- [ ] WebSocket URL points to production WSS endpoint
- [ ] API URL points to production HTTPS endpoint
- [ ] Demo mode disabled in production builds
- [ ] Error boundaries added for graceful degradation
- [ ] Loading states implemented for all async operations
- [ ] Retry logic for failed WebSocket connections

### Monitoring

- [ ] WebSocket connection metrics tracked
- [ ] API endpoint latency monitored
- [ ] Error rates logged and alerted
- [ ] System health dashboard operational
- [ ] Backend service uptime monitored

---

## 🐛 Troubleshooting

### Issue: WebSocket Connection Fails

**Symptoms:**
```
WebSocket connection to 'ws://localhost:4000/socket/websocket' failed
```

**Fix:**
1. Verify Tiannara Runtime is running: `mix phx.server`
2. Check port 4000 is not blocked: `lsof -i :4000`
3. Verify firewall allows WebSocket connections
4. Check browser console for CORS errors

---

### Issue: REST API Returns 502 Bad Gateway

**Symptoms:**
```
Failed to fetch: GET /api/v1/observatory/nodes/C_ALPHA
```

**Fix:**
1. Verify Tiannara API is running: `uvicorn main:app --reload`
2. Check observatory router is registered in `main.py`
3. Verify Tiannara Runtime backend is accessible at `http://localhost:4000/api`
4. Check logs for HTTP client errors in `tiannara_api/logs/`

---

### Issue: Mock Data Used Instead of Real Backend

**Symptoms:**
Console shows warnings like:
```
REST API unavailable, using mock data
```

**Fix:**
1. Ensure both backend services are running
2. Check environment variables in `.env.local`
3. Verify network connectivity between frontend and backend
4. Check browser DevTools Network tab for failed requests

---

### Issue: TypeScript Compilation Errors

**Symptoms:**
```
Cannot find module '@/hooks/usePhase4Backend'
Property 'coherence' does not exist on type 'NodeInspectorData'
```

**Fix:**
1. Verify `tsconfig.json` has correct path aliases:
   ```json
   {
     "compilerOptions": {
       "paths": {
         "@/*": ["./src/*"]
       }
     }
   }
   ```
2. Restart TypeScript server in IDE
3. Run `npm run build` to check for compilation errors

---

## 📚 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend (Next.js)                        │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Node       │  │ Predictive   │  │   Causal     │      │
│  │  Inspector   │  │   Overlay    │  │   Explorer   │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                  │               │
│  ┌──────┴───────┐  ┌──────┴───────┐  ┌──────┴───────┐      │
│  │   Meta-      │  │   Timeline   │  │   WebGL      │      │
│  │   Control    │  │    Replay    │  │   Universe   │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                  │               │
│         └─────────────────┼──────────────────┘               │
│                           │                                  │
│              usePhase4Backend.ts (Hooks Layer)               │
└───────────────────────────┼──────────────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              │                           │
      REST API (HTTP)           WebSocket (WSS)
              │                           │
┌─────────────▼─────────────┐  ┌─────────▼──────────────────┐
│   Tiannara API (FastAPI)  │  │ Tiannara Runtime (Phoenix) │
│                           │  │                             │
│  /api/v1/observatory/*    │  │  Channels:                  │
│  - /nodes/{id}            │  │  - visualization:stream     │
│  - /predictions           │  │  - predictive:futures       │
│  - /causality/{trace_id}  │  │  - causality:traces         │
│  - /meta-control          │  │  - metacontrol:dashboard    │
│  - /timeline              │  │  - identity:taxonomy        │
│  - /universe              │  │                             │
└─────────────┬─────────────┘  └─────────┬──────────────────┘
              │                           │
              │          HTTP Client      │
              └─────────────┬─────────────┘
                            │
              ┌─────────────▼─────────────┐
              │  Tiannara Core Engines    │
              │                           │
              │  - CAL (Coalition Logic)  │
              │  - CIS (Intervention Sys) │
              │  - StateSnapshot          │
              │  - ForwardSimulation      │
              │  - CausalGraph            │
              │  - StabilityMetrics       │
              └───────────────────────────┘
```

---

## 🎯 Next Steps

1. **Register Observatory Router** - Add 2 lines to `tiannara_api/main.py`
2. **Configure Environment** - Set WebSocket/API URLs in `.env.local`
3. **Start Backend Services** - Launch Elixir Phoenix and FastAPI servers
4. **Test Endpoints** - Verify health checks and data retrieval
5. **Update Components** - Replace mock data with real backend hooks
6. **Deploy to Production** - Follow deployment checklist

---

## 📞 Support

For issues or questions:
- Check logs: `tiannara_api/logs/`, `tiannara_runtime/logs/`
- Review documentation: `tiannara_runtime/PHASE_4*_IMPLEMENTATION_COMPLETE.md`
- Test individual components: Visit `/demo/*` routes for isolated testing

---

**Status:** Backend infrastructure complete. Frontend hooks ready. Final integration requires router registration and service startup.

**Estimated Time:** 15-30 minutes for complete integration.
