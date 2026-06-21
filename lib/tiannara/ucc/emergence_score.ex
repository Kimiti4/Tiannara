defmodule Tiannara.UCC.EmergenceScore do
  @moduledoc """
  The Canonical EmergenceScore representation.
  Scores the resilience and adaptive efficiency of a ConstitutionGenome or InstitutionGenome.
  """
  
  @derive Jason.Encoder
  defstruct [
    :rq,
    :ee,
    :compression_ratio,
    :predictive_retention,
    :adaptive_gain,
    :identity_retention
  ]
end
