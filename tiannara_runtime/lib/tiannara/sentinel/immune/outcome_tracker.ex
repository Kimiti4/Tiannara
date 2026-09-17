defmodule Tiannara.Sentinel.Immune.OutcomeTracker do
  @moduledoc """
  Listens to ongoing runtime ticks. If a recommendation's evaluation_tick
  arrives, it captures the current state delta and forwards to the Evaluator.
  """
  use GenServer

  alias Tiannara.Sentinel.Immune.RecommendationJournal
  alias Tiannara.Sentinel.Immune.RecommendationEvaluator

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def process_tick(current_tick, current_metrics) do
    GenServer.cast(__MODULE__, {:process_tick, current_tick, current_metrics})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:process_tick, current_tick, current_metrics}, state) do
    pending = RecommendationJournal.get_pending_evaluation()
    
    Enum.each(pending, fn intervention ->
      if intervention.evaluation_tick && current_tick >= intervention.evaluation_tick do
        # Time to evaluate!
        RecommendationEvaluator.evaluate_outcome(intervention, current_metrics)
      end
    end)

    {:noreply, state}
  end
end
