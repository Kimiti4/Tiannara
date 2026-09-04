defmodule TiannaraOS.DomainRegistry do
  @moduledoc """
  DEPRECATED — AC-001-D.

  This module is no longer an authoritative domain registry.
  It was previously a GenServer that was NEVER STARTED under supervision,
  meaning it never possessed operational authority.

  Domain identity is now exclusively provided by:
    Tiannara.Domains.CanonicalRegistry

  Historical APIs (all non-functional since inception):
    - list_all/0          → MIGRATED to CanonicalRegistry.all/0 | all_records/0
    - get/1               → MIGRATED to CanonicalRegistry.get/1
    - get_knowledge_capital/1 → NOT CARRIED FORWARD (explicit boundary)
    - get_portfolio_vector/1  → NOT CARRIED FORWARD (explicit boundary)
    - add_program/2       → DEAD (zero callers, retired)
    - record_activity/3   → DEAD (zero callers, retired)
    - get_all_domain_ids/0 → DEAD (zero callers, retired)

  Knowledge capital boundary:
    {:error, :knowledge_capital_unavailable}

  Portfolio boundary:
    {:error, :portfolio_unavailable}

  This module is retained temporarily for migration lineage.
  It possesses NO executable authority.

  Migration lineage: certification/remediation/AC001-C1-MIGRATION-LEDGER.md
  Deprecation gate: AC-001-D
  """

  @deprecated "Use Tiannara.Domains.CanonicalRegistry instead. Deprecated in AC-001-D."
  def list_all do
    raise """
    TiannaraOS.DomainRegistry is DEPRECATED (AC-001-D).
    This GenServer was never started and never possessed operational authority.

    Domain identity: Tiannara.Domains.CanonicalRegistry.all/0 | all_records/0
    """
  end

  @deprecated "Use Tiannara.Domains.CanonicalRegistry.get/1 instead. Deprecated in AC-001-D."
  def get(_domain_id) do
    raise """
    TiannaraOS.DomainRegistry is DEPRECATED (AC-001-D).
    Use Tiannara.Domains.CanonicalRegistry.get/1 instead.
    """
  end

  @deprecated "Not carried forward. Deprecated in AC-001-D."
  def get_knowledge_capital(_domain_id) do
    {:error, :knowledge_capital_unavailable}
  end

  @deprecated "Not carried forward. Deprecated in AC-001-D."
  def get_portfolio_vector(_domain_id) do
    {:error, :portfolio_unavailable}
  end

  @deprecated "Dead API. Zero callers. Deprecated in AC-001-D."
  def add_program(_domain_id, _program_id) do
    raise """
    TiannaraOS.DomainRegistry.add_program/2 is DEAD (AC-001-D).
    Zero callers. This API was never functional.
    """
  end

  @deprecated "Dead API. Zero callers. Deprecated in AC-001-D."
  def record_activity(_domain_id, _activity_type, _details \\ %{}) do
    raise """
    TiannaraOS.DomainRegistry.record_activity/3 is DEAD (AC-001-D).
    Zero callers. This API was never functional.
    """
  end

  @deprecated "Dead API. Zero callers. Deprecated in AC-001-D."
  def get_all_domain_ids do
    raise """
    TiannaraOS.DomainRegistry.get_all_domain_ids/0 is DEAD (AC-001-D).
    Zero callers. This API was never functional.
    """
  end
end
