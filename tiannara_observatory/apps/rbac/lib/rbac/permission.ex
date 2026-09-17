defmodule Rbac.Permission do
  @permissions %{
    observer: [:view_public, :view_internal],
    engineer: [:view_public, :view_internal, :view_restricted, :intervene_infrastructure],
    scientist: [:view_public, :view_internal, :view_restricted, :view_secret, :intervene_science],
    governor: [:view_all, :intervene_all, :amend_constitution, :override_operator],
    auditor: [:view_all, :view_audit_trails],
    administrator: [:view_all, :manage_accounts, :manage_credentials, :manage_storage],
    system: [:view_assigned, :intervene_assigned]
  }

  def for_role(role) do
    Map.get(@permissions, role, [])
  end

  def allowed?(role, permission) do
    permission in for_role(role)
  end
end
