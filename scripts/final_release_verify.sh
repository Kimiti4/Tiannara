#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== Tiannara Final Release Verification ==="
python3 scripts/final_release_verify.py || exit $?

echo
echo "=== Elixir checks (requires Elixir/OTP + dependencies) ==="
if command -v mix >/dev/null 2>&1; then
  mix format --check-formatted || exit $?
  mix test test/tiannara/os/research_engine_test.exs tiannara_runtime/test/world_scientific_closure_test.exs || exit $?
  mix test || exit $?
else
  echo "SKIPPED: mix/Elixir not installed"
fi

echo
echo "=== Python tests (requires configured environment) ==="
if command -v pytest >/dev/null 2>&1; then
  python3 -m pytest -q test_native_dialogue.py || exit $?
else
  echo "SKIPPED: pytest not installed"
fi

echo
echo "=== Observatory/SaaS build (requires Node dependencies) ==="
if command -v npm >/dev/null 2>&1; then
  if [ -d tiannara_observatory/apps/observatory_ui ]; then
    (cd tiannara_observatory/apps/observatory_ui && npm run build) || exit $?
  fi
  if [ -f tiannara_saas/package.json ]; then
    (cd tiannara_saas && npm run build) || exit $?
  fi
else
  echo "SKIPPED: npm not installed"
fi

echo
echo "ALL AVAILABLE RELEASE CHECKS COMPLETED."
