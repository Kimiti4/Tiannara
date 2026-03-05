# tiannara_pros/orchestrators/orchestrator_day28_fail_report.py

import argparse
from pathlib import Path

from tiannara_pros.analytics.run_metrics import compute_metrics


def main():
    ap = argparse.ArgumentParser(description="Day 28 failure reason report")
    ap.add_argument("--file", required=True, help="Path to packets.jsonl")
    args = ap.parse_args()

    m = compute_metrics(args.file)

    p = Path(m["path"]).resolve()
    run_folder = p.parent.name

    print("\n=== Day 28 Failure Report ===\n")
    print("Run folder:", run_folder)
    print("File:", m["path"])
    print("Packets:", m["totals"]["packets"])
    print("Success:", m["totals"]["success"])
    print("Fail:", m["totals"]["fail"])
    print("Success rate:", m["rates"]["success_rate"])

    print("\nFailure reasons:")
    reasons = m.get("failure_reasons", {}) or {}
    total_fail = max(1, m["totals"]["fail"])
    for r, c in sorted(reasons.items(), key=lambda x: (-x[1], x[0])):
        pct = round((c / total_fail) * 100, 2)
        print(f"  {r:>8}: {c:4d}  ({pct:5.2f}%)")

    print("\nBy intent (failures only):")
    by_intent_fail = (m.get("breakdown") or {}).get("by_intent_failures_only", {}) or {}
    for intent, c in sorted(by_intent_fail.items(), key=lambda x: (-x[1], x[0])):
        print(f"  {intent:>10}: {c}")

    print("\nBy mode (failures only):")
    by_mode_fail = (m.get("breakdown") or {}).get("by_mode_failures_only", {}) or {}
    for mode, c in sorted(by_mode_fail.items(), key=lambda x: (-x[1], x[0])):
        print(f"  {mode:>12}: {c}")

    print()


if __name__ == "__main__":
    main()