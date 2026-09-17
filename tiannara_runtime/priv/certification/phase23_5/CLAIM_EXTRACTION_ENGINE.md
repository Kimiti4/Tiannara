# Claim Extraction Engine

## Purpose

Extract and represent scientific claims from publications as first-class
constitutional objects. Claims become independently referenceable,
comparable, and verifiable.

## Claim Types

| Type | Description |
|------|-------------|
| Observation | Claim about observed phenomena |
| Relationship | Claim about correlation or causation |
| Mechanism | Claim about underlying process |
| Prediction | Claim about future observations |
| Methodology | Claim about method validity |
| Classification | Claim about category membership |
| Quantification | Claim about measured values |
| Comparison | Claim about relative properties |

## Claim Structure

Each claim records:
- Claim type
- Claim text (verbatim from publication)
- Section context (where in the document)
- Supporting evidence references
- Confidence/uncertainty (if reported)
- Publication ID
- Claim fingerprint
- Known contradictions (initially empty, populated by contradiction engine)

## Constitutional Requirements

- Claims preserve original wording
- Claims include surrounding context to prevent misrepresentation
- Claims without explicit evidence are marked as unsupported
- Claims cannot be altered after extraction
