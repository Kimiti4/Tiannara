use serde_json::{json, Map, Value};
use sha2::{Digest, Sha256};
use std::{fs, path::PathBuf};

const REQUIRED:[&str;11]=["effect_schema_version","principal","authority","authorization_scope","operation","target","parameters","intent","environment_scope","authority_epoch","policy_version"];
const DOMAIN:&[u8]=b"tiannara-effect-v1\0";

fn validate(v:&Value)->Result<(),String>{
    match v {
        Value::Null|Value::Bool(_)|Value::String(_)=>Ok(()),
        Value::Number(n)=>if n.is_i64()||n.is_u64(){Ok(())}else{Err("native_float_forbidden".into())},
        Value::Array(xs)=>{for x in xs{validate(x)?;}Ok(())},
        Value::Object(m)=>{
            if m.contains_key("$number"){
                if m.len()!=1 || !m.get("$number").and_then(Value::as_str).map(|s| regex_ok(s)).unwrap_or(false){return Err("invalid_numeric_token".into())}
                return Ok(())
            }
            if m.contains_key("$collection"){
                let kind=m.get("$collection").and_then(Value::as_str).unwrap_or("");
                let items=m.get("items").and_then(Value::as_array).ok_or("invalid_collection")?;
                if m.len()!=2 || !matches!(kind,"set"|"multiset"){return Err("invalid_collection".into())}
                for x in items{validate(x)?;} return Ok(())
            }
            for (k,x) in m{if k.is_empty(){return Err("invalid_key".into())}validate(x)?;} Ok(())
        }
    }
}
fn regex_ok(s:&str)->bool{
    if let Some(x)=s.strip_prefix("int:"){return integer_ok(x)}
    if let Some(x)=s.strip_prefix("decimal:"){
        let mut p=x.split('.');
        return p.next().map(integer_ok).unwrap_or(false)&&p.next().map(|q|!q.is_empty()&&q.chars().all(|c|c.is_ascii_digit())).unwrap_or(false)&&p.next().is_none()
    } false
}
fn integer_ok(s:&str)->bool{
    let x=s.strip_prefix('-').unwrap_or(s);
    !x.is_empty() && (x=="0" || (x.as_bytes()[0] != b'0' && x.chars().all(|c|c.is_ascii_digit())))
}
fn project(d:&Value)->Result<Value,String>{
    let o=d.as_object().ok_or("descriptor")?;
    for k in REQUIRED{if !o.contains_key(k){return Err(format!("missing_{k}"));}}
    if o["effect_schema_version"]!="effect-v1"{return Err("schema".into())}
    for k in ["principal","intent","authority_epoch","policy_version"]{if !o[k].is_string(){return Err(format!("text_{k}"));}}
    let op=o["operation"].as_str().ok_or("operation")?;
    if op.is_empty()||op.trim()!=op{return Err("operation".into())}
    for k in ["authority","authorization_scope","environment_scope"]{if !o[k].is_object(){return Err(format!("object_{k}"));}}
    let target=o["target"].as_object().ok_or("target")?;
    for k in ["namespace","resource_type","resource_id","subresource"]{if !target.contains_key(k){return Err(format!("target_{k}"));}}
    validate(&o["authority"])?;validate(&o["authorization_scope"])?;validate(&o["target"])?;validate(&o["parameters"])?;validate(&o["environment_scope"])?;
    let mut out=Map::new(); for k in REQUIRED{out.insert(k.to_string(),o[k].clone());} Ok(Value::Object(out))
}
fn canonical(v:&Value)->String{
    match v{
        Value::Null=>"null".into(),
        Value::Bool(b)=>if *b{"true".into()}else{"false".into()},
        Value::Number(n)=>n.to_string(),
        Value::String(s)=>serde_json::to_string(s).unwrap(),
        Value::Array(xs)=>format!("[{}]",xs.iter().map(canonical).collect::<Vec<_>>().join(",")),
        Value::Object(m)=>{
            if let (Some(Value::String(kind)),Some(Value::Array(items)))=(m.get("$collection").cloned(),m.get("items").cloned()){
                if m.len()==2 && (kind=="set"||kind=="multiset"){
                    let mut cs=items.iter().map(canonical).collect::<Vec<_>>();cs.sort();
                    if kind=="set"{cs.dedup();}
                    return format!("{{\"$collection\":{},\"items\":[{}]}}",serde_json::to_string(&kind).unwrap(),cs.join(","));
                }
            }
            let mut keys=m.keys().collect::<Vec<_>>();keys.sort_by(|a,b|a.as_bytes().cmp(b.as_bytes()));
            format!("{{{}}}",keys.iter().map(|k|format!("{}:{}",serde_json::to_string(k).unwrap(),canonical(m.get(*k).unwrap()))).collect::<Vec<_>>().join(","))
        }
    }
}
fn effect_id(d:&Value)->Result<String,String>{
    let p=project(d)?;let bytes=canonical(&p).into_bytes();let mut input=DOMAIN.to_vec();input.extend_from_slice(&bytes);Ok(hex::encode(Sha256::digest(input)))
}
fn main(){
    let path=PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../fixtures/effect_id_v1.json");
    let fixture:Value=serde_json::from_str(&fs::read_to_string(path).unwrap()).unwrap();
    assert_eq!(fixture["count"],117);
    let vectors=fixture["vectors"].as_array().unwrap();
    assert_eq!(effect_id(&vectors[0]["descriptor_a"]).unwrap(),fixture["expected_base_effect_id"].as_str().unwrap());
    let mut lines=Vec::new();
    for v in vectors{
        let a=effect_id(&v["descriptor_a"]);let b=effect_id(&v["descriptor_b"]);
        if v["expect"]=="error"{assert!(a.is_err()||b.is_err());lines.push(format!("{}|ERROR",v["id"].as_str().unwrap()));continue}
        let ai=a.unwrap();let bi=b.unwrap();let observed=if ai==bi{"same"}else{"different"};assert_eq!(observed,v["expect"].as_str().unwrap(),"{}",v["id"]);lines.push(format!("{}|{}|{}",v["id"],ai,bi));
    }
    println!("{}",lines.join("\n"));
}
