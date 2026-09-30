#!/usr/bin/env python3
"""Final release verification for the Tiannara truth boundary.

Run from repository root:
    python scripts/final_release_verify.py

This verifies source-level contracts without pretending to replace the full
Elixir/Node/Python integration suite. It exits non-zero on a violated contract.
"""
from pathlib import Path
import ast, re, sys

ROOT = Path(__file__).resolve().parents[1]
checks = []
def check(name, ok, detail=""):
    checks.append((name, bool(ok), detail))

# Python syntax for the native conversation/research gateway.
for rel in [
    "tiannara_core/conversation/native_dialogue.py",
    "tiannara_api/routes/chat.py",
]:
    p = ROOT / rel
    try:
        ast.parse(p.read_text(encoding="utf-8"))
        check(f"python syntax: {rel}", True)
    except Exception as exc:
        check(f"python syntax: {rel}", False, str(exc))

# Truth-boundary source checks.
targets = {
    "CIS plan validation": ROOT / "lib/tiannara/cis_constraint.ex",
    "Research program engine": ROOT / "lib/tiannara/os/research_program_engine.ex",
    "Evidence scorer": ROOT / "lib/tiannara/research/evidence_scorer.ex",
    "CEL kernel": ROOT / "lib/tiannara/cel/kernel.ex",
}
for name, p in targets.items():
    text = p.read_text(encoding="utf-8")
    check(name + " exists", p.exists())
    if "CIS plan validation" in name:
        check(name + " is not universal-pass", "{:ok, plan}" not in text)
    if "Research program engine" in name:
        check(name + " does not fabricate discovery", "evidence_score: 0.7" not in text and "outcome: :success" not in text)
    if "Evidence scorer" in name:
        check(name + " requires executed evidence", "execution_not_verified" in text and "missing_provenance" in text)
    if "CEL kernel" in name:
        check(name + " fails closed on score errors", "constitutional_score_unavailable" in text)

# UI must not contain the old fabricated headline metrics.
header = (ROOT / "tiannara_observatory/apps/observatory_ui/src/components/mission/DashboardHeader.tsx").read_text(encoding="utf-8")
check("Observatory header has no 99.7% claim", "99.7%" not in header)
check("Observatory header has no 99.99% claim", "99.99%" not in header)

print("\nTiannara final release verification\n" + "=" * 36)
failed = 0
for name, ok, detail in checks:
    print(("PASS" if ok else "FAIL").ljust(6), name, detail)
    failed += not ok
print(f"\n{len(checks)-failed}/{len(checks)} checks passed.")
if failed:
    sys.exit(1)
