use sha2::{Digest, Sha256};
use serde_json::{Map, Value};
use std::{env, fs};

const VERSION: &str = "effect-v1";
const DOMAIN: &[u8] = b"tiannara-effect-v1\0";

fn normalize(v: Value) -> Result<Value, String> {
    match v {
        Value::Null | Value::Bool(_) | Value::Number(_) | Value::String(_) => Ok(v),
        Value::Array(xs) => xs.into_iter().map(normalize).collect::<Result<Vec<_>,_>>().map(Value::Array),
        Value::Object(obj) => {
            let mut out = Map::new();
            for (k, v) in obj {
                out.insert(k, normalize(v)?);
            }
            Ok(Value::Object(out))
        }
    }
}

fn main() {
    let path = env::args().nth(1).expect("usage: renderer <descriptor.json>");
    let raw = fs::read_to_string(path).expect("read descriptor");
    let input: Value = serde_json::from_str(&raw).expect("valid JSON");
    let obj = input.as_object().expect("descriptor object");

    let required = [
        "effect_schema_version","principal","authority","authorization_scope",
        "operation","target","parameters","intent","environment_scope",
        "authority_epoch","policy_version"
    ];
    for key in required {
        assert!(obj.contains_key(key), "missing field {key}");
    }
    assert_eq!(obj["effect_schema_version"], VERSION);
    for key in ["principal","operation","intent","authority_epoch","policy_version"] {
        assert!(obj[key].is_string(), "{key} must be string");
    }
    assert!(obj["target"].is_object(), "target must be object");

    let normalized = normalize(input).expect("supported values");
    let bytes = serde_json::to_vec(&normalized).expect("canonical JSON");
    let mut h = Sha256::new();
    h.update(DOMAIN);
    h.update(&bytes);
    println!("{:x}", h.finalize());
}
