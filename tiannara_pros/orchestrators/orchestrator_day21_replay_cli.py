# tiannara_pros/orchestrators/orchestrator_day21_replay_cli.py

import argparse
import json


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", required=True, help="packets.jsonl path")
    ap.add_argument("--head", type=int, default=0, help="print first N packets")
    ap.add_argument("--tail", type=int, default=0, help="print last N packets (simple buffer)")
    ap.add_argument("--only-failures", action="store_true", help="print only packets where feedback.success=false")
    ap.add_argument("--only-retry-exhausted", action="store_true", help="print only packets with safety.retry_exhausted=true")
    args = ap.parse_args()

    lines = []
    with open(args.file, "r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if line:
                lines.append(line)

    def is_fail(pkt):
        fb = pkt.get("feedback", {}) or {}
        return fb.get("ok") and (fb.get("success") is False)

    def is_retry_exhausted(pkt):
        safety = pkt.get("safety", {}) or {}
        return bool(safety.get("retry_exhausted"))

    selected = []
    for ln in lines:
        pkt = json.loads(ln)
        if args.only_failures and not is_fail(pkt):
            continue
        if args.only_retry_exhausted and not is_retry_exhausted(pkt):
            continue
        selected.append(pkt)

    if args.head > 0:
        selected = selected[: args.head]
    elif args.tail > 0:
        selected = selected[-args.tail :]

    for pkt in selected:
        step = pkt.get("context", {}).get("step")
        tags = pkt.get("context", {}).get("tags")
        cmd_intent = pkt.get("command", {}).get("intent")
        fb = pkt.get("feedback", {})
        success = fb.get("success")
        metrics = fb.get("metrics", {})
        print(f"step={step} tags={tags} intent={cmd_intent} success={success} metrics={metrics}")


if __name__ == "__main__":
    main()