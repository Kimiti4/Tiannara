# Scientific Data Engine

## Purpose

Define the engine that ingests observations from scientific publications and datasets.

## Data Sources

- Open access repositories (arXiv, bioRxiv, PubMed Central).
- Scientific databases (Scopus, Web of Science, Google Scholar).
- Research data repositories (Zenodo, Figshare, Dryad).
- Conference proceedings.
- Government and institutional reports.
- Preprint servers.
- Patent databases (USPTO, EPO, WIPO).
- Clinical trial registries.
- Protocol repositories.

## Extraction Pipeline

1. **Discovery** — Identify new publications/datasets relevant to planetary state.
2. **Harvest** — Download or access the full content.
3. **Parse** — Extract structured data from PDF, HTML, database formats.
4. **Extract** — Identify specific observations (measurements, findings, statistics).
5. **Contextualize** — Capture methodology, uncertainty, limitations.
6. **Validate** — Cross-reference claims with cited evidence.
7. **Observation Creation** — Create structured observation from extracted data.

## Quality Scoring

- Publication venue quality (impact factor, peer review standard).
- Methodology rigor (sample size, controls, blinding).
- Replication status (independently replicated?).
- Effect size and statistical significance.
- Conflicts of interest.
- Funding source transparency.
