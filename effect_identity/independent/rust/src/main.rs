use serde_json::{json, Value};
use sha2::{Digest, Sha256};

const EXPECTED: &str = "a565edecfc000c7f6be7c3714183b21241f067e80305072fce77b6485a8e2a50";

fn canonical(v: &Value) -> String {
    match v {
        Value::Null | Value::Bool(_) | Value::Number(_) | Value::String(_) => serde_json::to_string(v).unwrap(),
        Value::Array(items) => format!("[{}]", items.iter().map(canonical).collect::<Vec<_>>().join(",")),
        Value::Object(map) => {
            let mut entries: Vec<_> = map.iter().collect();
            entries.sort_by(|(a,_),(b,_)| a.as_bytes().cmp(b.as_bytes()));
            let body = entries.iter()
                .map(|(k,v)| format!("{}:{}", serde_json::to_string(k).unwrap(), canonical(v)))
                .collect::<Vec<_>>().join(",");
            format!("{{{}}}", body)
        }
    }
}

fn main() {
    let descriptor = json!({
      "effect_schema_version":"effect-v1",
      "principal":"human:amos",
      "authority":{"id":"omega-deployer","scope":"production"},
      "authorization_scope":{"resource_scope":"candidate","operation_scope":["deploy"],"parameter_constraints":{}},
      "operation":"deploy",
      "target":{"namespace":"omega","resource_type":"candidate","resource_id":"cand-001","subresource":null},
      "parameters":{"mode":"supervised","replicas":1},
      "intent":"deploy candidate",
      "environment_scope":{"type":"production","id":"prod-ke-1","region":"ke-central"},
      "authority_epoch":"epoch-7",
      "policy_version":"policy-42"
    });
    let bytes = canonical(&descriptor).into_bytes();
    let mut input = b"tiannara-effect-v1".to_vec();
    input.push(0);
    input.extend_from_slice(&bytes);
    let digest = Sha256::digest(&input);
    let actual = hex::encode(digest);
    assert_eq!(actual, EXPECTED);
    println!("{}", String::from_utf8(bytes).unwrap());
    println!("{}", actual);
}
