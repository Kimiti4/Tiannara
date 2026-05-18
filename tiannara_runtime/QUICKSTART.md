# Quick Start Guide - Tiannara Runtime Phase 1

## 🚀 Get Running in 5 Minutes

### Step 1: Install Elixir

**Windows:**
```powershell
# Using Chocolatey (recommended)
choco install elixir

# Or download installer from https://elixir-lang.org/install.html
```

**macOS:**
```bash
brew install elixir
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install elixir erlang-dev erlang-parsetools
```

### Step 2: Verify Installation

```bash
elixir --version
# Should output: Elixir 1.14.x or higher

mix --version
# Should output: Mix 1.14.x or higher
```

### Step 3: Navigate to Runtime Directory

```bash
cd c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic\tiannara_runtime
```

### Step 4: Install Dependencies

```bash
mix deps.get
```

This will download:
- Phoenix framework (for API and real-time signaling)
- Phoenix LiveView (for ecological dashboard)
- Jason (JSON encoding/decoding)
- Req (HTTP client)

### Step 5: Start the Cognitive Ecology

```bash
mix run --no-halt
```

**Expected Output:**
```
🧠 Tiannara Runtime - Cognitive Ecology Starting...
✅ NATS Connected: nats://localhost:4222
🧬 Identity identity_1 born in lineage lineage_founding_1
🧬 Identity identity_2 born in lineage lineage_founding_2
🧬 Identity identity_3 born in lineage lineage_founding_3
🛡️ CIS Entropy Alert: unknown → healthy (H=0.682)
```

### Step 6: Interactive Mode (Optional)

For debugging and exploration:

```bash
iex -S mix
```

Then you can interact with the system:

```elixir
# Check entropy status
TiannaraRuntime.CIS.EntropyMonitor.get_entropy_status()

# Spawn a new identity
TiannaraRuntime.GRCC.EcologySupervisor.spawn_identity("test_identity", "test_lineage")

# Count active identities
TiannaraRuntime.GRCC.EcologySupervisor.count_identities()

# Check NATS connection status
TiannaraRuntime.NATS.ConnectionManager.get_status()
```

---

## 🔧 Configuration

### Environment Variables (Optional)

Create a `.env` file or export variables:

```bash
# NATS server URL (default: nats://localhost:4222)
export NATS_URL="nats://localhost:4222"

# Monitoring interval in milliseconds (default: 5000)
export ENTROPY_MONITOR_INTERVAL="5000"
```

On Windows PowerShell:
```powershell
$env:NATS_URL="nats://localhost:4222"
```

### Config Files

Main configuration: `config/config.exs`

Environment-specific configs (create as needed):
- `config/dev.exs` - Development settings
- `config/test.exs` - Test settings
- `config/prod.exs` - Production settings

---

## 🧪 Testing

### Run All Tests

```bash
mix test
```

### Run Specific Module Tests

```bash
# Test identity processes
mix test test/tiannara_runtime/grcc/identity_test.exs

# Test CIS entropy monitor
mix test test/tiannara_runtime/cis/entropy_monitor_test.exs

# Test NATS bridge
mix test test/tiannara_runtime/nats/bridge_test.exs
```

### Code Quality Checks

```bash
# Run Credo (code analysis)
mix credo

# Generate documentation
mix docs
```

---

## 📊 Monitoring

### View Logs

The runtime logs to console by default. To see detailed logs:

```bash
# Set log level to debug
export ELIXIR_LOG_LEVEL=debug
mix run --no-halt
```

### Health Checks

In IEx mode:

```elixir
# Check overall system health
%{
  entropy: TiannaraRuntime.CIS.EntropyMonitor.get_entropy_status(),
  identities: TiannaraRuntime.GRCC.EcologySupervisor.count_identities(),
  nats: TiannaraRuntime.NATS.ConnectionManager.get_status()
}
```

---

## 🐛 Troubleshooting

### Issue: "mix command not found"

**Solution:** Elixir not installed or not in PATH.
- Reinstall Elixir from https://elixir-lang.org/install.html
- Restart your terminal

### Issue: "Could not find Hex"

**Solution:** Update Hex package manager:
```bash
mix local.hex
mix deps.get
```

### Issue: "NATS Connection Failed"

**Solution:** This is expected in Phase 1 if NATS server isn't running.
- The system will continue operating with simulated NATS
- To run actual NATS: `docker run -p 4222:4222 nats:latest`

### Issue: Port conflicts

**Solution:** If Phoenix port 4000 is in use:
```elixir
# In config/dev.exs
config :tiannara_runtime, TiannaraRuntimeWeb.Endpoint,
  http: [port: 4001]  # Change to available port
```

---

## 🎯 What's Running?

When you start the runtime, these processes are active:

1. **SignalBus.Supervisor** - Phoenix PubSub for inter-process communication
2. **GRCC.EcologySupervisor** - Dynamic supervisor managing identity processes
3. **CIS.Supervisor** - Immune system monitoring ecological health
   - EntropyMonitor (checks diversity every 5 seconds)
   - DiversityRegulator (anti-monoculture pressure)
   - CollapseDetector (failure mode identification)
   - RecoveryOrchestrator (immune interventions)
4. **AEO.Supervisor** - Execution layer (stubbed in Phase 1)
5. **NATS.Supervisor** - Bridge to Python simulation layer
   - ConnectionManager (maintains NATS connection)
   - Publisher (Elixir → Python events)
   - Subscriber (Python → Elixir events)
6. **Interface.Supervisor** - API and monitoring (stubbed in Phase 1)

---

## 📚 Next Steps

After confirming Phase 1 foundation works:

1. **Read the full README**: `cat README.md`
2. **Review architecture**: See [elixir.md](../elixir.md)
3. **Explore code structure**: 
   ```bash
   tree lib/tiannara_runtime
   ```
4. **Run integration tests** (when available)
5. **Connect to Python simulation** (Phase 2)

---

## 💡 Tips

### Hot Code Reloading

One of BEAM's superpowers - you can update code without restarting:

```elixir
# In IEx, after modifying a file:
r(TiannaraRuntime.GRCC.Identity)
# Recompiles and reloads the module
```

### Process Inspection

See all running processes:

```elixir
# List all processes
Process.list() |> length()

# Find identity processes
:sys.get_state(TiannaraRuntime.GRCC.EcologySupervisor)
```

### Performance Profiling

```elixir
# Measure function execution time
:timer.tc(fn -> 
  TiannaraRuntime.CIS.EntropyMonitor.get_entropy_status()
end)
```

---

## 🆘 Getting Help

- **Documentation**: `mix docs` then open `doc/index.html`
- **Issues**: Check GitHub issues
- **Community**: Elixir Forum (https://elixirforum.com)
- **Architecture Questions**: Review [elixir.md](../elixir.md)

---

## ✅ Success Checklist

Before moving to Phase 2, verify:

- [ ] Elixir 1.14+ installed and working
- [ ] `mix deps.get` completes without errors
- [ ] `mix run --no-halt` starts successfully
- [ ] Entropy monitor reports HEALTHY status (H > 0.60)
- [ ] At least 3 identity processes spawned
- [ ] No crash loops or error messages
- [ ] Can interact via IEx (`iex -S mix`)

If all checks pass, you're ready for Phase 2: CIS Stabilization!
