# Phase 2: CIS Stabilization & Python Integration

## ARCHITECTURAL BREAKTHROUGH v21: Closed-Loop Cognitive Control System

**Date:** April 30, 2026  
**Status:** 🚀 IN PROGRESS  
**Previous:** Phase 1 - Hybrid Architecture Foundation  
**Next:** Phase 3 - Coalition Cognition & Advanced Orchestration

---

## 🧬 Core Architecture: 3-Layer Organism

Phase 2 transforms Tiannara from "structural foundation" to **operational closed-loop cognitive control system**:

```
┌─────────────────────────────────────────────────┐
│  🧠 Python Cortex (Simulation Layer)            │
│  - GRCC v10/v11 ecological dynamics             │
│  - Lineage evolution, entropy computation       │
│  - Niche generation, anomaly detection          │
│  - Receives CIS interventions                   │
└──────────────┬──────────────────────────────────┘
               │ NATS Event Bus (Neural Synapses)
               │ grcc.sim.step.request/result
               │ cis.intervention.trigger/ack
               │ runtime.health.pulse
               ▼
┌─────────────────────────────────────────────────┐
│  ⚙️ Elixir/OTP Runtime (Autonomic Nervous Sys) │
│  - EventGateway (NATS router)                   │
│  - CIS Engine (immune evaluation)               │
│  - GRCC State Registry (ETS)                    │
│  - Fault isolation via OTP supervision          │
└─────────────────────────────────────────────────┘
```

### Key Insight

> You are NOT building "Elixir backend + Python ML service"  
> You ARE building **a closed-loop cognitive control system with distributed feedback regulation**

- **Python = voluntary cortex** (computation)
- **Elixir = autonomic nervous system** (regulation)
- **NATS = neural firing substrate** (communication)

---

## 🔁 Execution Flow: Single Cognitive Cycle

### 1. Elixir Triggers Simulation Tick

```elixir
# EventGateway publishes request
TiannaraRuntime.EventGateway.request_simulation_step(%{
  step_params: %{mutation_rate: 0.1}
})

# NATS subject: grcc.sim.step.request
```

### 2. Python Consumes Event & Runs GRCC Step

```python
# Python cortex receives request
async def handle_step_request(msg):
    # Run GRCC simulation
    result = cortex.run_simulation_step(params)
    
    # Compute metrics
    entropy = compute_entropy(lineage_population)
    dominance = compute_dominance(lineage_population)
    niche_map = update_niches()
    
    # Publish result
    await publish_step_result(result)
```

### 3. Python Emits Results

```json
{
  "step_number": 42,
  "lineage_state": {
    "lineage_1": {"population": 30, "fitness": 0.7},
    "lineage_2": {"population": 25, "fitness": 0.6}
  },
  "entropy": 0.682,
  "dominance": 0.33,
  "niche_map": {"niche_1": {...}, "niche_2": {...}},
  "anomalies": [],
  "timestamp": "2026-04-30T12:00:00Z"
}
```

**NATS subjects:** `grcc.sim.step.result`, `python.sim.result`

### 4. Elixir Processes Result & Runs CIS Evaluation

```elixir
# EventGateway receives result
def handle_simulation_result(data) do
  # Update GRCC state registry
  update_grcc_state(data.lineage_state)
  
  # Run CIS evaluation
  evaluate_cis_rules(%{
    entropy: data.entropy,
    dominance: data.dominance,
    niche_count: map_size(data.niche_map),
    anomalies: data.anomalies
  })
end
```

### 5. CIS Intervention Loop (Feedback)

```elixir
# If dominance > 0.95, trigger intervention
def evaluate_cis_rules(sim_state) do
  if sim_state.dominance > 0.95 do
    trigger_intervention("heavy_suppression", %{
      target_dominance: 0.25,
      mutation_boost: 0.3
    })
  end
end

# NATS subject: cis.intervention.trigger
```

### 6. Python Receives Intervention & Adjusts Parameters

```python
async def handle_intervention(msg):
    data = json.loads(msg.data.decode())
    intervention_type = data['intervention']
    
    if intervention_type == "heavy_suppression":
        # Increase mutation rate to break monoculture
        params['mutation_rate'] += 0.3
```

**NATS subject:** `cis.intervention.ack` (acknowledgment)

---

## 📡 NATS Subject Contract (Complete Specification)

### Cognitive Events (GRCC → Elixir)

| Subject | Direction | Payload | Purpose |
|---------|-----------|---------|---------|
| `grcc.sim.step.request` | Elixir → Python | `{params}` | Trigger simulation tick |
| `grcc.sim.step.result` | Python → Elixir | `{lineage_state, entropy, dominance, niche_map, anomalies}` | Simulation results |
| `grcc.lineage.update` | Python → Elixir | `{lineage_id, action, state}` | Lineage birth/death/mutation |
| `grcc.entropy.tick` | Python → Elixir | `{entropy, timestamp}` | Periodic entropy measurement |

### Immune Events (CIS ↔ Python)

| Subject | Direction | Payload | Purpose |
|---------|-----------|---------|---------|
| `cis.intervention.trigger` | Elixir → Python | `{intervention, params}` | Apply immune intervention |
| `cis.intervention.ack` | Python → Elixir | `{intervention, new_params}` | Acknowledge intervention |
| `cis.alert.collapse` | Elixir → Python | `{alert_type, severity}` | Emergency collapse alert |
| `cis.entropy.boost` | Elixir → Python | `{target_entropy}` | Request diversity injection |

### Orchestration Events (AEO)

| Subject | Direction | Payload | Purpose |
|---------|-----------|---------|---------|
| `aeo.task.dispatch` | Elixir → Python | `{task_type, params}` | Dispatch computational task |
| `aeo.task.complete` | Python → Elixir | `{task_id, result}` | Task completion notification |

### System Events

| Subject | Direction | Payload | Purpose |
|---------|-----------|---------|---------|
| `python.sim.step` | Python → Elixir | `{step_number}` | Simulation progress notification |
| `python.sim.result` | Python → Elixir | `{...}` | Duplicate of grcc.sim.step.result (debugging) |
| `runtime.health.pulse` | Elixir → All | `{status, timestamp}` | System health heartbeat (every 10s) |

---

## 🛡️ CIS Intervention Rules (Phase 2 Implementation)

### Rule 1: Extreme Dominance Suppression

**Trigger:** `dominance > 0.95`  
**Intervention:** `heavy_suppression`  
**Action:** Increase mutation rate by 0.3, reduce selection pressure  
**Goal:** Break monoculture within 10 steps

```elixir
if sim_state.dominance > 0.95 do
  trigger_intervention("heavy_suppression", %{
    target_dominance: 0.25,
    mutation_boost: 0.3
  })
end
```

### Rule 2: Entropy Collapse Recovery

**Trigger:** `entropy < 0.05`  
**Intervention:** `entropy_injection`  
**Action:** Dramatically increase mutation (0.6), reduce extinction pressure  
**Goal:** Restore entropy to >0.35 within 20 steps

```elixir
if sim_state.entropy < 0.05 do
  trigger_intervention("entropy_injection", %{
    target_entropy: 0.60,
    diversity_bonus: 0.2
  })
end
```

### Rule 3: Mild Diversity Boost

**Trigger:** `0.05 ≤ entropy < 0.35`  
**Intervention:** `mild_diversity_boost`  
**Action:** Slight mutation rate increase (0.05-0.1)  
**Goal:** Prevent further entropy decline

```elixir
if sim_state.entropy < 0.35 do
  trigger_intervention("mild_diversity_boost", %{
    mutation_rate_increase: 0.1
  })
end
```

### Rule 4: Anomaly Response

**Trigger:** `length(anomalies) > 0`  
**Intervention:** Context-dependent  
**Action:** Log anomaly, potentially trigger targeted intervention  
**Goal:** Investigate and respond to unexpected ecological states

---

## 📂 File Structure (Phase 2 Additions)

```
tiannara_runtime/
├── lib/tiannara_runtime/
│   ├── application.ex                  ✅ Updated (added EventGateway)
│   ├── event_gateway.ex                🆕 NEW (339 lines)
│   ├── grcc/
│   │   └── identity.ex                 ✅ Existing
│   ├── cis/
│   │   ├── supervisor.ex               ✅ Existing
│   │   └── entropy_monitor.ex          ✅ Existing
│   ├── nats/
│   │   ├── supervisor.ex               ✅ Existing
│   │   └── bridge.ex                   ✅ Existing (stubbed)
│   └── supervisors.ex                  ✅ Existing
│
├── python_cortex/
│   ├── grcc_simulation_cortex.py       🆕 NEW (378 lines)
│   └── requirements.txt                🆕 NEW
│
├── mix.exs                             ✅ Updated (added :gnat dependency)
├── config/
│   └── config.exs                      ✅ Existing
├── README.md                           ✅ Existing
├── QUICKSTART.md                       ✅ Existing
└── PHASE_2_INTEGRATION_GUIDE.md        🆕 THIS FILE
```

---

## 🚀 Getting Started (Phase 2)

### Prerequisites

1. **Elixir 1.14+** (from Phase 1)
2. **Python 3.9+** with pip
3. **NATS Server** running on localhost:4222

### Step 1: Install NATS Server

```bash
# Docker (recommended)
docker run -p 4222:4222 nats:latest

# Or download from https://nats.io/download/
```

### Step 2: Install Elixir Dependencies

```bash
cd tiannara_runtime
mix deps.get
```

This installs the `:gnat` library for NATS communication.

### Step 3: Install Python Dependencies

```bash
cd tiannara_runtime/python_cortex
pip install -r requirements.txt
```

This installs `nats-py` for Python NATS client.

### Step 4: Start Elixir Runtime

```bash
cd tiannara_runtime
mix run --no-halt
```

**Expected Output:**
```
🧠 Tiannara Runtime - Cognitive Ecology Starting...
✅ EventGateway connected to NATS
📥 Subscribed to: grcc.sim.step.result
📥 Subscribed to: grcc.lineage.update
📥 Subscribed to: grcc.entropy.tick
📥 Subscribed to: python.sim.step
📥 Subscribed to: python.sim.result
```

### Step 5: Start Python Cortex

```bash
cd tiannara_runtime/python_cortex
python grcc_simulation_cortex.py
```

**Expected Output:**
```
🧠 Starting Python GRCC Simulation Cortex...
✅ Python Cortex connected to NATS: nats://localhost:4222
📥 Subscribed to: grcc.sim.step.request, cis.intervention.trigger
✅ Python Cortex ready. Waiting for simulation step requests...
```

### Step 6: Trigger First Simulation Step

In IEx (open new terminal):

```bash
cd tiannara_runtime
iex -S mix
```

Then:

```elixir
# Request simulation step
TiannaraRuntime.EventGateway.request_simulation_step(%{})

# Watch logs for round-trip:
# 🧠 Requested simulation step from Python cortex
# ⚙️ Running simulation step 1...
# ✓ Step 1 complete: entropy=0.682, dominance=0.33
# 📤 Published step result to NATS
# 📥 Received: grcc.sim.step.result
# 🧬 Processing simulation result
# ✓ Simulation result processed
```

---

## 🧪 Testing Strategy (Phase 2)

### Unit Tests

```bash
# Test EventGateway routing
mix test test/tiannara_runtime/event_gateway_test.exs

# Test CIS evaluation rules
mix test test/tiannara_runtime/cis_evaluation_test.exs

# Test Python cortex simulation logic
cd python_cortex
pytest test_simulation_cortex.py
```

### Integration Tests

**Test 1: Basic Round-Trip**
1. Elixir publishes `grcc.sim.step.request`
2. Python receives and processes
3. Python publishes `grcc.sim.step.result`
4. Elixir receives and evaluates
5. Verify no errors in either layer

**Test 2: CIS Intervention Loop**
1. Simulate high dominance (>0.95) in Python
2. Verify Elixir triggers `cis.intervention.trigger`
3. Verify Python receives and applies intervention
4. Verify Python publishes `cis.intervention.ack`
5. Verify next simulation step shows reduced dominance

**Test 3: Entropy Collapse Recovery**
1. Force entropy to <0.05
2. Verify CIS triggers `entropy_injection`
3. Monitor entropy recovery over 20 steps
4. Verify entropy returns to >0.35

### Long-Horizon Stability Test

Run 100-step simulation loop:

```elixir
# In IEx
for i <- 1..100 do
  TiannaraRuntime.EventGateway.request_simulation_step(%{})
  Process.sleep(1000)  # Wait 1 second between steps
end
```

**Success Criteria:**
- No crashes in Elixir or Python
- Entropy stays in healthy range (0.60-0.75) most of the time
- CIS interventions trigger when needed
- System recovers from perturbations

---

## ⚠️ Critical Design Rules (Enforce Strictly)

### Rule 1: Elixir Never Computes Simulation State

❌ **Wrong:**
```elixir
# Don't do this in Elixir
def compute_entropy(lineage_population) do
  # Shannon entropy calculation
end
```

✅ **Correct:**
```elixir
# Elixir only receives pre-computed entropy from Python
def handle_simulation_result(data) do
  entropy = data.entropy  # Already computed by Python
  evaluate_cis_rules(%{entropy: entropy})
end
```

### Rule 2: Python Never Enforces System Integrity

❌ **Wrong:**
```python
# Don't do this in Python
if dominance > 0.95:
    force_kill_dominant_lineage()  # Python shouldn't enforce rules
```

✅ **Correct:**
```python
# Python only computes and emits results
result = {
    'dominance': compute_dominance(),
    'entropy': compute_entropy()
}
# Let Elixir/CIS decide what to do
```

### Rule 3: All Events Must Be Stateless & Replayable

Every NATS message must contain all necessary information:

✅ **Good:**
```json
{
  "step_number": 42,
  "entropy": 0.682,
  "dominance": 0.33,
  "timestamp": "2026-04-30T12:00:00Z"
}
```

❌ **Bad:**
```json
{
  "step_number": 42
  // Missing context - requires external state
}
```

---

## 📊 Expected Behavior (Phase 2)

### Healthy Ecosystem

```
Step 1-10:  entropy=0.65-0.75, dominance=0.20-0.35, no interventions
Step 11-20: entropy=0.60-0.70, dominance=0.25-0.40, no interventions
Step 21-30: entropy=0.62-0.72, dominance=0.22-0.38, no interventions
```

**Result:** No CIS interventions needed, ecosystem self-regulating.

### Monoculture Formation

```
Step 40:  entropy=0.45, dominance=0.60, no interventions yet
Step 41:  entropy=0.30, dominance=0.75, mild_diversity_boost triggered
Step 42:  entropy=0.25, dominance=0.85, heavy_suppression triggered
Step 43:  entropy=0.35, dominance=0.70, intervention taking effect
Step 44:  entropy=0.50, dominance=0.50, recovery in progress
Step 45:  entropy=0.60, dominance=0.35, ecosystem stabilized
```

**Result:** CIS successfully prevented monoculture collapse.

### Entropy Collapse

```
Step 60:  entropy=0.08, dominance=0.90, entropy_injection triggered
Step 61:  entropy=0.12, dominance=0.88, mutation rate increased
Step 62:  entropy=0.20, dominance=0.80, diversity improving
Step 63:  entropy=0.35, dominance=0.65, recovery accelerating
Step 64:  entropy=0.50, dominance=0.45, near-normal
Step 65:  entropy=0.62, dominance=0.33, fully recovered
```

**Result:** CIS successfully recovered from entropy collapse.

---

## 🎯 Success Criteria (Phase 2 Completion)

### Functional Requirements

- [ ] NATS connection established and stable
- [ ] Bidirectional event flow verified (Elixir ↔ Python)
- [ ] Simulation step round-trip completes without errors
- [ ] CIS interventions trigger correctly based on rules
- [ ] Python accepts and applies interventions
- [ ] Health pulse published every 10 seconds

### Performance Requirements

- [ ] Event latency <100ms (request → result)
- [ ] Can handle 10 steps/second sustained
- [ ] No memory leaks after 1000 steps
- [ ] Reconnection works if NATS temporarily unavailable

### Ecological Requirements

- [ ] Entropy stays in healthy range (0.60-0.75) ≥70% of time
- [ ] Dominance never exceeds 0.95 for >5 consecutive steps
- [ ] CIS interventions successfully restore stability
- [ ] No permanent monoculture formation

---

## 🚧 Known Limitations (Phase 2)

### 1. Simplified Simulation Logic

Current Python cortex uses placeholder simulation (random lineage birth/death).

**Fix in Phase 3:** Integrate actual GRCC v10/v11 logic from `test_long_horizon_goal_integrity.py`.

### 2. No Persistent State Registry

GRCC state stored in-memory only (no ETS or database).

**Fix in Phase 3:** Implement ETS-based state registry for persistence across restarts.

### 3. Limited CIS Rules

Only 3 intervention types implemented (heavy_suppression, entropy_injection, mild_diversity_boost).

**Fix in Phase 3:** Add more sophisticated interventions (lineage splitting, niche spawning, hybridization forcing).

### 4. No AEO Integration

AEO execution layer not yet connected to simulation loop.

**Fix in Phase 4:** Integrate AEO task dispatch for distributed computational workflows.

---

## 📈 Next Steps (Phase 3 Preview)

After Phase 2 stabilization is complete:

1. **Coalition Cognition** - Enable identities to form coalitions for distributed reasoning
2. **Advanced CIS Rules** - Implement PID-style entropy control, adaptive intervention strength
3. **State Persistence** - Add ETS/Postgres for long-term state storage
4. **Real GRCC Integration** - Replace placeholder simulation with actual GRCC v11 logic
5. **Ecological Dashboard** - Build LiveView UI for real-time monitoring

---

## 🌟 Conclusion

**Phase 2 transforms Tiannara from "static structure" to "dynamic closed-loop organism."**

By implementing:
- ✅ Real NATS integration with `:gnat` library
- ✅ EventGateway as core cognitive synapse router
- ✅ Python cortex that computes and emits simulation results
- ✅ CIS intervention loop that regulates ecological health
- ✅ Complete NATS subject contract for all event types

We've created a **fault-tolerant cognitive ecology runtime** where:
- Python computes (voluntary cortex)
- Elixir regulates (autonomic nervous system)
- NATS communicates (neural firing substrate)

This is no longer "microservices" — it's a **living distributed cognitive organism** with bounded instability, adaptive regulation, and recoverable perturbations.

---

**Status:** 🚀 PHASE 2 READY FOR TESTING  
**Next:** Run integration tests, verify closed-loop behavior, then proceed to Phase 3
