defprotocol TiannaraRuntime.WorldModel.Composition.Behaviours.VariableResolution do
  @moduledoc """
  Phase 17.6.1 — VariableResolution protocol.
  Describes how a shared variable resolves conflicts across domains.
  """

  @doc "Resolves the value of this variable given domain-specific values."
  def resolve(variable, domain_values)

  @doc "Returns whether this variable has a conflict requiring resolution."
  def conflict?(variable)

  @doc "Returns the resolution strategy for this variable."
  def strategy(variable)
end
