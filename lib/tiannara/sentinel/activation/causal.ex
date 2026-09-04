defmodule Tiannara.Sentinel.Activation.Causal do
  @moduledoc """
  Moves from "What happened?" to "Why did it happen?".
  Integrates with Reality Graph, REA lineage, and Archaeology records
  to produce causal interpretations for epistemic events.
  """

  alias Tiannara.Sentinel.Activation.Event

  @doc """
  Analyzes the event to determine root causes and causal links.
  Returns the event populated with interpretation, confidence, and causal_links.
  """
  @spec interpret(Event.t()) :: Event.t()
  def interpret(%Event{} = event) do
    causal_paths = Tiannara.RealityGraph.find_causal_paths(event.source, event.observation)

    root_cause = extract_root_cause(causal_paths)
    confidence = calculate_causal_confidence(causal_paths)

    %{event |
      causal_links: causal_paths,
      interpretation: root_cause,
      confidence: confidence
    }
  end

  defp extract_root_cause([]), do: "Unknown causal pattern"
  defp extract_root_cause([path | _]), do: Map.get(path, :root_cause, "No root cause identified")

  defp calculate_causal_confidence([]), do: 0.1
  defp calculate_causal_confidence([path | _]), do: Map.get(path, :confidence, 0.5)
end
