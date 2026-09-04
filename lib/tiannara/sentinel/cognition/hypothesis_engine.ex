defmodule Tiannara.Sentinel.Cognition.HypothesisEngine do
  @moduledoc "Generates scientific hypotheses from observations and causal analysis."
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)
  def formulate(pid, event, causal), do: GenServer.call(pid, {:formulate, event, causal})

  @impl true
  def init(_), do: {:ok, %{}}

  @impl true
  def handle_call({:formulate, event, causal}, _from, state) do
    hypothesis = %Tiannara.Sentinel.Cognition.Hypothesis{
      id: UUID.uuid4(),
      observation: event.observation,
      question: "Why is #{event.source} experiencing #{event.observation}?",
      hypothesis: "The #{causal.root_cause} is causing the observed degradation.",
      prediction: "Intervening on #{causal.root_cause} will restore baseline metrics by >15%.",
      evidence: [event.id],
      confidence: causal.confidence,
      status: :proposed
    }
    {:reply, hypothesis, state}
  end
end
