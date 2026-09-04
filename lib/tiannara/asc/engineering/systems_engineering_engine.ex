defmodule Tiannara.ASC.Engineering.SystemsEngineeringEngine do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def generate_requirements(design) do
    GenServer.call(__MODULE__, {:requirements, design}, 30_000)
  end

  def trade_study(alternatives, criteria) do
    GenServer.call(__MODULE__, {:trade_study, alternatives, criteria}, 30_000)
  end

  @impl true
  def init(_opts) do
    {:ok, %{requirements_generated: 0, trade_studies: 0}}
  end

  @impl true
  def handle_call({:requirements, design}, _from, state) do
    reqs = %{
      design_id: Map.get(design, :id),
      functional: generate_functional_requirements(design),
      non_functional: generate_non_functional_requirements(design),
      constraints: generate_requirement_constraints(design),
      verification_matrix: generate_verification_matrix(design),
      generated_at: DateTime.utc_now()
    }

    {:reply, {:ok, reqs}, %{state | requirements_generated: state.requirements_generated + 1}}
  end

  @impl true
  def handle_call({:trade_study, alternatives, criteria}, _from, state) do
    scored = Enum.map(alternatives, fn alt ->
      scores = Map.new(criteria, fn criterion ->
        {criterion, score_alternative(alt, criterion)}
      end)

      total = scores |> Map.values() |> Enum.sum()
      weighted = total / max(1, length(criteria))

      %{alternative: alt, scores: scores, weighted_score: weighted}
    end)

    ranked = Enum.sort_by(scored, & &1.weighted_score, :desc)
    recommendation = hd(ranked)

    result = %{
      alternatives: length(alternatives),
      criteria: criteria,
      ranked: ranked,
      recommendation: recommendation.alternative,
      confidence: recommendation.weighted_score,
      generated_at: DateTime.utc_now()
    }

    {:reply, {:ok, result}, %{state | trade_studies: state.trade_studies + 1}}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp generate_functional_requirements(design) do
    components = Map.get(design, :components, [])

    Enum.map(components, fn comp ->
      %{
        id: "FR-#{comp.id}",
        description: "The system shall #{String.downcase(comp.description || "perform its function")}",
        priority: :shall,
        source: Map.get(design, :source_principle, "unnamed"),
        verifiable: true
      }
    end)
  end

  defp generate_non_functional_requirements(design) do
    constraints = Map.get(design, :constraints, %{})

    [
      %{id: "NFR-PERF-01", description: "Latency shall not exceed #{Map.get(constraints, :max_latency_ms, 1000)}ms", priority: :shall},
      %{id: "NFR-MEM-01", description: "Memory usage shall not exceed #{Map.get(constraints, :max_memory_mb, 512)}MB", priority: :shall},
      %{id: "NFR-AVAIL-01", description: "Availability shall be >= #{Map.get(constraints, :availability_target, 0.99) * 100}%", priority: :shall},
      %{id: "NFR-SAFE-01", description: "Safety constraints shall be enforced at all times", priority: :shall}
    ]
  end

  defp generate_requirement_constraints(design) do
    [
      %{id: "CON-01", description: "Must not depend on single vendor or platform"},
      %{id: "CON-02", description: "Must be verifiable through automated testing"},
      %{id: "CON-03", description: "Must maintain audit trail of all decisions"}
    ]
  end

  defp generate_verification_matrix(design) do
    %{
      method: [:test, :analysis, :inspection, :demonstration],
      coverage_target: 1.0,
      traceability: :requirement_to_test
    }
  end

  defp score_alternative(alternative, criterion) do
    case criterion do
      :cost -> 0.7
      :performance -> 0.8
      :reliability -> 0.75
      :maintainability -> 0.65
      :scalability -> 0.7
      _ -> 0.5
    end
  end
end
