defmodule Tiannara.SelfImprovement.ProtectedCore do
  @moduledoc """
  The immutable protected core: authorization, constitutional, audit, and safety
  substrate. No self-generated modification may alter these without INDEPENDENT
  verification from outside the self-improvement system.

  Constitutional basis: "Constitutional Authority is Supreme", "Capability must
  never outpace verification", "Security by design", augmentation clause.
  """

  @protected [:authorization, :constitutional, :audit, :safety]

  def protected_subsystems, do: @protected
  def protected?(subsystem), do: subsystem in @protected
  def touches_protected?(targets) when is_list(targets),
    do: Enum.any?(targets, &protected?/1)
end