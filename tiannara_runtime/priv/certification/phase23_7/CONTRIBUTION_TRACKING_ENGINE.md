# Contribution Tracking Engine

## Purpose

Record every scientific contribution immutably. Every contribution — author, organization, agent, timestamp, knowledge created, knowledge modified, evidence produced, engineering contribution — is permanently attributed.

## Contribution Types

| Type | Recorded Data |
|------|---------------|
| Knowledge Creation | New discovery, law, model, theory |
| Knowledge Modification | Revision of existing knowledge |
| Evidence Production | New experimental or observational data |
| Engineering Contribution | New design, implementation, test |
| Review Contribution | Peer review, critique, objection |
| Coordination Contribution | Team management, task allocation |

## Contribution Record

Each contribution records:
- Contribution ID
- Contributor ID and type
- Contribution type
- Artifact ID(s) affected
- Timestamp
- Previous version reference (if modification)
- Supporting evidence references
- Fingerprint (content hash)

## Constitutional Rules

- Contributions are immutable once recorded
- Contributions cannot be retroactively modified
- Contribution history is fully replayable
- Contributors are permanently attributed
