defmodule Tiannara.DomainCortex do
  @moduledoc "Registry of the 3-level Cognitive Domain Taxonomy."

  @l1_discovery_domains [
    :computation,        # Maps to Algorithm
    :communication,      # Maps to NLP
    :technology,         # Maps to Reverse Engineering
    :system_admin,       # Maps to Troubleshooting
    :perception,         # Maps to Vision / Audio
    :engineering, :construction, :robotics, :transport,
    :medicine, :governance, :physics, :chemistry,
    :agriculture, :energy, :logistics, :finance, :cognition,
    :materials_science, :manufacturing, :education, :ecology, :law
  ]

  @l2_cognitive_operators [
    :temporal,
    :combinatorial,
    :logic,
    :prediction,
    :causal,
    :analogical,
    :counterfactual,
    :recursive,
    :adversarial,
    :symbolic,
    :abductive,
    :empirical
  ]

  @l3_meta_cognitive_layers [
    :collective_intelligence,
    :creative_synthesis,
    :social_intelligence,
    :ethical_reasoning,
    :embodied_cognition,
    :meta_cognition
  ]

  def l1_discovery_domains, do: @l1_discovery_domains
  def l2_cognitive_operators, do: @l2_cognitive_operators
  def l3_meta_cognitive_layers, do: @l3_meta_cognitive_layers

  @doc "Legacy support for modules querying the active reasoning operators."
  def domains, do: @l2_cognitive_operators
end
