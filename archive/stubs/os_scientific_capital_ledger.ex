defmodule TiannaraOS.ScientificCapitalLedger do
  use Tiannara.Stub, subsystem: :os, phase: "Omega+", priority: :high
  def calculate_delta(ledger, entry), do: stub_result(:calculate_delta, [ledger, entry], {:ok, 0})
end
