defmodule Shared.Constants do
  @moduledoc "Shared constants used across all Observatory apps."

  def constitution_version, do: "1.0.0"
  def api_version, do: "1.0.0"
  def schema_version, do: "1.0.0"

  def event_domains do
    ~w(
      runtime/health runtime/discovery runtime/challenge runtime/experiment
      runtime/hypothesis runtime/checkpoint runtime/generation
      scientific/observation scientific/measurement scientific/analysis
      scientific/peer_review scientific/replication
      engineering/design engineering/optimization engineering/deployment
      engineering/integration engineering/trl
      knowledge/concept knowledge/theory knowledge/relationship knowledge/literature
      governance/policy governance/drift governance/compliance governance/constitution
      planetary/earth_model planetary/environmental planetary/resource
      civilization/innovation civilization/kardashev civilization/societal
      evolution/self_modification evolution/generation_gene evolution/adaptation
      certification/status certification/invalidation certification/audit
      security/auth security/access security/audit
      infrastructure/node infrastructure/network infrastructure/storage
      research/campaign research/finding research/review
      economics/compute_cost economics/storage_cost economics/efficiency
      simulation/run simulation/parameter simulation/result
      experiment/design experiment/execution experiment/result
      operator/action operator/decision operator/note
      audit/review audit/finding audit/recommendation
      replay/session replay/check replay/export
      alert/triggered alert/acknowledged alert/resolved alert/escalated
      prediction/forecast prediction/verification prediction/accuracy
    )
  end

  def classification_levels, do: ~w(public internal restricted secret constitutional)
  def certification_statuses, do: ~w(certified provisional degraded stale uncertain)
  def operator_roles, do: ~w(observer engineer scientist governor auditor administrator system)
  def compression_types, do: ~w(none gzip zstd)
  def default_retention, do: "P90D"
end
