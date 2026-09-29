#!/usr/bin/env python3
"""UAG-2F cross-runtime conformance runner.

Python is an independent reference implementation for this runner. The frozen
expected digest is the oracle. Rust and TypeScript must independently reproduce it.
"""
from __future__ import annotations
import json, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "effect_identity/fixtures/effect_id_v1.json"
DESCRIPTOR = ROOT / "effect_identity/fixtures/effect_id_v1_descriptor.json"
EXPECTED = "a565edecfc000c7f6be7c3714183b21241f067e80305072fce77b6485a8e2a50"

def run(cmd, cwd=ROOT):
    p = subprocess.run(cmd, cwd=cwd, text=True, capture_output=True)
    if p.returncode:
        raise RuntimeError(f"command failed: {' '.join(cmd)}\n{p.stdout}\n{p.stderr}")
    return p.stdout.strip().splitlines()[-1]

def main():
    fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))
    positive = fixture["positive"][0]
    DESCRIPTOR.write_text(json.dumps(positive["descriptor"], ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    py = run([sys.executable, "effect_identity/renderers/python/effect_id.py", str(DESCRIPTOR)])
    assert py == EXPECTED, ("python mismatch", py, EXPECTED)

    rust = run(["cargo", "run", "--quiet", "--manifest-path",
                "effect_identity/renderers/rust/Cargo.toml", "--", str(DESCRIPTOR)])
    assert rust == EXPECTED, ("rust mismatch", rust, EXPECTED)

    ts = run(["npx", "--yes", "tsx", "effect_identity/renderers/typescript/effect_id.ts", str(DESCRIPTOR)])
    assert ts == EXPECTED, ("typescript mismatch", ts, EXPECTED)

    for vector in fixture["negative"]:
        altered = dict(positive["descriptor"])
        altered[vector["field"]] = vector["value"]
        tmp = DESCRIPTOR.with_name(f".negative-{vector['id']}.json")
        tmp.write_text(json.dumps(altered, ensure_ascii=False), encoding="utf-8")
        try:
            value = run([sys.executable, "effect_identity/renderers/python/effect_id.py", str(tmp)])
            if value == EXPECTED:
                raise AssertionError(f"negative vector collapsed: {vector['id']}")
        finally:
            tmp.unlink(missing_ok=True)

    print("UAG-2F CROSS-RUNTIME PASS: Python/Rust/TypeScript parity + negative semantic vectors")

if __name__ == "__main__":
    main()
