#!/usr/bin/env python3
"""UAG-2F independent Python EffectID v1 renderer.

This implementation intentionally does not import Tiannara's Elixir canonicalizer.
"""
import hashlib
import json
from pathlib import Path

DOMAIN = b"tiannara-effect-v1\x00"
EXPECTED = "a565edecfc000c7f6be7c3714183b21241f067e80305072fce77b6485a8e2a50"

DESCRIPTOR = {
    "effect_schema_version":"effect-v1",
    "principal":"human:amos",
    "authority":{"id":"omega-deployer","scope":"production"},
    "authorization_scope":{"resource_scope":"candidate","operation_scope":["deploy"],"parameter_constraints":{}},
    "operation":"deploy",
    "target":{"namespace":"omega","resource_type":"candidate","resource_id":"cand-001","subresource":None},
    "parameters":{"mode":"supervised","replicas":1},
    "intent":"deploy candidate",
    "environment_scope":{"type":"production","id":"prod-ke-1","region":"ke-central"},
    "authority_epoch":"epoch-7",
    "policy_version":"policy-42",
}

def canonical_bytes(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"), allow_nan=False).encode("utf-8")

def effect_id(value):
    return hashlib.sha256(DOMAIN + canonical_bytes(value)).hexdigest()

if __name__ == "__main__":
    encoded = canonical_bytes(DESCRIPTOR)
    actual = effect_id(DESCRIPTOR)
    assert actual == EXPECTED, (actual, EXPECTED)
    print(encoded.decode("utf-8"))
    print(actual)
