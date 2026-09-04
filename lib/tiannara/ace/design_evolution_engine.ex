defmodule Tiannara.ACE.DesignEvolutionEngine do
  @moduledoc """
  Evolves engineering designs through simulation-based selection.
  Pipeline: Problem → Design Space → Candidates → Simulation → Optimization → Selection → Prototype

  Similar to biological evolution:
  - Design Variation (mutation)
  - Simulation Selection (environment)
  - Engineering Constraints (fitness landscape)
  """
  use GenServer
  alias Tiannara.ACE.Models.{EngineeringProposal, DesignCandidate}

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)

  def evolve_design(pid, proposal), do: GenServer.call(pid, {:evolve, proposal})
  def get_best_design(pid, proposal_id), do: GenServer.call(pid, {:best, proposal_id})

  @impl true
  def init(_), do: {:ok, %{proposals: %{}, generations: %{}}}

  @impl true
  def handle_call({:evolve, proposal}, _from, state) do
    candidates = generate_initial_candidates(proposal)

    {evolved_candidates, generation} = Enum.reduce(1..10, {candidates, 0}, fn gen, {cands, _} ->
      evaluated = Enum.map(cands, &evaluate_candidate(&1, proposal))
      selected = select_best(evaluated, 5)
      mutated = mutate_designs(selected, proposal)
      {mutated, gen}
    end)

    best = Enum.max_by(evolved_candidates, & &1.fitness)

    updated_proposal = %{proposal |
      design_candidates: evolved_candidates,
      approval_status: :ready_for_simulation
    }

    state = put_in(state, [:proposals, proposal.id], updated_proposal)
    state = put_in(state, [:generations, proposal.id], generation)

    {:reply, {:ok, updated_proposal, best}, state}
  end

  @impl true
  def handle_call({:best, proposal_id}, _from, state) do
    case Map.get(state.proposals, proposal_id) do
      nil -> {:reply, {:error, :not_found}, state}
      proposal ->
        best = Enum.max_by(proposal.design_candidates, & &1.fitness, fn -> nil end)
        {:reply, {:ok, best}, state}
    end
  end

  defp generate_initial_candidates(proposal) do
    Enum.map(1..20, fn i ->
      %DesignCandidate{
        id: UUID.uuid4(),
        proposal_id: proposal.id,
        design_spec: generate_design_spec(proposal, i),
        performance_metrics: %{},
        resource_requirements: estimate_resources(proposal),
        failure_modes: [],
        fitness: 0.0,
        generation: 0,
        status: :evaluating
      }
    end)
  end

  defp generate_design_spec(proposal, variant) do
    %{
      architecture: "variant_#{variant}",
      components: proposal.required_capabilities,
      constraints: proposal.constraints
    }
  end

  defp estimate_resources(proposal) do
    %{
      materials: length(proposal.required_capabilities) * 10,
      energy: 100,
      time_cycles: 50
    }
  end

  defp evaluate_candidate(candidate, proposal) do
    performance = simulate_performance(candidate, proposal)
    fitness = calculate_fitness(candidate, performance, proposal)

    %{candidate |
      performance_metrics: performance,
      fitness: fitness,
      status: :evaluated
    }
  end

  defp simulate_performance(_candidate, _proposal) do
    %{
      efficiency: :rand.uniform() * 0.5 + 0.5,
      reliability: :rand.uniform() * 0.4 + 0.6,
      cost_effectiveness: :rand.uniform() * 0.6 + 0.4,
      scalability: :rand.uniform() * 0.5 + 0.5
    }
  end

  defp calculate_fitness(_candidate, performance, _proposal) do
    eff = performance.efficiency
    rel = performance.reliability
    cost = performance.cost_effectiveness
    scale = performance.scalability

    (eff * 0.3) + (rel * 0.3) + (cost * 0.2) + (scale * 0.2)
  end

  defp select_best(candidates, count) do
    candidates
    |> Enum.sort_by(& &1.fitness, :desc)
    |> Enum.take(count)
  end

  defp mutate_designs(selected, proposal) do
    mutations = Enum.flat_map(selected, fn parent ->
      Enum.map(1..2, fn _ ->
        %DesignCandidate{
          id: UUID.uuid4(),
          proposal_id: proposal.id,
          design_spec: mutate_spec(parent.design_spec),
          performance_metrics: %{},
          resource_requirements: parent.resource_requirements,
          failure_modes: [],
          fitness: 0.0,
          lineage: [parent.id | parent.lineage],
          generation: parent.generation + 1,
          status: :evaluating
        }
      end)
    end)
    selected ++ mutations
  end

  defp mutate_spec(spec) do
    %{spec | architecture: "#{spec.architecture}_mutated"}
  end
end
