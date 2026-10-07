#!/usr/bin/env python3
"""Independent UAG-2F EffectID v1 renderer.

This implementation intentionally does not call Tiannara's Elixir canonicalizer.
It validates the frozen semantic descriptor, recursively sorts object keys, keeps
array order, and hashes the exact domain-separated UTF-8 JSON bytes.
"""
from __future__ import annotations
import hashlib
import json
import math
from typing import Any

VERSION = "effect-v1"
DOMAIN = b"tiannara-effect-v1\x00"
REQUIRED = (
    "effect_schema_version", "principal", "authority", "authorization_scope",
    "operation", "target", "parameters", "intent", "environment_scope",
    "authority_epoch", "policy_version",
)
TARGET_REQUIRED = ("namespace", "resource_type", "resource_id", "subresource")

def normalize(value: Any, field: str = "") -> Any:
    if value is None or isinstance(value, bool) or isinstance(value, int):
        return value
    if isinstance(value, float):
        if not math.isfinite(value):
            raise ValueError(f"non-finite number: {field}")
        return 0.0 if value == 0.0 else value
    if isinstance(value, str):
        value.encode("utf-8")
        return value
    if isinstance(value, list):
        return [normalize(v, field) for v in value]
    if isinstance(value, dict):
        out = {}
        for k, v in value.items():
            if not isinstance(k, str):
                raise ValueError(f"object key must be string: {field}")
            k.encode("utf-8")
            out[k] = normalize(v, f"{field}.{k}" if field else k)
        return {k: out[k] for k in sorted(out.keys(), key=lambda x: x.encode("utf-8"))}
    raise ValueError(f"unsupported value: {field}")

def canonical_bytes(descriptor: dict[str, Any]) -> bytes:
    if not isinstance(descriptor, dict):
        raise ValueError("descriptor must be object")
    missing = [k for k in REQUIRED if k not in descriptor]
    if missing:
        raise ValueError(f"missing fields: {missing}")
    if descriptor["effect_schema_version"] != VERSION:
        raise ValueError("unsupported schema version")
    for field in ("principal", "operation", "intent", "authority_epoch", "policy_version"):
        if not isinstance(descriptor[field], str):
            raise ValueError(f"{field} must be string")
        descriptor[field].encode("utf-8")
    if descriptor["operation"].strip() != descriptor["operation"] or not descriptor["operation"]:
        raise ValueError("invalid operation")
    if not isinstance(descriptor["target"], dict):
        raise ValueError("target must be object")
    missing_target = [k for k in TARGET_REQUIRED if k not in descriptor["target"]]
    if missing_target:
        raise ValueError(f"missing target fields: {missing_target}")
    normalized = normalize(descriptor)
    return json.dumps(
        normalized, ensure_ascii=False, separators=(",", ":"), sort_keys=True
    ).encode("utf-8")

def effect_id(descriptor: dict[str, Any]) -> str:
    return hashlib.sha256(DOMAIN + canonical_bytes(descriptor)).hexdigest()

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2:
        raise SystemExit("usage: effect_id.py <descriptor.json>")
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        descriptor = json.load(f)
    print(effect_id(descriptor))
