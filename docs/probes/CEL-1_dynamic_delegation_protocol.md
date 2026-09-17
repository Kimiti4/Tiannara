# CEL-1 Certification Protocol: Dynamic Delegation

## Objective
Prove the CEL Executive answers "Who can solve this?" dynamically, rather than 
"Which hardcoded subsystem handles this event?"

## The Litmus Test
If a developer adds a brand new capability to the registry with a novel tool 
signature, CEL must be able to route a matching objective to it *without* 
requiring a code change to the CEL Executive or Mission Director.

---

## Test 1: The Novel Objective (Positive Control)
**Action:** Submit a mission to the CEL Executive:
```elixir
%Mission{
  objective: "Analyze lineage and assess risk",
  required_tools: [:analyze_lineage, :assess_risk],
  payload: %{entity_id: "mem_fc71ac45db255750"}
}
```
**Expected Behavior:**
1. CEL queries `CapabilityRegistry.find_by_tools([:analyze_lineage, :assess_risk])`.
2. Registry returns `DiscoveryEngine` and `CollapsePredictor`.
3. CEL checks health: `DiscoveryEngine.health() == :healthy` (AE-010 verified), `CollapsePredictor` grounded (AE-005 verified).
4. CEL requests C14 authorization for the composed delegation.
5. CEL routes to Mission Director, which executes the sequence.
6. ExecutiveMemory records the causal trace.
**Fail Condition:** If CEL uses a hardcoded `case mission.objective do` block, or if it fails to compose the two capabilities dynamically.

## Test 2: The Missing Capability (Negative Control 1)
**Action:** Submit a mission requiring a tool that does not exist:
```elixir
%Mission{
  objective: "Calibrate physical sensor array",
  required_tools: [:calibrate_lidar],
  payload: %{}
}
```
**Expected Behavior:**
1. Registry returns `[]`.
2. CEL halts and returns `{:error, :no_eligible_provider, missing_tools: [:calibrate_lidar]}`.
**Fail Condition:** If CEL attempts to route to a "default" handler, or crashes with a MatchError.

## Test 3: The Unhealthy Provider (Negative Control 2)
**Action:** Submit a valid mission, but artificially mark the required capability as `:degraded` or `:unhealthy` in the registry state.
**Expected Behavior:**
1. Registry returns the provider, but with `health: :unhealthy`.
2. CEL evaluates the risk (using the grounded F10 `assess_risk` logic).
3. CEL refuses delegation and returns `{:error, :provider_unhealthy, reason: ...}`.
**Fail Condition:** If CEL blindly routes to the unhealthy provider without checking state.

## Test 4: The Governance Block (Negative Control 3)
**Action:** Submit a valid mission to a healthy provider, but the C14 policy engine denies the action (e.g., insufficient quorum/authority).
**Expected Behavior:**
1. CEL discovers and evaluates successfully.
2. C14 returns `{:deny, :insufficient_authority}`.
3. CEL returns `{:error, :governance_denied, reason: ...}`.
**Fail Condition:** If CEL bypasses C14 or ignores the denial.
