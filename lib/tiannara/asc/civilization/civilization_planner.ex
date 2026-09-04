defmodule Tiannara.ASC.Civilization.Planner do
  use GenServer

  @horizons [10, 50, 100]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def generate_plan(world_state, risk, sustainability, equity, forecast) do
    GenServer.call(__MODULE__, {:generate, world_state, risk, sustainability, equity, forecast}, 60_000)
  end

  def plans, do: GenServer.call(__MODULE__, :plans)

  @impl true
  def init(_opts), do: {:ok, %{plans: [], total: 0}}

  @impl true
  def handle_call({:generate, world_state, risk, sustainability, equity, forecast}, _from, state) do
    plan = %{
      id: "plan_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
      horizons: generate_horizons(world_state, risk, sustainability, equity, forecast),
      priorities: identify_priorities(world_state, risk, sustainability),
      constraints: identify_constraints(risk, sustainability, equity),
      success_criteria: define_success_criteria(),
      review_schedule: define_review_schedule(),
      generated_at: DateTime.utc_now()
    }
    {:reply, {:ok, plan}, %{state | plans: [plan | state.plans] |> Enum.take(50), total: state.total + 1}}
  end

  def handle_call(:plans, _from, state), do: {:reply, state.plans, state}
  def handle_info(_, state), do: {:noreply, state}

  defp generate_horizons(world_state, _risk, sustainability, equity, _forecast) do
    Enum.map(@horizons, fn years ->
      %{
        horizon_years: years, objectives: generate_objectives(world_state, years),
        milestones: generate_milestones(years),
        risk_tolerance: risk_tolerance_for_horizon(years),
        sustainability_target: min(1.0, sustainability.score + years * 0.005),
        equity_target: min(1.0, equity.score + years * 0.003)
      }
    end)
  end

  defp generate_objectives(world_state, years) do
    [:technology, :ecology, :energy, :education, :medicine, :governance]
    |> Enum.map(fn domain ->
      current = Map.get(world_state, domain, 0.5)
      %{domain: domain, current: current, target: min(1.0, current + years * 0.01), gap: min(1.0, current + years * 0.01) - current}
    end)
    |> Enum.sort_by(& &1.gap, :desc)
    |> Enum.take(3)
  end

  defp generate_milestones(10), do: [%{year: 5, milestone: "Mid-term review"}, %{year: 10, milestone: "Decade assessment"}]
  defp generate_milestones(50), do: [%{year: 10, milestone: "First decade"}, %{year: 25, milestone: "Quarter-century"}, %{year: 50, milestone: "Half-century"}]
  defp generate_milestones(100), do: [%{year: 25, milestone: "Generation 1"}, %{year: 50, milestone: "Generation 2"}, %{year: 75, milestone: "Generation 3"}, %{year: 100, milestone: "Century assessment"}]

  defp risk_tolerance_for_horizon(10), do: 0.3
  defp risk_tolerance_for_horizon(50), do: 0.2
  defp risk_tolerance_for_horizon(100), do: 0.1

  defp identify_priorities(world_state, risk, sustainability) do
    (if risk.overall_risk > 0.5, do: [%{priority: :risk_reduction, urgency: :high}], else: [])
    ++ (if sustainability.score < 0.5, do: [%{priority: :sustainability_improvement, urgency: :high}], else: [])
    ++ (if Map.get(world_state, :energy, 0.5) < 0.5, do: [%{priority: :energy_transition, urgency: :medium}], else: [])
    ++ (if Map.get(world_state, :education, 0.5) < 0.5, do: [%{priority: :education_expansion, urgency: :medium}], else: [])
  end

  defp identify_constraints(_risk, _sustainability, _equity) do
    [
      %{constraint: "Must not increase existential risk", source: :global_risk},
      %{constraint: "Must not degrade ecological systems beyond recovery", source: :sustainability},
      %{constraint: "Must not compromise future generations' options", source: :intergenerational_equity},
      %{constraint: "Must maintain human authority over high-impact decisions", source: :constitutional_governance}
    ]
  end

  defp define_success_criteria do
    ["Scientific output increases by measurable amount each decade",
     "Engineering productivity improves continuously",
     "Sustainability index trends upward over 10-year windows",
     "No existential risk increase",
     "Intergenerational equity maintained or improved",
     "Human collaboration effectiveness maintained above 0.7"]
  end

  defp define_review_schedule do
    [%{interval_years: 1, type: :annual_review},
     %{interval_years: 5, type: :strategic_review},
     %{interval_years: 10, type: :paradigm_review},
     %{interval_years: 25, type: :generational_review}]
  end
end
