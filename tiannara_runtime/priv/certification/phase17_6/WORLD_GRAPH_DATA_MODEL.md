# Phase 17.6 — World Graph Data Model

## 1. Core Structs

### ComposedWorldModel

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| composition_id | String | computed | `cw_` + SHA-256 |
| name | String | yes | Composition name |
| parent_model_ids | [String.t()] | yes | Constituent model IDs |
| world_graph | WorldGraph.t() | yes | The composition graph |
| shared_variables | [SharedVariable.t()] | yes | Resolved shared variables |
| sync_rules | [SynchronizationRule.t()] | yes | Synchronization rules |
| interfaces | [DomainInterface.t()] | yes | Domain interfaces |
| evidence_roots | [String.t()] | no | Evidence lineage |
| replay_fingerprint | String | computed | `fp_` + SHA-256 |
| archaeology_root | String | no | Archaeology record |
| certificate | CompositionCertificate.t() | no | Certification |
| created_at | String | computed | ISO 8601 |

### DomainInterface

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| interface_id | String | computed | `di_` + SHA-256 |
| source_domain | String | yes | Source domain name |
| target_domain | String | yes | Target domain name |
| shared_variables | [String.t()] | yes | Variable names |
| direction | atom | yes | :bidirectional \| :source_to_target \| :target_to_source |
| constraints | [map()] | no | Interface constraints |
| priority | integer | no | Resolution priority (lower = higher) |
| description | String | no | Description |
| metadata | map() | no | Extra metadata |

### SharedVariable

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| variable_id | String | computed | `sv_` + SHA-256 |
| name | String | yes | Canonical variable name |
| domain_mappings | %{String.t() => String.t()} | yes | Domain → local name map |
| resolved_value | term() | no | Resolved value |
| conflict | boolean() | no | Whether conflict exists |
| resolution_strategy | atom() | no | :average \| :priority \| :custom |
| metadata | map() | no | Extra metadata |

### SynchronizationRule

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| rule_id | String | computed | `sr_` + SHA-256 |
| source_model | String | yes | Source model ID |
| target_model | String | yes | Target model ID |
| variable | String | yes | Shared variable name |
| mode | atom | yes | :discrete \| :continuous \| :event_driven |
| frequency | integer | no | Steps between syncs (discrete mode) |
| transform | map() | no | Optional value transform fn |
| metadata | map() | no | Extra metadata |

### WorldGraph

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| graph_id | String | computed | `wg_` + SHA-256 |
| nodes | [WorldNode.t()] | yes | Graph nodes |
| edges | [WorldEdge.t()] | yes | Graph edges |
| metadata | map() | no | Extra metadata |

### WorldNode

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| node_id | String | yes | Content-addressed node ID |
| type | atom | yes | :world_model \| :variable \| :equation \| :causal_graph \| :evidence \| :prediction \| :counterfactual |
| label | String | yes | Human-readable label |
| properties | map() | no | Node properties |
| metadata | map() | no | Extra metadata |

### WorldEdge

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| edge_id | String | computed | `we_` + SHA-256 |
| source_id | String | yes | Source node ID |
| target_id | String | yes | Target node ID |
| type | atom | yes | :dependency \| :causality \| :synchronization \| :composition \| :ownership |
| weight | float | no | Edge weight |
| metadata | map() | no | Extra metadata |

### CompositionEvidence

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| evidence_id | String | computed | `ce_` + SHA-256 |
| composition_id | String | yes | Parent composition ID |
| model_roots | [String.t()] | no | Constituent model evidence |
| interface_hashes | [String.t()] | no | Interface fingerprints |
| sync_hashes | [String.t()] | no | Sync rule fingerprints |
| math_verification | String | no | Math proof hash |
| replay_attempts | [map()] | no | Replay records |
| metadata | map() | no | Extra metadata |

### CompositionCertificate

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| certificate_id | String | computed | `cc_` + SHA-256 |
| composition_id | String | yes | Composed model ID |
| checks | [map()] | yes | Certification checks |
| overall | atom | yes | :pass \| :fail |
| issued_by | atom | yes | :composition_engine |
| issued_at | String | yes | ISO 8601 |

### InterfaceConstraint

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| constraint_id | String | computed | `ic_` + SHA-256 |
| interface_id | String | yes | Parent interface ID |
| type | atom | yes | :range \| :equality \| :inequality \| :custom |
| expression | String | yes | Constraint expression |
| metadata | map() | no | Extra metadata |

## 2. ID Prefixes

| Prefix | Struct |
|--------|--------|
| `cw_` | ComposedWorldModel |
| `di_` | DomainInterface |
| `sv_` | SharedVariable |
| `sr_` | SynchronizationRule |
| `wg_` | WorldGraph |
| `wn_` | WorldNode |
| `we_` | WorldEdge |
| `ce_` | CompositionEvidence |
| `cc_` | CompositionCertificate |
| `ic_` | InterfaceConstraint |
| `fp_` | Replay fingerprint |

## 3. Serialization Rules

- All structs implement `canonicalize/1` returning key-sorted map
- Nested structs canonicalized recursively
- Atoms stringified via `Atom.to_string/1`
- Lists sorted where order is semantically irrelevant
- ID computed via SHA-256 over canonical JSON
- Replay fingerprint excludes: composition_id, archaeology_root, created_at, metadata, replay_fingerprint, certificate
