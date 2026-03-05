# tiannara_pros/analytics/run_metrics.py

import json
from pathlib import Path
from collections import defaultdict
from typing import Any, Dict

from tiannara_pros.analytics.failure_reasons import classify_failure_reason


def _safe_num(x):
    try:
        return float(x)
    except Exception:
        return None


def compute_metrics(path: str) -> dict:
    p = Path(path)
    packets = []

    with p.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                packets.append(json.loads(line))
            except json.JSONDecodeError:
                continue

    totals = {"packets": len(packets), "success": 0, "fail": 0}

    retries_used_total = 0
    retry_exhausted_count = 0

    by_intent = defaultdict(lambda: {"total": 0, "success": 0, "fail": 0})
    by_mode = defaultdict(lambda: {"total": 0, "success": 0, "fail": 0})

    # failures-only breakdowns
    by_intent_failures_only = defaultdict(int)
    by_mode_failures_only = defaultdict(int)

    # average feedback metrics (FINAL feedback)
    metric_sums = defaultdict(float)
    metric_counts = defaultdict(int)

    # initial feedback stats
    initial_packets_seen = 0
    initial_ok_count = 0
    initial_missing_ok_count = 0
    initial_success = 0
    initial_fail = 0

    # failure reasons
    failure_reasons = defaultdict(int)

    for pkt in packets:
        cmd = pkt.get("command", {}) or {}
        dec = pkt.get("decision", {}) or {}
        safety = pkt.get("safety", {}) or {}

        intent = (cmd.get("intent") or dec.get("intent") or "unknown")
        mode = (cmd.get("mode") or "unknown")

        fb = pkt.get("feedback", {}) or {}
        ok = bool(fb.get("ok"))
        success = bool(fb.get("success")) if ok else False

        by_intent[intent]["total"] += 1
        by_mode[mode]["total"] += 1

        if success:
            totals["success"] += 1
            by_intent[intent]["success"] += 1
            by_mode[mode]["success"] += 1
        else:
            totals["fail"] += 1
            by_intent[intent]["fail"] += 1
            by_mode[mode]["fail"] += 1
            by_intent_failures_only[intent] += 1
            by_mode_failures_only[mode] += 1

            reason = classify_failure_reason(fb, cfg=None)
            failure_reasons[reason] += 1

        # retries
        retries_used = int(safety.get("retries_used", 0) or 0)
        retries_used_total += retries_used

        if bool(safety.get("retry_exhausted")):
            retry_exhausted_count += 1

        # feedback metrics averages (FINAL feedback)
        metrics = fb.get("metrics", {}) or {}
        for k, v in metrics.items():
            nv = _safe_num(v)
            if nv is None:
                continue
            metric_sums[k] += nv
            metric_counts[k] += 1

        # initial feedback (attempt 0)
        fb0 = pkt.get("feedback_initial", None)

        if isinstance(fb0, dict):
            initial_packets_seen += 1

            if "ok" in fb0:
                if bool(fb0.get("ok")):
                    initial_ok_count += 1
            else:
                initial_missing_ok_count += 1

            ok0 = fb0.get("ok", True)  # default True if missing
            succ0 = bool(fb0.get("success", False))

            if bool(ok0) and succ0:
                initial_success += 1
            else:
                initial_fail += 1

    avg_feedback_metrics = {}
    for k in sorted(metric_sums.keys()):
        c = metric_counts.get(k, 0)
        avg_feedback_metrics[k] = round(metric_sums[k] / c, 4) if c else None

    success_rate = round((totals["success"] / totals["packets"]) if totals["packets"] else 0.0, 4)

    initial_success_rate = round(
        (initial_success / initial_packets_seen) if initial_packets_seen else 0.0, 4
    )

    return {
        "path": str(p),
        "totals": totals,
        "rates": {"success_rate": success_rate},
        "initial": {
            "packets_with_initial_feedback": initial_packets_seen,
            "ok_count": initial_ok_count,
            "missing_ok_count": initial_missing_ok_count,
            "success": initial_success,
            "fail": initial_fail,
            "success_rate": initial_success_rate,
        },
        "retries": {
            "retries_used_total": retries_used_total,
            "retry_exhausted_count": retry_exhausted_count,
        },
        "avg_feedback_metrics": avg_feedback_metrics,
        "failure_reasons": dict(failure_reasons),
        "breakdown": {
            "by_intent": dict(by_intent),
            "by_mode": dict(by_mode),
            "by_intent_failures_only": dict(by_intent_failures_only),
            "by_mode_failures_only": dict(by_mode_failures_only),
        },
    }