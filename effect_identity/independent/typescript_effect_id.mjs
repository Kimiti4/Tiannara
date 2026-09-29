import { createHash } from "node:crypto";

const descriptor = {
  effect_schema_version: "effect-v1",
  principal: "human:amos",
  authority: { id: "omega-deployer", scope: "production" },
  authorization_scope: {
    resource_scope: "candidate",
    operation_scope: ["deploy"],
    parameter_constraints: {}
  },
  operation: "deploy",
  target: {
    namespace: "omega",
    resource_type: "candidate",
    resource_id: "cand-001",
    subresource: null
  },
  parameters: { mode: "supervised", replicas: 1 },
  intent: "deploy candidate",
  environment_scope: { type: "production", id: "prod-ke-1", region: "ke-central" },
  authority_epoch: "epoch-7",
  policy_version: "policy-42"
};

const expected = "a565edecfc000c7f6be7c3714183b21241f067e80305072fce77b6485a8e2a50";
const canonicalBytes = Buffer.from(JSON.stringify(descriptor, Object.keys(descriptor).sort()), "utf8");
// JSON.stringify's replacer-array is not recursive, so use a recursive renderer.
function canonical(value: unknown): string {
  if (value === null || typeof value === "boolean" || typeof value === "number" || typeof value === "string")
    return JSON.stringify(value);
  if (Array.isArray(value)) return "[" + value.map(canonical).join(",") + "]";
  if (typeof value === "object") {
    const entries = Object.entries(value as Record<string, unknown>).sort(([a], [b]) => Buffer.from(a).compare(Buffer.from(b)));
    return "{" + entries.map(([k, v]) => JSON.stringify(k) + ":" + canonical(v)).join(",") + "}";
  }
  throw new TypeError("unsupported value");
}
const bytes = Buffer.from(canonical(descriptor), "utf8");
const actual = createHash("sha256").update(Buffer.concat([Buffer.from("tiannara-effect-v1"), Buffer.from([0]), bytes])).digest("hex");
if (actual !== expected) throw new Error(`EffectID mismatch: ${actual}`);
console.log(bytes.toString("utf8"));
console.log(actual);
