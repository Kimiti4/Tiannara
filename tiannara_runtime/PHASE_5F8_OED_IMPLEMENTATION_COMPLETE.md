# Phase 5F.8 OED Implementation Complete

Phase 5F.8 turns Procedural Decoy Ontologies from static traps into a supervised adversarial containment layer.

## Implemented Runtime Modules

- `Tiannara.Runtime.OED.Supervisor`
  - Owns the Phase 5F.8 supervision boundary.
- `Tiannara.Runtime.OED.ISRD`
  - Detects inter-sandbox entropy resonance.
  - Records recent resonance events.
- `Tiannara.Runtime.OED.OED`
  - Computes escape pressure from CSI and resonance.
  - Tracks active resonance tunnel arbitration state.
- `Tiannara.Runtime.OED.Adversarial.CSI`
  - Scores the full Compiler Suspicion Index vector.
- `Tiannara.Runtime.OED.Lattice.ELF`
  - Registers PDOs as semi-real counterfactual manifold nodes.
  - Tracks phase-offset interference edges.
- `Tiannara.Runtime.OED.Lattice.EntropicLoadBalancer`
  - Routes high truth-pressure into higher-dimensional PDO branches.
  - Registers those branches back into the ELF lattice.

## Kernel Integration

`Tiannara.Runtime.Kernel` now supervises `Tiannara.Runtime.OED.Supervisor`, making ISRD, OED, ELF, and the entropic load balancer part of the core runtime substrate.

## Behavioral Surface

Phase 5F.8 now supports:

- inter-sandbox resonance tunneling detection,
- Compiler Suspicion Index measurement,
- coordinated escape pressure scoring,
- resonance tunnel arbitration,
- PDO lattice registration,
- entropic load routing into semi-real counterfactual branches.

## Tests

Coverage was added in:

- `test/tiannara/runtime/oed/oed_test.exs`

The tests validate resonance detection, CSI scoring, ELF registration, PDO pressure routing, and escape profile arbitration.
