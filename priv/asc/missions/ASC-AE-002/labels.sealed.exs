# ASC-AE-002 sealed ground-truth labels.
# Pre-registered: SHA-256 of this exact file is recorded in the PROTOCOL
# ledger entry before any arm is built. Read only AFTER ranking, verdict,
# and falsification records are finalized and persisted.
%{
  genuine: :bulk_ingest,
  non_beneficial: [:parallel_ingest, :recursive_ingest]
}