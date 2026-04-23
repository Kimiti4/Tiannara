from __future__ import annotations

import statistics
from concurrent.futures import ThreadPoolExecutor
from multiprocessing import get_context

from .worker import run_worker


def run_distributed(meta_list, workers=4):
    configs = [dict(item) for item in meta_list or []]
    if not configs:
        return []

    worker_count = max(1, min(int(workers), len(configs)))
    backend = "serial"

    if worker_count == 1:
        results = [run_worker(config) for config in configs]
    else:
        try:
            ctx = get_context("spawn")
            with ctx.Pool(worker_count) as pool:
                results = pool.map(run_worker, configs)
            backend = "process"
        except Exception:
            with ThreadPoolExecutor(max_workers=worker_count) as executor:
                results = list(executor.map(run_worker, configs))
            backend = "thread"

    for result in results:
        result["execution_backend"] = backend

    return sorted(results, key=lambda item: item["score"], reverse=True)


def summarize_results(results):
    if not results:
        return {
            "worker_count": 0,
            "backend": "none",
            "best_score": 0.0,
            "avg_score": 0.0,
            "score_spread": 0.0,
            "genome_counts": {},
        }

    scores = [float(item.get("score", 0.0) or 0.0) for item in results]
    genome_counts = {}
    for item in results:
        genome_type = item.get("genome_type", "unknown")
        genome_counts[genome_type] = genome_counts.get(genome_type, 0) + 1

    return {
        "worker_count": len(results),
        "backend": results[0].get("execution_backend", "serial"),
        "best_score": round(max(scores), 4),
        "avg_score": round(statistics.fmean(scores), 4),
        "score_spread": round(max(scores) - min(scores), 4),
        "genome_counts": genome_counts,
    }
