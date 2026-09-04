defmodule Tiannara.Sentinel.Cognition.ExperimentPlanner do
  @moduledoc "Creates structured experiment proposals for human approval."
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)
  def design(pid, hypothesis), do: GenServer.call(pid, {:design, hypothesis})

  @impl true
  def init(_), do: {:ok, %{}}

  @impl true
  def handle_call({:design, hyp}, _from, state) do
    experiment = %Tiannara.Sentinel.Cognition.Experiment{
      id: UUID.uuid4(), hypothesis_id: hyp.id,
      observation: hyp.observation, research_question: hyp.question, hypothesis: hyp.hypothesis,
      independent_variables: [:pruning_frequency, :retention_policy],
      dependent_variables: [:memory_usage, :retrieval_latency],
      controls: [:baseline_configuration],
      expected_outcome: "+20% discovery improvement, memory stabilization",
      failure_conditions: ["Retrieval latency increases > 50ms", "Memory usage continues to grow"],
      validation_metrics: [:memory_delta, :discovery_yield],
      rollback_plan: "Revert to previous pruning configuration via Sandbox."
    }
    {:reply, experiment, state}
  end
end
