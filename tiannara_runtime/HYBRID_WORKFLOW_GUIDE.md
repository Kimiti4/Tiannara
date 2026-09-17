# Tiannara Runtime - Hybrid Development Workflow Guide

## 🎯 Overview

This guide establishes a **hybrid development workflow** where you:
- **Develop in WSL Ubuntu** (stable Elixir 1.18.3 + Erlang OTP 27)
- **Test in both WSL and Windows** (cross-platform validation)
- **Sync code via Git** (single source of truth)

---

## 📋 Prerequisites

### ✅ Already Installed:
- **WSL Ubuntu** with Elixir 1.18.3 + Erlang OTP 27
- **Windows PowerShell** with Elixir 1.18.2 (downgraded, needs reinstall)
- **Git** for version control
- **VS Code** with WSL extension (recommended)

### 🔧 To Fix:
- Windows Elixir installation (corrupted after downgrade)
- NATS server for testing (Docker)

---

## 🚀 Quick Start - WSL Development

### Step 1: Copy Project to WSL Filesystem

```bash
# In WSL Ubuntu terminal
cp -r /mnt/c/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/tiannara_runtime ~/tiannara_runtime
cd ~/tiannara_runtime
```

**Why?** Running Mix on Windows filesystem (`/mnt/c/...`) is slow due to cross-filesystem I/O. Native WSL filesystem is 5-10x faster.

### Step 2: Clean and Compile

```bash
# Remove old build artifacts
mix clean
rm -rf _build deps

# Install dependencies
mix deps.get

# Compile project
mix compile
```

Expected output:
```
Compiling 13 files (.ex)
Generated tiannara_runtime app
```

### Step 3: Start Interactive Runtime

```bash
iex -S mix
```

You should see:
```
Erlang/OTP 27 [erts-15.2.7.4] ...
Elixir 1.18.3 (compiled with Erlang/OTP 27)

Interactive Elixir (1.18.3) - press Ctrl+C to exit
iex(1)>
```

✅ **Success!** The runtime is running.

---

## 🔄 Hybrid Workflow - Daily Development

### Pattern 1: Develop in WSL, Commit, Test in Both

```bash
# 1. Make changes in WSL
cd ~/tiannara_runtime
# Edit files with VS Code or nano/vim

# 2. Compile and test in WSL
mix compile
mix test  # When tests exist

# 3. Commit changes
git add .
git commit -m "feat: add NATS event routing"
git push

# 4. Pull and test in Windows PowerShell
cd C:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic\tiannara_runtime
git pull
mix compile
iex -S mix
```

### Pattern 2: Real-Time Sync with VS Code WSL Extension

1. **Install VS Code WSL Extension**
   - Open VS Code
   - Extensions → Search "WSL" → Install "Remote - WSL"

2. **Open Project in WSL**
   ```bash
   # In WSL terminal
   code ~/tiannara_runtime
   ```
   This opens VS Code connected to WSL filesystem.

3. **Edit files directly** - Changes are saved to WSL instantly.

4. **Compile in WSL terminal** while editing in VS Code.

### Pattern 3: Cross-Platform Testing Matrix

| Test Type | WSL | Windows | Purpose |
|-----------|-----|---------|---------|
| Compilation | ✅ Fast | ⚠️ Slow | Verify syntax |
| Unit Tests | ✅ Primary | ✅ Validation | Catch bugs |
| Integration | ✅ Primary | ✅ Validation | End-to-end |
| Performance | ✅ Accurate | ⚠️ Slower | Benchmarking |
| Production | ✅ Deploy | ❌ Not used | Final target |

---

## 🐳 NATS Server Setup (Required for Testing)

### Option A: Docker (Recommended)

```bash
# Start NATS server in Docker
docker run -d --name nats-server -p 4222:4222 nats:latest

# Verify it's running
docker ps | grep nats

# Check logs
docker logs nats-server
```

### Option B: Native Installation

```bash
# Download NATS server
wget https://github.com/nats-io/nats-server/releases/download/v2.10.0/nats-server-v2.10.0-linux-amd64.tar.gz
tar -xzf nats-server-v2.10.0-linux-amd64.tar.gz
sudo mv nats-server-v2.10.0-linux-amd64/nats-server /usr/local/bin/

# Start NATS
nats-server -DV
```

---

## 🧪 Testing Workflow

### Phase 1: Compilation Tests (Immediate Feedback)

```bash
# WSL - Fast compilation
cd ~/tiannara_runtime
mix compile --force

# Should complete in <5 seconds on WSL filesystem
```

### Phase 2: Interactive Testing (Runtime Validation)

```bash
# Start IEx session
iex -S mix

# Test NATS modules
iex(1)> TiannaraRuntime.NATS.Publisher.publish("test.subject", %{data: "hello"})
📤 NATS Publish: test.subject

iex(2)> TiannaraRuntime.NATS.Connection.get_status()
%{connected: false, reconnect_attempts: 0, ...}
```

### Phase 3: Automated Tests (When Available)

```bash
# Run all tests
mix test

# Run specific test file
mix test test/nats/publisher_test.exs

# Run with coverage
mix test --cover
```

### Phase 4: Cross-Platform Validation

```bash
# 1. Test in WSL
cd ~/tiannara_runtime
mix test
# Record results

# 2. Test in Windows
cd /mnt/c/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/tiannara_runtime
mix test
# Compare results - should match!
```

---

## 🛠️ Common Tasks

### Task 1: Add New Module

```bash
# 1. Create file in WSL
cd ~/tiannara_runtime
mkdir -p lib/tiannara_runtime/new_module
touch lib/tiannara_runtime/new_module/component.ex

# 2. Edit in VS Code (WSL mode)
code lib/tiannara_runtime/new_module/component.ex

# 3. Compile
mix compile

# 4. Commit
git add .
git commit -m "feat: add new module component"
```

### Task 2: Update Dependencies

```bash
# WSL
cd ~/tiannara_runtime
mix deps.update gnat jason
mix deps.compile

# Commit lockfile changes
git add mix.lock
git commit -m "chore: update dependencies"
```

### Task 3: Debug Compilation Errors

```bash
# Clean build
mix clean
rm -rf _build

# Recompile with verbose output
mix compile --verbose

# Check for specific errors
mix compile 2>&1 | grep error
```

### Task 4: Profile Performance

```bash
# WSL - Accurate benchmarks
mix profile.fprof

# Compare with Windows (slower due to filesystem)
# Use WSL results as baseline
```

---

## 📊 Performance Comparison

| Operation | WSL (Native) | WSL (/mnt/c) | Windows |
|-----------|--------------|--------------|---------|
| `mix deps.get` | ~10s | ~30s | ~45s |
| `mix compile` | ~5s | ~25s | ~35s |
| `mix test` | ~8s | ~40s | ~50s |
| File I/O | Fast | Slow | Medium |
| Hot Reload | Instant | Delayed | Delayed |

**Recommendation:** Always develop on WSL native filesystem (`~/tiannara_runtime`), not `/mnt/c/...`.

---

## 🔧 Troubleshooting

### Issue 1: "beam.smp" Process Locked

**Symptom:** Can't compile, process already running.

**Fix:**
```bash
# Kill all BEAM processes
pkill -9 beam.smp
pkill -9 epmd

# Clean and recompile
mix clean
mix compile
```

### Issue 2: Hex Registry Timeout

**Symptom:** `mix deps.get` hangs or times out.

**Fix:**
```bash
# Clear Hex cache
rm -rf ~/.hex

# Force refresh
mix local.hex --force
mix deps.get
```

### Issue 3: Module Not Found After Git Pull

**Symptom:** Compilation fails with undefined module.

**Fix:**
```bash
# Clean everything
mix clean
rm -rf _build deps

# Reinstall and recompile
mix deps.get
mix compile --force
```

### Issue 4: Windows Line Endings (CRLF)

**Symptom:** Compilation errors on Windows but not WSL.

**Fix:**
```bash
# Configure Git to use LF
git config --global core.autocrlf input

# Convert existing files
find . -name "*.ex" -exec dos2unix {} \;
```

### Issue 5: NATS Connection Refused

**Symptom:** `NATS connection failed: connection refused`

**Fix:**
```bash
# Check if NATS is running
docker ps | grep nats

# Start if needed
docker start nats-server

# Or restart
docker restart nats-server
```

---

## 📝 Best Practices

### ✅ Do:
1. **Develop in WSL** - Faster compilation, stable toolchain
2. **Use native WSL filesystem** - `~/tiannara_runtime`, not `/mnt/c/...`
3. **Commit from WSL** - Single source of truth
4. **Test in both environments** - Catch platform-specific issues
5. **Use VS Code WSL extension** - Seamless editing experience
6. **Keep Git repo synced** - Pull before switching environments

### ❌ Don't:
1. **Edit same files in both simultaneously** - Causes conflicts
2. **Run Mix on `/mnt/c/...`** - Extremely slow
3. **Ignore compilation warnings** - Fix them early
4. **Skip cross-platform testing** - Bugs hide in differences
5. **Use Windows Elixir until fixed** - Currently corrupted

---

## 🎓 Learning Path

### Week 1: WSL Basics
- [ ] Copy project to WSL
- [ ] Compile successfully
- [ ] Start IEx session
- [ ] Run basic commands

### Week 2: Hybrid Workflow
- [ ] Set up VS Code WSL extension
- [ ] Practice edit-compile-test cycle
- [ ] Commit changes from WSL
- [ ] Pull and test in Windows

### Week 3: Advanced Testing
- [ ] Write unit tests
- [ ] Run cross-platform validation
- [ ] Profile performance
- [ ] Debug compilation issues

### Week 4: Production Prep
- [ ] Set up CI/CD pipeline
- [ ] Configure deployment scripts
- [ ] Document environment setup
- [ ] Create release builds

---

## 📚 Additional Resources

- [Elixir School](https://elixirschool.com/) - Comprehensive tutorials
- [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html) - Web framework docs
- [NATS Documentation](https://docs.nats.io/) - Event bus reference
- [OTP Design Principles](https://erlang.org/doc/design_principles/users_guide.html) - Supervision trees
- [WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/) - Microsoft guides

---

## 🚀 Next Steps

1. **Set up WSL development environment** (this guide)
2. **Fix Windows Elixir installation** (Admin PowerShell required)
3. **Start NATS server** (Docker recommended)
4. **Begin Phase 2 integration testing**
5. **Write first automated tests**

---

## 💡 Pro Tips

### Tip 1: Alias Common Commands

Add to `~/.bashrc` in WSL:

```bash
alias tr='cd ~/tiannara_runtime'
alias trc='cd ~/tiannara_runtime && mix compile'
alias tri='cd ~/tiannara_runtime && iex -S mix'
alias trt='cd ~/tiannara_runtime && mix test'
```

Then use:
```bash
tr    # Navigate to project
trc   # Compile
tri   # Start IEx
trt   # Run tests
```

### Tip 2: Auto-Reload in IEx

```elixir
# In IEx session
recompile()  # Reload changed modules without restarting
```

### Tip 3: Watch Mode for Development

```bash
# Install file_system watcher
mix deps.add file_system

# Auto-recompile on file changes
mix compile --watch
```

### Tip 4: Parallel Compilation

```bash
# Use all CPU cores
export ELIXIR_ERL_OPTIONS="+SMP auto"
mix compile --parallel
```

---

## 🎉 Success Metrics

You've mastered the hybrid workflow when you can:

- ✅ Switch between WSL and Windows seamlessly
- ✅ Compile in <10 seconds on WSL
- ✅ Debug issues across platforms
- ✅ Maintain single Git repository
- ✅ Test in both environments confidently
- ✅ Deploy from WSL to production

---

**Last Updated:** April 30, 2026  
**Maintained By:** Tiannara Development Team  
**Version:** 1.0
