defmodule Tiannara.OLEF.ComputeBackends.Native do
  def serialize_to_binary(field) when is_map(field) do
    sorted = Enum.sort(field)
    {index_map, _} = Enum.reduce(sorted, {%{}, 0}, fn {k, _}, {acc, idx} ->
      {Map.put(acc, k, idx), idx + 1}
    end)
    binary = Enum.reduce(sorted, <<>>, fn {_, v}, acc ->
      acc <> <<v::float-64-native>>
    end)
    {binary, index_map}
  end

  def deserialize_from_binary(binary, index_map) when is_binary(binary) do
    index_to_key = Enum.reduce(index_map, %{}, fn {k, v}, acc ->
      Map.put(acc, v, k)
    end)
    num_floats = div(byte_size(binary), 8)
    values = for i <- 0..(num_floats - 1) do
      offset = i * 8
      <<_::binary-size(offset), v::float-64-native, _::binary>> = binary
      {Map.get(index_to_key, i), v}
    end
    Enum.into(values, %{})
  end
end
