# Phase 5 Safeguards - Quick Reference

## 🛡️ The 5 Critical Safeguards

| # | Safeguard | Module | Purpose |
|---|-----------|--------|---------|
| 1 | Resource Quotas | `ResourceQuota` | Prevent runaway spawning |
| 2 | Memory Ceilings | `MemoryManager` | Control memory explosion |
| 3 | Deterministic Replay | `DeterministicReplay` | Debug divergence |
| 4 | World Freeze | `WorldFreeze` | Rollback & analysis |
| 5 | Kill-Switch | `KillSwitch` | Emergency termination |

---

## 🔧 Quick Commands (Elixir)

### Spawn World (All Safeguards Active)
```elixir
{:ok, pid, world_id} = WorldSupervisor.spawn_world(%{
  seed: 12345,
  max_agents: 100,
  max_coalitions: 10
})
```

### Check Resource Quotas
```elixir
# Get status
{:ok, status} = ResourceQuota.get_status()
# %{max_worlds: 10, active_worlds: 5, ...}

# Check specific world
:ok = ResourceQuota.check_quota(world_id)
# or {:warning, reasons} or {:violation, reasons}
```

### Monitor Memory
```elixir
# Allocate memory
:ok = MemoryManager.allocate_memory(world_id, 100)  # 100MB

# Get usage
{:ok, mb} = MemoryManager.get_world_memory(world_id)

# Trigger GC
MemoryManager.trigger_gc(world_id)

# Emergency GC
MemoryManager.emergency_gc()
```

### Record & Replay
```elixir
# Start recording
DeterministicReplay.start_recording(world_id, seed: 42)

# Record events
DeterministicReplay.record_event(world_id, :agent_update, data)

# Stop recording
{:ok, info} = DeterministicReplay.stop_recording(world_id)

# Replay
{:ok, total} = DeterministicReplay.start_replay(world_id)
{:ok, event} = DeterministicReplay.step_replay(world_id)
```

### Freeze & Snapshot
```elixir
# Freeze world
WorldFreeze.freeze_world(world_id)

# Create snapshot
{:ok, snap_id} = WorldFreeze.create_snapshot(world_id)

# Export
WorldFreeze.export_snapshot(snap_id, "/tmp/snap.json")

# Restore
WorldFreeze.restore_snapshot(world_id, snap_id)

# Unfreeze
WorldFreeze.unfreeze_world(world_id)
```

### Kill-Switch
```elixir
# Request kill (two-step)
KillSwitch.request_kill(world_id, "Reason")
# → Confirmation code: A3F7B2E9

# Confirm within 30 seconds
KillSwitch.confirm_kill(world_id, "A3F7B2E9")

# OR emergency kill (immediate)
KillSwitch.emergency_kill(world_id, "EMERGENCY")

# Check killed worlds
{:ok, killed} = KillSwitch.get_killed_worlds()
```

---

## ⚙️ Configuration Defaults

### ResourceQuota
```elixir
max_worlds: 10
max_cpu_seconds: 300        # 5 minutes
max_memory_mb: 512          # Per world
max_events_per_second: 1000
```

### MemoryManager
```elixir
system_warning_mb: 4096     # 4GB
system_critical_mb: 8192    # 8GB
world_soft_limit_mb: 256
world_hard_limit_mb: 512
```

### DeterministicReplay
```elixir
max_events_per_world: 100_000
```

### WorldFreeze
```elixir
max_snapshots_per_world: 10
```

### KillSwitch
```elixir
entropy_critical_threshold: 0.95
memory_critical_multiplier: 2.0
cascade_detection_window_ms: 5000
max_cascade_events: 100
```

---

## 🚨 Emergency Procedures

### Scenario 1: Memory Explosion
```elixir
# Immediate action
MemoryManager.emergency_gc()

# If still critical
KillSwitch.emergency_kill(world_id, "Memory explosion")
```

### Scenario 2: Runaway World Spawning
```elixir
# Check quota status
{:ok, status} = ResourceQuota.get_status()

# Update limits if needed
ResourceQuota.update_limits(%{max_worlds: 5})

# Kill excess worlds
Enum.each(excess_worlds, fn world_id ->
  KillSwitch.emergency_kill(world_id, "Quota exceeded")
end)
```

### Scenario 3: Evolutionary Cascade
```elixir
# Automatically detected by KillSwitch
# Manual intervention if needed
KillSwitch.emergency_kill(world_id, "Cascade detected")
```

### Scenario 4: Need to Debug Divergence
```elixir
# Export recordings from both worlds
DeterministicReplay.export_recording(world_a, "/tmp/world_a.json")
DeterministicReplay.export_recording(world_b, "/tmp/world_b.json")

# Compare event logs offline
```

### Scenario 5: Rollback Bad State
```elixir
# List snapshots
{:ok, snaps} = WorldFreeze.list_snapshots(world_id)

# Restore to good state
WorldFreeze.restore_snapshot(world_id, hd(snaps).id)
```

---

## 📊 Monitoring Queries

### Get System Status
```elixir
status = WorldSupervisor.get_status()
# %{
#   active_worlds: 5,
#   max_worlds: 10,
#   system_memory_mb: 1250,
#   killed_worlds: %{},
#   timestamp: ...
# }
```

### Check Memory Pressure
```elixir
pressure = MemoryManager.check_pressure()
# :normal | :warning | :critical
```

### List Active Worlds
```elixir
{:ok, status} = ResourceQuota.get_status()
Map.keys(status.worlds)
# ["world_123", "world_456", ...]
```

### View Kill History
```elixir
{:ok, killed} = KillSwitch.get_killed_worlds()
Enum.each(killed, fn {id, info} ->
  IO.puts("#{id}: #{info.reason} at #{info.killed_at}")
end)
```

---

## ✅ Architectural Boundaries

### ❌ NEVER Allow
- Visualization → CAL decisions
- Predictions → Direct actions
- UI feedback → Automatic mutations
- Meta-controls → Bypass CIS

### ✅ Always Enforce
- Read-only observation layer
- Human-in-the-loop for predictions
- Explicit user actions for mutations
- CIS validation for all parameter changes

---

## 🐛 Troubleshooting

### World Won't Spawn
```elixir
# Check quotas
{:ok, status} = ResourceQuota.get_status()
# If active_worlds >= max_worlds → need to terminate some

# Check memory
pressure = MemoryManager.check_pressure()
# If :critical → run emergency GC or kill worlds
```

### Replay Not Deterministic
```elixir
# Verify same seed used
{:ok, info} = DeterministicReplay.get_recording_info(world_id)
IO.inspect(info.seed)

# Check if all events recorded
# Missing events → non-determinism
```

### Snapshot Restore Fails
```elixir
# Verify snapshot exists
{:ok, info} = WorldFreeze.get_snapshot_info(snap_id)

# Check snapshot integrity
# Corrupted export → re-export
```

### Kill-Switch Not Triggering
```elixir
# Verify auto-kill enabled
# (Check KillSwitch state - should be true by default)

# Manually trigger if needed
KillSwitch.emergency_kill(world_id, "Manual override")
```

---

## 📞 Quick Diagnostics

```bash
# Check if all safeguard modules are running
iex -S mix

# In IEx:
Code.ensure_loaded?(TiannaraRuntime.MultiWorld.ResourceQuota)
Code.ensure_loaded?(TiannaraRuntime.MultiWorld.MemoryManager)
Code.ensure_loaded?(TiannaraRuntime.MultiWorld.DeterministicReplay)
Code.ensure_loaded?(TiannaraRuntime.MultiWorld.WorldFreeze)
Code.ensure_loaded?(TiannaraRuntime.MultiWorld.KillSwitch)
Code.ensure_loaded?(TiannaraRuntime.MultiWorld.WorldSupervisor)
# All should return: true
```

---

**Full Documentation:** See `PHASE5_SAFEGUARDS_IMPLEMENTATION.md` for complete details.
