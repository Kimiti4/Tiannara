defprotocol TiannaraRuntime.WorldModel.Composition.Behaviours.ComposableModel do
  @moduledoc """
  Phase 17.6.1 — ComposableModel protocol.
  Describes how a world model exposes its domains, variables, and interfaces for composition.
  """

  @doc "Returns the list of domain names this model participates in."
  def domains(model)

  @doc "Returns the list of variable names this model exposes."
  def exposed_variables(model)

  @doc "Returns the domain interface definition for a given target domain."
  def interface_for(model, target_domain)

  @doc "Returns whether this model is certified and operational."
  def certified?(model)
end
