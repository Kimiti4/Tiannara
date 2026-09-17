# U1x Execution Protocol — Full Closed-Loop Certification

**Class:** CERTIFICATION (auth-free, contract-bound). No production mutation.
**Goal:** Prove the unified organism operates as ONE causally-closed executive loop.

## The loop under test
```text
C11 ingress → C1 perception → C2 reality → C3 knowledge → C4 epistemics
 → C5/C6 math+planning → C8 context → C14 governance
 → CEL-1 provider discovery (executive bridge)
 → C9 ASC → C12 homeostasis → C15 continuity → C11 egress (dry-run)
```

## Three claims U1x must prove
1. **Loop genuinely closed** — each phase's output is the causally-relevant input
   to the next (continuous `causal_parent` chain, no gaps, no shadow branches).
2. **CEL is the executive bridge** — the trace contains the CEL-1 `registry_query`
   and selected-provider evidence INSIDE the causal chain (not "subsystems happen
   to connect"). The strong claim: *"the executive dynamically discovers and
   governs the capability required to advance the mission."*
3. **Mathematics is a substrate capability** — `constitutional_mathematics` is
   discoverable via `CapabilityRegistry.find_provider` with the SAME architectural
   status as any other capability (no `CEL → math` special-case).

## Sub-tests
- **U1x-A (closed-loop core):** novel objective (descriptor `capability_engineering`)
  enters via C11, traverses the loop, CEL discovers ASC, governance gates, ASC acts,
  homeostasis monitors, continuity survives, traceable dry-run egress. REQUIRED for PASS.
- **U1x-B (math-as-substrate):** attempt CEL discovery of `constitutional_mathematics`.
  Reports `MATH_DISCOVERABLE` or `MATH_NOT_REGISTERED`. NOT a hard gate for the loop
  verdict — if not registered, it is the honest next gap feeding Constitutional Math v1.

## Acceptance criterion (verbatim intent)
> A novel objective enters through C11, traverses the unified cognitive substrate,
> causes CEL to discover the required capability dynamically, passes constitutional
> governance, produces an ASC action, is monitored by homeostasis, survives continuity
> validation, and produces a traceable egress — without hardcoded routing or
> fabricated evidence.

## Execution steps
1. Finalize contract hash: `python tools/hash_contract.py priv/tiannara/probes/contracts/U1x_closed_loop.contract.yaml`
2. Wire real module calls in `u1x_helpers.exs` at each `# WIRE:` marker (inspect repo; real paths only).
3. Run the Elixir driver: `mix run priv/tiannara/probes/u1x_helpers.exs` → emits `u1x_trace.json`.
4. Run the verifier: `python priv/tiannara/probes/U1x_closed_loop.py` → emits result + evidence.
5. Fill the five post-execution artifacts from REAL evidence (see protocol end).

## Division of labor
- **Human:** finalize hash, wire real paths, execute steps 3–4, report `u1x_result.json`.
- **Assistant:** interpret the reported evidence → verdict → next evolution step.

## Guardrails
- Do NOT convert PARTIAL/BLOCKED into a capability upgrade.
- On FAIL, record before rewriting; identify which edge broke
  (discovery / metadata / selection / dispatch / governance / continuity / egress).
- Egress is dry-run: any real external mutation requires a separate C14 action gate.
- No-pollution: loop must leave no stray DETS/archive artifacts.

## Post-execution artifacts (fill from real evidence, never pre-fill)
- `priv/tiannara/probes/results/U1x_closed_loop_result.json` (verifier output)
- `docs/probes/U1x_findings.md`
- `docs/probes/U1x_evidence_report.md`
- `docs/audit/U1x_capability_matrix_update.md`
- `docs/decisions/DEC-U1X-CLOSURE.md`
