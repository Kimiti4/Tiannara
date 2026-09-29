defmodule TiannaraOS.ScientificCapitalLedger do
  @moduledoc "Deterministic scientific-capital delta calculation."

  def calculate_delta(ledger, entry) when is_map(ledger) and is_map(entry) do
    before = numeric(ledger, :capital, 0.0)
    after_value = numeric(entry, :capital, numeric(entry, :value, before))
    {:ok, %{before: before, after: after_value, delta: after_value - before}}
  end
  def calculate_delta(_, _), do: {:error, :invalid_ledger_entry}

  defp numeric(map, key, default) do
    case Map.get(map, key, default) do
      x when is_number(x) -> x
      _ -> default
    end
  end
end
