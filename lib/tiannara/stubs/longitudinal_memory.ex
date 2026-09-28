defmodule Tiannara.Meta.Epistemics.LongitudinalMemory do
  @moduledoc "Bounded longitudinal state store; never fabricates compressed memory."

  @table :tiannara_longitudinal_memory

  def put_compressed_state(world_id, state) when not is_nil(world_id) do
    ensure_table()
    :ets.insert(@table, {world_id, state, DateTime.utc_now()})
    :ok
  end

  def get_compressed_state(world_id) do
    ensure_table()
    case :ets.lookup(@table, world_id) do
      [{^world_id, state, timestamp}] -> {:ok, %{state: state, stored_at: timestamp}}
      [] -> {:error, :memory_not_found}
    end
  end

  defp ensure_table do
    case :ets.whereis(@table) do
      :undefined -> :ets.new(@table, [:set, :public, :named_table, {:read_concurrency, true}])
      _ -> @table
    end
  end
end
