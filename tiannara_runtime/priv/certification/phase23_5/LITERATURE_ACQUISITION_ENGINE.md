# Literature Acquisition Engine

## Purpose

Acquire publications from diverse sources while tracking provenance,
licensing, and source integrity.

## Source Types

| Source | Examples |
|--------|----------|
| Peer-Reviewed Journals | Nature, Science, domain-specific journals |
| Preprints | arXiv, bioRxiv, medRxiv |
| Conference Proceedings | Major conferences by field |
| Books | Textbooks, monographs, reference works |
| Technical Standards | ISO, IEEE, ASTM standards |
| Engineering Specifications | Industry specifications and handbooks |
| Government Research | National lab reports, agency publications |
| Institutional Reports | University and research institute publications |

## Acquisition Process

1. Identify target publications (via scheduled discovery or explicit request)
2. Verify source authenticity
3. Acquire full text with metadata
4. Record acquisition provenance (source URL, timestamp, access method)
5. Submit to Publication Authentication Engine
6. Register in acquisition log

## Acquisition Metadata

Each acquisition records:
- Source type and identifier
- Access method (open access, subscription, repository)
- Acquisition timestamp
- Content fingerprint (hash)
- License information
- Source reliability score
