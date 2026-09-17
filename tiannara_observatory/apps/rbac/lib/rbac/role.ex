defmodule Rbac.Role do
  @roles ~w(observer engineer scientist governor auditor administrator system)a

  def all, do: @roles

  def valid?(role) when is_atom(role), do: role in @roles
  def valid?(_), do: false

  def hierarchy do
    %{
      observer: 1,
      engineer: 2,
      scientist: 3,
      governor: 4,
      auditor: 4,
      administrator: 5,
      system: 5
    }
  end

  def dominates?(role_a, role_b) do
    Map.get(hierarchy(), role_a, 0) >= Map.get(hierarchy(), role_b, 0)
  end
end
