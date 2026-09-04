defmodule Tiannara.Sentinel.Activation.Intelligence do
  @moduledoc """
  Determines whether observations matter.
  Filters noise and calculates importance scores based on
  Impact, Confidence, Novelty, and Urgency.
  """

  alias Tiannara.Sentinel.Activation.Event

  @doc """
  Evaluates an event and returns its importance score and priority.
  """
  @spec evaluate(Event.t()) :: %{event: Event.t(), importance: float(), priority: atom()}
  def evaluate(%Event{} = event) do
    if noise?(event) do
      %{event: event, importance: 0.0, priority: :ignore}
    else
      importance = calculate_importance(event)
      priority = determine_priority(importance, event.severity)
      %{event: tag_event(event, priority), importance: importance, priority: priority}
    end
  end

  defp noise?(%Event{category: :runtime, severity: :info, confidence: conf}) when not is_nil(conf) and conf < 0.5, do: true
  defp noise?(%Event{category: :runtime, severity: :info, confidence: nil}), do: true
  defp noise?(_), do: false

  defp calculate_importance(%Event{} = event) do
    impact = severity_weight(event.severity)
    confidence = event.confidence || 0.5
    novelty = novelty_score(event)
    urgency = urgency_score(event)

    impact * confidence * novelty * urgency
  end

  defp severity_weight(:critical), do: 1.0
  defp severity_weight(:warning), do: 0.6
  defp severity_weight(:info), do: 0.2

  defp novelty_score(%Event{metadata: %{historical_frequency: freq}}) when is_number(freq) and freq > 0 do
    1.0 / (1.0 + :math.log(freq + 1))
  end

  defp novelty_score(_), do: 0.8

  defp urgency_score(%Event{severity: :critical}), do: 1.0
  defp urgency_score(%Event{severity: :warning}), do: 0.7
  defp urgency_score(_), do: 0.3

  defp determine_priority(importance, severity) do
    cond do
      importance > 0.7 or severity == :critical -> :high
      importance > 0.4 or severity == :warning -> :medium
      true -> :low
    end
  end

  defp tag_event(event, priority) do
    %{event | metadata: Map.put(event.metadata, :priority, priority)}
  end
end
