defmodule Tiannara.Sentinel.PressureMonitor do
  @moduledoc "Evidence-backed pressure delta monitor."
  @table :tiannara_pressure_deltas
  def record(world_id, delta) when is_number(delta) do
    ensure_table()
    event = %{world_id: world_id, delta: delta, timestamp: System.system_time(:millisecond)}
    :ets.insert(@table, {world_id, event})
    :ok
  end
  def get_latest_deltas do
    ensure_table()
    worlds = :ets.tab2list(@table) |> Enum.map(fn {_, e} -> e end)
    {:ok, %{tick: System.monotonic_time(:millisecond), worlds: worlds}}
  end
  defp ensure_table do
    case :ets.whereis(@table) do
      :undefined -> :ets.new(@table, [:bag, :public, :named_table, {:read_concurrency, true}])
      _ -> @table
    end
  end
end
