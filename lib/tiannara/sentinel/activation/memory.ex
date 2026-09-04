defmodule Tiannara.Sentinel.Activation.Memory do
  @moduledoc """
  Epistemic Memory Integration — converts every Sentinel event into
  structured knowledge that feeds back into the Reality Graph and
  Tiannara's memory architecture.

  Data → Information → Knowledge → Pattern → Model → Engineering Insight
  """

  alias Tiannara.Sentinel.Activation.Event

  @doc """
  Records the outcome of an intervention into the epistemic memory.
  Stores successful and failed interventions, causal discoveries,
  invalid hypotheses, and recovered archaeology.
  """
  @spec record_outcome(Event.t(), map(), :success | :failure) :: :ok
  def record_outcome(%Event{} = event, outcome_data, result) do
    knowledge_record = %{
      event_id: event.id,
      category: event.category,
      source: event.source,
      observation: event.observation,
      interpretation: event.interpretation,
      root_cause: event.interpretation,
      action_taken: outcome_data.action,
      result: result,
      confidence: event.confidence,
      timestamp: DateTime.utc_now()
    }

    Tiannara.RealityGraph.add_node(:epistemic_event, knowledge_record)
    Tiannara.Memory.store(:sentinel_lessons, knowledge_record)

    :ok
  end
end
