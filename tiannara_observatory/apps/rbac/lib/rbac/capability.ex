defmodule Rbac.Capability do
  @moduledoc """
  Capability definitions for capability-based security.

  Format: `domain.resource.action`
  Examples: metrics.read, replay.execute, certification.sign
  """

  @doc "All known capabilities."
  def all do
    ~w(
      metrics.read metrics.write
      events.read events.write
      replay.execute replay.export
      science.discoveries.read science.experiments.start science.experiments.pause
      engineering.designs.read engineering.trl.read
      theory.publish theory.read
      certification.sign certification.verify certification.invalidate
      runtime.health.read runtime.shutdown runtime.restart
      configuration.read configuration.modify
      admin.users.read admin.users.create admin.users.delete
      audit.read audit.export
      operator.action
    )
  end

  @doc "Check if a capability string is valid."
  def valid?(cap) when is_binary(cap), do: cap in all()
  def valid?(_), do: false

  @doc "Parse a capability into its components."
  def parse(cap) do
    case String.split(cap, ".") do
      [domain, resource, action] -> %{domain: domain, resource: resource, action: action}
      _ -> nil
    end
  end

  @doc "Check if a granted capability satisfies a required capability (supports wildcard)."
  def satisfies?("*", _required), do: true
  def satisfies?("*.*", _required), do: true

  def satisfies?(granted, required) when granted == required, do: true

  def satisfies?(granted, required) do
    gp = String.split(granted, ".")
    rp = String.split(required, ".")

    length(gp) == length(rp) and
      Enum.zip(gp, rp)
      |> Enum.all?(fn
        {"*", _} -> true
        {g, r} -> g == r
      end)
  end
end
