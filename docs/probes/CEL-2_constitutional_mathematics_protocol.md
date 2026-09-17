# CEL-2 Protocol — Constitutional Mathematics as a Discoverable Capability

**Class:** Two-gate mission.
  - Gate R (CEL-2-REGISTER): C14-gated ACTION — register the capability.
  - Gate C (CEL-2-CERTIFY): auth-free CERTIFICATION — discover/govern/delegate.
**Dispositive question:** Can CEL discover, select, govern, and delegate to a real
constitutional mathematics provider from live registry state, WITHOUT hardcoding
the provider?

## Authorization boundary (the loop under test)
```text
objective → CapabilityRegistry registry_query → candidate_set
 → capability/interface/tool inspection → health + ownership + dependency
 → provider selection → C14 governance_gate → delegation
 → real mathematics operation → trace/evidence
```

## Two-gate sequence
1. **Negative control (before registration):** query `constitutional_mathematics`
   against the live 4-entry registry → must return `MATH_NOT_REGISTERED`.
   Proves honesty; proves no hardcoded fallback to `Tiannara.Math.*`.
2. **CEL-2-REGISTER (C14-gated):** register `constitutional_mathematics` exposing
   REAL existing math interfaces (from `math/*.ex`). Do NOT invent interfaces.
   Do NOT expand the math domain.
3. **Positive path (after registration):** query → discover → inspect → health →
   ownership → dependency → select → govern → delegate → real math op → result.

## 11 required assertions
| Check | Requirement |
|-------|-------------|
| MATH_DISCOVERABLE | Registry returns math capability from live registry |
| NO_HARDCODED_PROVIDER | Provider selected from registry result, not objective→module map |
| INTERFACE_DISCOVERY | Provider exposes declared mathematical interface/tool |
| HEALTH | Selected provider is actually healthy |
| OWNERSHIP | Registry identifies an actual owner |
| DEPENDENCY | Required dependencies are available |
| GOVERNANCE | C14 gate consulted before delegation |
| DELEGATION | CEL actually invokes the selected provider |
| RESULT | Real math operation produces structured, deterministic result |
| TRACE | registry_query→candidate_set→selection→governance→delegation is causal |
| HONESTY | Missing provider → MATH_NOT_REGISTERED, not fabricated success |

## Critical negative controls
- No provider → `MATH_NOT_REGISTERED` (never `→ Tiannara.Math.* → success`).
- Provider present but unhealthy → NO delegation.
- Governance DENY → delegation NOT_EXECUTED.

## Verdict semantics (bounded)
- **PASS:** all positive assertions AND negative control pass.
- **PARTIAL:** discovery works but the math provider/interface cannot complete the op.
- **FAIL:** CEL bypasses discovery, hardcodes provider, delegates without governance,
  or fabricates/accepts an invalid provider.
- **BLOCKED:** a genuine substrate prerequisite prevents execution.

## Division of labor
- **Human:** finalize hash; wire real paths; run negative; authorize+perform
  registration; run positive; report both results.
- **Assistant:** interpret reported evidence → verdict → next step.

## Post-CEL-2 language (binding — do not overclaim)
> CEL demonstrates registry-mediated capability discovery for the CERTIFIED
> providers; generalized runtime capability/interface/tool ingestion remains an
> architectural expansion. The 4→5-entry registry is still the known limitation.

## Guardrails
- Do NOT expand the math domain. Expose existing interfaces only.
- Do NOT invent interfaces to satisfy the probe.
- Do NOT convert PARTIAL/BLOCKED into a capability upgrade.
- Registration is C14-gated; certification is auth-free. Keep them separate.

## Post-execution artifacts (fill from REAL evidence, never pre-fill)
- results/CEL-2_constitutional_mathematics_result.json
- results/CEL-2_trace.json
- docs/probes/CEL-2_findings.md
- docs/probes/CEL-2_evidence_report.md
- docs/audit/U0_matrix_update.md
- docs/decisions/DEC-CEL-2-<PASS|PARTIAL|FAIL|BLOCKED>.md
