import argparse
from pathlib import Path
from tiannara_pros.analytics.run_metrics import compute_metrics


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", required=True, help="Path to packets.jsonl")
    args = ap.parse_args()

    m = compute_metrics(args.file)

    p = Path(m["path"]).resolve()
    run_folder = p.parent.name

    print("\n=== Day 22 Run Report ===\n")
    print("Run folder:", run_folder)
    print("File:", m["path"])
    print("Packets:", m["totals"]["packets"])
    print("Success:", m["totals"]["success"])
    print("Fail:", m["totals"]["fail"])
    print("Success rate:", m["rates"]["success_rate"])
    print("Retries total:", m["retries"]["retries_used_total"])
    print("Retry exhausted:", m["retries"]["retry_exhausted_count"])

    print("\nInitial feedback (attempt 0):")
    print("Packets with initial:", m["initial"]["packets_with_initial_feedback"])
    print("Initial ok:", m["initial"]["ok_count"])
    print("Initial missing ok:", m["initial"]["missing_ok_count"])
    print("Initial success:", m["initial"]["success"])
    print("Initial fail:", m["initial"]["fail"])
    print("Initial success rate:", m["initial"]["success_rate"])

    print("\nAvg metrics:", m["avg_feedback_metrics"])

    print("\nBy intent:")
    for intent, d in sorted(m["breakdown"]["by_intent"].items()):
        print(
            f"  {intent:>10}  total={d['total']:3d}  success={d['success']:3d}  fail={d['fail']:3d}"
        )

    print("\nBy mode:")
    for mode, d in sorted(m["breakdown"]["by_mode"].items()):
        print(
            f"  {mode:>12}  total={d['total']:3d}  success={d['success']:3d}  fail={d['fail']:3d}"
        )

    print()


if __name__ == "__main__":
    main()