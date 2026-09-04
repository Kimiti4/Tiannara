defmodule Tiannara.Interface.DiscoveryPresenter do
  @moduledoc """
  Discovery Presenter — formats discoveries for human comprehension.
  Transforms raw internal data structures into clear human-readable presentations.
  """

  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec present(map()) :: %{title: String.t(), body: String.t(), evidence: [term()]}
  def present(discovery) do
    GenServer.call(__MODULE__, {:present, discovery})
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(_opts) do
    {:ok, %{total_presented: 0}}
  end

  @impl true
  def handle_call({:present, discovery}, _from, state) do
    {:reply, format_discovery(discovery), %{state | total_presented: state.total_presented + 1}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{total_presented: state.total_presented}, state}
  end

  defp format_discovery(%{type: :anomaly} = discovery) do
    %{title: "Anomaly Detected: #{discovery[:domain]} / #{discovery[:signal]}",
      body: "**Severity:** #{discovery[:severity] || :unknown}\n**Domain:** #{discovery[:domain]}\n**Signal:** #{discovery[:signal]}\n**Confidence:** #{format_confidence(discovery[:confidence])}\n\n**What happened:**\n#{discovery[:rationale] || "An anomalous signal was detected."}\n\n**Evidence:**\n#{format_evidence_list(discovery[:evidence] || [])}\n\n**Recommended action:**\n#{discovery[:recommended_action] || "Monitor closely; investigate if trend continues."}",
      evidence: discovery[:evidence] || []}
  end

  defp format_discovery(%{type: :knowledge_contradiction} = discovery) do
    %{title: "Knowledge Contradiction Detected",
      body: "**Confidence:** #{format_confidence(discovery[:confidence])}\n\n**Contradiction:**\n#{discovery[:rationale] || "Two validated knowledge items contradict each other."}\n\n**Item A:** #{inspect(discovery[:item_a])}\n**Item B:** #{inspect(discovery[:item_b])}\n\n**Recommended action:**\n#{discovery[:recommended_action] || "Re-investigate both items; design discriminating experiment."}",
      evidence: discovery[:evidence] || []}
  end

  defp format_discovery(%{type: :experiment_convergence} = discovery) do
    %{title: "Experimental Convergence: #{discovery[:count] || "Multiple"} Experiments Agree",
      body: "**Confidence:** #{format_confidence(discovery[:confidence])}\n\n**Finding:**\n#{discovery[:rationale] || "Multiple independent experiments converged on the same conclusion."}\n\n**Converging experiments:**\n#{format_evidence_list(discovery[:experiment_ids] || [])}\n\n**Implication:**\n#{discovery[:implication] || "High-confidence knowledge candidate ready for integration."}",
      evidence: discovery[:evidence] || []}
  end

  defp format_discovery(%{type: :degradation} = discovery) do
    %{title: "Runtime Degradation Detected: #{discovery[:signal]}",
      body: "**Severity:** #{discovery[:severity] || :warning}\n**Signal:** #{discovery[:signal]}\n**Confidence:** #{format_confidence(discovery[:confidence])}\n\n**Observation:**\n#{discovery[:rationale] || "Performance degradation detected."}\n\n**Current value:** #{inspect(discovery[:value])}\n**Threshold:** #{inspect(discovery[:threshold])}\n\n**Recommended action:**\n#{discovery[:recommended_action] || "Investigate root cause; consider scaling or optimization."}",
      evidence: discovery[:evidence] || []}
  end

  defp format_discovery(discovery) do
    %{title: discovery[:title] || "Discovery",
      body: "**Source:** #{discovery[:source] || :unknown}\n**Confidence:** #{format_confidence(discovery[:confidence])}\n\n#{discovery[:rationale] || inspect(discovery)}\n\n**Recommended action:**\n#{discovery[:recommended_action] || "Review and assess."}",
      evidence: discovery[:evidence] || []}
  end

  defp format_confidence(nil), do: "Not quantified"
  defp format_confidence(score) when is_float(score), do: "#{Float.round(score * 100, 1)}%"
  defp format_confidence(score), do: inspect(score)

  defp format_evidence_list([]), do: "No specific evidence available."
  defp format_evidence_list(items) do
    items |> Enum.with_index(1) |> Enum.map(fn {item, idx} ->
      case item do
        %{rationale: r} -> "#{idx}. #{r}"
        text when is_binary(text) -> "#{idx}. #{text}"
        other -> "#{idx}. #{inspect(other)}"
      end
    end) |> Enum.join("\n")
  end
end
