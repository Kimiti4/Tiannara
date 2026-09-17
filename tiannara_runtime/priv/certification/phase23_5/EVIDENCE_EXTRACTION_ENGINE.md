# Evidence Extraction Engine

## Purpose

Extract supporting evidence from publications — data, methodology, statistical
results, and experimental conditions — and map them to extracted claims.

## Evidence Types

| Type | Description |
|------|-------------|
| Experimental Data | Measured values, observations |
| Statistical Results | P-values, effect sizes, confidence intervals |
| Methodology | Experimental design, protocols |
| Code/Software | Analysis code, simulation software |
| Derivations | Mathematical proofs or derivations |
| Referenced Evidence | Evidence cited from other publications |

## Evidence Structure

Each evidence record includes:
- Evidence type
- Source publication ID
- Claim IDs supported
- Data or reference (structured where possible)
- Methodological context
- Quality indicators (sample size, controls, reproducibility)
- Access status (open data vs. not available)

## Evidence Mapping

Every claim is linked to its supporting evidence. Claims without extracted
evidence are flagged as unsupported. Evidence quality is independently
evaluated by the Publication Quality Engine.
