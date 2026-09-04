defmodule Tiannara.Discovery.Topics do
  @moduledoc """
  SINGLE SOURCE OF TRUTH for discovery-pipeline event topics.

  Publisher and subscriber MUST both read from here. The contract test
  (provider_contract_test.exs) walks every topic and asserts each subscriber
  has a publisher and vice versa, so a vocabulary drift can never again
  present as a silent stall (the Seam-B / WSS-envelope class of bug, per
  rules.md: "Detect degraded performance"; "Uncertainty should never be
  hidden").

  Hand-typed topic strings elsewhere are a defect. Add new topics HERE.
  """

  def evidence_routed, do: "discovery.evidence.routed"
  def experiment_completed, do: "discovery.experiment.completed"
  def discovery_completed, do: "discovery.completed"

  @doc "All topics — the contract test iterates this to prove pub/sub balance."
  def all, do: [evidence_routed(), experiment_completed(), discovery_completed()]
end
