defmodule Tiannara.Sentinel.Cognition.ConfidenceEngine do
  @moduledoc "Calculates epistemic confidence. Penalizes for contradictions and unknowns."
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)
  def evaluate(pid, hypothesis), do: GenServer.call(pid, {:evaluate, hypothesis})

  @impl true
  def init(_), do: {:ok, %{}}

  @impl true
  def handle_call({:evaluate, hyp}, _from, state) do
    evidence_quality = 0.85
    evidence_quantity = min(length(hyp.evidence) / 10.0, 1.0)
    contradiction_penalty = length(hyp.contradictions) * 0.1
    unknown_penalty = length(hyp.unknown_variables) * 0.05

    raw = (evidence_quality * 0.4) + (evidence_quantity * 0.6)
    adjusted = max(0.0, raw - contradiction_penalty - unknown_penalty)

    result = %{
      hypothesis_id: hyp.id, confidence: Float.round(adjusted, 2),
      evidence_quality: evidence_quality, evidence_quantity: evidence_quantity,
      contradictions: length(hyp.contradictions), unknowns: length(hyp.unknown_variables)
    }
    {:reply, result, state}
  end
end
