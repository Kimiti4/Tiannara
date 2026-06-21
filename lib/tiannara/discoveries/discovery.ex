defmodule Tiannara.Discoveries.Discovery do
  @moduledoc """
  Represents a system-level scientific discovery, law, or attractor.
  """
  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
    :confidence, # map of %{simulation: 0.0, operational: 0.0, theoretical: 0.0, consensus: 0.0}
    :worlds_evidence,
    :operational_runs_evidence,
    :claim,
    :status, # :observation | :candidate_law | :supported_law | :validated
    :scientific_impact,
    :operational_impact,
    :architectural_impact,
    :timestamp,
    parents: [],
    children: [],
    influenced_by: [],
    influences: [],
    falsification_attempts: 0,
    successful_challenges: 0,
    survived_challenges: 0
  ]

  @file_path "data/discoveries.ndjson"
  @orbits_file_path "data/archive/rea_generativity_orbits.json"

  @doc """
  Loads the generated Orbit Classification data (Phase 11.8).
  """
  def load_orbits do
    if File.exists?(@orbits_file_path) do
      case File.read(@orbits_file_path) do
        {:ok, content} ->
          case Jason.decode(content, keys: :atoms) do
            {:ok, data} -> data
            _ -> nil
          end
        _ -> nil
      end
    else
      nil
    end
  end


  @doc """
  Calculates aggregate confidence from decomposed confidence scores.
  """
  def get_aggregate_confidence(%__MODULE__{confidence: %{simulation: s, operational: o, theoretical: t, consensus: c}}) do
    (s + o + t + c) / 4.0
  end
  def get_aggregate_confidence(%__MODULE__{confidence: %{"simulation" => s, "operational" => o, "theoretical" => t, "consensus" => c}}) do
    (s + o + t + c) / 4.0
  end
  def get_aggregate_confidence(%__MODULE__{confidence: c}) when is_number(c), do: c
  def get_aggregate_confidence(_), do: 0.0

  @doc """
  Evaluates promotion thresholds based on evidence and confidence.
  """
  def promote(%__MODULE__{} = disc) do
    agg_conf = get_aggregate_confidence(disc)
    cond do
      disc.operational_runs_evidence > 50 ->
        {:ok, %{disc | status: :validated}}

      disc.worlds_evidence > 500 and agg_conf > 0.75 ->
        {:ok, %{disc | status: :supported_law}}

      disc.worlds_evidence > 100 and agg_conf > 0.6 ->
        {:ok, %{disc | status: :candidate_law}}

      true ->
        {:error, :threshold_not_met}
    end
  end

  @doc """
  Loads all discoveries from persistence.
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
            
            # Format confidence to support atom key mapping
            attrs = 
              case attrs[:confidence] do
                %{simulation: _} = conf -> Map.put(attrs, :confidence, conf)
                %{"simulation" => _} = conf ->
                  Map.put(attrs, :confidence, %{
                    simulation: conf["simulation"],
                    operational: conf["operational"],
                    theoretical: conf["theoretical"],
                    consensus: conf["consensus"]
                  })
                _ -> attrs
              end

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
  Saves a single discovery.
  """
  def save(%__MODULE__{} = disc) do
    File.mkdir_p!(Path.dirname(@file_path))
    disc = %{disc | timestamp: disc.timestamp || DateTime.utc_now() |> DateTime.to_iso8601()}
    line = Jason.encode!(disc) <> "\n"
    File.write!(@file_path, line, [:append])
    {:ok, disc}
  end

  @doc """
  Saves all discoveries back to the file.
  """
  def write_all(list) do
    File.mkdir_p!(Path.dirname(@file_path))
    content = Enum.map(list, fn disc -> Jason.encode!(disc) <> "\n" end) |> Enum.join("")
    File.write!(@file_path, content)
    :ok
  end

  def seeds do
    [
      %__MODULE__{
        id: "structured_forgetting",
        name: "Structured Forgetting",
        confidence: %{simulation: 0.92, operational: 0.18, theoretical: 0.88, consensus: 0.84},
        worlds_evidence: 430,
        operational_runs_evidence: 12,
        claim: "Peak generativity occurs at intermediate retention levels",
        status: :candidate_law,
        scientific_impact: 0.85,
        operational_impact: 0.75,
        architectural_impact: 0.90,
        parents: [],
        children: ["adaptive_memory_ecology"],
        influenced_by: [],
        influences: ["adaptive_memory_ecology"],
        falsification_attempts: 14,
        successful_challenges: 3,
        survived_challenges: 11,
        timestamp: "2026-06-11T12:00:00Z"
      },
      %__MODULE__{
        id: "scp_retention_boundary",
        name: "SCP Retention Boundary",
        confidence: %{simulation: 0.95, operational: 0.25, theoretical: 0.90, consensus: 0.88},
        worlds_evidence: 550,
        operational_runs_evidence: 20,
        claim: "Regenerative recovery occurs when scp_retention > 0.178",
        status: :supported_law,
        scientific_impact: 0.95,
        operational_impact: 0.80,
        architectural_impact: 0.85,
        parents: [],
        children: ["regenerative_governance"],
        influenced_by: [],
        influences: ["regenerative_governance"],
        falsification_attempts: 20,
        successful_challenges: 2,
        survived_challenges: 18,
        timestamp: "2026-06-11T12:30:00Z"
      },
      %__MODULE__{
        id: "generative_orbit_equivalence",
        name: "Generative Orbit Equivalence",
        confidence: %{simulation: 0.98, operational: 0.10, theoretical: 0.95, consensus: 0.92},
        worlds_evidence: 500,
        operational_runs_evidence: 5,
        claim: "Phoenix and Settler families converge onto equivalent orbit geometries, proving Navigators are search heuristics.",
        status: :candidate_law,
        scientific_impact: 0.98,
        operational_impact: 0.85,
        architectural_impact: 0.90,
        parents: ["structured_forgetting", "scp_retention_boundary"],
        children: [],
        influenced_by: ["structured_forgetting", "scp_retention_boundary"],
        influences: ["research_optimization"],
        falsification_attempts: 12,
        successful_challenges: 0,
        survived_challenges: 12,
        timestamp: "2026-06-11T18:00:00Z"
      },
      %__MODULE__{
        id: "identity_sustained_regeneration",
        name: "Identity-Sustained Regeneration",
        confidence: %{simulation: 0.99, operational: 0.30, theoretical: 0.95, consensus: 0.95},
        worlds_evidence: 500,
        operational_runs_evidence: 15,
        claim: "Identity Persistence (I) is the primary invariant sustaining repeated entry into generative orbits under collapse.",
        status: :supported_law,
        scientific_impact: 0.99,
        operational_impact: 0.90,
        architectural_impact: 0.95,
        parents: ["structured_forgetting"],
        children: [],
        influenced_by: ["structured_forgetting"],
        influences: ["uncertainty_weighted_governance"],
        falsification_attempts: 15,
        successful_challenges: 1,
        survived_challenges: 14,
        timestamp: "2026-06-11T18:15:00Z"
      }
    ]
  end
end
