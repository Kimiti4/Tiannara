defmodule Tiannara.Research.Director do
  @moduledoc """
  The Research Director upgrades. Handles dynamic allocations across domains, portfolio diversity calculations,
  recommends primary and cross-domain experiments, and closes the scientific loop by propagating outcome feedback.
  """
  @derive Jason.Encoder
  defstruct [
    :id,
    :target_unknown_id,
    :target_theory_id,
    :target_domain_id,
    :experiment_name,
    :expected_information_gain,      # float 0..1
    :expected_uncertainty_reduction, # float 0..1
    :expected_dvr_gain,              # float 0..1
    :reason_explanation,             # String explanation "Why this experiment?"
    :status,                         # :proposed | :scheduled
    type: :primary                   # :primary | :cross_domain_transfer
  ]

  alias Tiannara.KnowledgeGraph.Registry, as: KG
  alias Tiannara.Domains.Registry, as: DomReg
  alias Tiannara.Domains.TransferMatrix

  @file_path "data/director_proposals.ndjson"

  @doc """
  Loads all proposals from persistence.
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
              |> Map.update!(:status, &String.to_atom(to_string(&1)))
              |> Map.update!(:type, &String.to_atom(to_string(&1 || :primary)))
            struct(__MODULE__, attrs)
          _ -> nil
        end
      end)
      |> Stream.reject(&is_nil/1)
      |> Enum.to_list()
    else
      list = generate_proposals()
      write_all(list)
      list
    end
  end

  @doc """
  Saves a single proposal.
  """
  def save(%__MODULE__{} = prop) do
    list = all()
    new_list = 
      if Enum.any?(list, & &1.id == prop.id) do
        Enum.map(list, fn p -> if p.id == prop.id, do: prop, else: p end)
      else
        list ++ [prop]
      end

    write_all(new_list)
    {:ok, prop}
  end

  @doc """
  Saves all proposals back to the file.
  """
  def write_all(list) do
    File.mkdir_p!(Path.dirname(@file_path))
    content = Enum.map(list, fn prop -> Jason.encode!(prop) <> "\n" end) |> Enum.join("")
    File.write!(@file_path, content)
    :ok
  end

  @doc """
  Generates allocations of research effort across the 20 domains based on active programs and operational maturity.
  Returns a map of %{domain_id => allocation_percentage}.
  """
  def get_domain_allocations do
    domains = DomReg.all()
    # Calculate recommended allocations
    raw_allocs = Enum.reduce(domains, %{}, fn dom, acc ->
      vector = DomReg.get_portfolio_vector(dom.id)
      # Allocate higher effort to active but low maturity domains
      active_weight = if dom.status == :active, do: 1.0, else: 0.1
      # Lower operational maturity (e.g. 1.0 - maturity) means we need more focus
      maturity_deficit = max(1.0 - vector.operational_maturity, 0.05)
      
      score = active_weight * maturity_deficit * (vector.research_debt + 1.0)
      Map.put(acc, dom.id, score)
    end)

    total_score = Enum.sum(Map.values(raw_allocs))
    if total_score > 0 do
      Enum.reduce(raw_allocs, %{}, fn {k, v}, acc -> Map.put(acc, k, Float.round(v / total_score, 2)) end)
    else
      Enum.reduce(domains, %{}, fn dom, acc -> Map.put(acc, dom.id, 1.0 / Enum.count(domains)) end)
    end
  end

  @doc """
  Identifies neglected domains (active status, low operational maturity < 0.3).
  """
  def identify_neglected_domains do
    DomReg.all()
    |> Enum.filter(fn dom ->
      vector = DomReg.get_portfolio_vector(dom.id)
      dom.status == :active and vector.operational_maturity < 0.3
    end)
  end

  @doc """
  Evaluates Shannon entropy diversity across domain allocations.
  Returns %{entropy: float, status: :balanced | :skewed, recommendation: string}
  """
  def balance_portfolio do
    allocs = get_domain_allocations()
    vals = Map.values(allocs) |> Enum.filter(& &1 > 0)
    
    entropy = -Enum.sum(Enum.map(vals, fn p -> p * :math.log(p) end))
    
    status = if entropy > 2.0, do: :balanced, else: :skewed
    recommendation = 
      if status == :skewed do
        "Research portfolio is heavily skewed. Increase allocations to neglected domains like Medicine or Robotics to improve cross-pollination."
      else
        "Research portfolio is well-balanced across multiple scientific domains. Continue exploring."
      end

    %{entropy: Float.round(entropy, 2), status: status, recommendation: recommendation}
  end

  @doc """
  Upgraded experiment recommender traversing:
  Domain -> Program -> Theory Gap -> Unknown -> Experiment -> Discovery -> Cross-Domain Application.
  """
  def recommend_experiments do
    nodes = KG.all()
    domains = DomReg.all()
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

    # 1. Primary recommendations for unresolved unknowns
    primary_props = Enum.flat_map(domains, fn dom ->
      vector = DomReg.get_portfolio_vector(dom.id)
      Enum.flat_map(dom.program_ids || [], fn prog_id ->
        # Find unknowns of the program
        program = Enum.find(programs, fn p -> to_string(p.id) == to_string(prog_id) end)
        prog_unknown_ids = (program && program.unknowns) || []
        relevant_unknowns = Enum.filter(unknowns, fn u -> to_string(u.id) in Enum.map(prog_unknown_ids, &to_string/1) end)
        
        Enum.map(relevant_unknowns, fn unknown ->
          %__MODULE__{
            id: "prop_p_#{dom.id}_#{unknown.id}",
            target_unknown_id: unknown.id,
            target_theory_id: "adaptive_memory_ecology_theory",
            target_domain_id: dom.id,
            experiment_name: "Optimize #{unknown.id} simulation run (REA-#{dom.id})",
            expected_information_gain: Float.round(0.85 - (vector.operational_maturity * 0.2), 2),
            expected_uncertainty_reduction: Float.round(0.90 - (vector.validation_depth * 0.2), 2),
            expected_dvr_gain: 0.10,
            reason_explanation: "Proposed for the #{dom.name} domain under program #{prog_id} to resolve unknown #{unknown.id}. Expected to improve operational maturity.",
            status: :proposed,
            type: :primary
          }
        end)
      end)
    end)

    # 2. Cross-domain transfer recommendations
    discoveries = Enum.filter(nodes, & &1.type == :discovery)

    cross_props = Enum.flat_map(discoveries, fn discovery ->
      # Find ancestor principles of discovery
      parent_principles = find_ancestor_principles(discovery, nodes)

      Enum.flat_map(parent_principles, fn principle ->
        # Find domains listed in parent principle where this discovery is not currently applied
        target_domains = Enum.filter(principle.domains, fn target_dom ->
          target_dom_atom = String.to_atom(to_string(target_dom))
          not (target_dom_atom in discovery.domains)
        end)

        Enum.map(target_domains, fn target_dom ->
          %__MODULE__{
            id: "prop_c_#{discovery.id}_to_#{target_dom}",
            target_unknown_id: "un_transfer_#{discovery.id}",
            target_theory_id: "uncertainty_weighted_governance_theory",
            target_domain_id: target_dom,
            experiment_name: "Cross-Domain Transfer: #{discovery.name} to #{target_dom}",
            expected_information_gain: 0.80,
            expected_uncertainty_reduction: 0.75,
            expected_dvr_gain: 0.15,
            reason_explanation: "Proposed to transfer discovery #{discovery.name} to domain #{target_dom} utilizing universal principle #{principle.name}.",
            status: :proposed,
            type: :cross_domain_transfer
          }
        end)
      end)
    end)

    primary_props ++ cross_props
  end

  defp find_ancestor_principles(node, nodes) do
    traverse_ancestors([node], nodes, MapSet.new())
  end

  defp traverse_ancestors([], _nodes, acc), do: MapSet.to_list(acc)
  defp traverse_ancestors([node | rest], nodes, acc) do
    if node.type == :principle do
      traverse_ancestors(rest, nodes, MapSet.put(acc, node))
    else
      parents = Enum.filter(nodes, fn n -> to_string(n.id) in Enum.map(node.parents || [], &to_string/1) end)
      traverse_ancestors(parents ++ rest, nodes, acc)
    end
  end

  @doc """
  Traces downstream outcome evidence back up the graph to dynamically adjust Principle confidence levels.
  Outcome Evidence -> Intervention -> Discovery/Law -> Principle Confidence Update
  """
  def evaluate_outcomes_and_update_principles do
    nodes = KG.all()
    outcomes = Enum.filter(nodes, & &1.type == :outcome)
    
    updated_nodes = Enum.reduce(outcomes, nodes, fn outcome, acc_nodes ->
      dvr_gain = outcome.metadata[:dvr_gain] || outcome.metadata["dvr_gain"] || 0.0
      
      # Trace parents (interventions)
      parent_interventions = Enum.filter(acc_nodes, fn n -> 
        to_string(n.id) in Enum.map(outcome.parents || [], &to_string/1) and n.type == :intervention 
      end)
      
      Enum.reduce(parent_interventions, acc_nodes, fn intervention, acc_nodes2 ->
        # Adjust success rating
        curr_rating = intervention.metadata[:success_rating] || intervention.metadata["success_rating"] || 0.75
        new_rating = min(curr_rating + dvr_gain, 1.0)
        intervention = Map.update!(intervention, :metadata, &Map.put(&1, :success_rating, new_rating))
        acc_nodes2_updated = Enum.map(acc_nodes2, fn n -> if n.id == intervention.id, do: intervention, else: n end)
        
        # Trace parents (discoveries/laws)
        parent_discoveries = Enum.filter(acc_nodes2_updated, fn n -> 
          to_string(n.id) in Enum.map(intervention.parents || [], &to_string/1) and n.type in [:discovery, :law] 
        end)
        
        Enum.reduce(parent_discoveries, acc_nodes2_updated, fn discovery, acc_nodes3 ->
          # Find parent principles and theories
          parent_principles = Enum.filter(acc_nodes3, fn n -> 
            to_string(n.id) in Enum.map(discovery.parents || [], &to_string/1) and n.type == :principle 
          end)
          
          parent_theories = Enum.filter(acc_nodes3, fn n -> 
            to_string(n.id) in Enum.map(discovery.parents || [], &to_string/1) and n.type == :theory 
          end)
          
          more_principles = Enum.flat_map(parent_theories, fn theory ->
            Enum.filter(acc_nodes3, fn n -> 
              to_string(n.id) in Enum.map(theory.parents || [], &to_string/1) and n.type == :principle 
            end)
          end)
          
          all_principles = Enum.uniq_by(parent_principles ++ more_principles, & &1.id)
          
          # Update principle confidence
          Enum.reduce(all_principles, acc_nodes3, fn principle, acc_nodes4 ->
            current_conf = principle.metadata[:confidence] || 0.85
            new_conf = min(current_conf + dvr_gain * 0.5, 1.0)
            principle = Map.update!(principle, :metadata, &Map.put(&1, :confidence, new_conf))
            Enum.map(acc_nodes4, fn n -> if n.id == principle.id, do: principle, else: n end)
          end)
        end)
      end)
    end)
    
    KG.write_all(updated_nodes)
    :ok
  end

  @doc """
  For backward compatibility with tests. Returns a hardcoded list of proposals.
  """
  def generate_proposals do
    [
      %__MODULE__{
        id: "prop1",
        target_unknown_id: "un1",
        target_theory_id: "adaptive_memory_ecology",
        experiment_name: "Stability Lower Bound Sweep (REA-12A)",
        expected_information_gain: 0.82,
        expected_uncertainty_reduction: 0.91,
        expected_dvr_gain: 0.05,
        reason_explanation: "Directly resolves high-priority unknown regarding 10% lower retention bounds in the Adaptive Memory Ecology theory. Minimizes stability risk before phase transitions.",
        status: :proposed
      },
      %__MODULE__{
        id: "prop2",
        target_unknown_id: "un2",
        target_theory_id: "regenerative_governance",
        experiment_name: "Asymmetric Specialization Longitudinal Run (REA-13A)",
        expected_information_gain: 0.70,
        expected_uncertainty_reduction: 0.78,
        expected_dvr_gain: 0.15,
        reason_explanation: "Validates long-term DVR impacts of the asymmetric specialization law, resolving medium-priority research debt in Regenerative Governance.",
        status: :proposed
      }
    ]
  end
end
