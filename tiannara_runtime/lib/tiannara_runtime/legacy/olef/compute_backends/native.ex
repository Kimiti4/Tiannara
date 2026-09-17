defmodule TiannaraRuntime.Legacy.Tiannara.OLEF.ComputeBackends.Native do
  @moduledoc """
  Bridges the BEAM ecology to the Rust Native GPU Scheduler.
  Handles binary tensor serialization and asynchronous messaging.
  """
  @behaviour Tiannara.OLEF.ComputeBackend
  
  alias Tiannara.Native.A10
  
  @impl true
  def diffuse(field, _neighborhood_map, coefficient, _steps \\ 1) do
    {binary_tensor, index_map} = serialize_to_binary(field)
    
    ref_id = UUID.uuid4()
    
    # Submit asynchronous job to the Native Scheduler
    case A10.submit_diffusion_job(binary_tensor, coefficient, ref_id, self()) do
      :ok ->
        # Wait for the native scheduler to message back the result
        receive do
          {:ok, ^ref_id, result_binary} ->
            deserialize_from_binary(result_binary, index_map)
        after
          5000 ->
            raise "Native Compute Backend timeout for job #{ref_id}"
        end
      :error ->
        raise "Failed to submit job to Native Compute Backend"
    end
  end
  
  @doc """
  Flattens the Map-based field into a highly cache-friendly little-endian Float64 binary tensor
  along with an index_map to rebuild it later.
  """
  def serialize_to_binary(field_map) do
    nodes = Map.keys(field_map) |> Enum.sort()
    
    # Create index map: {node_id => offset_index}
    index_map = 
      nodes
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {node_id, index}, acc -> Map.put(acc, node_id, index) end)
      
    binary_tensor = 
      nodes
      |> Enum.map(fn node_id -> Map.get(field_map, node_id) end)
      |> Enum.reduce(<<>>, fn value, acc -> acc <> <<value::float-little-size(64)>> end)
      
    {binary_tensor, index_map}
  end
  
  @doc """
  Rebuilds the Elixir map using the returned binary and the index map.
  """
  def deserialize_from_binary(binary_tensor, index_map) do
    # Invert the index map: {offset_index => node_id}
    inverted_index = Enum.reduce(index_map, %{}, fn {k, v}, acc -> Map.put(acc, v, k) end)
    
    parse_binary(binary_tensor, 0, inverted_index, %{})
  end
  
  defp parse_binary(<<value::float-little-size(64), rest::binary>>, index, inverted_index, acc) do
    node_id = Map.get(inverted_index, index)
    parse_binary(rest, index + 1, inverted_index, Map.put(acc, node_id, value))
  end
  
  defp parse_binary(<<>>, _index, _inverted_index, acc) do
    acc
  end
end
