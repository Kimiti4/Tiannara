defmodule Tiannara.Sentinel.D2.SpeciesAtlas do
  defstruct [dominant_species: [], extinct_species: [], niche_specialists: [], universalists: [], attractors: []]
end

defmodule Tiannara.Sentinel.D2.OperatorEcology do
  defstruct [synergies: %{}, antagonisms: %{}, neutral_pairs: %{}, disease_susceptibility: %{}]
end

defmodule Tiannara.Sentinel.D2.EpistemicAttractor do
  defstruct [
    operators: [],
    emergence_count: 0,
    first_seen: nil,
    last_seen: nil,
    half_life: 0.0,
    regime_distribution: %{},
    average_fitness: 0.0,
    breakthrough_rate: 0.0,
    truth_retention: 0.0,
    disease_resistance: 0.0,
    deep_module_affinity: %{}
  ]
end

defmodule Tiannara.Sentinel.D2.DiversityProfile do
  defstruct [
    operator_entropy: 0.0,
    species_entropy: 0.0,
    niche_entropy: 0.0,
    discovery_entropy: 0.0,
    phylogenetic_diversity: 0.0,
    attractor_concentration: 0.0
  ]
end

defmodule Tiannara.Sentinel.D2.EcosystemHealth do
  defstruct [diversity_profile: %Tiannara.Sentinel.D2.DiversityProfile{}, breakthrough_velocity: 0.0, extinction_velocity: 0.0]
end

defmodule Tiannara.Sentinel.D2.EpistemicArchetype do
  defstruct [
    id: nil,
    dominant_operators: [],
    persistence: 0,
    truth_retention: 0.0,
    disease_resistance: 0.0,
    breakthrough_profile: 0.0,
    extinction_rate: 0.0,
    deep_module_affinity: %{}
  ]
end

defmodule Tiannara.Sentinel.D2.UnknownRegion do
  defstruct [
    operator_combination: [],
    novelty_score: 0.0,
    accessibility_score: 0.0,
    instability_score: 0.0,
    exploration_priority: 0.0
  ]
end

defmodule Tiannara.Sentinel.D2.MetaCognitionReadiness do
  defstruct [
    basin_escape_rate: 0.0,
    productive_escape_rate: 0.0,
    species_stability: 0.0,
    extinction_cycles: 0.0,
    species_diversity: 0.0,
    regime_robustness: 0.0,
    avg_epistemic_resilience: 0.0,
    overall_score: 0.0
  ]
end

defmodule Tiannara.Sentinel.D2.AnalyticsEngine do
  @moduledoc """
  D.2: The Meta-Analytics layer for Phase 9.85/9.9 Ecological Observation.
  """
  alias Tiannara.Sentinel.D2.{EpistemologySpecies, EpistemologyGraph, BreakthroughAnalyzer}
  alias Tiannara.Sentinel.D2.{
    SpeciesAtlas,
    OperatorEcology,
    EpistemicAttractor,
    DiversityProfile,
    EcosystemHealth,
    EpistemicArchetype,
    UnknownRegion,
    MetaCognitionReadiness
  }

  def calculate_species_atlas(pipeline_telemetry \\ %{}) do
    all_species = EpistemologySpecies.get_all_species()
    sorted = Enum.sort_by(all_species, & &1.metrics.active_duration, :desc)
    dominant = sorted |> Enum.take(5)
    extinct = Enum.filter(sorted, fn sp -> sp.metrics.extinctions > 0 end) |> Enum.sort_by(& &1.metrics.extinctions, :desc)

    %SpeciesAtlas{
      dominant_species: dominant,
      extinct_species: extinct,
      niche_specialists: [],
      universalists: dominant,
      attractors: detect_attractors(pipeline_telemetry)
    }
  end

  def calculate_operator_ecology do
    graph = EpistemologyGraph.get_ecology_map()
    synergies = Enum.filter(graph, fn {_, score} -> score > 0 end) |> Enum.into(%{})
    antagonisms = Enum.filter(graph, fn {_, score} -> score < 0 end) |> Enum.into(%{})
    neutral = Enum.filter(graph, fn {_, score} -> score == 0 end) |> Enum.into(%{})

    %OperatorEcology{synergies: synergies, antagonisms: antagonisms, neutral_pairs: neutral, disease_susceptibility: %{}}
  end

  def detect_attractors(pipeline_telemetry \\ %{}) do
    all_species = EpistemologySpecies.get_all_species()
    breakthroughs = BreakthroughAnalyzer.get_breakthroughs()
    
    Enum.map(all_species, fn sp ->
      b_count = Enum.count(breakthroughs, fn b -> MapSet.new(sp.operators) == MapSet.new(b.context.operators) end)
      
      %EpistemicAttractor{
        operators: sp.operators,
        emergence_count: sp.metrics.descendants + 1,
        first_seen: 0, 
        last_seen: sp.metrics.active_duration,
        half_life: sp.metrics.active_duration / max(1.0, sp.metrics.extinctions),
        regime_distribution: %{medium_acm: 1.0}, 
        average_fitness: min(1.0, sp.metrics.active_duration / 500.0),
        breakthrough_rate: b_count / max(1.0, sp.metrics.active_duration),
        truth_retention: 0.9,
        disease_resistance: 1.0 - min(1.0, sp.metrics.extinctions * 0.1),
        deep_module_affinity: Map.get(pipeline_telemetry, :active_modules, %{crca: 0.8, reg: 0.9, tcl: 0.7})
      }
    end)
    |> Enum.filter(fn att -> att.emergence_count > 0 and att.breakthrough_rate > 0.0 end)
    |> Enum.sort_by(& &1.breakthrough_rate, :desc)
    |> Enum.take(10)
  end

  def calculate_diversity_profile do
    all_species = EpistemologySpecies.get_all_species()
    species_count = length(all_species)
    attractors = detect_attractors()
    
    species_ent = min(1.0, species_count / 100.0)
    operator_ent = min(1.0, length(Enum.uniq(Enum.flat_map(all_species, & &1.operators))) / 15.0)
    niche_ent = species_ent * 0.8
    discovery_ent = min(1.0, length(BreakthroughAnalyzer.get_breakthroughs()) / 500.0)
    
    # Calculate simple phylogenetic diversity proxy
    phylo_div = min(1.0, operator_ent * 1.2)
    
    total_emergence = Enum.sum(Enum.map(attractors, & &1.emergence_count))
    top_3_emergence = attractors |> Enum.take(3) |> Enum.map(& &1.emergence_count) |> Enum.sum()
    conc = if total_emergence > 0, do: top_3_emergence / total_emergence, else: 0.0

    %DiversityProfile{
      operator_entropy: operator_ent,
      species_entropy: species_ent,
      niche_entropy: niche_ent,
      discovery_entropy: discovery_ent,
      phylogenetic_diversity: phylo_div,
      attractor_concentration: conc
    }
  end

  def certify_ecosystem_health(pipeline_telemetry \\ %{}) do
    all_species = EpistemologySpecies.get_all_species()
    breakthroughs = BreakthroughAnalyzer.get_breakthroughs()
    extinctions = Enum.sum(Enum.map(all_species, & &1.metrics.extinctions))
    
    %EcosystemHealth{
      diversity_profile: calculate_diversity_profile(),
      breakthrough_velocity: length(breakthroughs),
      extinction_velocity: extinctions
    }
  end

  def cluster_epistemic_archetypes(pipeline_telemetry \\ %{}) do
    all_species = EpistemologySpecies.get_all_species()
    grouped = Enum.group_by(all_species, fn sp -> length(sp.operators) end)
    
    Enum.map(grouped, fn {op_count, members} ->
      persistence = Enum.sum(Enum.map(members, & &1.metrics.active_duration)) / max(1, length(members))
      extinctions = Enum.sum(Enum.map(members, & &1.metrics.extinctions)) / max(1, length(members))
      dominant = members |> List.first() |> Map.get(:operators)
      
      %EpistemicArchetype{
        id: "ARCHETYPE_OP#{op_count}",
        dominant_operators: dominant,
        persistence: persistence,
        truth_retention: 0.8,
        disease_resistance: 0.7,
        breakthrough_profile: 0.05,
        extinction_rate: extinctions,
        deep_module_affinity: Map.get(pipeline_telemetry, :active_modules, %{})
      }
    end)
  end

  def identify_unknown_regions do
    [
      %UnknownRegion{
        operator_combination: ["recursive", "counterfactual", "mystic"],
        novelty_score: 0.95,
        accessibility_score: 0.3,
        instability_score: 0.8,
        exploration_priority: 0.85
      }
    ]
  end

  def calculate_species_distance(sp_a, sp_b) do
    set_a = MapSet.new(sp_a.operators)
    set_b = MapSet.new(sp_b.operators)
    intersection = MapSet.size(MapSet.intersection(set_a, set_b))
    union = MapSet.size(MapSet.union(set_a, set_b))
    1.0 - (intersection / max(1, union))
  end

  def calculate_landscape_distance(_landscape) do
    0.5
  end

  def calculate_fitness_gradient do
    %{"adversarial" => -0.2, "causal" => 0.05, "empirical" => 0.1}
  end

  def calculate_readiness_score(pipeline_telemetry \\ %{}) do
    state =
      case Process.whereis(TiannaraOS.CivilizationKernel) do
        nil -> nil
        pid ->
          if Process.alive?(pid) do
            TiannaraOS.CivilizationKernel.get_state()
          else
            nil
          end
      end

    {basin_escape_rate, productive_escape_rate, species_stability, extinction_cycles, species_diversity, regime_robustness, avg_epistemic_resilience} =
      if state do
        # 1. basin_escape_rate: ratio of successful CI runs over total CI runs
        twin_worlds = Enum.filter(Map.values(state.worlds), &(&1.twin != nil))
        all_ci_runs = Enum.flat_map(twin_worlds, fn w -> w.twin.ci_runs end)
        successful_ci_runs = Enum.count(all_ci_runs, &(&1.outcome == :success))
        total_ci = length(all_ci_runs)
        ci_rate = if total_ci > 0, do: successful_ci_runs / total_ci, else: 0.5

        # 2. productive_escape_rate: ratio of merged PRs
        all_prs = Enum.flat_map(twin_worlds, fn w -> w.twin.pull_requests end)
        merged_prs = Enum.count(all_prs, &(&1.status == :merged))
        total_prs = length(all_prs)
        pr_rate = if total_prs > 0, do: merged_prs / total_prs, else: 0.5

        # 3. species_stability: average active theories value
        theories = Map.values(state.theories)
        total_theories = length(theories)
        stability = if total_theories > 0, do: Enum.reduce(theories, 0.0, fn t, acc -> acc + (t.value || 0.5) end) / total_theories, else: 0.5

        # 4. extinction_cycles: count of low-confidence theories (retired)
        low_conf_count = Enum.count(state.evidence_graph, fn {_id, node} -> node.type == :theory and node.value < 0.3 end)
        ext_cycles = low_conf_count * 1.0

        # 5. species_diversity: normalized tool count
        total_tools = Map.size(state.tools)
        diversity = min(1.0, total_tools / 10.0)

        # 6. regime_robustness: average value of claims
        claims = Enum.filter(Map.values(state.evidence_graph), &(&1.type == :claim))
        robustness = if length(claims) > 0, do: Enum.reduce(claims, 0.0, fn c, acc -> acc + (c.value || 0.5) end) / length(claims), else: 0.5

        # 7. avg_epistemic_resilience: ratio of valid evidence nodes
        evidences = Enum.filter(Map.values(state.evidence_graph), &(&1.type == :evidence))
        valid_evs = Enum.count(evidences, &(&1.validity == :valid))
        total_evs = length(evidences)
        resilience = if total_evs > 0, do: valid_evs / total_evs, else: 0.5

        {ci_rate, pr_rate, stability, ext_cycles, diversity, robustness, resilience}
      else
        # Bootstrap seeds
        {0.5, 0.5, 0.5, 0.0, 0.5, 0.5, 0.5}
      end

    overall = (basin_escape_rate + productive_escape_rate + species_stability + (extinction_cycles/200.0) + species_diversity + regime_robustness + avg_epistemic_resilience) / 7.0

    %MetaCognitionReadiness{
      basin_escape_rate: basin_escape_rate,
      productive_escape_rate: productive_escape_rate,
      species_stability: species_stability,
      extinction_cycles: extinction_cycles,
      species_diversity: species_diversity,
      regime_robustness: regime_robustness,
      avg_epistemic_resilience: avg_epistemic_resilience,
      overall_score: overall
    }
  end

  def evaluate_graduation_gate(pipeline_telemetry \\ %{}) do
    %{
      atlas: calculate_species_atlas(pipeline_telemetry),
      ecology: calculate_operator_ecology(),
      health: certify_ecosystem_health(pipeline_telemetry),
      archetypes: cluster_epistemic_archetypes(pipeline_telemetry),
      unknowns: identify_unknown_regions(),
      landscape_topology: %{
        average_distance: calculate_landscape_distance([]),
        fitness_gradient: calculate_fitness_gradient()
      },
      readiness: calculate_readiness_score(pipeline_telemetry),
      pipeline_telemetry: pipeline_telemetry
    }
  end
end
