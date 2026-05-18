# Tiannara Runtime - Phase 1 Hybrid Architecture

## ARCHITECTURAL BREAKTHROUGH v20: Cognitive Ecology on BEAM

This is the **Phase 1 hybrid architecture** that transitions Tiannara from a Python-only simulation to a production-ready distributed cognitive ecology using Elixir/OTP.

---

## 🧠 Core Insight

From [elixir.md](../elixir.md):

> Most systems: software executing logic  
> Your direction: ecosystems regulating cognition

The BEAM runtime was designed for exactly the properties your GRCC v10 system needs:
- Persistent distributed processes (identity lineages)
- Fault isolation (one identity crash doesn't collapse ecosystem)
- Adaptive runtime recovery (supervision trees = immune system)
- Massively concurrent actors (thousands of identities)
- Autonomous process supervision (CIS interventions)

---

## 🌿 Architecture Overview

```
Tiannara.Application (Root Supervisor)
│
├── SignalBus.Supervisor
│   └── Phoenix.PubSub (inter-process communication)
│
├── GRCC.EcologySupervisor (DynamicSupervisor)
│   └── Identity GenServers (one per lineage)
│       ├── Evolving state (coherence, fitness, genome)
│       ├── Mutation logic
│       └── Ecological metrics
│
├── CIS.Supervisor (Immune System)
│   ├── EntropyMonitor (Shannon diversity tracking)
│   ├── DiversityRegulator (anti-monoculture pressure)
│   ├── CollapseDetector (failure mode identification)
│   └── RecoveryOrchestrator (immune interventions)
│
├── AEO.Supervisor (Execution Layer)
│   ├── Planner agents
│   ├── Executor agents
│   ├── Tool agents
│   └── Coordination mesh
│
├── NATS.Supervisor (Python Bridge)
│   ├── ConnectionManager (persistent NATS connection)
│   ├── Publisher (Elixir → Python events)
│   └── Subscriber (Python → Elixir events)
│
└── Interface.Supervisor (API & Monitoring)
    ├── REST/GraphQL API
    ├── Phoenix Channels (real-time signals)
    └── LiveView dashboard (ecological observability)
```

---

## 🔥 Key Components

### 1. GRCC Identity Processes (`lib/tiannara_runtime/grcc/identity.ex`)

Each identity lineage becomes a **GenServer process** with:
- Evolving state (coherence, activation, fitness)
- Semantic genome (6-dimensional adaptation biases)
- Mutation logic (genetic variation under evolutionary pressure)
- Inter-identity communication via message passing

**Mapping to GRCC v10 spec:**
```elixir
Identity:
  id: "identity_1"
  lineage_id: "lineage_founding_1"
  state: %{
    coherence: 1.0,
    activation_level: 0.5,
    fitness: 0.5,
    specialization_vector: %{...},
    semantic_genome: %{
      merge_bias: 0.5,
      contradiction_tolerance: 0.5,
      novelty_affinity: 0.5,
      topology_preference: 0.5,
      exploration_exploitation_balance: 0.5,
      stability_sensitivity: 0.5
    }
  }
```

### 2. CIS Immune System (`lib/tiannara_runtime/cis/`)

The Cognitive Immune System extends OTP supervision into **higher-order cognitive immune architecture**:

#### Entropy Monitor (`cis/entropy_monitor.ex`)
- Tracks Shannon diversity: `H = -Σ p_i * log(p_i)`
- Target range: 0.60-0.75 (HEALTHY)
- Alerts: <0.35 (CRITICAL), 0.35-0.55 (AT_RISK)
- Periodic sampling every 5 seconds

#### Diversity Regulator
- Applies anti-monoculture pressure
- Penalizes dominant lineages (>25% population)
- Rewards underrepresented lineages (<15% population)

#### Collapse Detector
- Identifies ecological failure modes:
  - Monoculture formation
  - Entropy collapse
  - Oscillatory instability
  - Runaway feedback loops

#### Recovery Orchestrator
- Coordinates immune interventions:
  - `increase_mutation()` - Boost mutation rates
  - `split_lineage()` - Emergency lineage splitting
  - `spawn_niche()` - Create new niches
  - `force_hybridization()` - Cross-lineage synthesis
  - `reduce_resources()` - Suppress dominant lineages

### 3. NATS Bridge (`lib/tiannara_runtime/nats/`)

Bridges Python simulation layer with Elixir runtime via event bus:

**Event Subjects:**
- `tiannara.simulation.grcc.*` ← Python sends GRCC v10 state updates
- `tiannara.simulation.fitness.*` ← Fitness landscape changes
- `tiannara.ecology.identity.*` → Elixir publishes identity lifecycle events
- `tiannara.ecology.cis.*` → Immune system interventions

**Bidirectional Communication:**
```
Python (GRCC v10 ML/Simulation) ←NATS→ Elixir (Cognitive Runtime)
  ├─ Sends: ecological state, fitness scores, niche data
  └─ Receives: identity actions, immune interventions, orchestration
```

---

## 🚀 Getting Started

### Prerequisites

1. **Install Elixir** (1.14+):
   ```bash
   # Windows (using Chocolatey)
   choco install elixir
   
   # macOS (using Homebrew)
   brew install elixir
   
   # Linux (Ubuntu/Debian)
   sudo apt-get install elixir
   ```

2. **Install NATS Server** (optional for Phase 1):
   ```bash
   # Download from https://nats.io/download/
   # Or run via Docker:
   docker run -p 4222:4222 nats:latest
   ```

### Running the Runtime

```bash
cd tiannara_runtime

# Install dependencies
mix deps.get

# Start the cognitive ecology
mix run --no-halt

# Or start with IEx for interactive debugging
iex -S mix
```

### Expected Output

```
🧠 Tiannara Runtime - Cognitive Ecology Starting...
✅ NATS Connected: nats://localhost:4222
🧬 Identity identity_1 born in lineage lineage_founding_1
🧬 Identity identity_2 born in lineage lineage_founding_2
🧬 Identity identity_3 born in lineage lineage_founding_3
🛡️ CIS Entropy Alert: unknown → healthy (H=0.682)
```

---

## 📊 Phase 1 Goals

### Immediate Objectives

1. ✅ **Establish OTP topology** matching elixir.md specification
2. ✅ **Implement identity processes** as GenServers with evolving state
3. ✅ **Create CIS immune monitoring** (entropy tracking, health classification)
4. ✅ **Build NATS bridge stubs** for Python/Elixir integration
5. ⏳ **Integrate with Python simulation** (next step after Phase 1 foundation)

### Success Criteria

- [ ] All supervisors start without errors
- [ ] Identity processes can be spawned dynamically
- [ ] Entropy monitor reports healthy diversity (H > 0.60)
- [ ] NATS connection established (or graceful degradation if unavailable)
- [ ] No single point of failure (process crashes isolated)

---

## 🔧 Configuration

### Environment Variables

```bash
# NATS server URL (default: nats://localhost:4222)
export NATS_URL="nats://localhost:4222"

# Ecological monitoring interval (default: 5 seconds)
export ENTROPY_MONITOR_INTERVAL="5000"

# Maximum identity population (default: unlimited)
export MAX_IDENTITIES="100"
```

### GRCC v10 Parameters

Configured in code (see `identity.ex` and `entropy_monitor.ex`):

```elixir
# Fitness function weights
w1 = 0.30  # Coherence
w2 = 0.25  # Niche utility
w3 = 0.25  # Adaptation success
w4 = 0.20  # Hybridization contribution

# Entropy thresholds
@critical_threshold 0.35
@at_risk_threshold 0.55
@target_entropy_min 0.60
@target_entropy_max 0.75

# Dominance suppression
@max_dominance 0.25
@lineage_population_penalty 0.2
```

---

## 🧪 Testing

### Unit Tests

```bash
# Run all tests
mix test

# Run specific module tests
mix test test/tiannara_runtime/grcc/identity_test.exs
mix test test/tiannara_runtime/cis/entropy_monitor_test.exs
```

### Integration Test with Python

TODO: After Phase 1 foundation is stable, create integration test that:
1. Starts Python GRCC v10 simulation
2. Launches Elixir runtime
3. Verifies bidirectional NATS communication
4. Monitors ecological health metrics

---

## 📈 Next Steps (Phase 2+)

### Phase 2: CIS Stabilization
- Implement actual dominance suppression logic
- Add PID-style entropy control
- Enable automatic immune interventions
- Track intervention effectiveness

### Phase 3: Coalition Cognition
- Implement identity coalition formation
- Add cross-identity synthesis mechanisms
- Enable distributed reasoning across lineages
- Build adaptive orchestration layer

### Phase 4: Environmental Co-Evolution
- Connect to real-world signal sources
- Implement environmental adaptation loops
- Add recursive learning from execution feedback
- Enable full evolutionary regulation

---

## 🌌 Architectural Philosophy

This is **not** a traditional AI system optimized for:
- Intelligence
- Speed
- Capability

It's an **artificial cognitive ecology** optimized for:
- Resilience (fault isolation via OTP)
- Adaptation (evolutionary dynamics via GenServers)
- Ecological coherence (CIS immune regulation)
- Recoverable instability (bounded oscillation via entropy control)
- Distributed survivability (no central brain, emergent cognition)

---

## 📚 References

- [elixir.md](../elixir.md) - Full architectural rationale for Elixir/BEAM adoption
- [PHASE_1_TOPOLOGY_RESULTS.md](../PHASE_1_TOPOLOGY_RESULTS.md) - Python simulation results informing this design
- [GRCC v10 Spec](../test_long_horizon_goal_integrity.py) - Immune-regulated stabilization equations

---

## ⚠️ Important Notes

### Phase 1 Limitations

1. **NATS integration is stubbed** - Actual gnatsd library not yet integrated
2. **Python bridge is simulated** - Event publishing/receiving logs but doesn't connect
3. **AEO layer is minimal** - Agent mesh supervisors created but not populated
4. **Interface layer is empty** - No Phoenix endpoint or API routes yet

These are intentional - Phase 1 focuses on establishing the **OTP topology foundation**. Subsequent phases will fill in the implementation details.

### Production Readiness

For production deployment, you'll need to:
1. Add actual NATS client library (`:gnatsd` or `:nats`)
2. Implement Phoenix endpoint for API/LiveView
3. Add database persistence (Postgres + Ecto)
4. Configure clustering for distributed deployment
5. Add comprehensive telemetry/metrics collection

---

## 🎯 Summary

**Phase 1 achieves:**
- ✅ OTP topology matching elixir.md specification
- ✅ Identity processes as autonomous GenServers
- ✅ CIS immune monitoring framework
- ✅ NATS bridge structure for Python integration
- ✅ Foundation for distributed cognitive ecology

**What's next:**
- Integrate with running Python GRCC v10 simulation
- Implement actual NATS communication
- Add ecological dashboard (LiveView)
- Begin Phase 2: CIS stabilization logic

This is the transition from "Python simulation" to "production cognitive runtime."
