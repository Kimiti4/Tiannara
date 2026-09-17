defmodule TiannaraRuntime.Civilization.Economy.ScientificMarket do
  def initialize() do
    {:ok, %{exchange: [], assets: %{}, valuations: %{}}}
  end

  def list_asset(market, asset_id, asset_type, value) do
    asset = %{id: asset_id, type: asset_type, value: value}
    new_valuations = Map.put(market.valuations, asset_id, value)
    {:ok, %{market | assets: Map.put(market.assets, asset_id, asset), valuations: new_valuations}}
  end

  def exchange(market, from, to, asset_id) do
    asset = Map.get(market.assets, asset_id)
    if is_nil(asset) do
      {:error, :not_found}
    else
      record = %{from: from, to: to, asset_id: asset_id, timestamp: :erlang.unique_integer([:positive])}
      {:ok, %{market | exchange: [record | market.exchange]}}
    end
  end

  def value(market, asset_id) do
    {:ok, Map.get(market.valuations, asset_id, 0)}
  end

  def metrics(market) do
    {:ok, %{
      assets_listed: map_size(market.assets),
      exchanges: length(market.exchange),
      valuations: map_size(market.valuations)
    }}
  end
end
