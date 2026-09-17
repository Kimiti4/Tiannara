# MC-002-A0 — Logic Verification Assessment

**Gate:** MC-002-A0 (Observational) — READ-ONLY

## Distinguishing verification claims from actual verification (A0.6)

| Claimed/nameable as | Real behavior | Verdict |
|---------------------|---------------|---------|
| `Tiannara.Foundations.FormalVerification.verify_invariants/2` | Returns `{:error, :formal_verification_unavailable}` | **UNAVAILABLE** (correctly, post-MC-001-M) |
| `Substrate.GCK.ContradictionDetector.detect/2` "scans Reality Graph for logical impossibilities" | Logger + hardcoded `push_event 0.99`; no input-derived computation | **THEATRICAL** (verification-in-name-only) |
| `Substrate.OSK.ContinuityAuditor` "cryptographically verifies continuous identity" | Logger + hardcoded metrics (`1.0`, `0.22`) | **THEATRICAL** |
| `Substrate.OPC.check_consistency/2` | scenario-keyword + Logger + hardcoded metric | **THEATRICAL** |
| `Substrate.HSV.verify_integration/2`, `OSE.verify_integration/2` | scenario-keyword + Logger | **THEATRICAL** |
| `Sentinel.Verification` (evidence link confidence/contradiction) | Real computation over `contradicts`/`supports` links, confidence from evidence counts/decay | **REAL** (but is evidence assessment, not a logic prover) |
| `Graph.Audit.has_cycle?/1` | Real DFS cycle detection | **REAL** |

## Capability-inflation findings

1. **Rule matching ≠ formal proof:** BeltSystem negation matcher is keyword substring matching presented as contradiction detection.
2. **Pattern/flag matching ≠ entailment:** `CTL.ParadoxResolver` reads boolean flags and calls it "paradox resolution".
3. **Heuristic scoring ≠ logical verification:** `ContradictionAnalyzer` estimates impact; it adds decision-weight to the discovery stream, but is not verification.
4. **Logger + metric emission ≠ verification:** substrate modules.

## Verification claim audit

The most important safety question for logic: *can any code path treat a broken or
absent logical verification as evidence of correctness?*

- **Fixed/silent false-success risk: `BeliefSystem`.** `are_direct_contradictions?/2` returns a Boolean from keyword matching, never raises, never signals "unsupported". Consumers (`api.ex:39,71`) cannot distinguish a real contradiction verdict from a broken heuristic verdict. This is the closest logical analogue to the pre-MC-001-M `mock:true` hazard, and unlike `registry.ex:118` it fails **silently** with a wrong answer rather than crashing.
- **Fail-loud risk: `constitution/registry.ex:118`.** `Audit.find_contradictions(g)` will raise `UndefinedFunctionError`; this is safe-ish (no silent wrongness) but crashes a governance probe.

## Verification layer maturity

- No proof objects, no proof checker, no SAT/SMT, no theorem prover anywhere in `lib/`.
- What exists is **evidence-based verification** (Sentinel) and **graph-structural verification** (Graph.Audit) — both real and sound within their bounds, but NOT logical/proof verification.
- Test inventory: `test/tiannara/contradiction/engine_test.exs` exercises `Engine`; `test/tiannara/asc/reality/audit_test.exs` + `test/tiannara/asc/c_missions/verification_test.exs` exist. A passing test of a theatrical implementation is noted: `osc`/substrate tests would pass while theatrical.