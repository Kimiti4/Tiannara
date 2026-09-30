# Tiannara Systems Closure — World, ASC, CEL, Sentinel, CIS and Mathematics

## Executive finding
Tiannara has substantial real infrastructure, but the repository is not yet a fully autonomous scientific civilization. Several historical layers were theatrical or disconnected. This release pass converts a number of those surfaces to explicit unavailable/pending states and connects the canonical world lineage to genomes.

## World simulation
REAL infrastructure exists: WorldRegistry, per-world OTP supervision, WorldStateManager, CAL, CIS, memory, event processing, simulation loop, world forking and multi-world counterfactual models.
Previously, missing world components could silently return healthy-looking default CAL/CIS results. That is now fail-closed.
Previously, WorldForkEngine generated a child ID that did not necessarily match the ID created by WorldRegistry. This is fixed by canonical create_world_with_id/3.
WorldRegistry now persists a WorldGenome for every world and exposes parent/child lineage.

## World genomes
WorldGenome existed but was only partially connected to runtime. Child generation was hard-coded to one in the standalone constructor and fork state did not persist the genome.
Forking now inherits the parent genome, mutates it, sets the child world ID, increments the actual parent generation, and records parent_ids.
This establishes the intended parent→child sequence at the canonical runtime boundary. It still requires runtime tests to prove persistence across restart/replay.

## Scientific worlds
Tiannara can now invoke a canonical bounded scientific method through Tiannara.World.ScientificResearch.
Pipeline: domain capability check → mathematical consistency where premises exist → real domain simulation → domain validation → replication → evidence/defense record → epistemic status.
Supported outcomes include bounded_verified, replicated_unverified, inconclusive and explicit unavailable errors.
Formal proof is NOT yet universal. A structural verifier must not be called a theorem prover. Domains without real simulation/formal verification remain unavailable.

## Mathematics
Mathematics is genuinely used in bounded paths. Bayesian update is deterministic and the Physics pilot uses the real RK4 calculus implementation.
Constitutional Mathematics certification demonstrates a bounded evidence→math→governance→CEL path.
Mathematics is therefore an epistemic substrate in tested paths, but it is NOT yet the universal computational foundation of every domain. Many domains still lack real solvers, formal verification or live scientific execution.

## ASC and ToolForge
ASC and ToolForge must not operate as independent autonomous mutation authorities. This release adds Tiannara.CEL.Delegation as the governed ingress for ASC and ToolForge delegation.
ToolForge generated tools now explicitly return not_implemented rather than implemented-looking execution results.
ToolForge review requests are now pending review, not silently interpreted as approval.
Full CEL ServiceRegistry integration for every ASC/ToolForge capability remains a follow-up hardening step; the gateway is the immediate controlled boundary.

## Sentinel/CIS
Sentinel has real observation, anomaly detection, causal analysis, activation, research and cognition infrastructure.
However, the old ImmuneCoordinator used random shadow success and the EpistemicShadowGraph used fabricated fallback state and constant divergence. Those claims are removed.
Shadow validation now requires real providers; if they are unavailable, Sentinel performs no live mutation.
Passing shadow validation produces a pending CEL/C14 authorization rather than directly mutating live state.
CIS.validate_plan now checks evidence, provenance, authority, risk and contradictions instead of returning {:ok, plan} unconditionally.
One remaining major CIS task is integrating every runtime immune decision path into the same measured, governed policy surface.

## Hardcoded-theatre removal
Additional false-success surfaces were decommissioned:
- Agency Sandbox random experiment success
- TheoryEvolution unconditional validation
- ResearchEpisode fake completion
- Sentinel random immune intervention success
- Sentinel constant causal divergence
- world simulation healthy defaults when components are missing
- ToolForge generated implementation placeholders that claimed success

scripts/truth_surface_audit.py was added to continuously locate common theatrical indicators in production code.

## What remains genuinely unproven
1. Full production runtime execution across the complete Elixir/Python/Next stack.
2. Universal formal proof/theorem proving.
3. Universal multi-domain scientific simulation.
4. End-to-end world research automatically producing a new theorem/discovery and independently defending it.
5. Full restart/replay persistence of world genomes and lineage.
6. Complete CEL admission coverage for every consequential ASC, ToolForge, world and Sentinel operation.
7. Complete CIS integration across all legacy/runtime immune paths.
8. Removal/classification of every historical theatrical module; many are intentionally retained as certification fixtures and experiments.

## Design conclusion
The intended intelligence loop is now clearer:
Observation → epistemic assessment → mathematical/domain reasoning → hypothesis → simulation → replication → adversarial challenge → verification/proof when available → provenance → CEL admission → memory → calibration → proactive dialogue.
CEL governs authority and effects. Mathematics provides formal quantitative reasoning where supported. Domains provide specialized models and experiments. Worlds provide persistent evolving environments. ASC provides civilizational capability evolution. ToolForge provides governed tool construction. Sentinel observes and challenges. CIS constrains and protects. None of these components may fabricate successful cognition when the underlying capability is absent.