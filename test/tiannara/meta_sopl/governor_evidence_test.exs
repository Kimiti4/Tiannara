defmodule Tiannara.MetaSOPL.GovernorEvidenceTest do
  use ExUnit.Case, async: true

  # The fail-closed MetaSOPL boundary lives in the sibling tiannara_runtime
  # app, which is not on the root app's compile path. Load it explicitly
  # (same approach as test/activation_integration.exs) so this evidence test
  # exercises the real module in the root suite.
  Code.require_file("tiannara_runtime/lib/tiannara_runtime/layer.ex")
  Code.require_file("tiannara_runtime/lib/tiannara_runtime/contracts/meta_adjustment.ex")
  Code.require_file("tiannara_runtime/lib/tiannara_runtime/core_stack/meta_sopl_governor.ex")

  alias Tiannara.MetaSOPL.Governor

  test "fails closed when telemetry backend is absent" do
    {:ok, pid} = Governor.start_link(
      telemetry_provider: nil,
      authorizer: nil,
      validator: nil
    )

    assert {:error, :meta_sopl_backend_unavailable} = GenServer.call(pid, :propose)
    GenServer.stop(pid)
  end
end
