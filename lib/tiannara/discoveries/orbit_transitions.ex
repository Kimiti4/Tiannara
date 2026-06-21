defmodule Tiannara.OrbitTransitions do
  @moduledoc """
  Handles persistence for the Orbit Transition Matrix data.
  """
  alias Tiannara.OrbitTransition

  @file_path "data/orbit_transitions.ndjson"

  @doc """
  Loads all stored transitions from data/orbit_transitions.ndjson.
  """
  def all do
    if File.exists?(@file_path) do
      @file_path
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == ""))
      |> Stream.map(fn line ->
        case Jason.decode(line, keys: :atoms) do
          {:ok, attrs} ->
            attrs = 
              attrs
              |> Map.update!(:from_orbit, &String.to_atom(to_string(&1)))
              |> Map.update!(:to_orbit, &String.to_atom(to_string(&1)))
            struct(OrbitTransition, attrs)
          _ -> nil
        end
      end)
      |> Stream.reject(&is_nil/1)
      |> Enum.to_list()
    else
      []
    end
  end

  @doc """
  Writes all transitions to data/orbit_transitions.ndjson.
  """
  def write_all(list) do
    File.mkdir_p!(Path.dirname(@file_path))
    content = Enum.map(list, fn t -> Jason.encode!(t) <> "\n" end) |> Enum.join("")
    File.write!(@file_path, content)
    :ok
  end
end
