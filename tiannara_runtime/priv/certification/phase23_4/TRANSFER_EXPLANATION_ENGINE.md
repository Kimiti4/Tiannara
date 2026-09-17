# Transfer Explanation Engine

## Purpose

Ensure every transfer is explainable — why it exists, what evidence supports
it, which abstractions matched, what assumptions changed, and what
uncertainty remains. No opaque transfers permitted.

## Required Explanations

Every transfer must explain:
- **Why transfer exists**: The discovery or reasoning that motivated it
- **What evidence supports it**: Source discoveries and validation results
- **Which abstractions matched**: The abstraction levels and alignment
- **What assumptions changed**: How source assumptions adapt to target
- **What uncertainty remains**: Confidence in the transfer's validity
- **What disanalogies exist**: Where the analogy breaks down

## Explanation Structure

Each explanation records:
- Transfer candidate ID
- Explanation text (structured, deterministic)
- Evidence chain (source → abstraction → mapping → validation → adaptation)
- Assumption deltas (what changed between source and target)
- Uncertainty statements (why this confidence level)
- Provenance (which engines generated which parts)

## Constitutional Rules

- All explanations must be deterministic
- Explanations must be regenerable from stored data
- Incomplete explanations are an acceptable state
- No opaque transfers permitted
