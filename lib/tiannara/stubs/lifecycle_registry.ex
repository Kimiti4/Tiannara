defmodule TiannaraOS.LifecycleRegistry do
  @moduledoc "Concrete lifecycle event registry backed by ETS."

  @table :tiannara_lifecycle_registry

  def track_entity(entity_type, entity_id, event_type, metadata \\ %{}) do
    ensure_table()
    event = %{entity_type: entity_type, entity_id: entity_id, event_type: event_type,
      metadata: metadata, timestamp: DateTime.utc_now(), id: Base.encode16(:crypto.strong_rand_bytes(8), case: :lower)}
    :ets.insert(@table, {{entity_type, entity_id}, event})
    {:ok, event}
  end

  def history(entity_type, entity_id) do
    ensure_table()
    {:ok, :ets.lookup(@table, {entity_type, entity_id}) |> Enum.map(fn {_, e} -> e end)}
  end

  defp ensure_table do
    case :ets.whereis(@table) do
      :undefined -> :ets.new(@table, [:bag, :public, :named_table, {:read_concurrency, true}])
      _ -> @table
    end
  end
end
