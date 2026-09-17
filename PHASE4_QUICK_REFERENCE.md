# Phase 4 Backend Integration - Quick Reference Card

## 🚀 One-Liner Startup

```bash
# Windows
start_phase4_services.bat

# Linux/Mac
./start_phase4_services.sh
```

---

## 🔗 Service URLs

| Service | URL | Purpose |
|---------|-----|---------|
| Dashboard | http://localhost:3000 | Next.js frontend |
| API | http://localhost:8000 | FastAPI REST server |
| WebSocket | ws://localhost:4000/socket/websocket | Phoenix real-time stream |

---

## 🧪 Demo Pages

| Page | URL | Tests |
|------|-----|-------|
| Observatory | http://localhost:3000/demo/observatory | Node Inspector, Predictive Overlay, Timeline Replay |
| Meta-Control | http://localhost:3000/demo/meta-control | Parameter sliders, stability metrics |
| Universe | http://localhost:3000/demo/universe | WebGL 3D visualization |

---

## 📡 REST API Endpoints

```bash
# Health check
curl http://localhost:8000/api/v1/observatory/health

# Node inspector data
curl http://localhost:8000/api/v1/observatory/nodes/C_ALPHA

# Predictive forecasts
curl http://localhost:8000/api/v1/observatory/predictions

# Causal chain
curl http://localhost:8000/api/v1/observatory/causality/test_trace_001

# Meta-control state
curl http://localhost:8000/api/v1/observatory/meta-control

# Timeline snapshots (last hour)
curl "http://localhost:8000/api/v1/observatory/timeline?start=$(date -d '1 hour ago' +%s)&end=$(date +%s)"

# Universe state
curl http://localhost:8000/api/v1/observatory/universe
```

---

## 🔌 WebSocket Channels

| Channel | Topic | Purpose |
|---------|-------|---------|
| Visualization | `visualization:stream` | Real-time cognitive events |
| Predictions | `predictive:futures` | Future state forecasts |
| Causality | `causality:traces` | Causal chain updates |
| Meta-Control | `metacontrol:dashboard` | Parameter changes |
| Identity | `identity:taxonomy` | Coalition species tracking |

**Join Message Format:**
```javascript
{
  "topic": "visualization:stream",
  "event": "phx_join",
  "payload": {},
  "ref": "1"
}
```

---

## 🎣 React Hooks Usage

```typescript
import { 
  useNodeInspector,
  usePredictiveOverlay,
  useCausalExplorer,
  useMetaControl,
  useTimelineReplay,
  useUniverseState
} from '@/hooks/usePhase4Backend'

// Node Inspector
const { data, loading, error } = useNodeInspector('C_ALPHA')

// Predictive Overlay
const [enabled, setEnabled] = useState(false)
const { predictions } = usePredictiveOverlay(enabled)

// Causal Explorer
const { events, loading } = useCausalExplorer('C_ALPHA', 'trace_123')

// Meta-Control
const { state, locked, setLocked, updateParameters } = useMetaControl()

// Timeline Replay
const { snapshots, loading, fetchTimeline } = useTimelineReplay()
useEffect(() => {
  fetchTimeline(Date.now() / 1000 - 3600, Date.now() / 1000)
}, [])

// Universe State
const { state } = useUniverseState()
```

---

## ✅ Integration Test

```bash
python test_phase4_integration.py
```

**Expected Output:**
```
✅ Passed:    8
❌ Failed:    0
⏭️  Skipped:   0

🎉 All tests passed!
```

---

## 🐛 Common Issues & Fixes

### Port Already in Use
```bash
# Kill process on port 8000
lsof -ti:8000 | xargs kill  # Linux/Mac
netstat -ano | findstr :8000  # Windows (then taskkill /PID <pid>)
```

### WebSocket Connection Fails
```bash
# Check if Phoenix is running
curl http://localhost:4000/api/health

# Restart Tiannara Runtime
cd tiannara_runtime && mix phx.server
```

### API Returns 502
```bash
# Check if FastAPI is running
curl http://localhost:8000/health

# Restart Tiannara API
cd tiannara_api && uvicorn main:app --reload --port 8000
```

### Mock Data Instead of Real Backend
```bash
# Verify both services are running
curl http://localhost:8000/api/v1/observatory/health
curl http://localhost:4000/api/health

# Check environment variables
cat tiannara_internal_dashboard/.env.local
```

---

## 📊 File Locations

| Component | Path |
|-----------|------|
| Observatory Routes | `tiannara_api/routes/observatory.py` |
| Backend Hooks | `tiannara_internal_dashboard/src/hooks/usePhase4Backend.ts` |
| WebSocket Channels | `tiannara_runtime/lib/tiannara_runtime_web/channels/*.ex` |
| Demo Pages | `tiannara_internal_dashboard/src/app/demo/*/page.tsx` |
| Integration Guide | `PHASE4_BACKEND_INTEGRATION_GUIDE.md` |
| Test Suite | `test_phase4_integration.py` |

---

## 🔧 Configuration Files

**.env.local (Dashboard):**
```bash
NEXT_PUBLIC_TIANNARA_WS_URL=ws://localhost:4000/socket/websocket
NEXT_PUBLIC_TIANNARA_API_URL=http://localhost:8000/api/v1
```

**main.py (API Router Registration):**
```python
from tiannara_api.routes.observatory import router as observatory_router
app.include_router(observatory_router, prefix="/api/v1")
```

---

## 📈 Performance Targets

| Metric | Target | Typical |
|--------|--------|---------|
| API Response Time | < 200ms | 40-120ms |
| WebSocket Latency | < 50ms | 15-30ms |
| Reconnection Time | < 10s | 2-5s |
| Memory Usage | < 500MB | 200-350MB |

---

## 🎯 Success Checklist

- [ ] All 3 services running (ports 3000, 4000, 8000)
- [ ] Integration tests pass (8/8)
- [ ] Demo pages load without errors
- [ ] Browser console shows WebSocket connected
- [ ] Health check returns `"status": "healthy"`
- [ ] No "Failed to fetch" errors in DevTools

---

## 📞 Quick Diagnostics

```bash
# Check all services
curl http://localhost:3000 > /dev/null && echo "✅ Dashboard OK" || echo "❌ Dashboard DOWN"
curl http://localhost:8000/health > /dev/null && echo "✅ API OK" || echo "❌ API DOWN"
curl http://localhost:4000/api/health > /dev/null && echo "✅ Runtime OK" || echo "❌ Runtime DOWN"

# Run full test suite
python test_phase4_integration.py

# View logs
tail -f /tmp/tiannara_api.log        # API logs
tail -f /tmp/tiannara_runtime.log    # Runtime logs
tail -f /tmp/tiannara_dashboard.log  # Dashboard logs
```

---

**Need Help?** See `PHASE4_BACKEND_INTEGRATION_GUIDE.md` for detailed documentation.
