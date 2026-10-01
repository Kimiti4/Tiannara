defmodule Tiannara.MetaSOPL.GovernorEvidenceTest do
  use ExUnit.Case, async: true

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
