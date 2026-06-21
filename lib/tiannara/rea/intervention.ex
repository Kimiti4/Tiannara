defmodule Tiannara.REA.Intervention do
  @moduledoc """
  Bridges discoveries/laws and experiments with real modifications to parameters.
  """
  @derive Jason.Encoder
  defstruct [
    :id,
    :origin_discovery_id,
    :origin_law_id,
    :origin_theory_id,
    :proposal_text,
    :confidence,
    :expected_effect,
    :actual_effect,
    :status, # :proposed | :active | :completed | :rolled_back
    :timestamp
  ]

  @file_path "data/interventions.ndjson"

  @doc """
  Loads all interventions from persistence.
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
            attrs = Map.update!(attrs, :status, &String.to_atom(to_string(&1)))
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
  Saves a single intervention.
  """
  def save(%__MODULE__{} = intervention) do
    File.mkdir_p!(Path.dirname(@file_path))
    intervention = %{intervention | timestamp: intervention.timestamp || DateTime.utc_now() |> DateTime.to_iso8601()}
    line = Jason.encode!(intervention) <> "\n"
    File.write!(@file_path, line, [:append])
    {:ok, intervention}
  end

  @doc """
  Saves all interventions back to the file.
  """
  def write_all(list) do
    File.mkdir_p!(Path.dirname(@file_path))
    content = Enum.map(list, fn intervention -> Jason.encode!(intervention) <> "\n" end) |> Enum.join("")
    File.write!(@file_path, content)
    :ok
  end

  def seeds do
    [
      %__MODULE__{
        id: "int1",
        origin_discovery_id: "structured_forgetting",
        origin_law_id: "structured_forgetting",
        origin_theory_id: "adaptive_memory_ecology",
        proposal_text: "Set Specialist Context Retention = 55%",
        confidence: 0.85,
        expected_effect: "DVR +12%",
        actual_effect: "DVR +12%",
        status: :completed,
        timestamp: "2026-06-11T14:00:00Z"
      },
      %__MODULE__{
        id: "int2",
        origin_discovery_id: "scp_retention_boundary",
        origin_law_id: "scp_retention_boundary",
        origin_theory_id: "regenerative_governance",
        proposal_text: "Enforce network redundancy > 20%",
        confidence: 0.90,
        expected_effect: "Recovery Time -1 epoch",
        actual_effect: nil,
        status: :active,
        timestamp: "2026-06-11T14:15:00Z"
      }
    ]
  end
end
