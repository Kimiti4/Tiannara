defmodule Tiannara.Sentinel.Activation.Dialogue do
  @moduledoc """
  Manages Sentinel-initiated conversations.
  Acts as a scientific communication channel — not a chatbot.
  Sentinel observes, interprets, and proposes; humans decide.
  """

  alias Tiannara.Sentinel.Activation.Event

  @doc """
  Initiates a dialogue with the human operator based on the event.
  Formats the observation, interpretation, and recommendations into
  a structured message and pushes it to the Observatory interface.
  """
  @spec initiate(Event.t(), list(map())) :: :ok
  def initiate(%Event{} = event, recommendations) do
    message = format_message(event, recommendations)

    Tiannara.Observatory.push_dialogue(%{
      event_id: event.id,
      category: event.category,
      severity: event.severity,
      message: message,
      requires_response: event.requires_human
    })
  end

  defp format_message(event, recommendations) do
    recs_text = if recommendations == [] do
      "  No specific recommendations generated."
    else
      Enum.map_join(recommendations, "\n", fn r ->
        "  - #{r.action} (Expected gain: #{r.expected_gain}, Risk: #{r.risk})"
      end)
    end

    """
    [Sentinel Event #{String.slice(event.id, 0..7)}]
    Category: #{event.category} | Severity: #{event.severity}

    Observation:
      #{event.observation}

    Interpretation:
      #{event.interpretation || "Pending analysis"}

    Confidence: #{Float.round(event.confidence || 0.0, 2)}

    Recommended Actions:
    #{recs_text}

    Status: #{if event.requires_human, do: "Awaiting human direction.", else: "Information only."}
    """
  end
end
