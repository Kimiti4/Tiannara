defmodule Tiannara.Discovery.Cycle do
  @states [:idle, :scanning, :gap_analysis, :hypothesis_generation, :prediction,
           :experiment_planning, :prioritization, :dispatch, :waiting_for_evidence,
           :evidence_integration, :knowledge_update, :metrics]

  @transitions %{
    idle: [:scanning], scanning: [:gap_analysis, :idle],
    gap_analysis: [:hypothesis_generation, :idle],
    hypothesis_generation: [:prediction, :idle],
    prediction: [:experiment_planning, :idle],
    experiment_planning: [:prioritization, :idle],
    prioritization: [:dispatch, :metrics, :idle],
    dispatch: [:waiting_for_evidence, :idle],
    waiting_for_evidence: [:evidence_integration, :idle],
    evidence_integration: [:knowledge_update, :idle],
    knowledge_update: [:metrics, :idle],
    metrics: [:idle]
  }

  def states, do: @states
  def next_states(current) when current in @states, do: Map.get(@transitions, current, [])
  def valid_transition?(from, to) when from in @states and to in @states, do: to in Map.get(@transitions, from, [])
  def valid_transition?(_, _), do: false

  def new(discovery_id, opts \\ %{}) do
    %{discovery_id: discovery_id, state: :idle, metadata: Map.put(opts, :started_at, DateTime.utc_now()),
      cycle_count: 0, hypotheses_generated: 0, experiments_dispatched: 0,
      evidence_collected: 0, completed_at: nil}
  end

  def transition(cycle, new_state) do
    current = cycle.state
    if valid_transition?(current, new_state) do
      {:ok, Map.merge(cycle, %{state: new_state,
        metadata: Map.put(cycle.metadata, :last_transition, %{from: current, to: new_state, at: DateTime.utc_now()})})}
    else
      {:error, {:invalid_transition, current, new_state}}
    end
  end

  def completed?(%{state: :idle, completed_at: ts}) when not is_nil(ts), do: true
  def completed?(_), do: false
  def interruptible?(%{state: :idle}), do: false
  def interruptible?(_), do: true
end
