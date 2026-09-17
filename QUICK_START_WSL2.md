# WSL2 Quick Start - Copy & Paste Instructions

## Option 1: Full Automated Setup (Recommended)

Copy this entire block and paste it into a **WSL2 terminal**:

```bash
# Step 1: Copy project to Linux filesystem
mkdir -p ~/projects && \
cp -r /mnt/c/Users/user/Tiannara/Tiannara-MindCache-Prosthetic ~/projects/tiannara && \
cd ~/projects/tiannara && \

# Step 2: Make script executable
chmod +x scripts/setup_and_test_wsl2.sh && \

# Step 3: Run automated setup and test
./scripts/setup_and_test_wsl2.sh
```

**That's it!** The script will:
- ✅ Verify you're in the right location
- ✅ Check/install Elixir if needed
- ✅ Install dependencies
- ✅ Compile the project (3-5 min)
- ✅ Run Phase 5 campaign (5-10 min)
- ✅ Analyze results and show metrics
- ✅ Save output to `phase5_wsl2_results.txt`

---

## Option 2: Manual Step-by-Step

If you prefer to run each step manually:

### Step 1: Open WSL2
```powershell
wsl
```

### Step 2: Copy Project
```bash
mkdir -p ~/projects
cp -r /mnt/c/Users/user/Tiannara/Tiannara-MindCache-Prosthetic ~/projects/tiannara
cd ~/projects/tiannara
```

### Step 3: Setup Environment
```bash
chmod +x scripts/wsl2_setup.sh
./scripts/wsl2_setup.sh
```

### Step 4: Run Campaign
```bash
mix run scripts/evolution_alpha_2.exs
```

---

## What to Expect

### During Compilation (3-5 minutes)
```
==> earmark_parser
Compiling 3 files (.erl)
Compiling 47 files (.ex)
Generated earmark_parser app
...
Generated tiannara app
```

### During Campaign (5-10 minutes)
```
🧬 EVOLUTION ALPHA 2 CAMPAIGN
...
📈 Adaptation Velocity tracker started (Phase 5.3)

🔄 Generation 1/20
🔍 [ReuseEngine] Classified failure: implementation:boundary:boundary_value
📚 [ReuseEngine] Found 3 semantically similar patterns
🌍 Cross-project transfer detected: web_app_001 → api_001
📤 Transfer recorded: web_app_001 → api_001 (SUCCESS)
✅ Pattern reuse SUCCESS
📈 [AdaptationVelocity] Generation 1:
   Composite Fitness: 35.50%
   Adaptation Velocity: 2.100% per generation
   ✅ System is IMPROVING (positive adaptation)
```

### At the End
```
📊 PHASE 5 CORE METRICS SUMMARY
----------------------------------------------------------------------

📈 Adaptation Velocity:
   Velocity: 1.850% per generation
   Trend: IMPROVING
   ✅ EXIT CRITERION MET - System is adapting!

🔄 Knowledge Reuse:
   Reuse Rate: 32.50%
   ✅ EXIT CRITERION MET (>10%)

🌍 Knowledge Transfer:
   Transfer Count: 15
   Transfer Success Rate: 66.67%
   ✅ EXIT CRITERION MET (>5% success rate)
```

---

## After Completion

### View Results
```bash
# See full output
cat phase5_wsl2_results.txt

# See just the summary
grep -A 40 'PHASE 5 CORE METRICS' phase5_wsl2_results.txt

# Check exit criteria
grep 'EXIT CRITERION' phase5_wsl2_results.txt
```

### Share Results with AI Assistant
Copy the output file content and share it for analysis:
```bash
# Copy to Windows clipboard (requires xclip)
cat phase5_wsl2_results.txt | xclip -selection clipboard

# Or just read it and copy-paste relevant sections
less phase5_wsl2_results.txt
```

---

## Troubleshooting

### "Permission denied" when running script
```bash
chmod +x scripts/setup_and_test_wsl2.sh
```

### "Elixir not found"
```bash
sudo apt update
sudo apt install elixir erlang-dev erlang-parsetools
```

### "mix.exs not found"
Make sure you're in the right directory:
```bash
cd ~/projects/tiannara
pwd  # Should show: /home/yourusername/projects/tiannara
```

### Compilation very slow
Check if you accidentally copied to `/mnt/c/`:
```bash
pwd
# Should NOT start with /mnt/c/
```

### Campaign fails
Check the error message in the output, then:
```bash
# Clean and retry
rm -rf _build deps
mix deps.get
mix compile
mix run scripts/evolution_alpha_2.exs
```

---

## Next Steps After Successful Run

1. **Share results** with AI assistant for analysis
2. **Review metrics** to see if Phase 5 exit criteria met
3. **If successful**: Proceed to Phase 6 (Law Discovery upgrades)
4. **If not**: Debug and iterate on repair strategies

Good luck! 🚀
