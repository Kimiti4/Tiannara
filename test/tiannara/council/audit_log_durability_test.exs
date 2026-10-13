defmodule Tiannara.Council.AuditLogDurabilityTest do
  use ExUnit.Case, async: false

  alias Tiannara.Council.AuditLog

  test "uses the active isolated storage context" do
    path = AuditLog.dets_path()

    assert String.ends_with?(path, Path.join(["test", "council_audit_log.dets"]))
    refute path == "./council_audit_log.dets"
  end

  test "writes a chain entry that verifies immediately" do
    action = String.to_atom("durability_probe_#{System.unique_integer([:positive])}")

    assert {:ok, entry} = AuditLog.append(action, :test, %{probe: true})
    assert entry.seq > 0
    assert :ok = AuditLog.verify_integrity()
  end
end