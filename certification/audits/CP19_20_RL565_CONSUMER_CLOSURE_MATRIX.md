# CP19.20 — RL-565 Consumer Closure Matrix

## Machine-authority consumers (Council trust root)

| Consumer | File | Status | Notes |
|----------|------|--------|-------|
| WorldMutationEngine | `lib/tiannara/world/world_mutation_engine.ex` | **Closed** | Migrated to `Council.decide/3` + `MachineAuthorization.mint/3` with explicit effect-descriptor scope; registry provenance verified at effect. |
| UnifiedWorldModel.delete_entity/2 | `lib/tiannara/world/unified_world_model.ex` | **Closed** | `MintRegistry.verify_council_presentation/3` (registry-anchored grant/decision/type/scope/effect); emergency gate enforced. |

## Direct `Council.authorize/3` callers (decision consumers, not machine-grant minters)

| Consumer | File | Status | Notes |
|----------|------|--------|-------|
| CEL.Kernel | `lib/tiannara/cel/kernel.ex` | Unresolved | Uses Council decision for CEL governance; does not mint machine grants. Disclosed; out of RL-565 machine-authority closure. |
| ResourceManager | `lib/tiannara/cel/services/resource_manager.ex` | Unresolved | Decision consumer only. |
| ExperimentOrchestrator | `lib/tiannara/phase4/experiment_orchestrator.ex` | Unresolved | Decision consumer only. |
| Forecasting.DecisionImpl | `lib/tiannara/forecasting/adapters/decision.ex` | Unresolved | Decision consumer only. |

These routes do not call `MachineAuthorization.mint/2` or `MintRegistry.record_mint/1` and are not machine-authority sources. They remain direct decision consumers and are disclosed as unresolved for full Council-decision closure.

## Human trust root (RL-564) consumers — unchanged

| Consumer | File | Status |
|----------|------|--------|
| HumanDelivery.Authorization | `lib/tiannara/omega/human_delivery/authorization.ex` | Unchanged (separate trust root) |
| ExecutionGovernance | `lib/tiannara/phase4/execution_governance.ex` | Unchanged + `:registry_corrupt` fail-closed |
| GovernedEffectSink | `lib/tiannara/omega/governed_effect_sink.ex` | Unchanged + `:registry_corrupt` fail-closed |
| DeploymentGateway | `lib/tiannara/omega/deployment_gateway.ex` | Unchanged + `:registry_corrupt` fail-closed |
| Verification.Baseline | `lib/tiannara/omega/verification/baseline.ex` | Unchanged (allowlisted human minter) |

## Conclusion
Machine-authority closure is complete for the two in-scope consumers (`WorldMutationEngine`, `UnifiedWorldModel.delete_entity/2`). Full Council-decision consumer closure is partial: four direct `Council.authorize/3` callers remain unresolved and are disclosed. RL-565 is not claimed fully closed on this basis; RL-564 and `F-ARC-018` remain `OPEN`.
