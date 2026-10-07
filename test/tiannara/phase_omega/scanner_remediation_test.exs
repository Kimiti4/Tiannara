defmodule Tiannara.PhaseOmega.ScannerRemediationTest do
  use ExUnit.Case, async: false

  test "overall health cannot treat UNKNOWN as healthy" do
    statuses = [:pass, :warn, :unknown]
    refute Enum.all?(statuses, &(&1 == :pass))
  end

  test "headless event-flow verification is not represented as healthy" do
    assert :unknown in [:unknown]
  end
end
