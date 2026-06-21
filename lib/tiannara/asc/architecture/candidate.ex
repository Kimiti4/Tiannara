defmodule Tiannara.ASC.Architecture.Candidate do
  @moduledoc """
  An architecture candidate — a first-class evolutionary organism.

  Implements the full REA organism contract so architecture candidates
  can be evolved through `Tiannara.REA.UniversalEvolutionEngine.tick_population/2`
  without any additional evolutionary machinery.

  ## Organism Contract

    * `fitness/2`       — composite weighted score across 7 dimensions
    * `mutate/2`        — applies a random mutation operator to the genome
    * `recombine/3`     — combines patterns/tech_stack from two parent candidates
    * `niche/1`         — architecture style atom (prevents monoculture)
    * `extinct?/2`      — true if composite_fitness < extinction threshold
    * `archive/2`       — returns an `EvolutionaryRuin` for the ArchaeologyRegistry
    * `transferability/1` — cross-project transfer fitness (Q1 addition for Phase 12)

  ## Evolution Semantics

  ```
  Architecture A             Architecture B
  (modular_monolith)         (event_driven)
       ↓                          ↓
     mutate                   mutate
       ↓                          ↓
  Architecture A'            Architecture B'
       ↓
    recombine(A', B')
       ↓
  Hybrid Architecture C
  ```
  """

  @derive Jason.Encoder
  defstruct [
    :id,
    :project_id,
    :style,
    :genome,
    :fitness_scores,
    :composite_fitness,
    :generation,
    :lineage_id,
    :status,
    :effective_fitness,  # populated by UniversalEvolutionEngine second-order selection
    :metadata
  ]

  @type style ::
    :modular_monolith
    | :microservices
    | :event_driven
    | :actor_based
    | :hybrid
    | :layered
    | :hexagonal
    | :cqrs_event_sourcing

  @type genome :: %{
    patterns: [String.t()],
    protocols: [String.t()],
    tech_stack: [String.t()]
  }

  @type fitness_scores :: %{
    complexity:          float(),
    performance:         float(),
    cost:                float(),
    reliability:         float(),
    security:            float(),
    maintainability:     float(),
    evolution_potential: float()
  }

  @type t :: %__MODULE__{
    id:               String.t(),
    project_id:       String.t(),
    style:            style(),
    genome:           genome(),
    fitness_scores:   fitness_scores(),
    composite_fitness: float(),
    generation:       non_neg_integer(),
    lineage_id:       String.t(),
    status:           :competing | :selected | :archived,
    effective_fitness: float() | nil,
    metadata:         map()
  }

  @fitness_weights %{
    complexity:          -0.15,   # negative: higher complexity = lower fitness
    performance:          0.20,
    cost:                -0.10,   # negative: higher cost = lower fitness
    reliability:          0.20,
    security:             0.20,
    maintainability:      0.15,
    evolution_potential:  0.10
  }

  # -------------------------------------------------------------------------
  # Construction
  # -------------------------------------------------------------------------

  @doc "Create a seed architecture candidate for a project."
  @spec new(String.t(), style()) :: t()
  def new(project_id, style) do
    id = "cand_#{:erlang.unique_integer([:positive, :monotonic])}"
    %__MODULE__{
      id: id,
      project_id: project_id,
      style: style,
      genome: seed_genome(style),
      fitness_scores: neutral_fitness(),
      composite_fitness: 0.5,
      generation: 0,
      lineage_id: id,
      status: :competing,
      effective_fitness: nil,
      metadata: %{}
    }
  end

  # -------------------------------------------------------------------------
  # REA Organism Contract
  # -------------------------------------------------------------------------

  @doc "Composite fitness. Weights defined in @fitness_weights."
  @spec fitness(t(), map()) :: float()
  def fitness(%__MODULE__{} = candidate, _env) do
    raw =
      Enum.reduce(@fitness_weights, 0.0, fn {dim, weight}, acc ->
        score = Map.get(candidate.fitness_scores, dim, 0.5)
        acc + score * weight
      end)

    # Normalize into 0.0–1.0
    normalised = (raw + 1.0) / 2.0
    Float.round(normalised, 4)
  end

  @doc "Apply a random mutation to the candidate's genome."
  @spec mutate(t(), map()) :: t()
  def mutate(%__MODULE__{} = candidate, env) do
    mutation = Enum.random([:add_pattern, :replace_protocol, :add_tech, :style_shift])
    mutated_genome = apply_mutation(candidate.genome, mutation, candidate.style, env)

    %{candidate |
      id: "cand_#{:erlang.unique_integer([:positive, :monotonic])}",
      genome: mutated_genome,
      generation: candidate.generation + 1,
      composite_fitness: fitness(%{candidate | genome: mutated_genome}, env),
      status: :competing
    }
  end

  @doc "Recombine two parent candidates. Takes union of patterns, intersection logic for tech_stack."
  @spec recombine(t(), [t()], map()) :: t()
  def recombine(%__MODULE__{} = parent_a, [parent_b | _], env) do
    merged_patterns  = (parent_a.genome.patterns ++ parent_b.genome.patterns) |> Enum.uniq() |> Enum.take(8)
    merged_protocols = (parent_a.genome.protocols ++ parent_b.genome.protocols) |> Enum.uniq() |> Enum.take(5)
    merged_tech      = interleave(parent_a.genome.tech_stack, parent_b.genome.tech_stack) |> Enum.take(6)

    child_genome = %{patterns: merged_patterns, protocols: merged_protocols, tech_stack: merged_tech}
    child_style  = if :rand.uniform() > 0.5, do: parent_a.style, else: parent_b.style

    child = %__MODULE__{
      id: "cand_#{:erlang.unique_integer([:positive, :monotonic])}",
      project_id: parent_a.project_id,
      style: if(child_style == parent_a.style and child_style == parent_b.style, do: child_style, else: :hybrid),
      genome: child_genome,
      fitness_scores: neutral_fitness(),
      composite_fitness: 0.5,
      generation: max(parent_a.generation, parent_b.generation) + 1,
      lineage_id: parent_a.lineage_id,
      status: :competing,
      effective_fitness: nil,
      metadata: %{parents: [parent_a.id, parent_b.id]}
    }

    %{child | composite_fitness: fitness(child, env)}
  end

  @doc "Niche is the architecture style — prevents monoculture via UniversalEvolutionEngine niche-aware selection."
  @spec niche(t()) :: style()
  def niche(%__MODULE__{} = candidate), do: candidate.style

  @doc "Extinct when fitness drops below the environment threshold (default 0.05)."
  @spec extinct?(t(), map()) :: boolean()
  def extinct?(%__MODULE__{} = candidate, env) do
    threshold = Map.get(env, :extinction_threshold, 0.05)
    fitness(candidate, env) < threshold
  end

  @doc "Produce an archive record for the ArchaeologyRegistry."
  @spec archive(t(), keyword()) :: map()
  def archive(%__MODULE__{} = candidate, opts \\ []) do
    %{
      id: "ruin_#{candidate.id}",
      organism_id: candidate.id,
      type: :architecture_candidate,
      reason: Keyword.get(opts, :reason, :unknown),
      epoch: Keyword.get(opts, :epoch, 0),
      genome: candidate.genome,
      style: candidate.style,
      final_fitness: candidate.composite_fitness,
      project_id: candidate.project_id,
      metadata: candidate.metadata
    }
  end

  @doc """
  Transferability score — how well this architecture pattern can be
  applied to a different project context.

  Used by Phase 12 (Meta-Learning) for cross-project architecture transfer.
  High transferability architectures are candidates for injection into new
  project genomes via `ASC.MetaLearning.Civilization`.
  """
  @spec transferability(t()) :: float()
  def transferability(%__MODULE__{} = candidate) do
    # Patterns and protocols that are domain-agnostic transfer better
    generic_patterns = ~w[hexagonal clean_architecture domain_driven ports_and_adapters cqrs]
    generic_count = Enum.count(candidate.genome.patterns, &(&1 in generic_patterns))
    pattern_score = min(generic_count / max(length(candidate.genome.patterns), 1), 1.0)

    # Lower coupling (maintainability proxy) → higher transferability
    maintainability = Map.get(candidate.fitness_scores, :maintainability, 0.5)
    evolution_potential = Map.get(candidate.fitness_scores, :evolution_potential, 0.5)

    Float.round((pattern_score * 0.4 + maintainability * 0.3 + evolution_potential * 0.3), 4)
  end

  # -------------------------------------------------------------------------
  # Private helpers
  # -------------------------------------------------------------------------

  defp seed_genome(:modular_monolith) do
    %{patterns: ["layered", "service_layer", "domain_model"],
      protocols: ["http_rest", "grpc"], tech_stack: ["elixir", "postgresql", "phoenix"]}
  end
  defp seed_genome(:microservices) do
    %{patterns: ["saga", "api_gateway", "strangler_fig"],
      protocols: ["http_rest", "grpc", "amqp"], tech_stack: ["elixir", "docker", "kubernetes", "postgresql"]}
  end
  defp seed_genome(:event_driven) do
    %{patterns: ["event_sourcing", "cqrs", "pub_sub"],
      protocols: ["amqp", "kafka", "nats"], tech_stack: ["elixir", "kafka", "postgresql", "phoenix"]}
  end
  defp seed_genome(:actor_based) do
    %{patterns: ["actor_model", "supervision_tree", "let_it_crash"],
      protocols: ["otp_distribution", "grpc"], tech_stack: ["elixir", "otp", "mnesia"]}
  end
  defp seed_genome(:hybrid) do
    %{patterns: ["modular_monolith", "event_sourcing", "hexagonal"],
      protocols: ["http_rest", "nats"], tech_stack: ["elixir", "postgresql", "phoenix", "nats"]}
  end
  defp seed_genome(_) do
    %{patterns: ["layered"], protocols: ["http_rest"], tech_stack: ["elixir", "postgresql"]}
  end

  defp neutral_fitness do
    %{complexity: 0.5, performance: 0.5, cost: 0.5, reliability: 0.5,
      security: 0.5, maintainability: 0.5, evolution_potential: 0.5}
  end

  defp apply_mutation(genome, :add_pattern, _style, _env) do
    all_patterns = ~w[hexagonal clean_architecture ports_and_adapters saga circuit_breaker bulkhead]
    new_pattern = Enum.random(all_patterns)
    %{genome | patterns: Enum.uniq([new_pattern | genome.patterns]) |> Enum.take(8)}
  end
  defp apply_mutation(genome, :replace_protocol, _style, _env) do
    all_protocols = ~w[http_rest grpc amqp nats kafka websocket graphql]
    new_protocol = Enum.random(all_protocols)
    %{genome | protocols: Enum.uniq([new_protocol | genome.protocols]) |> Enum.take(5)}
  end
  defp apply_mutation(genome, :add_tech, _style, _env) do
    all_tech = ~w[redis elasticsearch prometheus grafana oban broadway nx rustler]
    new_tech = Enum.random(all_tech)
    %{genome | tech_stack: Enum.uniq([new_tech | genome.tech_stack]) |> Enum.take(6)}
  end
  defp apply_mutation(genome, :style_shift, _style, _env) do
    # Remove a pattern (simplification mutation)
    %{genome | patterns: Enum.drop(genome.patterns, 1)}
  end

  defp interleave([], b), do: b
  defp interleave(a, []), do: a
  defp interleave([ha | ta], [hb | tb]), do: [ha, hb | interleave(ta, tb)]
end
