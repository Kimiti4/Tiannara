defmodule Tiannara.Observatory.Validation.MetricsStore do
  def create_table(campaign_id) do
    table_name = table_name(campaign_id)
    :ets.new(table_name, [:named_table, :ordered_set, :public, read_concurrency: true])
    table_name
  end

  def record(campaign_id, tick_result) do
    table_name = table_name(campaign_id)
    key = DateTime.to_unix(tick_result.timestamp, :millisecond)
    :ets.insert(table_name, {key, tick_result})
  end

  def get_all(campaign_id) do
    table_name = table_name(campaign_id)
    if :ets.whereis(table_name) != :undefined do
      table_name |> :ets.tab2list() |> Enum.sort_by(fn {k, _} -> k end) |> Enum.map(fn {_, v} -> v end)
    else
      []
    end
  end

  def destroy(campaign_id) do
    table_name = table_name(campaign_id)
    if :ets.whereis(table_name) != :undefined do
      :ets.delete(table_name)
    end
  end

  defp table_name(campaign_id), do: String.to_atom("validation_#{String.replace(campaign_id, "-", "_")}")
end
