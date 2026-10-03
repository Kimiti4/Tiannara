#!/usr/bin/env python3
"""UAG-2F cross-runtime conformance runner.

Drives every runtime renderer over the frozen 117-vector corpus, validates
each runtime's output against the corpus expectations, and asserts byte
parity across all runtime legs.

Line format:
  <id>|<hash_a>|<hash_b>   both sides rendered
  <id>|ERROR               at least one side failed to render

Expectation semantics (frozen fixture contract):
  error      descriptor_a must render, descriptor_b must fail
  same       both sides render with identical EffectIDs
  different  both sides render with different EffectIDs, or at least one
             side fails to render (an errored side can never be equal)

Leg selection: --legs python,typescript,rust,elixir or UAG2F_LEGS env var.
Per-leg command override: UAG2F_CMD_<LEG> (e.g. UAG2F_CMD_RUST="docker run ...").
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
import re
import shlex
import subprocess
import sys
import time
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "effect_identity" / "fixtures" / "effect_id_v1.json"
LINE_RE = re.compile(r"^(E-\d{3})\|(.*)$")
HASH_RE = re.compile(r"^[0-9a-f]{64}$")
LEG_ORDER = ["python", "typescript", "rust", "elixir"]
TAXONOMY = {
    "basic_positive": 7, "lifecycle_exclusion": 2, "retry": 7,
    "semantic_non_equivalence": 15, "null_absent_default": 6,
    "numeric_semantics": 10, "unicode": 6, "collection_semantics": 9,
    "principal_authority": 8, "operation_target": 8,
    "environment_epoch_policy": 8, "schema_evolution": 5,
    "invalid_unsupported": 10, "binding_forgery": 10, "recovery": 6,
}


class ConformanceError(RuntimeError):
    pass


def default_leg_commands() -> dict[str, tuple[list[str], Path]]:
    return {
        "python": ([sys.executable, str(ROOT / "effect_identity/independent/python_effect_id.py")], ROOT),
        "typescript": (["node", str(ROOT / "effect_identity/independent/typescript_effect_id.mjs")], ROOT),
        "rust": (["cargo", "run", "--quiet", "--manifest-path",
                  str(ROOT / "effect_identity/independent/rust/Cargo.toml")], ROOT),
        "elixir": (["mix", "run", "--no-start",
                    str(ROOT / "effect_identity/conformance/elixir_driver.exs")],
                   ROOT / "tiannara_runtime"),
    }


def resolve_legs(cli_legs: str | None) -> list[str]:
    raw = cli_legs or os.environ.get("UAG2F_LEGS") or ",".join(LEG_ORDER)
    legs = [x.strip() for x in raw.split(",") if x.strip()]
    unknown = [x for x in legs if x not in LEG_ORDER]
    if unknown:
        raise ConformanceError(f"unknown legs: {unknown} (valid: {LEG_ORDER})")
    if not legs:
        raise ConformanceError("no legs selected")
    return legs


def run_leg(name: str, cmd: list[str], cwd: Path) -> tuple[str, dict]:
    started = time.time()
    try:
        proc = subprocess.run(cmd, cwd=str(cwd), text=True, capture_output=True, timeout=900)
    except FileNotFoundError as exc:
        raise ConformanceError(f"leg {name}: tool not found: {exc}") from exc
    duration = round(time.time() - started, 3)
    if proc.returncode != 0:
        tail = (proc.stderr or proc.stdout or "").strip().splitlines()[-12:]
        raise ConformanceError(
            f"leg {name}: exited {proc.returncode}\n  " + "\n  ".join(tail))
    lines = [ln for ln in proc.stdout.splitlines() if LINE_RE.match(ln)]
    meta = {
        "cmd": cmd,
        "cwd": str(cwd),
        "exit_code": 0,
        "duration_s": duration,
        "output_lines": len(lines),
        "output_sha256": hashlib.sha256("\n".join(lines).encode("utf-8")).hexdigest(),
        "error_vectors": sum(1 for ln in lines if ln.endswith("|ERROR")),
    }
    return "\n".join(lines), meta


def validate_lines(leg: str, lines: str, vectors: list[dict]) -> None:
    parsed = lines.splitlines()
    if len(parsed) != len(vectors):
        raise ConformanceError(
            f"leg {leg}: expected {len(vectors)} lines, got {len(parsed)}")
    for line, vec in zip(parsed, vectors):
        m = LINE_RE.match(line)
        if not m:
            raise ConformanceError(f"leg {leg}: malformed line: {line!r}")
        vid, payload = m.group(1), m.group(2)
        if vid != vec["id"]:
            raise ConformanceError(
                f"leg {leg}: line order mismatch: expected {vec['id']}, got {vid}")
        expect = vec["expect"]
        if payload == "ERROR":
            if expect == "same":
                raise ConformanceError(
                    f"leg {leg}: {vid}: 'same' vector must render both sides")
            continue
        parts = payload.split("|")
        if len(parts) != 2 or not all(HASH_RE.match(p) for p in parts):
            raise ConformanceError(f"leg {leg}: malformed hashes: {line!r}")
        a, b = parts
        if expect == "error":
            raise ConformanceError(
                f"leg {leg}: {vid}: 'error' vector must emit ERROR (got hashes)")
        if expect == "same" and a != b:
            raise ConformanceError(f"leg {leg}: {vid}: expected same")
        if expect == "different" and a == b:
            raise ConformanceError(f"leg {leg}: {vid}: expected different")


def validate_taxonomy(fixture: dict) -> dict:
    counts = Counter(v["category"] for v in fixture["vectors"])
    if dict(counts) != TAXONOMY:
        raise ConformanceError(f"taxonomy mismatch: {dict(counts)}")
    if fixture["count"] != 117 or len(fixture["vectors"]) != 117:
        raise ConformanceError("fixture count is not 117")
    return dict(counts)


def main() -> int:
    parser = argparse.ArgumentParser(description="UAG-2F cross-runtime conformance runner")
    parser.add_argument("--legs", default=None,
                        help="comma-separated subset of: python,typescript,rust,elixir")
    parser.add_argument("--evidence", default=None,
                        help="write a machine-readable evidence JSON to this path")
    args = parser.parse_args()

    fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))
    vectors = fixture["vectors"]
    taxonomy = validate_taxonomy(fixture)
    fixture_sha = hashlib.sha256(FIXTURE.read_bytes()).hexdigest()

    legs = resolve_legs(args.legs)
    commands = default_leg_commands()

    outputs: dict[str, str] = {}
    evidence_legs: dict[str, dict] = {}
    for leg in legs:
        cmd, cwd = commands[leg]
        override = os.environ.get(f"UAG2F_CMD_{leg.upper()}")
        if override:
            cmd = shlex.split(override)
        out, meta = run_leg(leg, cmd, cwd)
        validate_lines(leg, out, vectors)
        outputs[leg] = out
        evidence_legs[leg] = meta
        print(f"[ok] {leg:10s} lines={meta['output_lines']:3d} "
              f"errors={meta['error_vectors']:2d} sha256={meta['output_sha256'][:16]}… "
              f"({meta['duration_s']}s)")

    reference = legs[0]
    for leg in legs[1:]:
        if outputs[leg] != outputs[reference]:
            a = outputs[reference].splitlines()
            b = outputs[leg].splitlines()
            for i, (x, y) in enumerate(zip(a, b)):
                if x != y:
                    raise ConformanceError(
                        f"byte parity failure {reference} vs {leg} at vector {i}:\n"
                        f"  {reference}: {x}\n  {leg}: {y}")
            raise ConformanceError(
                f"byte parity failure {reference} vs {leg}: line counts differ")
        print(f"[ok] parity {reference} == {leg}")

    evidence = {
        "schema": "uag2f-cross-runtime-matrix-v1",
        "timestamp_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "fixture": {
            "path": str(FIXTURE.relative_to(ROOT)),
            "sha256": fixture_sha,
            "count": fixture["count"],
            "expected_base_effect_id": fixture["expected_base_effect_id"],
            "taxonomy": taxonomy,
        },
        "legs": evidence_legs,
        "parity": {"reference": reference, "legs": legs, "identical": True},
        "environment": {
            "platform": platform.platform(),
            "python": platform.python_version(),
        },
    }
    if args.evidence:
        path = Path(args.evidence)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n",
                        encoding="utf-8")
        print(f"[ok] evidence written: {path}")

    print(f"UAG-2F CROSS-RUNTIME PASS: {len(legs)} leg(s), 117 vectors, byte parity")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except ConformanceError as exc:
        print(f"UAG-2F CROSS-RUNTIME FAIL: {exc}", file=sys.stderr)
        sys.exit(1)
