# Constitutional Constraint Checker

## Purpose
Ensures every intervention strategy respects the Tiannara Constitution — no strategy may violate constitutional principles regardless of expected benefits.

## Checks Performed

### Permitted Actions
- Is the intervention type permitted by the constitution?
- Does it require special authorization?
- Is there a constitutional prohibition?

### Rights Protection
- Does the intervention affect individual rights?
- Does it affect collective rights?
- Does it affect future generations?
- Are affected populations notified and consenting?

### Proportionality
- Is the intervention proportional to the risk?
- Are there less restrictive alternatives?
- Is the burden distributed fairly?

### Precautionary Principle
- Is there sufficient evidence of safety?
- Are irreversible consequences understood?
- Are monitoring and reversal mechanisms in place?

### Transparency
- Is the intervention rationale recorded?
- Are decision criteria explicit?
- Is there a public record?

## Output
- **pass** — strategy is constitutional
- **fail** — strategy is unconstitutional (with reasons)
- **conditional** — strategy is constitutional only if specific conditions are met
- **review_required** — requires higher authority review
