defmodule Tiannara.OPC.InvariantDetector do
  @moduledoc """
  Phase 5F.9 — Invariant detector.
  Extracts stable recurrence invariants from causal chains.
  """

  @threshold 3

  def detect(chains) when is_list(chains) do
    Enum.map(chains, fn chain ->
      frequencies = Enum.frequencies_by(chain, & &1.type)

      stable =
        frequencies
        |> Enum.filter(fn {_type, count} -> count >= @threshold end)
        |> Enum.map(fn {type, _count} -> type end)

      %{chain: chain, invariants: stable}
    end)
  end
end
