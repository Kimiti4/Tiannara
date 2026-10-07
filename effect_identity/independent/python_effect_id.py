#!/usr/bin/env python3
"""UAG-2F independent Python renderer and fixture runner."""
import hashlib, json, re
from pathlib import Path

DOMAIN = b"tiannara-effect-v1\x00"
REQUIRED = ["effect_schema_version","principal","authority","authorization_scope","operation","target","parameters","intent","environment_scope","authority_epoch","policy_version"]
FIXTURE = Path(__file__).resolve().parents[1] / "fixtures" / "effect_id_v1.json"

def canonical(v):
    if isinstance(v, dict):
        if "$collection" in v and "items" in v and len(v) == 2 and v["$collection"] in ("set","multiset"):
            items = [canonical(x) for x in v["items"]]
            items.sort()
            if v["$collection"] == "set":
                dedup = []
                for item in items:
                    if not dedup or dedup[-1] != item:
                        dedup.append(item)
                items = dedup
            return '{"$collection":' + json.dumps(v["$collection"], ensure_ascii=False, separators=(",",":")) + ',"items":[' + ",".join(items) + ']}'
        return "{" + ",".join(json.dumps(k,ensure_ascii=False,separators=(",",":")) + ":" + canonical(v[k]) for k in sorted(v, key=lambda s: s.encode("utf-8"))) + "}"
    if isinstance(v, list):
        return "[" + ",".join(canonical(x) for x in v) + "]"
    if isinstance(v, bool):
        return "true" if v else "false"
    if v is None:
        return "null"
    if isinstance(v, int) and not isinstance(v, bool):
        return str(v)
    if isinstance(v, float):
        raise ValueError("native_float_forbidden")
    if isinstance(v, str):
        return json.dumps(v, ensure_ascii=False, separators=(",",":"))
    raise ValueError("unsupported_value")

def validate_value(v):
    if isinstance(v, dict):
        if "$number" in v:
            if set(v) != {"$number"} or not isinstance(v["$number"],str):
                raise ValueError("invalid_numeric_token")
            if not re.fullmatch(r"(?:int:-?(?:0|[1-9][0-9]*)|decimal:-?(?:0|[1-9][0-9]*)\.[0-9]+)", v["$number"]):
                raise ValueError("invalid_numeric_token")
            return
        if "$collection" in v:
            if set(v) != {"$collection","items"} or v["$collection"] not in ("set","multiset") or not isinstance(v["items"],list):
                raise ValueError("invalid_collection")
            for x in v["items"]: validate_value(x)
            return
        for k,x in v.items():
            if isinstance(k,str) and k.startswith("$"): raise ValueError("unsupported_special_key")
            if not isinstance(k,str): raise ValueError("invalid_key")
            validate_value(x)
        return
    if isinstance(v,list):
        for x in v: validate_value(x)
        return
    if isinstance(v,(str,int,bool)) or v is None: return
    raise ValueError("unsupported_value")

def project(d):
    if not isinstance(d,dict): raise ValueError("descriptor")
    for k in REQUIRED:
        if k not in d: raise ValueError("missing_"+k)
    if d["effect_schema_version"] != "effect-v1": raise ValueError("schema")
    for k in ("principal","intent","authority_epoch","policy_version"):
        if not isinstance(d[k],str): raise ValueError("text_"+k)
    if not isinstance(d["operation"],str) or not d["operation"] or d["operation"].strip()!=d["operation"]: raise ValueError("operation")
    for k in ("authority","authorization_scope","environment_scope"):
        if not isinstance(d[k],dict): raise ValueError("object_"+k)
    if not isinstance(d["target"],dict): raise ValueError("target")
    for k in ("namespace","resource_type","resource_id","subresource"):
        if k not in d["target"]: raise ValueError("target_"+k)
    validate_value(d["authority"]); validate_value(d["authorization_scope"]); validate_value(d["target"])
    validate_value(d["parameters"]); validate_value(d["intent"]); validate_value(d["environment_scope"])
    return {k:d[k] for k in REQUIRED}

def effect_id(d):
    b = canonical(project(d)).encode("utf-8")
    return hashlib.sha256(DOMAIN+b).hexdigest()

def main():
    fixture=json.loads(FIXTURE.read_text(encoding="utf-8"))
    assert fixture["count"] == len(fixture["vectors"]) == 117
    assert effect_id(fixture["vectors"][0]["descriptor_a"]) == fixture["expected_base_effect_id"]
    lines=[]
    for v in fixture["vectors"]:
        a=b=None
        try: a=effect_id(v["descriptor_a"])
        except Exception: a=None
        try: b=effect_id(v["descriptor_b"])
        except Exception: b=None
        expect=v["expect"]
        if expect=="error":
            if a is None: raise AssertionError(v["id"]+": error vector requires descriptor_a to render")
            if b is not None: raise AssertionError(v["id"]+": error vector requires descriptor_b to fail")
            lines.append(f'{v["id"]}|ERROR')
        elif expect=="same":
            if a is None or b is None: raise AssertionError(v["id"]+": same vector requires both sides to render")
            if a != b: raise AssertionError(f'{v["id"]}: expected same, got different')
            lines.append(f'{v["id"]}|{a}|{b}')
        else:
            if a is None or b is None:
                lines.append(f'{v["id"]}|ERROR')
            elif a == b:
                raise AssertionError(f'{v["id"]}: expected different, got same')
            else:
                lines.append(f'{v["id"]}|{a}|{b}')
    print("\n".join(lines))

if __name__ == "__main__": main()
