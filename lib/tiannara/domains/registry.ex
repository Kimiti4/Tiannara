defmodule Tiannara.Domains.Registry do
  @moduledoc """
  Manages persistence of static Domain metadata and dynamically projects Knowledge Graph data
  to calculate domain portfolio vectors and knowledge capital.
  """
  alias Tiannara.Domains.Domain
  alias Tiannara.KnowledgeGraph.Registry, as: KG
  alias Tiannara.Domains.TransferMatrix

  @file_path "data/domains.ndjson"

  @doc """
  Loads all static domains from persistence.
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
            attrs = Map.update!(attrs, :id, &String.to_atom(to_string(&1)))
            struct(Domain, attrs)
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
  Finds a single domain by ID.
  """
  def get(id) do
    id_str = to_string(id)
    Enum.find(all(), & (to_string(&1.id) == id_str))
  end

  @doc """
  Saves a single domain metadata.
  """
  def save(%Domain{} = domain) do
    list = all()
    new_list = 
      if Enum.any?(list, & &1.id == domain.id) do
        Enum.map(list, fn d -> if d.id == domain.id, do: domain, else: d end)
      else
        list ++ [domain]
      end

    write_all(new_list)
    {:ok, domain}
  end

  @doc """
  Writes all domain metadata to persistence.
  """
  def write_all(list) do
    File.mkdir_p!(Path.dirname(@file_path))
    content = Enum.map(list, fn domain -> Jason.encode!(domain) <> "\n" end) |> Enum.join("")
    File.write!(@file_path, content)
    :ok
  end

  @doc """
  Computes the dynamic knowledge portfolio vector for a domain by querying the Knowledge Graph.
  """
  def get_portfolio_vector(domain_id) do
    domain_id_atom = String.to_atom(to_string(domain_id))
    nodes = KG.all()
    transfers = TransferMatrix.all()

    # Mapped nodes in the domain
    domain_discoveries = Enum.filter(nodes, fn n -> n.type == :discovery and domain_id_atom in n.domains end)
    domain_interventions = Enum.filter(nodes, fn n -> n.type == :intervention and domain_id_atom in n.domains end)
    
    # 1. Discovery Power
    discovery_power = Enum.count(domain_discoveries) * 1.0

    # 2. Intervention Power
    intervention_power =
      if Enum.empty?(domain_interventions) do
        0.75 # default baseline success
      else
        sum = Enum.sum(Enum.map(domain_interventions, fn i -> 
          i.metadata[:success_rating] || i.metadata["success_rating"] || 0.75 
        end))
        sum / Enum.count(domain_interventions)
      end

    # 3. Transferability
    relevant_transfers = Enum.filter(transfers, & (&1.source_domain == domain_id_atom or &1.target_domain == domain_id_atom))
    transferability =
      if Enum.empty?(relevant_transfers) do
        0.80 # default baseline
      else
        Enum.sum(Enum.map(relevant_transfers, & &1.transfer_success)) / Enum.count(relevant_transfers)
      end

    # 4. Research Debt & Uncertainty
    unknowns = 
      try do
        Tiannara.Discoveries.Unknown.all()
      rescue
        _ -> []
      end
    
    programs =
      try do
        Tiannara.Discoveries.Program.all()
      rescue
        _ -> []
      end
    
    # Find active programs belonging to this domain
    domain_programs = Enum.filter(all(), & &1.id == domain_id_atom) |> Enum.flat_map(& &1.program_ids || [])
    
    domain_programs_meta = Enum.filter(programs, fn p -> to_string(p.id) in Enum.map(domain_programs, &to_string/1) end)
    domain_unknown_ids = Enum.flat_map(domain_programs_meta, & &1.unknowns || [])

    domain_unknowns = Enum.filter(unknowns, fn u -> 
      to_string(u.id) in Enum.map(domain_unknown_ids, &to_string/1)
    end)
    
    research_debt = Enum.count(domain_unknowns) * 1.0
    uncertainty = research_debt / (discovery_power + research_debt + 1.0)

    # 5. Validation Depth
    validation_depth =
      if Enum.empty?(domain_discoveries) do
        0.85 # default validation
      else
        sum = Enum.sum(Enum.map(domain_discoveries, fn d ->
          conf = d.metadata[:confidence] || d.metadata["confidence"]
          case conf do
            %{simulation: s, operational: o, theoretical: t, consensus: c} -> (s + o + t + c) / 4.0
            %{"simulation" => s, "operational" => o, "theoretical" => t, "consensus" => c} -> (s + o + t + c) / 4.0
            c when is_number(c) -> c
            _ -> 0.85
          end
        end))
        sum / Enum.count(domain_discoveries)
      end

    # 6. Operational Maturity
    operational_maturity =
      if Enum.empty?(domain_discoveries) and Enum.empty?(domain_interventions) do
        0.10
      else
        validation_depth * intervention_power
      end

    %{
      discovery_power: Float.round(discovery_power, 2),
      intervention_power: Float.round(intervention_power, 2),
      transferability: Float.round(transferability, 2),
      uncertainty: Float.round(uncertainty, 2),
      research_debt: Float.round(research_debt, 2),
      validation_depth: Float.round(validation_depth, 2),
      operational_maturity: Float.round(operational_maturity, 2)
    }
  end

  @doc """
  Computes composite Knowledge Capital score: validated discoveries * intervention success * transferability.
  """
  def get_knowledge_capital(domain_id) do
    portfolio = get_portfolio_vector(domain_id)
    # We cap base discoveries at 1.0 if it is 0.0 to prevent total zeroing out for starting domains
    discoveries = max(portfolio.discovery_power, 1.0)
    score = discoveries * portfolio.intervention_power * portfolio.transferability
    Float.round(score, 2)
  end

  @doc """
  Initial seeds containing the 20 requested domains as lenses.
  """
  def seeds do
    [
      %Domain{id: :engineering, name: "Engineering", description: "Mechanical, civil, and physical resilience structures.", program_ids: ["resilient_systems", "adaptive_architecture"], status: :active},
      %Domain{id: :medicine, name: "Medicine", description: "Biological adaptability and systemic health preservation.", program_ids: ["adaptive_treatment_systems", "biological_resilience"], status: :active},
      %Domain{id: :governance, name: "Governance", description: "Constitutional steering and authority allocation protocols.", program_ids: ["constitutional_navigation", "uncertainty_allocation"], status: :active},
      %Domain{id: :computation, name: "Computation", description: "Algorithms, information entropy, and learning memory.", program_ids: ["adaptive_computation", "memory_ecology"], status: :active},
      %Domain{id: :science, name: "Science", description: "Epistemology, reasoning engines, and discovery methodology.", program_ids: [], status: :active},
      %Domain{id: :agriculture, name: "Agriculture", description: "Food systems, metabolic ecology, and nutrient distribution.", program_ids: [], status: :active},
      %Domain{id: :energy, name: "Energy", description: "Power generation, containment, and network distribution.", program_ids: ["energy_network_adaptation"], status: :active},
      %Domain{id: :logistics, name: "Logistics", description: "Resource routing, supply chain topology, and transport.", program_ids: [], status: :active},
      %Domain{id: :cognition, name: "Cognition", description: "Evolving intelligence and mental modeling frameworks.", program_ids: ["intelligence_evolution"], status: :active},
      %Domain{id: :materials, name: "Materials", description: "Structural property modulation and chemical resilience.", program_ids: [], status: :active},
      %Domain{id: :robotics, name: "Robotics", description: "Autonomous physical loops and mechanical steering.", program_ids: ["autonomous_resilience", "embodied_adaptation"], status: :active},
      %Domain{id: :economics, name: "Economics", description: "Resource exchange, market dynamics, and game theory.", program_ids: ["market_navigation_dynamics"], status: :active},
      %Domain{id: :philosophy, name: "Philosophy", description: "Metaphysics, logic systems, and ethical boundary conditions.", program_ids: [], status: :active},
      %Domain{id: :sociology, name: "Sociology", description: "Collective systems behavior and Speciation structures.", program_ids: [], status: :active},
      %Domain{id: :linguistics, name: "Linguistics", description: "Information coding, semantic structures, and data mesh.", program_ids: [], status: :active},
      %Domain{id: :aerospace, name: "Aerospace", description: "High-velocity trajectory physics and orbital navigation.", program_ids: [], status: :active},
      %Domain{id: :ecology, name: "Ecology", description: "Biological feedback loops and dynamic basin preservation.", program_ids: [], status: :active},
      %Domain{id: :cybernetics, name: "Cybernetics", description: "Feedback controls, negative entropy, and recursive steering.", program_ids: ["recursive_control_systems"], status: :active},
      %Domain{id: :architecture, name: "Architecture", description: "Possibility space design and topological boundaries.", program_ids: [], status: :active},
      %Domain{id: :mathematics, name: "Mathematics", description: "Pure geometry, tensor fields, and dynamic topology.", program_ids: ["adaptation_geometry"], status: :active},
      %Domain{id: :software_engineering, name: "Software Engineering", description: "Architecture evolution, API fitness, autonomous repair, and software law discovery — operated by the ASC civilization.", program_ids: ["architecture_evolution", "api_fitness", "autonomous_repair"], status: :active}
    ]
  end
end
