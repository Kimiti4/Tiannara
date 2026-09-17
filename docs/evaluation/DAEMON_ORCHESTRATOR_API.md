# Daemon Orchestrator API Documentation

## Overview

The **Daemon Orchestrator** provides persistent, autonomous operation for the Tiannara system. It implements the `upgrades.md` requirement for continuous background operation with nightly AutoDream consolidation cycles.

### Key Features

- ✅ **Background Process**: Runs continuously as a daemon/service
- ✅ **AutoDream Cycle**: Nightly skill reconsolidation, self-criticism, and creative synthesis
- ✅ **Health Monitoring**: Automatic health checks and recovery
- ✅ **Cron-like Scheduling**: Configurable periodic task execution
- ✅ **Graceful Shutdown**: Signal handling for clean termination
- ✅ **Checkpointing**: Automatic state persistence every N episodes

---

## Quick Start

### Basic Usage

```python
from tiannara_core.evaluation.daemon_orchestrator import DaemonOrchestrator

# Create and start daemon with default settings (2 AM AutoDream)
daemon = DaemonOrchestrator()
daemon.start()

# Run indefinitely until SIGINT/SIGTERM
try:
    while daemon.running:
        time.sleep(1)
except KeyboardInterrupt:
    daemon.stop()
```

### Command-Line Interface

```bash
# Start daemon with default settings (2 AM AutoDream)
python tiannara_core/evaluation/daemon_orchestrator.py

# Custom schedule hour (3 AM)
python tiannara_core/evaluation/daemon_orchestrator.py --schedule-hour 3

# Disable AutoDream cycle
python tiannara_core/evaluation/daemon_orchestrator.py --no-auto-dream

# Custom health check interval (60 seconds)
python tiannara_core/evaluation/daemon_orchestrator.py --health-check-interval 60
```

---

## API Reference

### Constructor

```python
DaemonOrchestrator(
    log_dir: str = None,
    schedule_hour: int = 2,
    enable_auto_dream: bool = True,
    health_check_interval: int = 300,
    checkpoint_interval: int = 100
)
```

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `log_dir` | `str` | `"tiannara_core/logs"` | Directory for logs and checkpoints |
| `schedule_hour` | `int` | `2` | Hour (0-23) for nightly AutoDream cycle |
| `enable_auto_dream` | `bool` | `True` | Enable nightly consolidation cycle |
| `health_check_interval` | `int` | `300` | Seconds between health checks (5 min) |
| `checkpoint_interval` | `int` | `100` | Episodes between automatic checkpoints |

#### Example

```python
# Custom configuration: 4 AM AutoDream, 1-minute health checks
daemon = DaemonOrchestrator(
    log_dir="/var/tiannara/logs",
    schedule_hour=4,
    enable_auto_dream=True,
    health_check_interval=60,
    checkpoint_interval=50
)
```

---

### Core Methods

#### `start()`

Start the daemon orchestrator in background threads.

```python
daemon.start()
```

**Behavior:**
- Initializes skill memory and episode logger
- Starts health monitoring thread
- Starts scheduler thread for periodic tasks
- Sets `self.running = True`

**Thread Safety:** Safe to call once. Multiple calls are ignored.

---

#### `stop()`

Gracefully shutdown the daemon.

```python
daemon.stop()
```

**Behavior:**
- Sets `self.shutdown_event` to signal all threads to stop
- Waits for threads to complete (timeout: 10s)
- Saves final checkpoint
- Closes database connections
- Sets `self.running = False`

**Usage:**
```python
import signal

def signal_handler(sig, frame):
    print("Received shutdown signal")
    daemon.stop()

signal.signal(signal.SIGINT, signal_handler)
```

---

#### `run_episode(episode_data: Dict[str, Any]) -> Dict[str, Any]`

Execute a single evaluation episode.

**Parameters:**
- `episode_data`: Dictionary containing episode information
  - Required keys: `episode`, `domain`, `task_type`
  - Optional keys: `correctness`, `score`, `runtime_ms`, etc.

**Returns:**
- Dictionary with episode results including computed metrics

**Example:**
```python
result = daemon.run_episode({
    "episode": 42,
    "domain": "algorithm",
    "task_type": "sorting",
    "inputs": {"array": [3, 1, 4, 1, 5]},
    "expected_output": [1, 1, 3, 4, 5]
})

print(f"Episode {result['episode']} correctness: {result['correctness']}")
```

**Side Effects:**
- Logs episode to JSONL and SQLite (via `EpisodeLogger`)
- Updates skill memory if correctness > threshold
- Triggers checkpoint if episode_count % checkpoint_interval == 0

---

#### `schedule_task(name: str, interval_seconds: int, func: callable, args: tuple = ())`

Schedule a periodic task for execution.

**Parameters:**
- `name`: Unique task identifier
- `interval_seconds`: Execution interval in seconds
- `func`: Callable to execute
- `args`: Arguments to pass to func

**Example:**
```python
def cleanup_old_logs():
    """Remove logs older than 7 days."""
    import shutil
    from datetime import datetime, timedelta
    
    cutoff = datetime.now() - timedelta(days=7)
    # ... cleanup logic ...

daemon.schedule_task(
    name="log_cleanup",
    interval_seconds=86400,  # Daily
    func=cleanup_old_logs
)
```

**Notes:**
- Tasks run in separate threads
- Exceptions in tasks are logged but don't crash the daemon
- Tasks are cancelled on `stop()`

---

#### `trigger_autodream()`

Manually trigger the AutoDream consolidation cycle.

**Behavior:**
1. **Skill Reconsolidation**: Merge similar skills (cosine similarity > 0.9)
2. **Skill Decay**: Remove skills unused for > 50 episodes
3. **Self-Criticism**: Analyze recent failures and identify patterns
4. **Creative Synthesis**: Generate new composite strategies from successful patterns
5. **Checkpoint**: Save consolidated state

**Example:**
```python
# Trigger AutoDream immediately (instead of waiting for scheduled time)
daemon.trigger_autodream()
```

**Automatic Scheduling:**
- Runs daily at `schedule_hour` (default: 2 AM)
- Only runs if `enable_auto_dream=True`
- Skips if last run was < 20 hours ago (prevents double-runs)

---

#### `get_status() -> Dict[str, Any]`

Get current daemon status and metrics.

**Returns:**
```python
{
    "running": True,
    "uptime_seconds": 3600,
    "episode_count": 150,
    "last_autodream": "2026-04-30T02:00:00",
    "skill_memory_size": 42,
    "scheduled_tasks": ["log_cleanup", "health_check"],
    "health_status": "healthy"
}
```

**Example:**
```python
status = daemon.get_status()
print(f"Daemon uptime: {status['uptime_seconds']} seconds")
print(f"Episodes processed: {status['episode_count']}")
```

---

#### `save_checkpoint(path: str = None)`

Save current state to disk.

**Parameters:**
- `path`: Checkpoint file path (default: `{log_dir}/checkpoint_{timestamp}.json`)

**Saved Data:**
- Skill memory (active skills, usage counts, quality scores)
- Episode count and statistics
- Scheduled task configuration
- Last AutoDream timestamp

**Example:**
```python
# Save to default location
daemon.save_checkpoint()

# Save to custom location
daemon.save_checkpoint("/backup/tiannara_checkpoint.json")
```

---

#### `load_checkpoint(path: str)`

Restore state from checkpoint.

**Parameters:**
- `path`: Checkpoint file path

**Example:**
```python
# Load latest checkpoint
import glob
checkpoints = sorted(glob.glob("tiannara_core/logs/checkpoint_*.json"))
if checkpoints:
    daemon.load_checkpoint(checkpoints[-1])
    print(f"Loaded checkpoint: {checkpoints[-1]}")
```

---

### AutoDream Cycle Details

The AutoDream cycle performs four key operations:

#### 1. Skill Reconsolidation

**Purpose:** Merge redundant skills to reduce memory footprint and improve retrieval efficiency.

**Algorithm:**
```python
for each pair of skills (A, B):
    similarity = cosine_similarity(A.embedding, B.embedding)
    if similarity > 0.9:
        merged_skill = merge_skills(A, B)
        remove A and B from memory
        add merged_skill to memory
```

**Metrics Logged:**
- Number of skills before/after consolidation
- Average similarity of merged pairs
- Memory savings (KB)

---

#### 2. Skill Decay

**Purpose:** Remove stale skills that haven't been used recently.

**Criteria:**
- Skills unused for > 50 episodes are removed
- High-quality skills (quality > 0.8) have extended lifetime (100 episodes)
- Recently added skills (< 10 episodes old) are protected

**Metrics Logged:**
- Number of skills removed
- Average age of removed skills
- Remaining skill count

---

#### 3. Self-Criticism

**Purpose:** Analyze recent failures to identify systemic weaknesses.

**Process:**
1. Query last 100 episodes from SQLite
2. Group by domain and task_type
3. Calculate failure rates per group
4. Identify top 3 failure patterns
5. Generate recommendations

**Example Output:**
```json
{
  "failure_analysis": {
    "causal_domain": {
      "total_episodes": 25,
      "failures": 8,
      "failure_rate": 0.32,
      "common_error": "confounded_variables"
    },
    "recommendations": [
      "Improve confounder detection in causal tasks",
      "Add partial correlation analysis",
      "Increase training data for branching systems"
    ]
  }
}
```

---

#### 4. Creative Synthesis

**Purpose:** Generate new composite strategies by combining successful patterns.

**Process:**
1. Identify top-performing skills per domain (top 10%)
2. Cross-reference skills across domains
3. Generate composite strategies using successful combinations
4. Test composites on historical data (offline validation)
5. Add high-performing composites to skill memory

**Example:**
```python
# Discovered composite strategy
composite = {
    "name": "sort_then_binary_search",
    "components": ["quick_sort", "binary_search"],
    "domains": ["algorithm", "search"],
    "validation_score": 0.92,
    "usage_count": 0  # New strategy
}
```

---

## Configuration Examples

### Production Deployment

```python
daemon = DaemonOrchestrator(
    log_dir="/var/log/tiannara",
    schedule_hour=3,  # 3 AM (off-peak)
    enable_auto_dream=True,
    health_check_interval=60,  # Aggressive monitoring
    checkpoint_interval=50  # Frequent checkpoints
)

# Schedule maintenance tasks
daemon.schedule_task(
    name="db_vacuum",
    interval_seconds=86400,  # Daily
    func=lambda: daemon.episode_logger.conn.execute("VACUUM")
)

daemon.schedule_task(
    name="log_rotation",
    interval_seconds=604800,  # Weekly
    func=rotate_logs
)

daemon.start()
```

### Development Mode

```python
daemon = DaemonOrchestrator(
    log_dir="./dev_logs",
    schedule_hour=12,  # Noon for easy testing
    enable_auto_dream=False,  # Disable for faster iteration
    health_check_interval=300,
    checkpoint_interval=1000  # Less frequent
)

daemon.start()
```

### Manual AutoDream Testing

```python
daemon = DaemonOrchestrator(enable_auto_dream=False)
daemon.start()

# Run some episodes
for i in range(100):
    daemon.run_episode({...})

# Manually trigger AutoDream to test
daemon.trigger_autodream()

# Check results
status = daemon.get_status()
print(f"Skills after AutoDream: {status['skill_memory_size']}")
```

---

## Logging

The daemon produces two types of logs:

### 1. Daemon Log (`daemon.log`)

**Location:** `{log_dir}/daemon.log`

**Format:**
```
2026-04-30 02:00:00,123 | INFO | Starting AutoDream cycle
2026-04-30 02:00:05,456 | INFO | Skill reconsolidation: 45 -> 38 skills
2026-04-30 02:00:06,789 | INFO | Skill decay: removed 5 stale skills
2026-04-30 02:00:10,012 | INFO | Self-criticism: identified 3 failure patterns
2026-04-30 02:00:15,345 | INFO | Creative synthesis: generated 2 new composites
2026-04-30 02:00:15,678 | INFO | AutoDream cycle complete (15.55s)
```

### 2. Episode Log (`episodes.jsonl` + `episodes.db`)

Managed by `EpisodeLogger` (see `episode_logger.py` documentation).

---

## Error Handling

### Graceful Degradation

The daemon is designed to continue operating even if individual components fail:

```python
# If SQLite write fails, JSONL logging continues
# If skill memory fails, episode logging continues
# If AutoDream fails, daemon continues running (error logged)
```

### Health Checks

The health monitoring thread checks:
1. **Disk space**: Warns if < 1 GB free
2. **Memory usage**: Warns if > 80% RAM used
3. **Database integrity**: Verifies SQLite database is not corrupted
4. **Thread liveness**: Ensures all background threads are alive

If health check fails:
- Warning logged to `daemon.log`
- Attempt automatic recovery (e.g., restart thread)
- If recovery fails, save checkpoint and shutdown gracefully

---

## Performance Characteristics

### Resource Usage

| Component | Memory | CPU | Disk I/O |
|-----------|--------|-----|----------|
| Episode Logger (sync) | ~5 MB | Low | Moderate |
| Episode Logger (async) | ~10 MB | Low | Low (batched) |
| Skill Memory (100 skills) | ~50 MB | Negligible | None |
| AutoDream Cycle | +100 MB (temporary) | High (5-15s) | High |
| Health Monitor | ~1 MB | Negligible | None |

### Scalability

- **Episodes**: Tested up to 10,000 episodes (linear scaling)
- **Skills**: Tested up to 500 skills (quadratic consolidation cost)
- **Scheduled Tasks**: Tested up to 20 concurrent tasks

### Optimization Tips

1. **Use async logging** for high-throughput scenarios (>100 episodes/min)
   ```python
   from tiannara_core.evaluation.episode_logger import EpisodeLogger
   logger = EpisodeLogger(async_mode=True, batch_size=100)
   ```

2. **Increase checkpoint interval** for long-running daemons
   ```python
   daemon = DaemonOrchestrator(checkpoint_interval=500)
   ```

3. **Disable AutoDream** during intensive experimentation
   ```python
   daemon = DaemonOrchestrator(enable_auto_dream=False)
   ```

---

## Troubleshooting

### Daemon Won't Start

**Symptom:** `start()` returns immediately, `running=False`

**Check:**
1. Port conflicts (if using network features)
2. File permissions on `log_dir`
3. Python version (requires 3.8+)

**Solution:**
```python
import logging
logging.basicConfig(level=logging.DEBUG)
daemon = DaemonOrchestrator()
daemon.logger.setLevel(logging.DEBUG)
daemon.start()  # Now check debug output
```

### AutoDream Not Running

**Symptom:** No AutoDream logs at scheduled time

**Check:**
1. `enable_auto_dream=True`?
2. System clock correct?
3. Last AutoDream was < 20 hours ago?

**Solution:**
```python
# Force AutoDream to run now
daemon.last_autodream = None  # Reset cooldown
daemon.trigger_autodream()
```

### High Memory Usage

**Symptom:** Memory grows unbounded over time

**Check:**
1. Skill memory size (should be < 500 skills)
2. Episode log size (SQLite should compact automatically)
3. Scheduled tasks not leaking resources

**Solution:**
```python
# Manually trigger skill decay
daemon.skill_memory.prune_unused_skills(max_age_episodes=30)

# Vacuum SQLite database
daemon.episode_logger.conn.execute("VACUUM")

# Check for memory leaks
import tracemalloc
tracemalloc.start()
# ... run daemon ...
snapshot = tracemalloc.take_snapshot()
stats = snapshot.statistics('lineno')
for stat in stats[:10]:
    print(stat)
```

### Database Lock Errors

**Symptom:** `sqlite3.OperationalError: database is locked`

**Cause:** Multiple processes accessing same SQLite database

**Solution:**
1. Ensure only one daemon instance running
2. Use WAL mode for better concurrency:
   ```python
   daemon.episode_logger.conn.execute("PRAGMA journal_mode=WAL")
   ```
3. Increase timeout:
   ```python
   import sqlite3
   daemon.episode_logger.conn = sqlite3.connect(
       str(daemon.episode_logger.db_path),
       timeout=30  # 30 second timeout
   )
   ```

---

## Integration Examples

### With Experiment Runner

```python
from tiannara_core.evaluation.daemon_orchestrator import DaemonOrchestrator
from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator
from tiannara_core.evaluation.evolution_engine import AlgorithmEvolver

# Initialize daemon
daemon = DaemonOrchestrator()
daemon.start()

# Run experiment through daemon
task_gen = AlgorithmTaskGenerator(seed=42)
evolver = AlgorithmEvolver(seed=42)

for episode in range(1000):
    task = task_gen.generate_task(episode=episode)
    variant = evolver.create_variant(task, episode=episode)
    
    # Execute through daemon (automatic logging + checkpointing)
    result = daemon.run_episode({
        "episode": episode,
        "domain": "algorithm",
        "task_type": task["type"],
        "variant": variant,
        "task": task
    })
    
    print(f"Episode {episode}: correctness={result['correctness']:.3f}")

# Daemon will auto-shutdown on SIGINT
```

### With Web API

```python
from fastapi import FastAPI
from tiannara_core.evaluation.daemon_orchestrator import DaemonOrchestrator

app = FastAPI()
daemon = DaemonOrchestrator()

@app.on_event("startup")
def startup():
    daemon.start()

@app.on_event("shutdown")
def shutdown():
    daemon.stop()

@app.post("/episode")
def run_episode(episode_data: dict):
    return daemon.run_episode(episode_data)

@app.get("/status")
def get_status():
    return daemon.get_status()

@app.post("/autodream")
def trigger_autodream():
    daemon.trigger_autodream()
    return {"status": "AutoDream triggered"}
```

### With Cron (Linux)

```bash
# /etc/crontab
# Start daemon at boot
@reboot cd /opt/tiannara && python3 -m tiannara_core.evaluation.daemon_orchestrator --schedule-hour 2

# Or use systemd service
# /etc/systemd/system/tiannara-daemon.service
[Unit]
Description=Tiannara Daemon Orchestrator
After=network.target

[Service]
Type=simple
User=tiannara
WorkingDirectory=/opt/tiannara
ExecStart=/usr/bin/python3 -m tiannara_core.evaluation.daemon_orchestrator
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

---

## Best Practices

### 1. Always Use Context Managers

```python
# Good
with DaemonOrchestrator() as daemon:
    daemon.start()
    # ... run episodes ...
# Automatically calls stop() on exit

# Bad
daemon = DaemonOrchestrator()
daemon.start()
# ... run episodes ...
# Forgot to call stop()!
```

### 2. Monitor Health Status

```python
import time

while daemon.running:
    status = daemon.get_status()
    if status['health_status'] != 'healthy':
        daemon.logger.warning(f"Unhealthy status: {status['health_status']}")
        # Take corrective action
    time.sleep(60)
```

### 3. Regular Checkpoints

```python
# Save checkpoint before major operations
daemon.save_checkpoint("/backup/pre_experiment_checkpoint.json")

# Restore if something goes wrong
try:
    risky_operation()
except Exception as e:
    daemon.logger.error(f"Operation failed: {e}")
    daemon.load_checkpoint("/backup/pre_experiment_checkpoint.json")
```

### 4. Log Rotation

```python
import logging
from logging.handlers import RotatingFileHandler

handler = RotatingFileHandler(
    'tiannara_core/logs/daemon.log',
    maxBytes=10*1024*1024,  # 10 MB
    backupCount=5
)
daemon.logger.addHandler(handler)
```

---

## Future Enhancements

Planned features for future releases:

- [ ] Distributed daemon coordination (multi-node)
- [ ] Web dashboard for real-time monitoring
- [ ] Plugin system for custom AutoDream operations
- [ ] Enhanced self-criticism with LLM integration
- [ ] Predictive health monitoring (ML-based anomaly detection)
- [ ] Remote checkpoint sync (S3, GCS)

---

## Support

For issues, questions, or contributions:

- **GitHub Issues**: https://github.com/Tiannara/MindCache-Prosthetic/issues
- **Documentation**: https://tiannara.readthedocs.io
- **Email**: support@tiannara.ai

---

**Version:** 1.0.0  
**Last Updated:** 2026-04-30  
**Author:** Tiannara Team
