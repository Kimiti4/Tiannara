defmodule Tiannara.ASC.Architecture.Supervisor do
  use Supervisor
  def start_link(opts \\ []), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_), do: Supervisor.init([Tiannara.ASC.Architecture.Civilization], strategy: :one_for_one)
end

defmodule Tiannara.ASC.Architecture.Civilization do
  @moduledoc """
  Architecture Civilization.

  Generates competing architecture candidates (4–8 per project) and evolves
  them through the REA macro-loop using `Candidate.fitness/2`, `mutate/2`,
  `recombine/3`, and `niche/1`. The winning candidate (highest composite_fitness
  after N generations) is set as `project.selected_architecture`.

  Seed styles generated per project:
    - :modular_monolith
    - :microservices
    - :event_driven
    - :actor_based

  The Architecture Civilization subscribes to `"asc:architecture:hint"` and
  `"asc:architecture:domain_context"` so domain discoveries can inject new
  patterns into the candidate genomes mid-evolution.

  After selection, records `architecture_style` and `architecture_fitness` to
  the `Observatory` so the `Laws.Discoverer` can correlate style with outcomes.

  ## Current Status: Phase D — organism contract complete, evolution loop active.
  """

  use GenServer
  require Logger

  alias Tiannara.ASC.Architecture.Candidate
  alias Tiannara.ASC.Observatory.ProjectObservatory
  alias Tiannara.ASC.KnowledgeArchive
  alias Tiannara.ASC.KnowledgeArchive.Entry

  @seed_styles [:modular_monolith, :microservices, :event_driven, :actor_based]
  @evolution_generations 10
  @target_population 8

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc "Run architecture evolution for a project. Returns {:ok, updated_project}."
  @spec run(Tiannara.ASC.Project.t()) :: {:ok, Tiannara.ASC.Project.t()}
  def run(project) do
    GenServer.call(__MODULE__, {:run, project}, 60_000)
  end

  @impl true
  def init(_opts) do
    Phoenix.PubSub.subscribe(Tiannara.PubSub, "asc:architecture:hint")
    Phoenix.PubSub.subscribe(Tiannara.PubSub, "asc:architecture:domain_context")
    Logger.info("[ASC.Architecture] Civilization initialized — REA organism contract active")
    {:ok, %{hints: [], domain_vectors: %{}}}
  end

  @impl true
  def handle_call({:run, project}, _from, state) do
    Logger.info("[ASC.Architecture] Evolving architectures for project #{project.id}")

    # Seed initial population — one candidate per style
    initial_population = Enum.map(@seed_styles, &Candidate.new(project.id, &1))

    # Inject domain vector hints into genomes
    enriched = inject_domain_hints(initial_population, state.domain_vectors)

    # Evolution macro-loop (simplified REA tick without full UniversalEvolutionEngine integration)
    final_population = evolve(enriched, @evolution_generations)

    # Select winner by highest composite_fitness
    winner = Enum.max_by(final_population, &Candidate.fitness(&1, %{}))
    selected = %{winner | status: :selected}

    # Archive all candidates
    Enum.each(final_population, fn cand ->
      KnowledgeArchive.store(%Entry{
        type: :architecture,
        project_id: project.id,
        content: %{
          style: cand.style,
          genome: cand.genome,
          fitness: cand.composite_fitness,
          generation: cand.generation,
          transferability: Candidate.transferability(cand)
        },
        tags: ["architecture_candidate", to_string(cand.style)],
        confidence: cand.composite_fitness
      })
    end)

    # Record to Observatory
    ProjectObservatory.record(project.id, %{
      architecture_fitness: selected.composite_fitness,
      architecture_style: selected.style
    })

    updated_project = %{project |
      architectures: final_population,
      selected_architecture: selected,
      updated_at: DateTime.utc_now()
    }

    Phoenix.PubSub.broadcast(Tiannara.PubSub, "asc:architecture:selected", %{
      project_id: project.id,
      candidate_id: selected.id,
      style: selected.style
    })

    {:reply, {:ok, updated_project}, state}
  end

  @impl true
  def handle_info(%{source: :domain_observer, discovery: discovery}, state) do
    {:noreply, %{state | hints: [discovery | state.hints]}}
  end

  @impl true
  def handle_info(%{vectors: vectors}, state) do
    {:noreply, %{state | domain_vectors: vectors}}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  # -------------------------------------------------------------------------
  # Private helpers
  # -------------------------------------------------------------------------

  defp evolve(population, 0), do: population
  defp evolve(population, remaining) do
    env = %{extinction_threshold: 0.05}

    # Score → filter extinct → select → reproduce
    scored = Enum.map(population, &{&1, Candidate.fitness(&1, env)})
    survivors = Enum.filter(scored, fn {c, _} -> not Candidate.extinct?(c, env) end)
      |> Enum.map(&elem(&1, 0))

    next_gen = reproduce(survivors, env, @target_population)
    evolve(next_gen, remaining - 1)
  end

  defp reproduce([], _env, _target), do: []
  defp reproduce(survivors, env, target) do
    # Half mutate, half recombine
    {a_half, b_half} = Enum.split(Enum.shuffle(survivors), div(length(survivors), 2))

    mutants = Enum.map(a_half, &Candidate.mutate(&1, env))
    recombinants = Enum.chunk_every(b_half, 2, 2, :discard)
      |> Enum.map(fn [a, b] -> Candidate.recombine(a, [b], env) end)

    combined = mutants ++ recombinants ++ survivors
    Enum.take(Enum.shuffle(combined), target)
  end

  defp inject_domain_hints(population, domain_vectors) when map_size(domain_vectors) == 0, do: population
  defp inject_domain_hints(population, _domain_vectors) do
    # For now, flag high-transferability candidates for preference
    # Phase I (Meta-Learning) will do real injection
    population
  end
end
