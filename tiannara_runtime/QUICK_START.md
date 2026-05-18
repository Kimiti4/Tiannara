# Quick Start Guide - Tiannara Runtime Phase 1

## Prerequisites Installation

### 1. Install Elixir and Erlang/OTP

#### macOS
```bash
brew install elixir
```

#### Linux (Ubuntu/Debian)
```bash
# Add Erlang Solutions repository
wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
sudo dpkg -i erlang-solutions_2.0_all.deb
sudo apt-get update

# Install Elixir
sudo apt-get install elixir
```

#### Windows (via WSL2)
```bash
# Install WSL2 first, then in Ubuntu terminal:
sudo apt-get update
sudo apt-get install elixir
```

#### Verify Installation
```bash
elixir --version
# Should show: Elixir 1.14+ and Erlang/OTP 25+
```

---

### 2. Install NATS Server

#### Option A: Docker (Recommended)
```bash
docker run -d \
  --name nats-server \
  -p 4222:4222 \
  -p 8222:8222 \
  nats:latest \
  --jetstream
```

#### Option B: Direct Download
```bash
# macOS
brew install nats-server

# Linux
wget https://github.com/nats-io/nats-server/releases/download/v2.10.0/nats-server-v2.10.0-linux-amd64.tar.gz
tar xzf nats-server-v2.10.0-linux-amd64.tar.gz
sudo mv nats-server-v2.10.0-linux-amd64/nats-server /usr/local/bin/

# Start NATS
nats-server -js
```

#### Verify NATS
```bash
# Test connection
nats context save default --server nats://localhost:4222
nats server info
```

---

### 3. Install PostgreSQL (Optional for Phase 1)

```bash
# Docker
docker run -d \
  --name postgres \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=postgres \
  postgres:15

# Or native installation
brew install postgresql  # macOS
sudo apt-get install postgresql  # Ubuntu
```

---

## Running Tiannara Runtime

### Step 1: Navigate to Runtime Directory

```bash
cd c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic\tiannara_runtime
```

### Step 2: Install Dependencies

```bash
mix deps.get
```

This will download:
- `gnat` (NATS client)
- `phoenix` (Web framework)
- `jason` (JSON serialization)
- `telemetry` (Monitoring)
- And other dependencies

### Step 3: Compile

```bash
mix compile
```

### Step 4: Run with Interactive Console

```bash
iex -S mix
```

You should see output like:
```
Erlang/OTP 25 [erts-13.0] [source] [64-bit]

Interactive Elixir (1.14.0) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)>
```

### Step 5: Verify Components Started

In the IEx console, check that all supervisors started:

```elixir
# Check if Application supervisor is running
Supervisor.which_children(TiannaraRuntime.Supervisor)

# Should show:
# [
#   {:undefined, #PID<0.123.0>, :worker, [TiannaraRuntime.Telemetry]},
#   {:undefined, #PID<0.124.0>, :worker, [Phoenix.PubSub]},
#   {:undefined, #PID<0.125.0>, :supervisor, [TiannaraRuntime.NATS.Supervisor]},
#   {:undefined, #PID<0.126.0>, :supervisor, [TiannaraRuntime.GRCC.EcologySupervisor]},
#   {:undefined, #PID<0.127.0>, :supervisor, [TiannaraRuntime.CIS.Supervisor]},
#   {:undefined, #PID<0.128.0>, :supervisor, [TiannaraRuntime.AEO.Supervisor]},
#   {:undefined, #PID<0.129.0>, :worker, [TiannaraRuntimeWeb.Endpoint]}
# ]
```

---

## Testing the Runtime

### Test 1: Create an Identity Lineage

```elixir
# In IEx console
initial_genome = %{
  merge_bias: 0.5,
  contradiction_tolerance: 0.6,
  novelty_affinity: 0.7,
  topology_preference: 0.4,
  exploration_exploitation_balance: 0.5,
  stability_sensitivity: 0.6
}

# Start new identity
{:ok, pid} = TiannaraRuntime.GRCC.IdentityLineage.start_link(
  "test_identity_1",
  "test_lineage_1",
  initial_genome
)

# Get state
state = TiannaraRuntime.GRCC.IdentityLineage.get_state("test_identity_1")
IO.inspect(state)

# Update fitness
TiannaraRuntime.GRCC.IdentityLineage.update_fitness("test_identity_1", 0.85)

# Apply mutation
TiannaraRuntime.GRCC.IdentityLineage.apply_mutation("test_identity_1", 0.1)

# Calculate ecological fitness
fitness = TiannaraRuntime.GRCC.IdentityLineage.calculate_ecological_fitness(
  "test_identity_1",
  %{coherence: 0.30, niche_utility: 0.25, adaptation_success: 0.25, hybridization: 0.20}
)
IO.puts("Fitness: #{fitness}")
```

### Test 2: Check CIS Entropy Monitor

```elixir
# Get entropy monitor state
entropy_state = TiannaraRuntime.CIS.EntropyMonitor.get_state()
IO.inspect(entropy_state)

# Should show:
# %TiannaraRuntime.CIS.EntropyMonitor{
#   current_entropy: 0.0,  # Will be 0 if no identities registered yet
#   target_min: 0.60,
#   target_max: 0.75,
#   alerts_active: []
# }
```

### Test 3: Check NATS Connection Status

```elixir
# Get NATS connection status
status = TiannaraRuntime.NATS.Supervisor.get_connection_status()
IO.inspect(status)

# Should show:
# %{connected: true, url: "nats://localhost:4222", uptime: ...}
```

---

## Running Tests

```bash
mix test
```

This will run all unit tests for:
- Identity lineage process management
- CIS entropy monitoring
- NATS connection handling
- Phoenix channel broadcasting

---

## Production Deployment

### Build Release

```bash
MIX_ENV=prod mix release
```

This creates a self-contained release in `_build/prod/rel/tiannara_runtime/`.

### Run Release

```bash
_build/prod/rel/tiannara_runtime/bin/tiannara_runtime start
```

### Monitor Logs

```bash
tail -f _build/prod/rel/tiannara_runtime/var/log/erlang.log.1
```

---

## Integration with Python Layer

### Python Side Setup

Install NATS Python client:

```bash
pip install nats-py
```

### Example: Publish Ecological State from Python

```python
import asyncio
import nats
import json

async def main():
    # Connect to NATS
    nc = await nats.connect("nats://localhost:4222")
    
    # Publish ecological state
    await nc.publish("tiannara.ecological.state", json.dumps({
        "step": 500,
        "entropy": 0.74,
        "dominance": 1.0,
        "active_niches": 5,
        "identities": [
            {"id": "identity_1", "fitness": 0.85, "lineage": "lineage_1"},
            {"id": "identity_2", "fitness": 0.72, "lineage": "lineage_2"}
        ]
    }).encode())
    
    print("✅ Published ecological state to Elixir")
    
    # Subscribe to CIS interventions
    async def intervention_handler(msg):
        data = json.loads(msg.data.decode())
        print(f"🛡️  CIS Intervention: {data}")
    
    await nc.subscribe("tiannara.cis.intervention", cb=intervention_handler)
    
    # Keep running
    await asyncio.sleep(3600)
    await nc.close()

if __name__ == "__main__":
    asyncio.run(main())
```

### Elixir Side: Receive Python Events

The NATS Subscriber module (to be implemented) will:

```elixir
def handle_message("tiannara.ecological.state", payload) do
  # Parse Python ecological state
  # Update Elixir identity processes
  # Trigger CIS monitoring if needed
end
```

---

## Troubleshooting

### Issue: `mix: command not found`

**Solution:** Elixir not installed. Follow installation steps above.

### Issue: NATS connection refused

**Solution:** NATS server not running. Start it:
```bash
docker start nats-server
# or
nats-server -js
```

### Issue: Port conflicts (4222, 4000, 5432)

**Solution:** Change ports in configuration files:
- NATS: Use different port in `config/config.exs`
- Phoenix: Change port in `config/dev.exs`
- PostgreSQL: Use different port in Docker command

### Issue: Dependency compilation errors

**Solution:** Clean and rebuild:
```bash
mix deps.clean --all
mix deps.get
mix compile
```

---

## Next Steps

After verifying the runtime works:

1. **Complete remaining CIS components** (DiversityRegulator, CollapseDetector, RecoveryOrchestrator)
2. **Implement NATS Publisher/Subscriber** modules
3. **Create Python integration test** that publishes real GRCC v10 events
4. **Run hybrid test** with Python simulation + Elixir runtime simultaneously
5. **Measure performance improvements** vs. pure Python

---

## Resources

- [Elixir Getting Started](https://elixir-lang.org/getting-started/introduction.html)
- [OTP Design Principles](https://erlang.org/doc/design_principles/users_guide.html)
- [NATS Documentation](https://docs.nats.io/)
- [Phoenix Framework Guides](https://hexdocs.pm/phoenix/overview.html)
- [Phase 1 Summary](PHASE1_HYBRID_ARCHITECTURE_SUMMARY.md)

---

## Support

For issues or questions:
- Check [elixir.md](../elixir.md) for architectural context
- Review [GRCC v10 test results](../test_long_horizon_goal_integrity.py) for baseline metrics
- Consult OTP documentation for supervision patterns
