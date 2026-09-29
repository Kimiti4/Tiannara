import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";

const VERSION = "effect-v1";
const DOMAIN = Buffer.from("tiannara-effect-v1\0", "utf8");

function normalize(v: unknown): unknown {
  if (v === null || typeof v === "boolean" || typeof v === "string") return v;
  if (typeof v === "number") {
    if (!Number.isFinite(v)) throw new Error("non-finite number");
    return Object.is(v, -0) ? 0 : v;
  }
  if (Array.isArray(v)) return v.map(normalize);
  if (typeof v === "object") {
    const input = v as Record<string, unknown>;
    const out: Record<string, unknown> = {};
    for (const key of Object.keys(input).sort((a, b) =>
      Buffer.compare(Buffer.from(a, "utf8"), Buffer.from(b, "utf8"))
    )) out[key] = normalize(input[key]);
    return out;
  }
  throw new Error("unsupported value");
}

const descriptor = JSON.parse(readFileSync(process.argv[2], "utf8")) as Record<string, unknown>;
const required = [
  "effect_schema_version","principal","authority","authorization_scope",
  "operation","target","parameters","intent","environment_scope",
  "authority_epoch","policy_version"
];
for (const key of required) if (!(key in descriptor)) throw new Error(`missing field ${key}`);
if (descriptor.effect_schema_version !== VERSION) throw new Error("unsupported schema version");
for (const key of ["principal","operation","intent","authority_epoch","policy_version"]) {
  if (typeof descriptor[key] !== "string") throw new Error(`${key} must be string`);
}
if (typeof descriptor.operation === "string" &&
    (descriptor.operation.trim() !== descriptor.operation || descriptor.operation.length === 0))
  throw new Error("invalid operation");
if (typeof descriptor.target !== "object" || descriptor.target === null || Array.isArray(descriptor.target))
  throw new Error("target must be object");

const canonical = JSON.stringify(normalize(descriptor));
const digest = createHash("sha256").update(DOMAIN).update(Buffer.from(canonical, "utf8")).digest("hex");
console.log(digest);
