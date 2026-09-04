defmodule Tiannara.Sentinel.Cognition.PriorityEngine do
  @moduledoc "Ranks investigations: Priority = Impact x Probability x Urgency x Knowledge Value."
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)
  def calculate(pid, hyp, pred), do: GenServer.call(pid, {:calculate, hyp, pred})

  @impl true
  def init(_), do: {:ok, %{}}

  @impl true
  def handle_call({:calculate, hyp, _pred}, _from, state) do
    impact = 0.8
    urgency = 0.7
    knowledge_value = 0.9
    score = impact * hyp.confidence * urgency * knowledge_value

    priority = %{
      hypothesis_id: hyp.id, score: score,
      tier: if(score > 0.7, do: :critical, else: :normal),
      breakdown: %{impact: impact, probability: hyp.confidence, urgency: urgency, knowledge_value: knowledge_value}
    }
    {:reply, priority, state}
  end
end
