import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";

const fixture=JSON.parse(readFileSync(new URL("../fixtures/effect_id_v1.json",import.meta.url),"utf8"));
const REQUIRED=["effect_schema_version","principal","authority","authorization_scope","operation","target","parameters","intent","environment_scope","authority_epoch","policy_version"];
const DOMAIN=Buffer.from("tiannara-effect-v1\0","utf8");
function validate(v){
  if(v===null||typeof v==="string"||typeof v==="boolean"||(typeof v==="number"&&Number.isInteger(v))) return;
  if(Array.isArray(v)){v.forEach(validate);return;}
  if(typeof v==="object"){
    if(Object.prototype.hasOwnProperty.call(v,"$number")){
      if(Object.keys(v).length!==1||typeof v.$number!=="string"||!/^(?:int:-?(?:0|[1-9][0-9]*)|decimal:-?(?:0|[1-9][0-9]*)\.[0-9]+)$/.test(v.$number)) throw new Error("invalid_numeric_token");
      return;
    }
    if(Object.prototype.hasOwnProperty.call(v,"$collection")){
      if(Object.keys(v).length!==2||!["set","multiset"].includes(v.$collection)||!Array.isArray(v.items)) throw new Error("invalid_collection");
      v.items.forEach(validate); return;
    }
    for(const [k,x] of Object.entries(v)){if(typeof k!=="string") throw new Error("invalid_key");validate(x);}
    return;
  }
  throw new Error("unsupported_value");
}
function project(d){
  if(!d||typeof d!=="object"||Array.isArray(d)) throw new Error("descriptor");
  for(const k of REQUIRED) if(!(k in d)) throw new Error("missing_"+k);
  if(d.effect_schema_version!=="effect-v1") throw new Error("schema");
  for(const k of ["principal","intent","authority_epoch","policy_version"]) if(typeof d[k]!=="string") throw new Error("text_"+k);
  if(typeof d.operation!=="string"||!d.operation||d.operation.trim()!==d.operation) throw new Error("operation");
  for(const k of ["authority","authorization_scope","environment_scope"]) if(!d[k]||typeof d[k]!=="object"||Array.isArray(d[k])) throw new Error("object_"+k);
  if(!d.target||typeof d.target!=="object"||Array.isArray(d.target)) throw new Error("target");
  for(const k of ["namespace","resource_type","resource_id","subresource"]) if(!(k in d.target)) throw new Error("target_"+k);
  validate(d.authority);validate(d.authorization_scope);validate(d.target);validate(d.parameters);validate(d.environment_scope);
  return Object.fromEntries(REQUIRED.map(k=>[k,d[k]]));
}
function canonical(v){
  if(v===null)return"null";
  if(typeof v==="boolean")return v?"true":"false";
  if(typeof v==="string")return JSON.stringify(v);
  if(typeof v==="number"){if(!Number.isInteger(v)||!Number.isFinite(v))throw new Error("native_float_forbidden");return String(v);}
  if(Array.isArray(v))return"["+v.map(canonical).join(",")+"]";
  if(typeof v==="object"){
    if("$collection"in v&&"items"in v&&Object.keys(v).length===2&&["set","multiset"].includes(v.$collection)){
      let items=v.items.map(canonical).sort();
      if(v.$collection==="set")items=[...new Set(items)];
      return JSON.stringify("$collection")+":"+JSON.stringify(v.$collection)+","+JSON.stringify("items")+":["+items.join(",")+"]";
    }
    return"{"+Object.keys(v).sort((a,b)=>Buffer.from(a).compare(Buffer.from(b))).map(k=>JSON.stringify(k)+":"+canonical(v[k])).join(",")+"}";
  }
  throw new Error("unsupported_value");
}
function id(d){const bytes=Buffer.from(canonical(project(d)),"utf8");return createHash("sha256").update(Buffer.concat([DOMAIN,bytes])).digest("hex");}
if(fixture.count!==117||fixture.vectors.length!==117)throw new Error("fixture_count");
if(id(fixture.vectors[0].descriptor_a)!==fixture.expected_base_effect_id)throw new Error("base_hash");
const lines=[];
for(const v of fixture.vectors){try{const a=id(v.descriptor_a),b=id(v.descriptor_b);if(v.expect==="error")throw new Error("expected_error");const observed=a===b?"same":"different";if(observed!==v.expect)throw new Error(v.id+" relation");lines.push(v.id+"|"+a+"|"+b);}catch(e){if(v.expect!=="error")throw e;lines.push(v.id+"|ERROR");}}
console.log(lines.join("\n"));
