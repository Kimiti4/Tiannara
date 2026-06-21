defmodule Tiannara.Discoveries.Unknown do
  @moduledoc """
  Tracks known unknowns and research debt in the system.
  """
  @derive Jason.Encoder
  defstruct [
    :id,
    :question,
    :confidence, # :low | :medium | :high
    :importance, # :low | :medium | :high
    :blocking_phase,
    :timestamp
  ]

  @file_path "data/unknowns.ndjson"

  @doc """
  Loads all unknowns from persistence.
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
            attrs = Map.update!(attrs, :confidence, &String.to_atom(to_string(&1)))
            attrs = Map.update!(attrs, :importance, &String.to_atom(to_string(&1)))
            struct(__MODULE__, attrs)
          _ -> nil
        end
      end)
      |> Stream.reject(&is_nil/1)
      |> Enum.to_list()
    else
      list = seeds()
      write_all(list)
      list
    end
  end

  @doc """
  Saves a single unknown.
  """
  def save(%__MODULE__{} = unknown) do
    File.mkdir_p!(Path.dirname(@file_path))
    unknown = %{unknown | timestamp: unknown.timestamp || DateTime.utc_now() |> DateTime.to_iso8601()}
    line = Jason.encode!(unknown) <> "\n"
    File.write!(@file_path, line, [:append])
    {:ok, unknown}
  end

  @doc """
  Saves all unknowns back to the file.
  """
  def write_all(list) do
    File.mkdir_p!(Path.dirname(@file_path))
    content = Enum.map(list, fn unknown -> Jason.encode!(unknown) <> "\n" end) |> Enum.join("")
    File.write!(@file_path, content)
    :ok
  end

  def seeds do
    [
      %__MODULE__{
        id: "un1",
        question: "What happens to stability when retention drops below 10%?",
        confidence: :low,
        importance: :high,
        blocking_phase: "Phase 11.7",
        timestamp: "2026-06-11T13:00:00Z"
      },
      %__MODULE__{
        id: "un2",
        question: "How does asymmetric specialization affect DVR long-term?",
        confidence: :medium,
        importance: :medium,
        blocking_phase: "Phase 12.1",
        timestamp: "2026-06-11T13:15:00Z"
      }
    ]
  end
end
