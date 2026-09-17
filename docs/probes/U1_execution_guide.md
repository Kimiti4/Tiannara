# Probe U1 Execution Guide

## Pre-Requisites

1. **Authorization Artifact**: `priv/tiannara/authorization/ASC-U0-U1.human.yaml`
   - Must be signed by human operator
   - Status must be `AUTHORIZED`
   - Valid for 24 hours from signing

2. **Trace Envelope Schema**: `priv/tiannara/trace_envelope_schema.yaml`
   - All transitions must emit conformant envelopes

3. **Python Environment**: Python 3.8+ with PyYAML

## Execution Steps

### Step 1: Human Authorization

1. Review `priv/tiannara/authorization/ASC-U0-U1.human.yaml`
2. Fill in the `human_authorization` block:
   ```yaml
   human_authorization:
     operator_id: schtickman        # e.g., "lead_architect_01"
     signature: mock-test-001
     timestamp: "2026-08-20T12:00:00Z"
     conditions_accepted: true
     notes: "Authorized for U1 probe execution"
   ```
3. Change `status` from `PENDING_HUMAN_AUTHORIZATION` to `AUTHORIZED`

### Step 2: Execute Probe

```bash
cd /path/to/tiannara
python3 priv/tiannara/probes/U1_reality_to_knowledge.py
```

### Step 3: Review Results

Results are saved to: `priv/tiannara/probes/results/U1_reality_to_knowledge_result.json`

Check for:
- `"status": "SUCCESS"`
- All 4 trace envelopes present
- Payload hash consistency
- No shadow state detected
- Single causal lineage

### Step 4: Human Review of Evidence (No Auto-Update)

The probe NEVER modifies the U0 audit matrix. Epistemic statuses are updated
only after human review of the real evidence files.

After a successful run, the human operator reviews
`priv/tiannara/probes/results/U1_reality_to_knowledge_result.json` and the
evidence files in `priv/tiannara/probes/evidence/`. A PARTIAL_FAILURE result
(preserved failure evidence) is valid U1 evidence and must be reviewed with
the same rigor.

If the human ratifies the evidence, they may update
`docs/audit/U0_unified_circulatory_audit.md`:

| Capability | Previous Status | New Status (only after human review) |
|------------|----------------|--------------------------------------|
| C1 Perception | `?` | `✓` or honest finding |
| C2 Reality Model | `?` | `✓` or honest finding |
| C3 Knowledge | `~` | `✓` or honest finding |
| C4 Epistemics | `~` | `✓` or honest finding |

## Success Criteria

Probe U1 is successful if:

1. ✅ Single `trace_id` lineage spans C1→C2→C3→C4
2. ✅ Canonical state mutation verified via read-back
3. ✅ Shadow-state check executed against `Tiannara.World.UnifiedWorldModel` and result reported honestly (unreachable standalone is a recorded finding, not a pass)
4. ✅ All transitions emit conformant trace envelopes
5. ✅ Payload hash consistency maintained end-to-end

## Failure Handling

If the probe fails:

1. **Do not modify production code**
2. Record the failure in the results file
3. Generate a diagnostic hypothesis:
   ```
   observation: [what failed]
   hypothesis: [what might explain it]
   supporting: [evidence]
   contradicting: [evidence]
   experiment: [what would resolve it]
   ```
4. Do not re-run until the hypothesis is tested

## Next Steps

Upon successful U1 completion:

1. Proceed to **Probe U4: Governance → Engineering**
2. Update U0 audit matrix
3. Prepare for **AE-004 Gate Fidelity** (queued post-U0)