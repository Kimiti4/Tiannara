# Cognitive Phase-Space Atlas (CPSA) - Quick Reference

## 🌌 Core Concept

Maps the **topology of cognitive transformation dynamics** in 4D phase-space:

```
X = Coherence (0.0 - 1.0)
Y = Entropy (0.0 - 1.0)
Z = Stability (0.0 - 1.0)
W = Intervention Density (0.0 - 1.0)
```

---

## 🔧 Quick Commands (Elixir)

### Record Phase Vector
```elixir
# Called every tick by world supervisor
CognitivePhaseSpaceAtlas.record_vector(world_id, %{
  coherence: 0.72,
  entropy: 0.41,
  stability: 0.83,
  intervention_density: 0.22
})
```

### Get Trajectory
```elixir
{:ok, trajectory} = CPSA.get_trajectory(world_id)
# trajectory = [%{vector, timestamp, sequence_number}, ...]
```

### Query Current Region
```elixir
{:ok, region} = CPSA.query_region(world_id)
# region = %{
#   region_type: :stable_attractor | :collapse_basin | :oscillation_zone |
#                :evolution_corridor | :immune_pressure_zone | :transitional
#   risk_level: :low | :medium | :high | :critical
#   nearest_attractor: %{...}
#   distance_to_attractor: 0.05
# }
```

### Check Collapse Risk
```elixir
case CPSA.check_collapse_risk(world_id) do
  :safe -> 
    # No risk
  
  {:warning, reason} ->
    # Approaching danger
  
  {:critical, reason} ->
    # In collapse basin - consider kill-switch
end
```

### Find Similar Trajectories
```elixir
{:ok, similar} = CPSA.find_similar_trajectories(world_id, max_results: 5)
# similar = [
#   %{world_id: "world_456", similarity_score: 0.92, outcome_description: "improving"}
# ]
```

### Get Atlas Status
```elixir
{:ok, status} = CPSA.get_atlas_status()
# status = %{
#   total_worlds_tracked: 10,
#   total_vectors_recorded: 50000,
#   attractors: 5,
#   collapse_basins: 2,
#   oscillation_loops: 1,
#   evolution_corridors: 3,
#   immune_boundaries: 2
# }
```

### Export/Import Atlas
```elixir
# Export
:ok = CPSA.export_atlas("/tmp/cpsa_atlas.json")

# Import
:ok = CPSA.import_atlas("/tmp/cpsa_atlas.json")

# Reset
CPSA.reset_atlas()
```

---

## 🔌 WebSocket Channel

### Frontend Connection
```javascript
const channel = socket.channel('cpsa:atlas', {})
channel.join()
  .receive('ok', () => console.log('✅ CPSA stream active'))
```

### Real-Time Events
```javascript
// Trajectory updates
channel.on('trajectory_update', data => {
  // data = {world_id, vector, timestamp}
  updateVisualization(data)
})

// Attractor detection
channel.on('attractor_detected', data => {
  // data = {center_vector, member_count, stability_score}
  markAttractor(data)
})

// Collapse risk alerts
channel.on('collapse_risk', data => {
  if (data.status === 'critical') {
    triggerAlert(data.reason)
  }
})

// Atlas summary
channel.on('atlas_summary', data => {
  updateDashboard(data)
})
```

### Frontend Queries
```javascript
// Get trajectory
channel.push('get_trajectory', {world_id: 'world_123'})

// Query region
channel.push('query_region', {world_id: 'world_123'})

// Check risk
channel.push('check_collapse_risk', {world_id: 'world_123'})

// Get atlas status
channel.push('get_atlas_status', {})

// Find similar
channel.push('find_similar_trajectories', {
  world_id: 'world_123',
  max_results: 5
})

// Export
channel.push('export_atlas', {filepath: '/tmp/atlas.json'})
```

---

## 🗺️ Region Types

| Type | Characteristics | Meaning |
|------|----------------|---------|
| `:stable_attractor` | High coherence, low entropy, high stability | Worlds settle here |
| `:collapse_basin` | Low stability, high entropy | Dangerous - avoid |
| `:oscillation_zone` | Medium entropy, high intervention | Unstable cycles |
| `:evolution_corridor` | Improving coherence, low intervention | Path to resilience |
| `:immune_pressure_zone` | Very high intervention density | CIS working hard |
| `:transitional` | Mixed signals | Between regions |

---

## ⚙️ Configuration Defaults

```elixir
@phase_space_dimensions [:coherence, :entropy, :stability, :intervention_density]
@attractor_epsilon 0.05              # Distance threshold for clustering
@trajectory_window_size 100          # Keep last 100 vectors per world
@cluster_min_points 5                # Min points to form cluster
@instability_gradient_weights:
  entropy_acceleration: 0.4
  intervention_density: 0.3
  recovery_velocity: -0.3
```

---

## 📊 Periodic Analysis (Every 30s)

Automatically detects:
1. **Attractors** - High-density convergence regions
2. **Collapse Basins** - Low-stability danger zones
3. **Oscillation Loops** - Persistent unstable cycles (TODO)
4. **Evolution Corridors** - Paths of improvement
5. **Immune Boundaries** - High intervention zones

---

## 🎯 Phase 5 Integration

### Topology-Aware Evolution
```elixir
# Before spawning world, check if parameters lead to collapse
predicted_vector = simulate_initial_state(params)

case CPSA.check_collapse_risk_for_vector(predicted_vector) do
  :safe ->
    spawn_world(params)
  
  {:critical, _} ->
    # Steer away from collapse
    adjusted = steer_away_from_collapse(params)
    spawn_world(adjusted)
end
```

### World Comparison
```elixir
# Compare evolutionary paths
{:ok, traj_a} = CPSA.get_trajectory(world_a)
{:ok, traj_b} = CPSA.get_trajectory(world_b)

similarity = calculate_similarity(traj_a, traj_b)

if similarity > 0.8 and outcomes_differ?(world_a, world_b) do
  Logger.info("Similar paths, different outcomes - investigate divergence")
end
```

### Species Niche Detection
```elixir
# Find clusters of successful worlds
successful = filter_by_success(all_worlds)
niches = cluster_trajectories(Enum.map(successful, &CPSA.get_trajectory/1))

Logger.info("Discovered #{length(niches)} evolutionary niches")
```

---

## ⚠️ Safety Boundary

**CPSA is DESCRIPTIVE only:**
- ✅ Maps behavioral topology
- ✅ Informs evolution strategy
- ❌ Does NOT control CAL/CIS
- ❌ Does NOT dictate cognition
- ❌ Does NOT force convergence

**Why:** Prevents diversity collapse and loss of novelty.

---

## 🐛 Troubleshooting

### No Trajectory Data
```elixir
# Verify vectors being recorded
{:ok, traj} = CPSA.get_trajectory(world_id)
IO.inspect(length(traj))  # Should be > 0

# If empty, check world supervisor is calling record_vector every tick
```

### Attractors Not Detected
```elixir
# Need sufficient data
# Minimum: @cluster_min_points (5) vectors in same grid cell

# Check grid density
status = CPSA.get_atlas_status()
IO.inspect(status.total_vectors_recorded)  # Should be > 100
```

### Collapse Risk Not Triggering
```elixir
# Verify vector values indicate instability
# Collapse requires: stability < 0.3 AND entropy > 0.7

# Manually test with failing trajectory
for i <- 1..50 do
  CPSA.record_vector("test", %{
    coherence: 0.5 - (i * 0.008),
    entropy: 0.5 + (i * 0.008),
    stability: 0.5 - (i * 0.008),
    intervention_density: 0.5 + (i * 0.008)
  })
end

{:critical, reason} = CPSA.check_collapse_risk("test")
```

### WebSocket Not Streaming
```bash
# Verify channel registered in TiannaraRuntimeWeb.Endpoint
# Should have: channel "cpsa:atlas", CognitivePhaseSpaceChannel

# Check PubSub subscriptions
# Backend should broadcast: cpsa_trajectories, cpsa_attractors, cpsa_risk_alerts
```

---

## 📈 Performance

| Operation | Cost | Frequency |
|-----------|------|-----------|
| Record vector | ~1ms | Every tick |
| Query region | ~2ms | On demand |
| Check risk | ~3ms | On demand |
| Find similar | ~50ms | On demand |
| Periodic analysis | ~500ms | Every 30s |
| Export atlas | ~100ms | On demand |

**Memory:** < 200KB for 10 worlds (negligible)

---

## 📞 Quick Diagnostics

```elixir
# Check if CPSA module loaded
Code.ensure_loaded?(TiannaraRuntime.CognitivePhaseSpaceAtlas)
# Should return: true

# Check WebSocket channel
Code.ensure_loaded?(TiannaraRuntimeWeb.CognitivePhaseSpaceChannel)
# Should return: true

# Test vector recording
CPSA.record_vector("test", %{coherence: 0.7, entropy: 0.3, stability: 0.8, intervention_density: 0.2})
{:ok, traj} = CPSA.get_trajectory("test")
IO.inspect(length(traj))  # Should be 1

# Run manual analysis
state = CPSA.run_periodic_analysis(initial_state)
IO.inspect(length(state.attractors))
```

---

**Full Documentation:** See `PHASE4E_COGNITIVE_PHASE_SPACE_ATLAS.md` for complete details.
