defmodule Tiannara.Engineering.EngineeringSynthesisEngine do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.Engineering.{DesignTranslator, DesignEvaluator, VerificationPlanner, Events}
  alias Tiannara.Engineering.Domain.{EngineeringInsight, EngineeringDesign}

  @impl Tiannara.ExecutiveService
  def id, do: :engineering_synthesis_engine

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [:engineering_translation, :design_evaluation, :verification_planning, :design_approval]
  end

  @impl Tiannara.ExecutiveService
  def dependencies, do: [:persistent_memory, :event_transport]

  @impl Tiannara.ExecutiveService
  def priority, do: :medium

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    stats = GenServer.call(__MODULE__, :stats)
    %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: id(), health: if(stats.healthy, do: 1.0, else: 0.0),
      constitutional_alignment: 1.0, transparency: 1.0, explainability: 1.0,
      evidence_quality: stats.approval_rate, human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  @impl Tiannara.ExecutiveService
  def health do
    GenServer.call(__MODULE__, :health)
  end

  @impl Tiannara.ExecutiveService
  def boot(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl Tiannara.ExecutiveService
  def shutdown(reason), do: GenServer.stop(__MODULE__, reason)

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def submit_insight(%EngineeringInsight{} = insight) do
    GenServer.call(__MODULE__, {:submit_insight, insight})
  end

  def active_designs do
    GenServer.call(__MODULE__, :active_designs)
  end

  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def init(_opts) do
    {:ok, %{active_designs: %{}, completed_designs: [], designs_generated: 0,
      designs_approved: 0, designs_rejected: 0, insights_processed: 0,
      approval_rate: 1.0, healthy: true, started_at: DateTime.utc_now()}}
  end

  @impl true
  def handle_call({:submit_insight, insight}, _from, state) do
    designs = DesignTranslator.translate(insight)

    Events.emit(:insight_received, insight.id, %{
      principle: insight.principle_statement, domain: insight.domain,
      designs_generated: length(designs)})

    evaluated = Enum.map(designs, fn design ->
      evaluation = DesignEvaluator.evaluate(design)
      decision = DesignEvaluator.approval_decision(design)
      Events.emit(:design_evaluated, design.id, %{
        composite_score: evaluation.composite_score, decision: decision,
        weakest_dimension: evaluation.weakest_dimension})
      {design, evaluation, decision}
    end)

    {approved, rejected} = Enum.split_with(evaluated, fn {_d, _e, decision} -> decision == :approve end)

    processed = Enum.map(approved, fn {design, evaluation, _decision} ->
      vplan = VerificationPlanner.plan(design)
      design = %{design | verification_plan: vplan, status: :approved}
      Events.emit(:design_approved, design.id, %{
        composite_score: evaluation.composite_score,
        verification_duration_hours: vplan.estimated_duration_hours})
      design
    end)

    Enum.each(rejected, fn {design, evaluation, _decision} ->
      Events.emit(:design_rejected, design.id, %{
        composite_score: evaluation.composite_score,
        recommendations: evaluation.recommendations})
    end)

    new_active = Map.new(processed, fn d -> {d.id, d} end)
    new_state = %{state | active_designs: Map.merge(state.active_designs, new_active),
      designs_generated: state.designs_generated + length(designs),
      designs_approved: state.designs_approved + length(approved),
      designs_rejected: state.designs_rejected + length(rejected),
      insights_processed: state.insights_processed + 1,
      approval_rate: safe_div(state.designs_approved + length(approved),
                              state.designs_generated + length(designs))}

    {:reply, {:ok, Enum.map(processed, & &1.id)}, new_state}
  end

  @impl true
  def handle_call(:active_designs, _from, state) do
    {:reply, Map.values(state.active_designs), state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{healthy: state.healthy, designs_generated: state.designs_generated,
      designs_approved: state.designs_approved, designs_rejected: state.designs_rejected,
      insights_processed: state.insights_processed, approval_rate: state.approval_rate,
      active_designs: map_size(state.active_designs)}, state}
  end

  @impl true
  def handle_call(:health, _from, state) do
    {:reply, if(state.healthy, do: :healthy, else: :degraded), state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp safe_div(_n, 0), do: 1.0
  defp safe_div(n, d), do: n / d
end
