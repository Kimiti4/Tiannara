defmodule Tiannara.Omega.CapabilityAuditTest do
  use ExUnit.Case, async: true

  alias Tiannara.Omega.CapabilityAudit
  alias Tiannara.Lineage.Entry

  defp audit(artifacts), do: CapabilityAudit.audit(artifacts)

  test "recovery observed when every failure has a matching recovery" do
    audit = audit(%{operations_reports: [%{"total_failures" => 2, "total_recoveries" => 2, "generated_at" => "x"}],
                    lineage_entries: [], cpl_checkpoints: 0})
    assert audit.capabilities.recovery.status == :observed
  end

  test "flags concern when failures lack recoveries" do
    audit = audit(%{operations_reports: [%{"total_failures" => 3, "total_recoveries" => 1, "generated_at" => "x"}],
                    lineage_entries: [], cpl_checkpoints: 0})
    assert audit.capabilities.recovery.status == :concern
  end

  test "constitutional restraint observed from rejected verification evidence" do
    e = Entry.new(%{scenario: :authorization_bypass, attack: :missing_grant, outcome: :rejected},
                  :verification_evidence)
    audit = audit(%{operations_reports: [], lineage_entries: [e], cpl_checkpoints: 0})
    assert audit.capabilities.constitutional_restraint.status == :observed
  end

  test "accepted adversarial outcome is a concern" do
    e = Entry.new(%{attack: :legacy_bypass, outcome: :accepted}, :verification_evidence)
    audit = audit(%{operations_reports: [], lineage_entries: [e], cpl_checkpoints: 0})
    assert audit.capabilities.constitutional_restraint.status == :concern
  end

  test "goal persistence observed when discovery cycles never regress" do
    reports = [%{"discovery_cycles" => 1}, %{"discovery_cycles" => 4}, %{"discovery_cycles" => 9}]
    audit = audit(%{operations_reports: reports, lineage_entries: [], cpl_checkpoints: 0})
    assert audit.capabilities.goal_persistence.status == :observed
  end

  test "continuity observed when the lineage chain verifies" do
    e1 = Entry.new(%{stage: :observation}, :observation)
    e2 = Entry.new(%{stage: :conclusion}, :conclusion, e1.entry_hash)
    audit = audit(%{operations_reports: [], lineage_entries: [e1, e2], cpl_checkpoints: 0})
    assert audit.capabilities.continuity.status == :observed
  end

  test "missing artifacts are reported not_measured, never faked" do
    audit = audit(%{operations_reports: [], lineage_entries: [], cpl_checkpoints: 0})

    assert audit.capabilities.situational_awareness.status == :not_measured
    assert audit.capabilities.learning.status == :not_measured
    assert :learning in audit.not_measured
    assert :agency_yield in audit.not_measured
    assert is_list(audit.synthesis)
  end
end