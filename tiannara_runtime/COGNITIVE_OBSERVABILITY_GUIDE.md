# 🧠 Cognitive Observability Layer - Visualization Rules Engine

## Overview

This document defines the **visualization rules** that transform raw cognitive events into meaningful visual representations. These rules ensure that the observability layer reflects **measured state only** — no inferred narratives, no AI personality projection.

---

## Core Principle

> **Visual State = Measured Cognitive State**

Every visual mutation must be directly traceable to a measurable metric from the cognitive system (CAL, CIS, or System layers).

---

## 1. CAL (Coalition Activity Layer) → Graph Space

### 1.1 Coalition Node Properties

| Metric | Visual Property | Mapping Rule |
|--------|----------------|--------------|
| `coherence` | Color Hue | `hue = coherence * 0.6` (0=red, 0.6=blue) |
| `coherence` | Opacity | `opacity = coherence > 0.3 ? 0.8 : 0.3` |
| `coherence` | Shininess | `shininess = coherence * 100` |
| `entropy` | Emissive Intensity | `emissiveIntensity = entropy * 0.3` |
| `state` | Animation | `active` → pulsing scale, `suppressed` → fade out |

### 1.2 Event → Visual Type Mapping

```elixir
"coalition.formed"      → node_create    (sphere appears)
"coalition.updated"     → node_morph     (material updates)
"coalition.arbitration" → node_highlight (yellow emissive glow for 2s)
"coalition.suppressed"  → node_fade      (opacity animation to 0)
```

### 1.3 Visual Behavior Rules

**Active Coalition:**
- Subtle pulsing: `scale = 1 + sin(time * 2) * 0.05`
- Bright, sharp edges when coherence > 0.7
- Stable position in 3D space

**Suppressed Coalition:**
- Fade animation: `opacity -= 0.02` per frame until removed
- Dimmed color (low saturation)
- Eventually removed from scene

**Arbitrating Coalition:**
- Yellow emissive glow (`0xffff00`, intensity `0.5`)
- Highlight lasts 2 seconds then returns to normal
- Indicates active decision-making

---

## 2. CIS (Cognitive Immune System) → Field Space

### 2.1 Entropy Field Visualization

| Entropy Range | Color | Meaning |
|---------------|-------|---------|
| `0.00 - 0.35` | 🔴 Red | CRITICAL - Entropy collapse |
| `0.35 - 0.55` | 🟠 Orange | AT RISK - Low diversity |
| `0.55 - 0.75` | 🟢 Green | HEALTHY - Optimal range |
| `0.75 - 1.00` | 🔵 Blue | HIGH - Excessive chaos |

### 2.2 Intervention Wave Types

```elixir
"entropy.spike"        → heatwave_expansion   (red ripple outward)
"entropy.damping"      → cooling_gradient     (blue cooling wave)
"intervention.issued"  → heatwave_damp        (targeted suppression)
"quarantine.applied"   → region_isolate       (circular exclusion zone)
"recovery.wave"        → stabilization_wave   (green restoration pulse)
```

### 2.3 Quarantine Zone Rendering

When `quarantine.applied`:
- Draw circular exclusion region around affected area
- Nodes inside become dimmed (opacity `0.3`)
- Boundary pulses slowly (`sin` wave at low frequency)
- Frozen motion (no position updates)

---

## 3. System Events → Timeline Layer

### 3.1 Event Visual Indicators

```elixir
"failure.alert"    → red_pulse      (🔴 #ff4444)
"recovery.complete"→ green_rebound  (🟢 #44ff44)
"mode.switch"      → phase_shift    (🔄 #4444ff)
"health.pulse"     → heartbeat      (💓 #ffaa44)
```

### 3.2 Timeline Display Rules

- Show last 20 events (newest first)
- Each event has:
  - Icon indicator
  - Entity type label (uppercase)
  - State description
  - Timestamp (HH:MM:SS format)
  - Color-coded left border
  - Background tint matching event severity

---

## 4. System Health Dashboard Metrics

### 4.1 Key Performance Indicators

| Metric | Calculation | Threshold |
|--------|-------------|-----------|
| Current Entropy | Latest CIS event | `< 0.35` = CRITICAL |
| Avg Coherence | Mean of last 50 CAL events | `> 0.7` = STABLE |
| Active Coalitions | Unique entity_ids with `state=active` | Context-dependent |
| Intervention Count | CIS events with `entity_type=intervention` | `> 5` = CONCERNING |

### 4.2 Chart Visualization Rules

**Entropy Chart:**
- Area chart with gradient fill
- Color based on current entropy level
- Y-axis domain: `[0, 1]`
- Shows last 50 data points

**Coherence Chart:**
- Line chart (no dots)
- Blue stroke (`#44aaff`)
- Y-axis domain: `[0, 1]`
- Shows last 50 data points

---

## 5. Critical Stability Constraints

### 5.1 No Inferred Narratives

❌ **DON'T:**
- Add emotional labels ("happy", "angry")
- Infer intent from patterns
- Project personality onto visuals

✅ **DO:**
- Show measured metrics only
- Use neutral terminology
- Reflect state changes objectively

### 5.2 Visual Consistency

- Same metric → same visual property across all views
- Color mappings are consistent (red always = critical/bad)
- Animations are subtle and non-distracting

### 5.3 Performance Limits

- Max 200 events in memory (sliding window)
- Max 100 coalition nodes visible simultaneously
- Frame rate target: 60 FPS for 3D renderer
- WebSocket reconnection: max 10 attempts with exponential backoff

---

## 6. Implementation Reference

### 6.1 Backend (Elixir)

File: `tiannara_runtime/lib/tiannara_runtime/observability/stream_processor.ex`

Key functions:
- `transform_to_visual_event/2` - Converts NATS events to visual model
- `enrich_visual_state/2` - Adds visual_type based on event type
- `broadcast_visual_event/1` - Publishes to Phoenix PubSub

### 6.2 Frontend (React)

Files:
- `tiannara_gui/src/hooks/useTiannaraStream.js` - WebSocket hook
- `tiannara_gui/src/components/CognitiveFieldRenderer.jsx` - Three.js renderer
- `tiannara_gui/src/components/SystemHealthDashboard.jsx` - Metrics dashboard
- `tiannara_gui/src/components/EventTimeline.jsx` - Event timeline

---

## 7. Debugging Cognitive States

### 7.1 What You'll See

**Healthy Cognition:**
- Multiple coalitions with varied colors (blue/green)
- Stable entropy in 0.55-0.75 range
- Occasional small interventions
- Smooth pulsing animations

**Entropy Collapse:**
- Few coalitions remaining
- Red/orange field coloring
- Frequent large interventions
- Nodes fading out

**Coalition Fragmentation:**
- Many small nodes appearing/disappearing rapidly
- High intervention count
- Oscillating entropy values
- Flickering visual states

**System Recovery:**
- Green stabilization waves spreading
- New coalitions forming (blue nodes appearing)
- Entropy returning to 0.60-0.70 range
- Reduced intervention frequency

---

## 8. Future Enhancements

### 8.1 Predictive Visualization (Option B)
- Forecast entropy collapse before it happens
- Show predicted trajectories as ghost lines
- Confidence intervals on predictions

### 8.2 Memory Layer Visualization (Option C)
- Track coalition evolution over time
- Historical lineage trails
- Merge/split event history

### 8.3 WebGL Cognitive Universe (Option D)
- Full 3D immersive mode
- VR/AR support
- Particle systems for fine-grained agent tracking

---

## 9. Deployment Checklist

- [ ] Install dependencies: `npm install three recharts`
- [ ] Start NATS server: `nats-server`
- [ ] Start Tiannara Runtime: `cd tiannara_runtime && mix phx.server`
- [ ] Start React dev server: `cd tiannara_gui && npm run dev`
- [ ] Verify WebSocket connection at `ws://localhost:4000/socket/websocket`
- [ ] Check health endpoint: `http://localhost:4000/health`
- [ ] Monitor browser console for connection logs

---

## 10. Architecture Summary

You have now built:

1. ✅ **Cognitive computation layer** (CAL)
2. ✅ **Immune stabilization layer** (CIS)
3. ✅ **Simulation cortex** (Python)
4. ✅ **Event substrate** (NATS)
5. ✅ **Real-time cognitive visualization layer** (NEW)

The system is production-ready for live debugging of distributed cognition.
