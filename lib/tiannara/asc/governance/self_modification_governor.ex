defmodule Tiannara.ASC.Governance.SelfModificationGovernor do
  @moduledoc """
  Phase 9.1: Prevents infinite self-expansion and protects critical infrastructure.
  Agents cannot modify the Constitution, the Executive, or the Governance Layer.
  """

  @protected_namespaces [
    "lib/tiannara/asc/constitution.ex",
    "lib/tiannara/asc/executive.ex",
    "lib/tiannara/asc/governance/",
    "lib/tiannara/asc/reality/reality_bridge.ex"
  ]

  def authorize_patch(target_file) do
    if Enum.any?(@protected_namespaces, fn ns -> String.starts_with?(target_file, ns) end) do
      {:deny, "CRITICAL VIOLATION: Attempted modification of protected civilizational infrastructure (#{target_file})."}
    else
      :allow
    end
  end
end
