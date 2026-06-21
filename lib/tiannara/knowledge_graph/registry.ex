defmodule Tiannara.KnowledgeGraph.Registry do
  @moduledoc """
  Handles persistence and dynamic querying for the unified Knowledge Graph.
  Data is stored in `data/knowledge_graph.ndjson`.
  """
  alias Tiannara.KnowledgeGraph.Node

  @file_path "data/knowledge_graph.ndjson"

  @doc """
  Loads all knowledge nodes from persistence.
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
            attrs = Map.update!(attrs, :type, &String.to_atom(to_string(&1)))
            domains = Enum.map(attrs[:domains] || [], &String.to_atom(to_string(&1)))
            attrs = Map.put(attrs, :domains, domains)
            struct(Node, attrs)
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
  Finds a single node by ID.
  """
  def get(id) do
    id_str = to_string(id)
    Enum.find(all(), & (to_string(&1.id) == id_str))
  end

  @doc """
  Saves a single node (inserting or updating existing).
  """
  def save(%Node{} = node) do
    list = all()
    node = %{node | timestamp: node.timestamp || DateTime.utc_now() |> DateTime.to_iso8601()}
    
    new_list = 
      if Enum.any?(list, & &1.id == node.id) do
        Enum.map(list, fn n -> if n.id == node.id, do: node, else: n end)
      else
        list ++ [node]
      end

    write_all(new_list)
    {:ok, node}
  end

  @doc """
  Saves a list of nodes.
  """
  def write_all(list) do
    File.mkdir_p!(Path.dirname(@file_path))
    content = Enum.map(list, fn node -> Jason.encode!(node) <> "\n" end) |> Enum.join("")
    File.write!(@file_path, content)
    :ok
  end

  @doc """
  Initial seeds containing Principles, Theories, Laws, Discoveries, Interventions, and Outcomes.
  """
  def seeds do
    [
      # --- PRINCIPLES ---
      %Node{
        id: "optionality_preservation",
        type: :principle,
        name: "Optionality Preservation",
        description: "Maximize potential degrees of freedom and future states in the phase space.",
        domains: [:medicine, :economics, :robotics],
        metadata: %{confidence: 0.90}
      },
      %Node{
        id: "uncertainty_weighted_governance",
        type: :principle,
        name: "Uncertainty-Weighted Governance",
        description: "Modulate control constraints dynamically according to the volatility and unpredictability of the environment.",
        domains: [:governance, :economics, :cybernetics],
        metadata: %{confidence: 0.92}
      },
      %Node{
        id: "adaptive_memory_ecology",
        type: :principle,
        name: "Adaptive Memory Ecology",
        description: "Balance system structural persistence and decay parameters to optimize possibility space emergence.",
        domains: [:cognition, :computation, :engineering],
        metadata: %{confidence: 0.88}
      },

      # --- THEORIES ---
      %Node{
        id: "adaptive_memory_ecology_theory",
        type: :theory,
        name: "Adaptive Memory Ecology",
        description: "Peak generativity occurs at intermediate levels of retention because structured forgetting allows possibility spaces to adapt.",
        domains: [:cognition, :computation, :engineering],
        parents: ["adaptive_memory_ecology"],
        children: ["structured_forgetting", "identity_sustained_regeneration"],
        metadata: %{
          evidence_strength: 0.82,
          contradiction_pressure: 0.12,
          operational_support: 0.10,
          research_debt: "Medium"
        }
      },
      %Node{
        id: "regenerative_governance_theory",
        type: :theory,
        name: "Regenerative Governance",
        description: "Civilization structures regenerate adaptively when topological network redundancy is kept above the recovery threshold.",
        domains: [:governance, :economics, :cybernetics],
        parents: ["uncertainty_weighted_governance"],
        children: ["scp_retention_boundary"],
        metadata: %{
          evidence_strength: 0.90,
          contradiction_pressure: 0.08,
          operational_support: 0.20,
          research_debt: "Low"
        }
      },
      %Node{
        id: "uncertainty_weighted_governance_theory",
        type: :theory,
        name: "Uncertainty-Weighted Governance",
        description: "The optimal institution allocates control dynamically according to uncertainty, shifting authority from strict managerial protocols to metaplastic governors.",
        domains: [:governance, :economics, :cybernetics],
        parents: ["uncertainty_weighted_governance"],
        children: [],
        metadata: %{
          evidence_strength: 0.88,
          contradiction_pressure: 0.05,
          operational_support: 0.15,
          research_debt: "Low"
        }
      },

      # --- LAWS ---
      %Node{
        id: "structured_forgetting",
        type: :law,
        name: "Structured Forgetting",
        description: "Peak generativity occurs at intermediate retention levels.",
        domains: [:cognition, :computation, :engineering],
        parents: ["adaptive_memory_ecology_theory"],
        children: ["int1"],
        metadata: %{
          confidence: %{simulation: 0.92, operational: 0.18, theoretical: 0.88, consensus: 0.84},
          status: :candidate_law,
          worlds_evidence: 430,
          falsification_attempts: 14,
          survived_challenges: 11
        }
      },
      %Node{
        id: "scp_retention_boundary",
        type: :law,
        name: "SCP Retention Boundary",
        description: "Regenerative recovery occurs when scp_retention > 0.178.",
        domains: [:governance, :economics, :cybernetics],
        parents: ["regenerative_governance_theory"],
        children: ["int2"],
        metadata: %{
          confidence: %{simulation: 0.95, operational: 0.25, theoretical: 0.90, consensus: 0.88},
          status: :supported_law,
          worlds_evidence: 550,
          falsification_attempts: 20,
          survived_challenges: 18
        }
      },
      %Node{
        id: "identity_sustained_regeneration",
        type: :law,
        name: "Identity-Sustained Regeneration",
        description: "Identity Persistence (I) is the primary invariant sustaining repeated entry into generative orbits under collapse.",
        domains: [:cognition, :computation, :engineering],
        parents: ["adaptive_memory_ecology_theory"],
        children: [],
        metadata: %{
          confidence: %{simulation: 0.99, operational: 0.30, theoretical: 0.95, consensus: 0.95},
          status: :supported_law,
          worlds_evidence: 500,
          falsification_attempts: 15,
          survived_challenges: 14
        }
      },

      # --- DISCOVERIES ---
      %Node{
        id: "generative_orbit_equivalence",
        type: :discovery,
        name: "Generative Orbit Equivalence",
        description: "Phoenix and Settler families converge onto equivalent orbit geometries, proving Navigators are search heuristics.",
        domains: [:mathematics, :engineering, :computation],
        parents: ["structured_forgetting", "scp_retention_boundary"],
        children: [],
        metadata: %{
          confidence: %{simulation: 0.98, operational: 0.10, theoretical: 0.95, consensus: 0.92},
          status: :candidate_law,
          worlds_evidence: 500,
          falsification_attempts: 12,
          survived_challenges: 12
        }
      },

      # --- INTERVENTIONS ---
      %Node{
        id: "int1",
        type: :intervention,
        name: "Specialist Context Retention = 55%",
        description: "Active memory constraint policy targeting intermediate retention levels.",
        domains: [:engineering, :computation],
        parents: ["structured_forgetting"],
        children: ["out1"],
        metadata: %{status: :executed, success_rating: 0.85}
      },
      %Node{
        id: "int2",
        type: :intervention,
        name: "Graduated Trust Allocation",
        description: "Uncertainty-weighted governor allocating local auth bounds dynamically.",
        domains: [:governance, :economics],
        parents: ["scp_retention_boundary"],
        children: ["out2"],
        metadata: %{status: :executed, success_rating: 0.80}
      },

      # --- OUTCOMES ---
      %Node{
        id: "out1",
        type: :outcome,
        name: "DVR +12%",
        description: "Significant positive return on adaptability and functional preservation metrics.",
        domains: [:engineering, :computation],
        parents: ["int1"],
        metadata: %{dvr_gain: 0.12, status: :evaluated}
      },
      %Node{
        id: "out2",
        type: :outcome,
        name: "Conflict Resonance -34%",
        description: "Drastic drop in systemic violations and constraint friction.",
        domains: [:governance, :economics],
        parents: ["int2"],
        metadata: %{dvr_gain: 0.08, status: :evaluated}
      }
    ]
  end
end
