defmodule Tiannara.Domains.Registry do
  @moduledoc """
  DEPRECATED — AC-001-D.

  This module is no longer an authoritative domain registry.
  It previously provided compile-time domain enumeration via:
    - all_domains/0
    - domain_names/0

  Domain identity is now exclusively provided by:
    Tiannara.Domains.CanonicalRegistry

  This module is retained temporarily for migration lineage and
  controlled deprecation. It possesses NO executable authority.

  Disposition:
    - all_domains/0 → REPLACED by CanonicalRegistry.all/0
    - domain_names/0 → REPLACED by CanonicalRegistry.all/0

  Migration lineage: certification/remediation/AC001-C1-MIGRATION-LEDGER.md
  Deprecation gate: AC-001-D
  """

  @deprecated "Use Tiannara.Domains.CanonicalRegistry.all/0 instead. Deprecated in AC-001-D."
  def all_domains do
    raise """
    Tiannara.Domains.Registry is DEPRECATED (AC-001-D).

    Domain identity is exclusively provided by:
      Tiannara.Domains.CanonicalRegistry.all/0

    This module no longer possesses domain-registry authority.
    Migration lineage: certification/remediation/AC001-C1-MIGRATION-LEDGER.md
    """
  end

  @deprecated "Use Tiannara.Domains.CanonicalRegistry.all/0 instead. Deprecated in AC-001-D."
  def domain_names do
    raise """
    Tiannara.Domains.Registry is DEPRECATED (AC-001-D).

    Domain identity is exclusively provided by:
      Tiannara.Domains.CanonicalRegistry.all/0

    This module no longer possesses domain-registry authority.
    Migration lineage: certification/remediation/AC001-C1-MIGRATION-LEDGER.md
    """
  end
end
