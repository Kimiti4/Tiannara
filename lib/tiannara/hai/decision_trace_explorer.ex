defmodule Tiannara.HAI.DecisionTraceExplorer do
  alias Tiannara.HAI.Domain.DecisionTrace
  alias Tiannara.Discovery.Discovery

  @spec trace_discovery(Discovery.t()) :: DecisionTrace.t()
  def trace_discovery(%Discovery{} = disc) do
    DecisionTrace.new(%{
      decision_id: disc.id, subsystem: :autonomous_discovery_engine,
      trigger: "Knowledge gap detected: #{disc.gap && disc.gap.description}",
      inputs: %{gap: disc.gap && %{id: disc.gap.id, domain: disc.gap.domain, severity: disc.gap.severity},
        hypothesis_count: length(disc.hypotheses), prediction_count: length(disc.predictions),
        experiment_count: length(disc.experiments)},
      steps: build_discovery_steps(disc),
      outputs: %{conclusion: disc.conclusion, confidence: disc.confidence,
        uncertainty: disc.uncertainty, status: disc.status},
      confidence_at_each_step: build_confidence_path(disc),
      total_duration_ms: compute_duration(disc), replayable: true
    })
  end

  @spec trace_from_events([map()]) :: DecisionTrace.t()
  def trace_from_events(events) when is_list(events) do
    steps = events
      |> Enum.sort_by(&Map.get(&1, :timestamp, DateTime.utc_now()))
      |> Enum.with_index()
      |> Enum.map(fn {event, idx} ->
        %{step: idx + 1, event_type: Map.get(event, :event_type, :unknown),
          description: describe_event(event), timestamp: Map.get(event, :timestamp),
          data_summary: summarize_event_data(Map.get(event, :data, %{}))}
      end)

    DecisionTrace.new(%{
      decision_id: "from_events", subsystem: :event_history,
      trigger: "Reconstructed from #{length(events)} events",
      inputs: %{event_count: length(events)}, steps: steps,
      outputs: %{final_event: List.last(events)},
      confidence_at_each_step: [], total_duration_ms: 0, replayable: true
    })
  end

  @spec summarize(DecisionTrace.t()) :: String.t()
  def summarize(%DecisionTrace{} = trace) do
    steps_text = trace.steps |> Enum.map(fn step ->
      "  #{step.step}. [#{step.event_type}] #{step.description}"
    end) |> Enum.join("\n")

    "Decision Trace: #{trace.decision_id}\n" <>
    "Subsystem: #{trace.subsystem}\n" <>
    "Trigger: #{trace.trigger}\n" <>
    "Duration: #{trace.total_duration_ms}ms\n" <>
    "Replayable: #{trace.replayable}\n\n" <>
    "Steps (#{length(trace.steps)}):\n#{steps_text}\n\n" <>
    "Output:\n" <>
    "  Confidence: #{get_in(trace.outputs, [:confidence]) || "N/A"}\n" <>
    "  Status: #{get_in(trace.outputs, [:status]) || "N/A"}\n"
  end

  defp build_discovery_steps(%Discovery{} = disc) do
    steps = [%{step: 1, event_type: :gap_detected,
      description: "Knowledge gap identified: #{disc.gap && disc.gap.description}",
      timestamp: disc.created_at,
      data_summary: %{domain: disc.gap && disc.gap.domain, severity: disc.gap && disc.gap.severity}}]

    steps = steps ++ [%{step: 2, event_type: :hypotheses_generated,
      description: "#{length(disc.hypotheses)} competing hypotheses generated",
      timestamp: disc.created_at,
      data_summary: %{hypotheses: Enum.map(disc.hypotheses, & &1.statement)}}]

    steps = steps ++ [%{step: 3, event_type: :predictions_made,
      description: "#{length(disc.predictions)} falsifiable predictions derived",
      timestamp: disc.updated_at,
      data_summary: %{prediction_count: length(disc.predictions)}}]

    steps = steps ++ [%{step: 4, event_type: :experiments_planned,
      description: "#{length(disc.experiments)} experiments designed",
      timestamp: disc.updated_at,
      data_summary: %{experiment_types: Enum.map(disc.experiments, & &1.type)}}]

    steps = steps ++ [%{step: 5, event_type: :evidence_collected,
      description: "#{length(disc.evidence)} evidence items collected",
      timestamp: disc.updated_at,
      data_summary: %{outcomes: Enum.map(disc.evidence, & &1.outcome)}}]

    if disc.conclusion do
      steps ++ [%{step: 6, event_type: :conclusion_reached,
        description: "Conclusion: #{Map.get(disc.conclusion, :summary, "reached")}",
        timestamp: disc.completed_at || disc.updated_at, data_summary: disc.conclusion}]
    else
      steps
    end
  end

  defp build_confidence_path(%Discovery{} = disc) do
    disc.lineage
    |> Enum.filter(fn event -> Map.has_key?(event, :new_confidence) end)
    |> Enum.map(fn event -> %{event: event.event, confidence: event.new_confidence, at: event.at} end)
  end

  defp compute_duration(%Discovery{created_at: created, completed_at: nil, updated_at: updated}) do
    DateTime.diff(updated, created, :millisecond)
  end
  defp compute_duration(%Discovery{created_at: created, completed_at: completed}) when not is_nil(completed) do
    DateTime.diff(completed, created, :millisecond)
  end
  defp compute_duration(_), do: 0

  defp describe_event(event) do
    case Map.get(event, :event_type) do
      :gap_detected -> "Knowledge gap detected"
      :hypothesis_generated -> "Hypothesis generated"
      :prediction_created -> "Prediction created"
      :experiment_planned -> "Experiment planned"
      :evidence_collected -> "Evidence collected"
      :belief_updated -> "Belief updated"
      :knowledge_promoted -> "Knowledge promoted"
      :discovery_completed -> "Discovery completed"
      other -> "Event: #{other}"
    end
  end

  defp summarize_event_data(data) when is_map(data) do
    data |> Map.take([:confidence, :outcome, :gap_id, :hypothesis_id, :evidence_count])
         |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()
  end
  defp summarize_event_data(_), do: %{}
end
