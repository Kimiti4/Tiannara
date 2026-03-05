# tiannara_pros/orchestrators/orchestrator_day27_replay_cli.py

import argparse
import json
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional


def _iter_packets(path: Path) -> Iterable[Dict[str, Any]]:
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                continue


def _is_success(pkt: Dict[str, Any]) -> bool:
    fb = pkt.get("feedback") or {}
    return bool(fb.get("ok")) and bool(fb.get("success"))


def _fault_injected(pkt: Dict[str, Any]) -> bool:
    safety = pkt.get("safety") or {}
    # tolerate multiple formats
    if bool(safety.get("fault_injected")):
        return True
    if safety.get("fault_injection") is True:
        return True
    if isinstance(safety.get("faults"), list) and len(safety.get("faults")) > 0:
        return True
    if safety.get("fault_type"):
        return True
    return False


def _step(pkt: Dict[str, Any]) -> Optional[int]:
    ctx = pkt.get("context") or {}
    try:
        return int(ctx.get("step"))
    except Exception:
        return None


def main():
    ap = argparse.ArgumentParser(description="Replay packets.jsonl with filters")
    ap.add_argument("--file", required=True, help="Path to packets.jsonl")
    ap.add_argument("--only-failures", action="store_true", help="Replay only success=false packets")
    ap.add_argument("--only-faults", action="store_true", help="Replay only fault-injected packets")
    ap.add_argument("--step-min", type=int, default=None, help="Minimum step (inclusive)")
    ap.add_argument("--step-max", type=int, default=None, help="Maximum step (inclusive)")
    ap.add_argument("--limit", type=int, default=None, help="Max packets to print")
    args = ap.parse_args()

    p = Path(args.file).expanduser().resolve()
    if not p.exists():
        raise SystemExit(f"File not found: {p}")

    printed = 0
    for pkt in _iter_packets(p):
        s = _step(pkt)
        if args.step_min is not None and (s is None or s < args.step_min):
            continue
        if args.step_max is not None and (s is None or s > args.step_max):
            continue

        if args.only_failures and _is_success(pkt):
            continue
        if args.only_faults and not _fault_injected(pkt):
            continue

        cmd = pkt.get("command") or {}
        dec = pkt.get("decision") or {}
        fb = pkt.get("feedback") or {}
        metrics = fb.get("metrics") or {}

        print(
            f"Step {s} | ctx={(pkt.get('context') or {}).get('tags')} | "
            f"decision={dec.get('intent')} conf={dec.get('confidence')} | "
            f"cmd.intent={cmd.get('intent')} | success={fb.get('success')} | "
            f"fault={_fault_injected(pkt)} metrics={metrics}"
        )

        printed += 1
        if args.limit is not None and printed >= args.limit:
            break

    if printed == 0:
        print("No packets matched your filters.")


if __name__ == "__main__":
    main()