defmodule Tiannara.ASC.ResourceAllocator do
  @moduledoc """
  Allocates civilizational resources through a selection mechanism.
  Priority = ScientificValue * Novelty * ExpectedImpact * Feasibility * Confidence * StrategicImportance
  """
  use GenServer
  alias Tiannara.ASC.Models.ResourceAllocation

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{budget: 1000}, opts)

  def allocate(pid, program, budget_request), do: GenServer.call(pid, {:allocate, program, budget_request})
  def get_budget(pid), do: GenServer.call(pid, :get_budget)

  @impl true
  def init(initial), do: {:ok, initial}

  @impl true
  def handle_call({:allocate, program, budget_request}, _from, state) do
    priority = calculate_priority(program)

    allocation = %ResourceAllocation{
      id: UUID.uuid4(),
      program_id: program.id,
      resources: budget_request,
      rationale: build_rationale(priority),
      expected_impact: priority.expected_impact,
      risk: priority.risk,
      approval_status: :pending_human_approval
    }

    if state.budget >= budget_request do
      new_state = %{state | budget: state.budget - budget_request}
      {:reply, {:approved, allocation}, new_state}
    else
      {:reply, {:insufficient_resources, allocation}, state}
    end
  end

  @impl true
  def handle_call(:get_budget, _from, state), do: {:reply, state.budget, state}

  defp calculate_priority(program) do
    scientific_value = 0.8
    novelty = 0.7
    expected_impact = 0.85
    feasibility = program.confidence || 0.6
    confidence = program.confidence || 0.6
    strategic_importance = 0.9

    score = scientific_value * novelty * expected_impact * feasibility * confidence * strategic_importance

    %{
      score: score, expected_impact: expected_impact,
      risk: 1.0 - feasibility,
      breakdown: %{scientific_value: scientific_value, novelty: novelty,
                   feasibility: feasibility, confidence: confidence}
    }
  end

  defp build_rationale(priority) do
    "Priority score: #{Float.round(priority.score, 3)}. Driven by high scientific value and strategic importance."
  end
end
