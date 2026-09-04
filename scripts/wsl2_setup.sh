#!/usr/bin/env bash

# ------------------------------------------------------------
# Tiannara WSL2 Setup Script
# ------------------------------------------------------------
# This script automates the recommended WSL2 workflow:
#   1. Verify the script is running inside WSL2 Linux filesystem
#   2. Ensure required tools (elixir, mix, hex, rebar) are installed
#   3. Install missing tools automatically
#   4. Fetch project dependencies
#   5. Clean previous Windows build artifacts
#   6. Compile the project
#   7. Display a success message with next steps
# ------------------------------------------------------------

set -euo pipefail

# Helper functions ------------------------------------------------
log() {
  echo -e "\e[32m[INFO]\e[0m $*"
}

error() {
  echo -e "\e[31m[ERROR]\e[0m $*" >&2
  exit 1
}

# 1. Verify we are NOT on a /mnt/c path (Linux-native location)
if [[ "$PWD" == /mnt/* ]]; then
  error "You appear to be running inside a Windows-mounted path.\n\n  Please copy the project to the Linux filesystem (e.g., ~/projects/tiannara) and re-run this script.\n\n  Current directory: $PWD"
fi

log "Running in Linux-native directory: $PWD"

# 2. Verify Elixir installation
if ! command -v elixir >/dev/null 2>&1; then
  log "Elixir not found. Installing Elixir and Erlang..."
  sudo apt-get update -y
  sudo apt-get install -y elixir erlang-dev erlang-parsetools
else
  log "Elixir version: $(elixir --version | head -n1)"
fi

# 3. Ensure Hex and Rebar are available
if ! mix help hex >/dev/null 2>&1; then
  log "Installing Hex..."
  mix local.hex --force
fi

if ! mix help rebar >/dev/null 2>&1; then
  log "Installing Rebar..."
  mix local.rebar --force
fi

# 4. Fetch project dependencies
log "Fetching Mix dependencies..."
mix deps.get

# 5. Clean any Windows build artifacts
if [ -d "_build" ]; then
  log "Removing stale Windows build artifacts..."
  rm -rf _build
fi

# 6. Compile the project
log "Compiling Tiannara project (this may take a few minutes)..."
mix compile

log "\n✅ Tiannara project compiled successfully!\n"

# 7. Final instructions
cat <<'EOF'

=== Next Steps ===

1️⃣ Run the Evolution Alpha 2 campaign (Phase 5):
   mix run scripts/evolution_alpha_2.exs

2️⃣ For regular development, keep using the Linux-native copy:
   cd ~/projects/tiannara   # adjust if you placed it elsewhere

3️️⃣ If you edit code from Windows (VS Code), the changes are instantly
   visible inside WSL2 via the \\wsl$ share.

Happy hacking! 🚀

EOF
