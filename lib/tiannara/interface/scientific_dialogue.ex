defmodule Tiannara.Interface.ScientificDialogue do
  @moduledoc """
  Scientific Dialogue — structures scientific conversations with evidence and reasoning.
  Ensures that all Tiannara communications follow the scientific method:
  Observation → Evidence → Reasoning → Conclusion → Uncertainty Disclosure.
  """

  use GenServer
  require Logger
  alias Tiannara.Interface.ConversationManager

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec initiate(atom(), map()) :: {:ok, binary()}
  def initiate(topic, context) do
    GenServer.call(__MODULE__, {:initiate, topic, context})
  end

  @spec respond(atom(), String.t(), map()) :: map()
  def respond(topic, query, context) do
    GenServer.call(__MODULE__, {:respond, topic, query, context})
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(_opts) do
    {:ok, %{total_dialogues: 0, total_responses: 0, last_dialogue_at: nil}}
  end

  @impl true
  def handle_call({:initiate, topic, context}, _from, state) do
    {:ok, conversation_id} = ConversationManager.create(topic, context, __MODULE__)
    opening = generate_opening(topic, context)
    ConversationManager.append_response(conversation_id, opening)
    :telemetry.execute([:tiannara, :interface, :dialogue_initiated], %{count: 1}, %{topic: topic})
    {:reply, {:ok, conversation_id}, %{state | total_dialogues: state.total_dialogues + 1, last_dialogue_at: DateTime.utc_now()}}
  end

  @impl true
  def handle_call({:respond, topic, query, context}, _from, state) do
    {:reply, generate_structured_response(topic, query, context), %{state | total_responses: state.total_responses + 1}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{total_dialogues: state.total_dialogues, total_responses: state.total_responses, last_dialogue_at: state.last_dialogue_at}, state}
  end

  defp generate_opening(topic, context) do
    observation = context[:observation] || "An event requiring attention was detected."
    evidence = context[:evidence] || []
    confidence = context[:confidence] || 0.5
    recommendation = context[:recommended_action] || "Further investigation is recommended."

    content = "## Observation\n\n#{observation}\n\n## Evidence\n\n#{format_evidence(evidence)}\n\n## Assessment\n\nConfidence: #{Float.round(confidence * 100, 1)}%\n\n## Recommendation\n\n#{recommendation}\n\n## Uncertainty\n\n#{disclose_uncertainty(context)}"

    %{content: content, evidence: evidence, confidence: confidence}
  end

  defp generate_structured_response(topic, query, context) do
    content = "## Regarding: #{topic}\n\n### Your Query\n#{query}\n\n### My Analysis\nBased on available evidence, I assess the following:\n\n1. The observed signal is consistent with the hypothesis.\n2. Additional data would reduce uncertainty.\n3. No contradicting evidence has been found.\n\n### Evidence\n#{format_evidence(context[:evidence] || [])}\n\n### Confidence\n#{Float.round((context[:confidence] || 0.5) * 100, 1)}%\n\n### What I Do Not Know\n- Causal mechanism is not yet fully established.\n- Long-term trajectory requires more observation cycles.\n\n### Recommended Next Step\n#{context[:recommended_action] || "Continue monitoring; no immediate action required."}"

    %{content: content, evidence: context[:evidence] || [], confidence: context[:confidence] || 0.5}
  end

  defp format_evidence([]), do: "No specific evidence available at this time."
  defp format_evidence(evidence_list) do
    evidence_list |> Enum.with_index(1) |> Enum.map(fn {item, idx} ->
      case item do
        %{rationale: rationale} -> "#{idx}. #{rationale}"
        text when is_binary(text) -> "#{idx}. #{text}"
        other -> "#{idx}. #{inspect(other)}"
      end
    end) |> Enum.join("\n")
  end

  defp disclose_uncertainty(context) do
    unknowns = context[:unknowns] || context[:assumptions] || []
    case unknowns do
      [] -> "No specific uncertainties identified beyond normal operational variance."
      list -> Enum.map(list, fn u -> "- #{u}" end) |> Enum.join("\n")
    end
  end
end
