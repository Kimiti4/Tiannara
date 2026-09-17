defmodule TiannaraRuntime.Civilization.Registry.CivilizationRegistry do
  def initialize() do
    {:ok, %{items: %{}, ordered_ids: [], created_at: :erlang.unique_integer([:positive])}}
  end

  def register(registry, item) do
    id = Map.get(item, :id)
    if Map.has_key?(registry.items, id) do
      {:error, {:duplicate, id}}
    else
      updated = %{registry | items: Map.put(registry.items, id, item), ordered_ids: registry.ordered_ids ++ [id]}
      {:ok, updated}
    end
  end

  def lookup(registry, id) do
    case Map.get(registry.items, id) do
      nil -> {:error, :not_found}
      item -> {:ok, item}
    end
  end

  def remove(registry, id) do
    case Map.has_key?(registry.items, id) do
      false -> {:error, :not_found}
      true -> {:ok, %{registry | items: Map.delete(registry.items, id), ordered_ids: Enum.reject(registry.ordered_ids, &(&1 == id))}}
    end
  end

  def list(registry) do
    {:ok, Enum.map(registry.ordered_ids, fn id -> Map.get(registry.items, id) end)}
  end

  def count(registry) do
    {:ok, map_size(registry.items)}
  end

  def validate(registry) do
    errors = Enum.reduce(registry.ordered_ids, [], fn id, acc ->
      item = Map.get(registry.items, id)
      if is_nil(item), do: [{:broken_reference, id} | acc], else: acc
    end)
    if errors == [], do: :ok, else: {:error, errors}
  end
end
