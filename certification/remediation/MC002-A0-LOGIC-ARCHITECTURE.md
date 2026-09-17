# MC-002-A0 — Logic Architecture Assessment

**Gate:** MC-002-A0 (Observational) — READ-ONLY

## Answers to the A0.11 questions, with evidence

1. **Is there a canonical logic substrate?** NO. No `lib/tiannara/logic/` namespace, no `Tiannara.Logic` module (`TIANNARA_LOGIC_ARCHAEOLOGY.md:14`; inventory confirms NO).

2. **Are logical primitives centralized?** NO. Contradiction detection is distributed across ≥5 sites with diverging semantics:
   - `contradiction/engine.ex:38` (value conflicts)
   - `sentinel/verification.ex:307` (evidence links)
   - `epistemic/debugger.ex:123` (node-state filter)
   - `discovery/contradiction_analyzer.ex` (classification/ranking)
   - `core/world_model/belief_system.ex:284` (broken negation matcher)

3. **Multiple competing implementations?** YES — see above; also 2 conflict resolvers (`world/conflict_resolver.ex`, `stabilization/ocm/conflict_resolver.ex`) and multiple invariant aggregators with differing failure semantics (first-fail vs collect-all).

4. **Logical operations mixed into domain modules?** YES — e.g. `CTL.ParadoxResolver` (`ctl/paradox_resolver.ex`), constitutional probes (`constitution/registry.ex:118`), substrate sandboxes (`substrate/*.ex`).

5. **Symbolic representation layer?** NO.

6. **Inference layer?** NO dedicated one.

7. **Proof layer?** NO.

8. **Verification layer?** PARTIAL — `Sentinel.Verification` (`sentinel/verification.ex`) is a real verification subsystem (evidence links, confidence) but it is not a logic substrate; it computes from evidence, not logical entailment.

9. **Composable capabilities?** NO — each site uses its own claim/evidence/record shapes; no shared contract.

10. **Explicit interfaces?** NO common interface; `Graph.Behaviour` exists for graphs (REAL) but no logic behaviour exists.

11. **Unavailable capabilities represented honestly?** PARTIAL — MC-001 math unavailability is honest (`formal_verification.ex:4-6`). Logical unavailable layers (proof/SAT/SMT/theorem proving) are simply ABSENT (not represented). Theatrical substrate modules return `:ok`/metric payloads as if successful — NOT honest.

12. **Components independently replaceable?** PARTIAL — sound sites (Engine, Sentinel, Debugger) are separable; theatrical sites would need decommission; the broken BeliefSystem path is entangled with Loop B API.

## Architectural conclusion

The substrate is **distributed, duplicated, partially theatrical, partially broken,
with no canonical interface and no probe-independent honesty for absent layers.**
A canonical 6-function kernel (as the archaeology prescribes) is the minimal
cohesive next step — but that is a MUTATION recommendation (L4), NOT performed here.

## Placement invariant (from archaeology §4)

Logic sits **ABOVE Math**: consumes scored claims from the Math/Probability layer,
never computes its own confidences. Enforced at mutation time by compile-time dep check.